"""Business logic for the Invoice system. Kept out of views on purpose so
every rule here is independently unit-testable without touching HTTP.

Rule map (see apps/invoices/tests.py for the matching tests):
  a) get_or_create_open_invoice   - one open invoice per customer
  b) split_payment_across_meters  - even split of paid_amount across meters
  c) add_meter_entry              - mileage correction device/meter memory_type match
  d) log_action (via apps.audit)  - full edit history on every mutation
  e) generate_public_share_token  - short, URL-safe, unguessable share link
  f) determine_status             - Unpaid / Partial Paid / Paid transitions
  g) apply_red_list_check         - consecutive-shortfall customer red-listing (Phase 2 rule)
"""
import secrets
from decimal import ROUND_HALF_UP, Decimal

from django.db import IntegrityError, transaction
from django.db.models import DecimalField, F, Sum
from django.utils import timezone

from apps.audit.services import log_action
from apps.invoices.exceptions import InvoiceError
from apps.meters.serializers import MeterSerializer
from apps.services.serializers import ServiceSerializer

TWO_PLACES = Decimal("0.01")


# --- id / token generation (rule e) ----------------------------------------

def generate_public_share_token(length=10):
    """Short, URL-safe, cryptographically random token - grants read-only
    access to an invoice with no login, so it must not be guessable."""
    from apps.invoices.models import Invoice

    while True:
        token = secrets.token_urlsafe(8)[:length]
        if not Invoice.all_objects.filter(public_share_token=token).exists():
            return token


def generate_invoice_no():
    """INV-<year>-<5 digit sequence>, sequential per year."""
    from apps.invoices.models import Invoice

    prefix = f"INV-{timezone.now().year}-"
    last = (
        Invoice.all_objects.filter(invoice_no__startswith=prefix)
        .order_by("-invoice_no")
        .first()
    )
    next_seq = int(last.invoice_no.rsplit("-", 1)[-1]) + 1 if last else 1
    return f"{prefix}{next_seq:05d}"


def create_invoice(customer, user=None):
    """Always creates a brand new Invoice row. Callers wanting rule (a)'s
    "reuse the open invoice" behavior should use get_or_create_open_invoice()
    instead - this is the low-level constructor it (and only it) calls."""
    from apps.invoices.models import Invoice

    for _ in range(5):
        try:
            with transaction.atomic():
                return Invoice.objects.create(customer=customer, created_by=user)
        except IntegrityError:
            continue  # invoice_no/public_share_token collision - retry with fresh values
    raise InvoiceError("Could not generate a unique invoice number, please retry.")


# --- rule (a): one open invoice per customer --------------------------------

def get_or_create_open_invoice(customer, user=None):
    """A customer may only have one open (Unpaid/Partial Paid) invoice at a
    time. If one exists, new work gets added to it instead of a new invoice
    being created. Only once it's fully paid (or cancelled) does the next
    visit get a fresh invoice.

    Returns (invoice, created).
    """
    from apps.invoices.models import Invoice

    open_invoice = (
        Invoice.objects.filter(customer=customer, status__in=[Invoice.Status.UNPAID, Invoice.Status.PARTIAL])
        .order_by("-created_at")
        .first()
    )
    if open_invoice:
        return open_invoice, False

    invoice = create_invoice(customer, user=user)
    log_action(invoice, "invoice_created", f"Invoice {invoice.invoice_no} created for {customer.name}.", user=user)
    return invoice, True


def _ensure_editable(invoice):
    if not invoice.is_editable:
        raise InvoiceError(
            f"Invoice {invoice.invoice_no} is {invoice.get_status_display()} and can no longer be edited."
        )


def _run_validation(func, *args):
    """Calls a DRF-style validation function (which raises
    rest_framework.exceptions.ValidationError) and re-raises any failure as
    a domain-level InvoiceError, so callers only ever need to catch one
    exception type."""
    try:
        func(*args)
    except Exception as exc:
        raise InvoiceError(str(getattr(exc, "detail", exc)))


# --- adding line items -------------------------------------------------------

