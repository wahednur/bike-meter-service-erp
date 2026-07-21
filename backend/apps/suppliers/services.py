from decimal import Decimal

from django.db.models import DecimalField, F, Sum


def build_supplier_ledger(supplier, from_date=None, to_date=None):
    """Aggregates every product bought from a supplier and the value of
    stock currently held from them.

    total_purchase_amount is buy_price (weighted-average cost) x
    current_stock_quantity, summed across their products - i.e. the cost
    basis of stock on hand right now. This is a point-in-time snapshot, so
    from_date/to_date do NOT filter it.

    purchases_in_range is different: it's the real sum of
    ProductRestockEvent.total_cost for this supplier's products, optionally
    scoped to [from_date, to_date] - i.e. actual money spent restocking
    from them in that window (0/unfiltered-total if no restock log exists
    for that window).

    payment_status is reported as "not_tracked": there's no supplier
    payment/bill model yet to say whether the shop has settled up for this
    stock, so it's left as an explicit placeholder rather than guessed.
    """
    from apps.products.models import ProductRestockEvent

    products = supplier.products.all().order_by("name")

    totals = products.aggregate(
        total_purchase_amount=Sum(
            F("buy_price") * F("current_stock_quantity"),
            output_field=DecimalField(max_digits=14, decimal_places=2),
        )
    )
    total_purchase_amount = totals["total_purchase_amount"] or Decimal("0")

    restocks = ProductRestockEvent.objects.filter(product__supplier=supplier)
    if from_date:
        restocks = restocks.filter(restocked_at__date__gte=from_date)
    if to_date:
        restocks = restocks.filter(restocked_at__date__lte=to_date)
    purchases_in_range = restocks.aggregate(total=Sum("total_cost"))["total"] or Decimal("0")

    return {
        "supplier": supplier,
        "products": list(products),
        "total_purchase_amount": total_purchase_amount,
        "purchases_in_range": purchases_in_range,
        "payment_status": "not_tracked",
    }
