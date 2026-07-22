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
  h) apply_discount               - fixed-BDT invoice-level discount, Admin only
  i) add_service_line             - merged meter+service flow for Mileage Correction
                                     services (creates InvoiceMeterEntry + InvoiceServiceLine
                                     together), with meter/service price defaulting
  j) update_service_line/delete_service_line/update_product_line/delete_product_line -
                                     edit & remove individual line items on an editable invoice
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


def add_service_line(
    invoice, service, meter_entry=None, price_charged=None, asset_used=None,
    meter=None, serial_number="", condition_note="", previous_km=None, current_km=None,
    mileage_correction_device=None, user=None,
):
    """Rule (i): the merged "add service" flow.

    For a regular repair service (category != Mileage Correction), this
    behaves exactly as before: `meter_entry` is an optional link to an
    already-existing InvoiceMeterEntry on this invoice, and everything
    else (meter/serial_number/condition_note/previous_km/current_km/
    mileage_correction_device) is ignored.

    For a Mileage Correction service, one of two things must be true:
      - `meter_entry` already points at an existing entry on this invoice
        (legacy path - still supported so old callers keep working), or
      - `meter_entry` is None and `meter` is given instead, in which case
        this creates a brand new InvoiceMeterEntry (via add_meter_entry(),
        rule c) and the InvoiceServiceLine together, in one transaction.
        The frontend never needs to call the standalone meter-entries
        endpoint for this case.
    Either way, previous_km/current_km/condition_note must be present (the
    services-app rule) before the line can be saved.

    Price defaulting: an explicit `price_charged` always wins. Otherwise it
    defaults to the meter's sales_price for a Mileage Correction service,
    or the service's own service_price for a regular repair.

    `asset_used` is optional - tags which shop tool/accessory performed the
    repair, feeding that asset's revenue tracking (see
    apps.assets.services.compute_asset_stats())."""
    from apps.invoices.models import InvoiceServiceLine

    _ensure_editable(invoice)

    if meter_entry is not None and meter_entry.invoice_id != invoice.id:
        raise InvoiceError("meter_entry does not belong to this invoice.")

    with transaction.atomic():
        if service.requires_mileage_correction_fields:
            if meter_entry is None:
                if meter is None:
                    raise InvoiceError(
                        f'"{service.name}" requires a meter to record the mileage correction against.'
                    )
                _run_validation(
                    ServiceSerializer.validate_invoice_line_fields, service, previous_km, current_km, condition_note,
                )
                meter_entry = add_meter_entry(
                    invoice, meter, serial_number=serial_number, condition_note=condition_note,
                    previous_km=previous_km, current_km=current_km,
                    mileage_correction_device=mileage_correction_device, user=user,
                )
            else:
                _run_validation(
                    ServiceSerializer.validate_invoice_line_fields,
                    service, meter_entry.previous_km, meter_entry.current_km, meter_entry.condition_note,
                )

        if price_charged is None:
            price_charged = meter_entry.meter.sales_price if service.requires_mileage_correction_fields else service.service_price

        line = InvoiceServiceLine.objects.create(
            invoice=invoice, meter_entry=meter_entry, service=service, price_charged=price_charged,
            asset_used=asset_used, created_by=user,
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


# --- rule (j): editing / removing individual line items ------------------------
#
# All four functions below share the same shape: confirm the line belongs to
# `invoice`, confirm the invoice is still editable, apply only the fields the
# caller actually passed (so a partial edit never clobbers untouched fields),
# log a human-readable audit entry, and recompute the invoice's totals (and
# re-split payment across meters, where relevant) so total_amount/due_amount
# never drift from what's actually on the invoice.

_METER_ENTRY_EDITABLE_FIELDS = {
    "serial_number", "condition_note", "previous_km", "current_km", "mileage_correction_device",
}


def update_service_line(invoice, service_line, user=None, **fields):
    """Edits an InvoiceServiceLine and, for a mileage-correction line, its
    linked InvoiceMeterEntry - together, in one call (so e.g. changing
    previous_km doesn't need a separate request). Only keys present in
    `fields` are changed; anything not passed is left untouched. `fields`
    may contain price_charged, asset_used, and - only for a line whose
    meter_entry is set - serial_number/condition_note/previous_km/
    current_km/mileage_correction_device."""
    if service_line.invoice_id != invoice.id:
        raise InvoiceError("This service line does not belong to this invoice.")
    _ensure_editable(invoice)

    meter_entry = service_line.meter_entry
    meter_entry_fields = {k: v for k, v in fields.items() if k in _METER_ENTRY_EDITABLE_FIELDS}
    if meter_entry_fields and meter_entry is None:
        raise InvoiceError("This service line has no linked meter entry to update.")

    changes = []

    if meter_entry_fields:
        new_device = meter_entry_fields.get("mileage_correction_device", meter_entry.mileage_correction_device)
        if "mileage_correction_device" in meter_entry_fields and new_device is not None:
            _run_validation(
                MeterSerializer.validate_mileage_correction_tool, meter_entry.meter.memory_type, new_device.name,
            )

        updated_fields = []
        for field_name, value in meter_entry_fields.items():
            if getattr(meter_entry, field_name) != value:
                changes.append(f"{field_name} changed from {getattr(meter_entry, field_name)!r} to {value!r}")
                setattr(meter_entry, field_name, value)
                updated_fields.append(field_name)

        if updated_fields:
            if service_line.service.requires_mileage_correction_fields:
                _run_validation(
                    ServiceSerializer.validate_invoice_line_fields,
                    service_line.service, meter_entry.previous_km, meter_entry.current_km, meter_entry.condition_note,
                )
            meter_entry.save(update_fields=updated_fields + ["updated_at"])

    if "price_charged" in fields and fields["price_charged"] != service_line.price_charged:
        changes.append(f"price_charged changed from {service_line.price_charged} to {fields['price_charged']}")
        service_line.price_charged = fields["price_charged"]

    if "asset_used" in fields and fields["asset_used"] != service_line.asset_used:
        old_name = service_line.asset_used.name if service_line.asset_used else "none"
        new_name = fields["asset_used"].name if fields["asset_used"] else "none"
        changes.append(f"asset_used changed from {old_name} to {new_name}")
        service_line.asset_used = fields["asset_used"]

    if changes:
        service_line.save()
        log_action(
            invoice, "service_line_updated",
            f"Updated service '{service_line.service.name}': {'; '.join(changes)}.", user=user,
        )
        recalculate_invoice_totals(invoice)
        if invoice.paid_amount > 0:
            split_payment_across_meters(invoice)

    return service_line


def delete_service_line(invoice, service_line, user=None):
    """Removes an InvoiceServiceLine. If it was a mileage-correction line
    and no other (non-deleted) service line still references the same
    InvoiceMeterEntry, that entry is removed too - so a Mileage Correction
    line and the meter it was billed against are added and removed as one
    unit, matching how they're created together in add_service_line()."""
    if service_line.invoice_id != invoice.id:
        raise InvoiceError("This service line does not belong to this invoice.")
    _ensure_editable(invoice)

    meter_entry = service_line.meter_entry
    description = f"Removed service '{service_line.service.name}' ({service_line.price_charged})."

    service_line.delete()  # soft delete, see BaseModel.delete()

    if meter_entry is not None and not meter_entry.service_lines.exists():
        description += (
            f" Also removed linked meter entry for {meter_entry.meter.title} (serial {meter_entry.serial_number})."
        )
        meter_entry.delete()  # soft delete

    log_action(invoice, "service_line_deleted", description, user=user)
    recalculate_invoice_totals(invoice)
    if invoice.paid_amount > 0:
        split_payment_across_meters(invoice)


def update_product_line(invoice, product_line, user=None, **fields):
    """Edits an InvoiceProductLine. A changed `quantity` adjusts the
    product's current_stock_quantity by the delta (same stock rule as
    add_product_line: can't drop stock below zero)."""
    if product_line.invoice_id != invoice.id:
        raise InvoiceError("This product line does not belong to this invoice.")
    _ensure_editable(invoice)

    product = product_line.product
    changes = []

    if "quantity" in fields and fields["quantity"] != product_line.quantity:
        new_quantity = fields["quantity"]
        delta = new_quantity - product_line.quantity
        if delta > 0 and product.current_stock_quantity < delta:
            raise InvoiceError(
                f"Not enough stock for {product.name}: {product.current_stock_quantity} available, "
                f"{delta} more requested."
            )
        product.current_stock_quantity -= delta
        product.save(update_fields=["current_stock_quantity", "updated_at"])
        changes.append(f"quantity changed from {product_line.quantity} to {new_quantity}")
        product_line.quantity = new_quantity

    if "price_charged" in fields and fields["price_charged"] != product_line.price_charged:
        changes.append(f"price_charged changed from {product_line.price_charged} to {fields['price_charged']}")
        product_line.price_charged = fields["price_charged"]

    if changes:
        product_line.save()
        log_action(
            invoice, "product_line_updated", f"Updated '{product.name}': {'; '.join(changes)}.", user=user,
        )
        recalculate_invoice_totals(invoice)

    return product_line


def delete_product_line(invoice, product_line, user=None):
    """Removes an InvoiceProductLine and restores its quantity to the
    product's current_stock_quantity."""
    if product_line.invoice_id != invoice.id:
        raise InvoiceError("This product line does not belong to this invoice.")
    _ensure_editable(invoice)

    product = product_line.product
    product.current_stock_quantity += product_line.quantity
    product.save(update_fields=["current_stock_quantity", "updated_at"])

    description = f"Removed {product_line.quantity} x '{product.name}' at {product_line.price_charged} each."
    product_line.delete()  # soft delete, see BaseModel.delete()

    log_action(invoice, "product_line_deleted", description, user=user)
    recalculate_invoice_totals(invoice)


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


def _gross_work_total(invoice):
    """Sum of all meter services + all product lines, BEFORE discount."""
    service_total = invoice.service_lines.aggregate(total=Sum("price_charged"))["total"] or Decimal("0")
    product_total = (
        invoice.product_lines.aggregate(
            total=Sum(F("price_charged") * F("quantity"), output_field=DecimalField(max_digits=12, decimal_places=2))
        )["total"]
        or Decimal("0")
    )
    return service_total + product_total


def recalculate_invoice_totals(invoice):
    from apps.invoices.models import Invoice

    gross_total = _gross_work_total(invoice)
    payment_total = invoice.payments.aggregate(total=Sum("amount"))["total"] or Decimal("0")

    invoice.total_amount = gross_total - invoice.discount_amount
    invoice.paid_amount = payment_total
    new_status = determine_status(invoice.total_amount, invoice.paid_amount)

    # Sticky: once this invoice has ever been underpaid, remember it even
    # after it's eventually paid off in full - the red-list rule needs this.
    if new_status == Invoice.Status.PARTIAL:
        invoice.had_shortfall = True

    invoice.status = new_status
    invoice.save(update_fields=[
        "total_amount", "paid_amount", "status", "had_shortfall",
        "discount_amount", "discount_note", "updated_at",
    ])
    return invoice


# --- discount (Admin only, see apps.accounts.permissions.IsAdmin on the view) --

def apply_discount(invoice, discount_amount, discount_note="", user=None):
    """Applies or updates the invoice-level discount. A fixed BDT amount,
    never a percentage - see Invoice.discount_amount. Only callable on an
    open (Unpaid/Partial Paid) invoice; the discount can't exceed the
    invoice's total work value, and can't drop the total below what's
    already been paid (that would silently "overpay" the invoice)."""
    discount_amount = Decimal(discount_amount)
    if discount_amount < 0:
        raise InvoiceError("discount_amount cannot be negative.")

    _ensure_editable(invoice)

    gross_total = _gross_work_total(invoice)
    if discount_amount > gross_total:
        raise InvoiceError(
            f"discount_amount ({discount_amount}) cannot exceed the invoice's total work value of {gross_total}."
        )

    new_total = gross_total - discount_amount
    if new_total < invoice.paid_amount:
        raise InvoiceError(
            f"A discount of {discount_amount} would reduce the total to {new_total}, "
            f"below the {invoice.paid_amount} already paid."
        )

    old_discount = invoice.discount_amount
    invoice.discount_amount = discount_amount
    invoice.discount_note = discount_note
    recalculate_invoice_totals(invoice)

    log_action(
        invoice, "discount_applied",
        (
            f"Discount changed from {old_discount} to {discount_amount}."
            + (f" Reason: {discount_note}" if discount_note else "")
        ),
        user=user,
    )
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