def add_meter_entry(
    invoice,
    meter,
    serial_number,
    condition_note="",
    previous_km=None,
    current_km=None,
    mileage_correction_device=None,
    user=None,
):
    """Rule (c): if a mileage_correction_device is given, it must be able to
    service this meter's memory_type - reuses the Phase 3 rule directly."""
    from apps.invoices.models import InvoiceMeterEntry

    _ensure_editable(invoice)

    if mileage_correction_device is not None:
        _run_validation(MeterSerializer.validate_mileage_correction_tool, meter.memory_type, mileage_correction_device.name)

    entry = InvoiceMeterEntry.objects.create(
        invoice=invoice,
        meter=meter,
        serial_number=serial_number,
        condition_note=condition_note,
        previous_km=previous_km,
        current_km=current_km,
        mileage_correction_device=mileage_correction_device,
        created_by=user,
    )
    log_action(invoice, "meter_entry_added", f"Added meter {meter.title} (serial {serial_number}).", user=user)

    if invoice.paid_amount > 0:
        split_payment_across_meters(invoice)

    return entry


def add_service_line(invoice, service, meter_entry=None, price_charged=None, user=None):
    """If `service`'s category is Mileage Correction, `meter_entry` is
    required and must already carry previous_km/current_km/condition_note
    (the Phase 4 services rule)."""
    from apps.invoices.models import InvoiceServiceLine

    _ensure_editable(invoice)

    if meter_entry is not None and meter_entry.invoice_id != invoice.id:
        raise InvoiceError("meter_entry does not belong to this invoice.")

    if service.requires_mileage_correction_fields:
        if meter_entry is None:
            raise InvoiceError(f'"{service.name}" requires a meter entry to record the mileage correction against.')
        _run_validation(
            ServiceSerializer.validate_invoice_line_fields,
            service, meter_entry.previous_km, meter_entry.current_km, meter_entry.condition_note,
        )

    if price_charged is None:
        price_charged = service.service_price

    line = InvoiceServiceLine.objects.create(
        invoice=invoice, meter_entry=meter_entry, service=service, price_charged=price_charged, created_by=user,
    )
    log_action(invoice, "service_line_added", f"Added service '{service.name}' for {price_charged}.", user=user)
    recalculate_invoice_totals(invoice)
    return line


def add_product_line(invoice, product, quantity, price_charged=None, user=None):
    from apps.invoices.models import InvoiceProductLine

    _ensure_editable(invoice)

    if quantity <= 0:
        raise InvoiceError("quantity must be positive.")
    if product.current_stock_quantity < quantity:
        raise InvoiceError(
            f"Not enough stock for {product.name}: {product.current_stock_quantity} available, {quantity} requested."
        )

    if price_charged is None:
        price_charged = product.sale_price

    line = InvoiceProductLine.objects.create(
        invoice=invoice, product=product, quantity=quantity, price_charged=price_charged, created_by=user,
    )

    product.current_stock_quantity -= quantity
    product.save(update_fields=["current_stock_quantity", "updated_at"])

    log_action(
        invoice, "product_line_added", f"Added {quantity} x '{product.name}' at {price_charged} each.", user=user,
    )
    recalculate_invoice_totals(invoice)
    return line


# --- payments -----------------------------------------------------------------

def add_payment(invoice, amount, payment_method, note="", payment_date=None, user=None):
    from apps.invoices.models import Invoice, InvoicePayment

    if invoice.status in (Invoice.Status.PAID, Invoice.Status.CANCELLED):
        raise InvoiceError(
            f"Invoice {invoice.invoice_no} is {invoice.get_status_display()} and cannot receive further payments."
        )

    amount = Decimal(amount)
    if amount <= 0:
        raise InvoiceError("Payment amount must be positive.")

    outstanding = invoice.total_amount - invoice.paid_amount
    if amount > outstanding:
        raise InvoiceError(f"Payment of {amount} exceeds the outstanding balance of {outstanding}.")

    payment = InvoicePayment.objects.create(
        invoice=invoice,
        amount=amount,
        payment_method=payment_method,
        note=note,
        payment_date=payment_date or timezone.now(),
        created_by=user,
    )

    recalculate_invoice_totals(invoice)
    split_payment_across_meters(invoice)
    log_action(invoice, "payment_added", f"Payment of {amount} recorded via {payment_method}.", user=user)
    apply_red_list_check(invoice, user=user)
    return payment


# --- totals / status (rule f) --------------------------------------------------

def determine_status(total_amount, paid_amount):
    from apps.invoices.models import Invoice

    if paid_amount <= 0:
        return Invoice.Status.UNPAID
    if total_amount > 0 and paid_amount >= total_amount:
        return Invoice.Status.PAID
    return Invoice.Status.PARTIAL


