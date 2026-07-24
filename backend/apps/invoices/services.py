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
                                     together), with meter/service/product price defaulting
  j) update_service_line/delete_service_line/update_product_line/delete_product_line/
     update_payment/delete_payment - edit, remove, and replace individual line items
                                     and payments, on an editable invoice
  k) force_close_invoice          - Admin write-off: accept a remaining due_amount as
                                     final, recorded as waived_amount (separate from
                                     discount_amount), still feeds the red-list check
  l) _ensure_editable_or_forced   - Admin + mandatory reason path to edit a Paid/
                                     force-closed invoice after the fact
"""
import secrets
from datetime import date
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


def _ensure_editable_or_forced(invoice, reason=None, user=None):
    """Rule (l): the gate every edit/delete/replace function on an
    existing line item, payment, or invoice date goes through.

    Normal path: `invoice` must be editable (Unpaid/Partial Paid) - same
    rule as adding new line items. Force path (rule 14): a Paid or
    force-closed invoice can still be edited if the caller supplies a
    non-blank `reason`. The view layer is responsible for making sure only
    an Admin can reach this branch (see apps.accounts.permissions.IsAdmin
    on the relevant actions) - this function only enforces the reason.
    A Cancelled invoice is never editable either way; it's void, not
    merely settled."""
    from apps.invoices.models import Invoice

    if invoice.is_editable:
        return
    if invoice.status == Invoice.Status.CANCELLED:
        raise InvoiceError(f"Invoice {invoice.invoice_no} is cancelled and cannot be edited.")
    if not reason or not reason.strip():
        raise InvoiceError(
            f"Invoice {invoice.invoice_no} is {invoice.get_status_display()}. "
            "Editing it requires a reason (Admin only)."
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
    serial_number="",
    condition_note="",
    previous_km=None,
    current_km=None,
    mileage_correction_device=None,
    user=None,
):
    """Rule (c): if a mileage_correction_device is given, it must be able to
    service this meter's memory_type - reuses the Phase 3 rule directly.
    Kept internal-only (not a standalone frontend entry point) - see
    apps.invoices.views.InvoiceViewSet.add_meter_entry's docstring. The
    merged add_service_line()/update_service_line() call this directly to
    create the InvoiceMeterEntry half of a Mileage Correction line."""
    from apps.invoices.models import InvoiceMeterEntry

    _ensure_editable(invoice)

    if mileage_correction_device is not None:
        _run_validation(MeterSerializer.validate_mileage_correction_tool, meter.memory_type, mileage_correction_device.name)

    entry = InvoiceMeterEntry.objects.create(
        invoice=invoice,
        meter=meter,
        serial_number=serial_number or None,
        condition_note=condition_note,
        previous_km=previous_km,
        current_km=current_km,
        mileage_correction_device=mileage_correction_device,
        created_by=user,
    )
    log_action(invoice, "meter_entry_added", f"Added meter {meter.title} (serial {serial_number or '—'}).", user=user)

    if invoice.paid_amount > 0:
        split_payment_across_meters(invoice)

    return entry


def _resolve_meter_entry(
    invoice, service, meter_entry, meter, serial_number, condition_note, previous_km, current_km,
    mileage_correction_device, user,
):
    """Returns the InvoiceMeterEntry that should end up linked to a service
    line for `service`, given the caller-supplied meter fields. Shared by
    add_service_line() (create) and update_service_line() (edit/replace)
    so "create the meter entry inline for a Mileage Correction service"
    behaves identically either way.

    If `service` doesn't require mileage-correction fields, `meter_entry`
    is returned unchanged (still allowed as an optional link - rule 3's
    "existing flow" for a regular repair tied to a specific meter)."""
    if not service.requires_mileage_correction_fields:
        return meter_entry

    if meter_entry is not None:
        _run_validation(
            ServiceSerializer.validate_invoice_line_fields,
            service, meter_entry.previous_km, meter_entry.current_km, meter_entry.condition_note,
        )
        return meter_entry

    if meter is None:
        raise InvoiceError(f'"{service.name}" requires a meter to record the mileage correction against.')
    _run_validation(ServiceSerializer.validate_invoice_line_fields, service, previous_km, current_km, condition_note)
    return add_meter_entry(
        invoice, meter, serial_number=serial_number, condition_note=condition_note,
        previous_km=previous_km, current_km=current_km,
        mileage_correction_device=mileage_correction_device, user=user,
    )


def add_service_line(
    invoice, service, meter_entry=None, price_charged=None, asset_used=None,
    meter=None, serial_number="", condition_note="", previous_km=None, current_km=None,
    mileage_correction_device=None, product_used=None, product_price=None, added_date=None, user=None,
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
    Either way, condition_note must be present (the services-app rule)
    before the line can be saved. previous_km/current_km are optional -
    some jobs don't have this info available at entry time - but if both
    are given, previous_km must be >= current_km.

    Price defaulting: an explicit `price_charged` always wins. Otherwise it
    defaults to the meter's sales_price for a Mileage Correction service,
    or the service's own service_price for a regular repair.

    `product_used`/`product_price` (rule 7): for combination repairs (e.g.
    Display Repair - polarizer paper only vs a full panel swap) that bill
    a part alongside the labor. Kept as two independent amounts - an
    explicit `product_price` always wins, otherwise it defaults to
    product_used's sale_price (or 0 if no product_used is given).
    Consumes one unit of product_used's stock, same as add_product_line().

    `asset_used` is optional - tags which shop tool/accessory performed the
    repair, feeding that asset's revenue tracking (see
    apps.assets.services.compute_asset_stats())."""
    from apps.invoices.models import InvoiceServiceLine

    _ensure_editable(invoice)

    if meter_entry is not None and meter_entry.invoice_id != invoice.id:
        raise InvoiceError("meter_entry does not belong to this invoice.")

    with transaction.atomic():
        meter_entry = _resolve_meter_entry(
            invoice, service, meter_entry, meter, serial_number, condition_note, previous_km, current_km,
            mileage_correction_device, user,
        )

        if price_charged is None:
            price_charged = meter_entry.meter.sales_price if (service.requires_mileage_correction_fields and meter_entry) else service.service_price
        if product_price is None:
            product_price = product_used.sale_price if product_used else Decimal("0")

        if product_used is not None and product_used.current_stock_quantity < 1:
            raise InvoiceError(f"Not enough stock for {product_used.name}: 0 available.")

        line = InvoiceServiceLine.objects.create(
            invoice=invoice, meter_entry=meter_entry, service=service, price_charged=price_charged,
            product_used=product_used, product_price=product_price,
            asset_used=asset_used, added_date=added_date or date.today(), created_by=user,
        )

        if product_used is not None:
            product_used.current_stock_quantity -= 1
            product_used.save(update_fields=["current_stock_quantity", "updated_at"])

        description = f"Added service '{service.name}' for {price_charged}"
        if product_used is not None:
            description += f" + product '{product_used.name}' for {product_price}"
        description += "."
        log_action(invoice, "service_line_added", description, user=user)
        recalculate_invoice_totals(invoice)
        apply_red_list_check(invoice, user=user)

    return line


