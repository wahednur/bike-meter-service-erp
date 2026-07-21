from decimal import Decimal

from django.db.models import Sum


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