def recalculate_invoice_totals(invoice):
    from apps.invoices.models import Invoice

    service_total = invoice.service_lines.aggregate(total=Sum("price_charged"))["total"] or Decimal("0")
    product_total = (
        invoice.product_lines.aggregate(
            total=Sum(F("price_charged") * F("quantity"), output_field=DecimalField(max_digits=12, decimal_places=2))
        )["total"]
        or Decimal("0")
    )
    payment_total = invoice.payments.aggregate(total=Sum("amount"))["total"] or Decimal("0")

    invoice.total_amount = service_total + product_total
    invoice.paid_amount = payment_total
    new_status = determine_status(invoice.total_amount, invoice.paid_amount)

    # Sticky: once this invoice has ever been underpaid, remember it even
    # after it's eventually paid off in full - the red-list rule needs this.
    if new_status == Invoice.Status.PARTIAL:
        invoice.had_shortfall = True

    invoice.status = new_status
    invoice.save(update_fields=["total_amount", "paid_amount", "status", "had_shortfall", "updated_at"])
    return invoice


# --- rule (b): even split of paid_amount across meter entries -----------------

def split_payment_across_meters(invoice):
    """When a customer pays less than the invoice total and multiple meters
    are on that invoice, the paid amount is split evenly across the meter
    entries (not weighted by each meter's own service cost).

    Example: 3 meters, service costs 400 + 400 + 500 = 1300 total, customer
    pays 1200 -> each meter entry's paid_share = 1200 / 3 = 400.00.

    Rounding remainders (when paid_amount doesn't divide evenly) are folded
    into the first entry so the shares always sum exactly to paid_amount.
    """
    entries = list(invoice.meter_entries.order_by("service_date"))
    if not entries:
        return

    count = len(entries)
    share = (invoice.paid_amount / count).quantize(TWO_PLACES, rounding=ROUND_HALF_UP)
    remainder = invoice.paid_amount - (share * count)

    for index, entry in enumerate(entries):
        entry.paid_share = share + (remainder if index == 0 else Decimal("0"))
        entry.save(update_fields=["paid_share"])


# --- rule (g): customer red-listing on consecutive shortfalls (Phase 2, wired up) -

def _consecutive_shortfall_streak(customer, upto_invoice):
    """Walks the customer's invoices backward from `upto_invoice` (most
    recent first, cancelled invoices ignored) and counts how many in a row
    have had_shortfall=True, stopping at the first one that doesn't."""
    from apps.invoices.models import Invoice

    invoices = (
        Invoice.objects.filter(customer=customer, created_at__lte=upto_invoice.created_at)
        .exclude(status=Invoice.Status.CANCELLED)
        .order_by("-created_at")
    )
    streak = 0
    for inv in invoices:
        if inv.had_shortfall:
            streak += 1
        else:
            break
    return streak


def apply_red_list_check(invoice, user=None):
    """Rule: when an invoice becomes fully paid, check whether it (and the
    customer's immediately preceding invoice) ever had a shortfall - i.e.
    passed through Partial Paid before being settled. Two such invoices in
    a row red-lists the customer.

    Reuses Customer.evaluate_red_list_status() from Phase 2 by feeding it
    the customer's current consecutive-shortfall streak with threshold=2.
    This is symmetric/self-healing: an invoice paid in full with no
    shortfall resets the streak to 0, which clears the red-list flag via
    that same method.
    """
    from apps.invoices.models import Invoice

    if invoice.status != Invoice.Status.PAID:
        return

    customer = invoice.customer
    streak = _consecutive_shortfall_streak(customer, invoice)
    was_red_listed = customer.is_red_listed

    customer.evaluate_red_list_status(streak, threshold=2)

    if customer.is_red_listed and not was_red_listed:
        log_action(
            invoice, "customer_red_listed",
            f"{customer.name} red-listed: {streak} consecutive invoices had a payment shortfall.",
            user=user,
        )
    elif was_red_listed and not customer.is_red_listed:
        log_action(
            invoice, "customer_red_list_cleared",
            f"{customer.name} cleared from the red list: latest invoice settled without a shortfall streak.",
            user=user,
        )


# --- cancellation ---------------------------------------------------------------

def cancel_invoice(invoice, user=None):
    from apps.invoices.models import Invoice

    if invoice.status == Invoice.Status.PAID:
        raise InvoiceError("A fully paid invoice cannot be cancelled.")

    invoice.status = Invoice.Status.CANCELLED
    invoice.save(update_fields=["status", "updated_at"])
    log_action(invoice, "invoice_cancelled", "Invoice cancelled.", user=user)
    return invoice