def add_product_line(invoice, product, quantity, price_charged=None, added_date=None, user=None):
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
        invoice=invoice, product=product, quantity=quantity, price_charged=price_charged,
        added_date=added_date or date.today(), created_by=user,
    )

    product.current_stock_quantity -= quantity
    product.save(update_fields=["current_stock_quantity", "updated_at"])

    log_action(
        invoice, "product_line_added", f"Added {quantity} x '{product.name}' at {price_charged} each.", user=user,
    )
    recalculate_invoice_totals(invoice)
    apply_red_list_check(invoice, user=user)
    return line


# --- rule (j): editing / removing / replacing individual line items and payments -
#
# Every function below shares the same shape: confirm the line/payment
# belongs to `invoice`, confirm the invoice is editable (or force-editable
# with a reason - rule (l)), apply only the fields the caller actually
# passed (so a partial edit never clobbers untouched fields), log a
# human-readable audit entry, and recompute the invoice's totals (and
# re-split payment across meters, and re-run the red-list check, where
# relevant) so total_amount/due_amount never drift from what's actually on
# the invoice - even after a forced edit to an already-Paid invoice.

_METER_ENTRY_EDITABLE_FIELDS = {
    "serial_number", "condition_note", "previous_km", "current_km", "mileage_correction_device",
}


