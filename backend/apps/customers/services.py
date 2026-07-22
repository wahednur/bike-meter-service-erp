import csv
import io
from decimal import Decimal

from django.db.models import Sum

CSV_PREVIEW_ROW_COUNT = 5

# Customer fields a CSV import is allowed to populate. Deliberately excludes
# things like id/created_by/is_red_listed so a crafted column_mapping can't
# be used to set fields the endpoint isn't meant to expose.
CSV_IMPORTABLE_FIELDS = {"name", "phone", "address", "description", "email"}


def _read_csv_text(csv_file):
    """Uploaded files arrive as bytes; decode once so csv.reader can work
    on a plain text stream. utf-8-sig quietly strips a BOM if present
    (common when the CSV was exported from Excel)."""
    csv_file.seek(0)
    raw = csv_file.read()
    if isinstance(raw, bytes):
        raw = raw.decode("utf-8-sig")
    return io.StringIO(raw)


def preview_customer_csv(csv_file):
    """Parses only the header row and the first CSV_PREVIEW_ROW_COUNT data
    rows. Does not create any records - lets the caller confirm the column
    mapping before committing to an import."""
    reader = csv.reader(_read_csv_text(csv_file))

    try:
        headers = next(reader)
    except StopIteration:
        return {"headers": [], "rows": []}

    rows = []
    for row in reader:
        if len(rows) >= CSV_PREVIEW_ROW_COUNT:
            break
        rows.append(dict(zip(headers, row)))

    return {"headers": headers, "rows": rows}


def import_customers_from_csv(csv_file, column_mapping, user):
    """Creates a Customer for every CSV row, using column_mapping (Customer
    field name -> CSV header name) to pick values out of each row. Every
    other column in the file is ignored.

    Duplicate phone numbers and rows missing a required field are skipped
    individually rather than aborting the whole import.
    """
    from apps.customers.models import Customer

    reader = csv.DictReader(_read_csv_text(csv_file))

    name_column = column_mapping.get("name")
    phone_column = column_mapping.get("phone")

    created, skipped, failed = [], [], []
    total = 0

    for row_number, row in enumerate(reader, start=2):  # row 1 is the header
        total += 1

        name = (row.get(name_column) or "").strip() if name_column else ""
        phone = (row.get(phone_column) or "").strip() if phone_column else ""

        if not name or not phone:
            missing = [field for field, value in (("name", name), ("phone", phone)) if not value]
            failed.append({
                "row": row_number,
                "reason": f"Missing required field(s): {', '.join(missing)}",
            })
            continue

        # Unique constraint on Customer.phone covers soft-deleted rows too,
        # so duplicate detection must check all_objects, not just objects.
        if Customer.all_objects.filter(phone=phone).exists():
            skipped.append({"row": row_number, "phone": phone, "reason": "Customer with this phone already exists"})
            continue

        customer_fields = {"name": name, "phone": phone, "created_by": user}
        for model_field, csv_column in column_mapping.items():
            if model_field in ("name", "phone") or model_field not in CSV_IMPORTABLE_FIELDS or not csv_column:
                continue
            value = (row.get(csv_column) or "").strip()
            if value:
                customer_fields[model_field] = value

        created.append(Customer.objects.create(**customer_fields))

    return {
        "total": total,
        "created_count": len(created),
        "skipped_count": len(skipped),
        "failed_count": len(failed),
        "created": created,
        "skipped": skipped,
        "failed": failed,
    }


def build_customer_ledger(customer, from_date=None, to_date=None):
    """Aggregates a customer's invoice history: every invoice (any status,
    so the record is complete) plus total billed/paid/due summed across
    their non-cancelled invoices. Optionally scoped to invoices created in
    [from_date, to_date]."""
    from apps.invoices.models import Invoice

    invoices = Invoice.objects.filter(customer=customer).order_by("-created_at")
    if from_date:
        invoices = invoices.filter(created_date__gte=from_date)
    if to_date:
        invoices = invoices.filter(created_date__lte=to_date)

    billable = invoices.exclude(status=Invoice.Status.CANCELLED)

    totals = billable.aggregate(total_billed=Sum("total_amount"), total_paid=Sum("paid_amount"))
    total_billed = totals["total_billed"] or Decimal("0")
    total_paid = totals["total_paid"] or Decimal("0")

    return {
        "customer": customer,
        "invoices": list(invoices),
        "total_billed": total_billed,
        "total_paid": total_paid,
        "total_due": total_billed - total_paid,
    }