def update_service_line(invoice, service_line, user=None, reason=None, **fields):
    """Edits - and can fully replace - an InvoiceServiceLine, and, for a
    mileage-correction line, its linked InvoiceMeterEntry - together, in
    one call. Only keys present in `fields` are changed.

    Supports: price_charged, product_used, product_price, asset_used,
    added_date, and `service` itself (rule 8's "replace" - swapping which
    Service this line bills without a delete+recreate). If the new
    service requires mileage-correction fields and the line has no
    meter_entry yet, also pass `meter` (+ the meter-entry fields) to
    create one inline, exactly like add_service_line(). Swapping away
    from a Mileage Correction service detaches (and, if unused elsewhere,
    removes) the linked meter entry. The meter-entry fields themselves
    (serial_number/condition_note/previous_km/current_km/
    mileage_correction_device) apply directly when the line already has
    (or is gaining) a meter_entry.

    `reason` is required (rule 14) if `invoice` is Paid/force-closed - see
    _ensure_editable_or_forced(). Normally callable by anyone with invoice
    change permission; the Paid/force-closed path additionally requires
    Admin, enforced by the view."""
    if service_line.invoice_id != invoice.id:
        raise InvoiceError("This service line does not belong to this invoice.")
    is_forced_edit = not invoice.is_editable
    original_status_display = invoice.get_status_display()
    _ensure_editable_or_forced(invoice, reason, user)

    changes = []

    old_service = service_line.service
    new_service = fields.get("service", old_service)
    service_changed = new_service.id != old_service.id

    meter_entry = service_line.meter_entry
    orphaned_entry = None

    if new_service.requires_mileage_correction_fields:
        resolved_entry = _resolve_meter_entry(
            invoice, new_service, meter_entry,
            fields.get("meter"), fields.get("serial_number", ""), fields.get("condition_note", ""),
            fields.get("previous_km"), fields.get("current_km"), fields.get("mileage_correction_device"),
            user,
        )
        if resolved_entry is not meter_entry:
            changes.append(f"linked meter entry for {resolved_entry.meter.title}")
            service_line.meter_entry = resolved_entry
        meter_entry = resolved_entry
    elif service_changed and old_service.requires_mileage_correction_fields and meter_entry is not None:
        # Switching away from Mileage Correction - detach; delete the entry
        # too if nothing else on the invoice still references it.
        changes.append(f"detached from meter entry for {meter_entry.meter.title}")
        service_line.meter_entry = None
        orphaned_entry = meter_entry
        meter_entry = None

    # Apply meter-entry field edits whenever this line still has (or just
    # gained) a linked meter_entry - regardless of whether `new_service`
    # itself requires mileage-correction fields, since rule 3 lets a
    # regular repair optionally stay tied to a meter too. A brand new
    # entry just created by _resolve_meter_entry() above already has these
    # values baked in from creation, so this diff is a harmless no-op then.
    meter_entry_fields = {k: v for k, v in fields.items() if k in _METER_ENTRY_EDITABLE_FIELDS}
    if meter_entry_fields:
        if meter_entry is None:
            raise InvoiceError("This service line has no linked meter entry to update.")
        # Blank and None both mean "no serial number" (see add_meter_entry) -
        # normalize so re-saving an already-blank one isn't reported as a change.
        if "serial_number" in meter_entry_fields:
            meter_entry_fields["serial_number"] = meter_entry_fields["serial_number"] or None
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
            if new_service.requires_mileage_correction_fields:
                _run_validation(
                    ServiceSerializer.validate_invoice_line_fields,
                    new_service, meter_entry.previous_km, meter_entry.current_km, meter_entry.condition_note,
                )
            meter_entry.save(update_fields=updated_fields + ["updated_at"])

    if service_changed:
        changes.append(f"service changed from '{old_service.name}' to '{new_service.name}'")
        service_line.service = new_service

    if "price_charged" in fields and fields["price_charged"] != service_line.price_charged:
        changes.append(f"price_charged changed from {service_line.price_charged} to {fields['price_charged']}")
        service_line.price_charged = fields["price_charged"]

    if "product_used" in fields and fields["product_used"] != service_line.product_used:
        old_product_used, new_product_used = service_line.product_used, fields["product_used"]
        old_name = old_product_used.name if old_product_used else "none"
        new_name = new_product_used.name if new_product_used else "none"
        changes.append(f"product_used changed from {old_name} to {new_name}")
        _swap_service_line_product_stock(old_product_used, new_product_used)
        service_line.product_used = new_product_used
        if "product_price" not in fields:
            # Re-default, same as add_service_line(), unless the caller
            # also gave an explicit price in this same request.
            service_line.product_price = new_product_used.sale_price if new_product_used else Decimal("0")
            changes.append(f"product_price re-defaulted to {service_line.product_price}")

    if "product_price" in fields and fields["product_price"] != service_line.product_price:
        changes.append(f"product_price changed from {service_line.product_price} to {fields['product_price']}")
        service_line.product_price = fields["product_price"]

    if "asset_used" in fields and fields["asset_used"] != service_line.asset_used:
        old_name = service_line.asset_used.name if service_line.asset_used else "none"
        new_name = fields["asset_used"].name if fields["asset_used"] else "none"
        changes.append(f"asset_used changed from {old_name} to {new_name}")
        service_line.asset_used = fields["asset_used"]

    if "added_date" in fields and fields["added_date"] != service_line.added_date:
        changes.append(f"added_date changed from {service_line.added_date} to {fields['added_date']}")
        service_line.added_date = fields["added_date"]

    if not changes:
        return service_line

    service_line.save()

    if orphaned_entry is not None and not orphaned_entry.service_lines.exists():
        changes.append(f"removed now-unused meter entry for {orphaned_entry.meter.title}")
        orphaned_entry.delete()

    log_action(invoice, "service_line_updated", f"Updated service line: {'; '.join(changes)}.", user=user)
    recalculate_invoice_totals(invoice)
    split_payment_across_meters(invoice)
    apply_red_list_check(invoice, user=user)

    if is_forced_edit:
        log_action(
            invoice, "invoice_force_edited",
            f"Edited a service line while {original_status_display}. Reason: {reason}", user=user,
        )

    return service_line


def delete_service_line(invoice, service_line, user=None, reason=None):
    """Removes an InvoiceServiceLine. If it was a mileage-correction line
    and no other (non-deleted) service line still references the same
    InvoiceMeterEntry, that entry is removed too - so a Mileage Correction
    line and the meter it was billed against are added and removed as one
    unit, matching how they're created together in add_service_line().
    Also restores product_used's stock, if any. `reason` required if
    `invoice` isn't currently editable (rule 14)."""
    if service_line.invoice_id != invoice.id:
        raise InvoiceError("This service line does not belong to this invoice.")
    is_forced_edit = not invoice.is_editable
    original_status_display = invoice.get_status_display()
    _ensure_editable_or_forced(invoice, reason, user)

    meter_entry = service_line.meter_entry
    product_used = service_line.product_used
    description = f"Removed service '{service_line.service.name}' ({service_line.price_charged})."

    if product_used is not None:
        product_used.current_stock_quantity += 1
        product_used.save(update_fields=["current_stock_quantity", "updated_at"])
        description += f" Restored 1 x '{product_used.name}' to stock."

    service_line.delete()  # soft delete, see BaseModel.delete()

    if meter_entry is not None and not meter_entry.service_lines.exists():
        description += (
            f" Also removed linked meter entry for {meter_entry.meter.title} "
            f"(serial {meter_entry.serial_number or '—'})."
        )
        meter_entry.delete()  # soft delete

    log_action(invoice, "service_line_deleted", description, user=user)
    recalculate_invoice_totals(invoice)
    split_payment_across_meters(invoice)
    apply_red_list_check(invoice, user=user)

    if is_forced_edit:
        log_action(
            invoice, "invoice_force_edited",
            f"Deleted a service line while {original_status_display}. Reason: {reason}", user=user,
        )


def _swap_service_line_product_stock(old_product, new_product, quantity=1):
    """Restores `quantity` to `old_product`'s stock (if any) and deducts it
    from `new_product`'s stock (if any) - used when a service line's
    product_used is replaced or cleared/set. Raises if the new product
    doesn't have enough stock. Caller guarantees old_product != new_product."""
    if new_product is not None and new_product.current_stock_quantity < quantity:
        raise InvoiceError(f"Not enough stock for {new_product.name}: {new_product.current_stock_quantity} available.")

    if old_product is not None:
        old_product.current_stock_quantity += quantity
        old_product.save(update_fields=["current_stock_quantity", "updated_at"])
    if new_product is not None:
        new_product.current_stock_quantity -= quantity
        new_product.save(update_fields=["current_stock_quantity", "updated_at"])


def update_product_line(invoice, product_line, user=None, reason=None, **fields):
    """Edits - and can fully replace - an InvoiceProductLine: quantity,
    price, added_date, or which product it is (rule 8's "replace"). A
    changed quantity or product adjusts stock by the delta (same rule as
    add_product_line: can't drop stock below zero). `reason` required if
    `invoice` isn't currently editable (rule 14)."""
    if product_line.invoice_id != invoice.id:
        raise InvoiceError("This product line does not belong to this invoice.")
    is_forced_edit = not invoice.is_editable
    original_status_display = invoice.get_status_display()
    _ensure_editable_or_forced(invoice, reason, user)

    changes = []
    target_product = fields.get("product", product_line.product)
    target_quantity = fields.get("quantity", product_line.quantity)
    product_changed = target_product.id != product_line.product_id
    quantity_changed = target_quantity != product_line.quantity

    if product_changed:
        if target_product.current_stock_quantity < target_quantity:
            raise InvoiceError(
                f"Not enough stock for {target_product.name}: {target_product.current_stock_quantity} available, "
                f"{target_quantity} requested."
            )
        product_line.product.current_stock_quantity += product_line.quantity
        product_line.product.save(update_fields=["current_stock_quantity", "updated_at"])
        target_product.current_stock_quantity -= target_quantity
        target_product.save(update_fields=["current_stock_quantity", "updated_at"])
        changes.append(f"product changed from '{product_line.product.name}' to '{target_product.name}'")
        if quantity_changed:
            changes.append(f"quantity changed from {product_line.quantity} to {target_quantity}")
        product_line.product = target_product
        product_line.quantity = target_quantity
        if "price_charged" not in fields:
            product_line.price_charged = target_product.sale_price
            changes.append(f"price_charged re-defaulted to {product_line.price_charged}")
    elif quantity_changed:
        delta = target_quantity - product_line.quantity
        if delta > 0 and target_product.current_stock_quantity < delta:
            raise InvoiceError(
                f"Not enough stock for {target_product.name}: {target_product.current_stock_quantity} available, "
                f"{delta} more requested."
            )
        target_product.current_stock_quantity -= delta
        target_product.save(update_fields=["current_stock_quantity", "updated_at"])
        changes.append(f"quantity changed from {product_line.quantity} to {target_quantity}")
        product_line.quantity = target_quantity

    if "price_charged" in fields and fields["price_charged"] != product_line.price_charged:
        changes.append(f"price_charged changed from {product_line.price_charged} to {fields['price_charged']}")
        product_line.price_charged = fields["price_charged"]

    if "added_date" in fields and fields["added_date"] != product_line.added_date:
        changes.append(f"added_date changed from {product_line.added_date} to {fields['added_date']}")
        product_line.added_date = fields["added_date"]

    if not changes:
        return product_line

    product_line.save()
    log_action(invoice, "product_line_updated", f"Updated product line: {'; '.join(changes)}.", user=user)
    recalculate_invoice_totals(invoice)
    apply_red_list_check(invoice, user=user)

    if is_forced_edit:
        log_action(
            invoice, "invoice_force_edited",
            f"Edited a product line while {original_status_display}. Reason: {reason}", user=user,
        )

    return product_line


def delete_product_line(invoice, product_line, user=None, reason=None):
    """Removes an InvoiceProductLine and restores its quantity to the
    product's current_stock_quantity. `reason` required if `invoice`
    isn't currently editable (rule 14)."""
    if product_line.invoice_id != invoice.id:
        raise InvoiceError("This product line does not belong to this invoice.")
    is_forced_edit = not invoice.is_editable
    original_status_display = invoice.get_status_display()
    _ensure_editable_or_forced(invoice, reason, user)

    product = product_line.product
    product.current_stock_quantity += product_line.quantity
    product.save(update_fields=["current_stock_quantity", "updated_at"])

    description = f"Removed {product_line.quantity} x '{product.name}' at {product_line.price_charged} each."
    product_line.delete()  # soft delete, see BaseModel.delete()

    log_action(invoice, "product_line_deleted", description, user=user)
    recalculate_invoice_totals(invoice)
    apply_red_list_check(invoice, user=user)

    if is_forced_edit:
        log_action(
            invoice, "invoice_force_edited",
            f"Deleted a product line while {original_status_display}. Reason: {reason}", user=user,
        )


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


def update_payment(invoice, payment, user=None, reason=None, **fields):
    """Edits an InvoicePayment - amount/payment_method/payment_date/note.
    Mainly for correcting a payment recorded against an already-closed
    invoice (rule 14) - `reason` is required in that case. Fully
    recalculates totals/split/red-list status afterward since a changed
    amount can shift paid_amount, status, and shares."""
    if payment.invoice_id != invoice.id:
        raise InvoiceError("This payment does not belong to this invoice.")
    is_forced_edit = not invoice.is_editable
    original_status_display = invoice.get_status_display()
    _ensure_editable_or_forced(invoice, reason, user)

    changes = []
    if "amount" in fields and fields["amount"] != payment.amount:
        changes.append(f"amount changed from {payment.amount} to {fields['amount']}")
        payment.amount = fields["amount"]
    if "payment_method" in fields and fields["payment_method"] != payment.payment_method:
        changes.append(f"payment_method changed from {payment.payment_method} to {fields['payment_method']}")
        payment.payment_method = fields["payment_method"]
    if "payment_date" in fields and fields["payment_date"] != payment.payment_date:
        changes.append(f"payment_date changed from {payment.payment_date} to {fields['payment_date']}")
        payment.payment_date = fields["payment_date"]
    if "note" in fields and fields["note"] != payment.note:
        changes.append("note updated")
        payment.note = fields["note"]

    if not changes:
        return payment

    if payment.amount <= 0:
        raise InvoiceError("Payment amount must be positive.")

    payment.save()
    log_action(invoice, "payment_updated", f"Updated payment: {'; '.join(changes)}.", user=user)
    recalculate_invoice_totals(invoice)
    split_payment_across_meters(invoice)
    apply_red_list_check(invoice, user=user)

    if is_forced_edit:
        log_action(
            invoice, "invoice_force_edited",
            f"Edited a payment while {original_status_display}. Reason: {reason}", user=user,
        )

    return payment


def delete_payment(invoice, payment, user=None, reason=None):
    """Removes an InvoicePayment. `reason` required if `invoice` isn't
    currently editable (rule 14)."""
    if payment.invoice_id != invoice.id:
        raise InvoiceError("This payment does not belong to this invoice.")
    is_forced_edit = not invoice.is_editable
    original_status_display = invoice.get_status_display()
    _ensure_editable_or_forced(invoice, reason, user)

    description = f"Removed payment of {payment.amount} ({payment.payment_method})."
    payment.delete()  # soft delete, see BaseModel.delete()

    log_action(invoice, "payment_deleted", description, user=user)
    recalculate_invoice_totals(invoice)
    split_payment_across_meters(invoice)
    apply_red_list_check(invoice, user=user)

    if is_forced_edit:
        log_action(
            invoice, "invoice_force_edited",
            f"Deleted a payment while {original_status_display}. Reason: {reason}", user=user,
        )


# --- totals / status (rule f) --------------------------------------------------

def determine_status(total_amount, paid_amount):
    from apps.invoices.models import Invoice

    if paid_amount <= 0:
        return Invoice.Status.UNPAID
    if total_amount > 0 and paid_amount >= total_amount:
        return Invoice.Status.PAID
    return Invoice.Status.PARTIAL


def _gross_work_total(invoice):
    """Sum of every service line's (price_charged + product_price) plus
    every product line's (price_charged * quantity), BEFORE discount/waived_amount."""
    service_total = (
        invoice.service_lines.aggregate(
            total=Sum(
                F("price_charged") + F("product_price"),
                output_field=DecimalField(max_digits=12, decimal_places=2),
            )
        )["total"]
        or Decimal("0")
    )
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

    invoice.total_amount = gross_total - invoice.discount_amount - invoice.waived_amount
    invoice.paid_amount = payment_total
    new_status = determine_status(invoice.total_amount, invoice.paid_amount)

    # Sticky: once this invoice has ever been underpaid, remember it even
    # after it's eventually paid off in full - the red-list rule needs this.
    if new_status == Invoice.Status.PARTIAL:
        invoice.had_shortfall = True

    invoice.status = new_status
    invoice.save(update_fields=[
        "total_amount", "paid_amount", "status", "had_shortfall",
        "discount_amount", "discount_note", "waived_amount", "waived_note", "updated_at",
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


# --- rule (k): force-close (write off the rest) as Paid ------------------------

def force_close_invoice(invoice, note, user=None):
    """Admin-only 'accept this as final' action for an invoice with a
    remaining due_amount the shop owner has decided not to keep chasing
    (e.g. customer paid 1000 of a 1200 invoice and won't pay the rest).

    Records the remaining outstanding_amount as waived_amount - kept
    separate from discount_amount, which is a deliberate reduction given
    upfront, not an accepted shortfall at closing time - and marks the
    invoice Paid. Reuses recalculate_invoice_totals()'s existing formula
    (total_amount = gross - discount - waived) so due_amount lands on
    zero without silently forgetting the write-off ever happened.

    Requires a non-blank `note`. Marks had_shortfall (rule 12: a waived
    amount is definitionally a shortfall, whether or not this invoice was
    ever Partial Paid beforehand) and feeds apply_red_list_check() exactly
    like add_payment() does, since force-closing can newly bring the
    invoice to Paid."""
    from apps.invoices.models import Invoice

    if not note or not note.strip():
        raise InvoiceError("A reason/note is required to force-close an invoice.")

    _ensure_editable(invoice)

    outstanding = invoice.outstanding_amount
    if outstanding <= 0:
        raise InvoiceError(f"Invoice {invoice.invoice_no} has no outstanding balance to waive.")

    invoice.waived_amount = outstanding
    invoice.waived_note = note
    invoice.had_shortfall = True
    recalculate_invoice_totals(invoice)

    # recalculate_invoice_totals() derives status from paid_amount vs
    # total_amount, which would read UNPAID (not Paid) for an invoice that
    # never received a single payment before being fully waived -
    # force-closing means "consider this settled" by decision, not by that
    # arithmetic, so it always lands on Paid.
    invoice.status = Invoice.Status.PAID
    invoice.save(update_fields=["status", "updated_at"])

    log_action(
        invoice, "invoice_force_closed",
        f"Force-closed as Paid, waiving {outstanding} of the remaining balance. Reason: {note}", user=user,
    )
    apply_red_list_check(invoice, user=user)
    return invoice


# --- rule (3): editable created_date (Admin only) -------------------------------

def update_invoice_created_date(invoice, created_date, user=None, reason=None):
    """Admin-only edit of created_date (rule 3) - e.g. to backdate an
    invoice entered a day late. Freely editable while the invoice is open;
    needs a `reason` if it's Paid/force-closed (rule 14)."""
    is_forced_edit = not invoice.is_editable
    original_status_display = invoice.get_status_display()
    _ensure_editable_or_forced(invoice, reason, user)

    if created_date == invoice.created_date:
        return invoice

    old_date = invoice.created_date
    invoice.created_date = created_date
    invoice.save(update_fields=["created_date", "updated_at"])

    log_action(invoice, "invoice_date_updated", f"created_date changed from {old_date} to {created_date}.", user=user)

    if is_forced_edit:
        log_action(
            invoice, "invoice_force_edited",
            f"Edited created_date while {original_status_display}. Reason: {reason}", user=user,
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
    passed through Partial Paid before being settled, or was force-closed
    with a waived_amount (rule 12 - a waived amount is a shortfall too,
    since had_shortfall is set directly by force_close_invoice()). Two
    such invoices in a row red-lists the customer.

    Reuses Customer.evaluate_red_list_status() from Phase 2 by feeding it
    the customer's current consecutive-shortfall streak with threshold=2.
    This is symmetric/self-healing: an invoice paid in full with no
    shortfall resets the streak to 0, which clears the red-list flag via
    that same method. No-op unless `invoice` is currently Paid, so it's
    safe to call unconditionally after any recalculation."""
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
