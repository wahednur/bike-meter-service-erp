from decimal import ROUND_HALF_UP, Decimal

from django.db import transaction
from django.utils import timezone

TWO_PLACES = Decimal("0.01")


def compute_landed_unit_cost(quantity, unit_price, extra_costs=Decimal("0")):
    """Spreads incidental costs (packaging, delivery, etc.) for a purchase
    batch evenly across the units bought, producing one per-unit cost.

    Worked example: buying 5 SF displays at 350 each, plus a 350 casing and
    a 150 delivery charge for the whole batch:
        total_cost = (5 * 350) + 350 + 150 = 2250
        landed_unit_cost = 2250 / 5 = 450.00
    """
    quantity = Decimal(quantity)
    if quantity <= 0:
        raise ValueError("quantity must be positive")

    total_cost = (quantity * Decimal(unit_price)) + Decimal(extra_costs)
    return (total_cost / quantity).quantize(TWO_PLACES, rounding=ROUND_HALF_UP)


def restock_product(product, quantity, unit_price, extra_costs=Decimal("0")):
    """Adds `quantity` units to `product`'s stock and recalculates
    buy_price as a weighted average of the existing stock and this batch's
    landed unit cost. This is the only way stock/cost should be applied -
    never create a second Product row for a restock.

        new_avg_cost = ((old_qty * old_avg_cost) + (new_qty * landed_unit_cost))
                        / (old_qty + new_qty)
    """
    quantity = Decimal(quantity)
    if quantity <= 0:
        raise ValueError("quantity must be positive")

    landed_unit_cost = compute_landed_unit_cost(quantity, unit_price, extra_costs)

    old_qty = Decimal(product.current_stock_quantity)
    old_avg_cost = product.buy_price
    combined_qty = old_qty + quantity

    new_avg_cost = ((old_qty * old_avg_cost) + (quantity * landed_unit_cost)) / combined_qty
    new_avg_cost = new_avg_cost.quantize(TWO_PLACES, rounding=ROUND_HALF_UP)

    product.buy_price = new_avg_cost
    product.current_stock_quantity = int(combined_qty)
    product.save(update_fields=["buy_price", "current_stock_quantity", "updated_at"])

    from apps.products.models import ProductRestockEvent

    ProductRestockEvent.objects.create(
        product=product,
        quantity=int(quantity),
        unit_price=Decimal(unit_price),
        extra_costs=Decimal(extra_costs),
        landed_unit_cost=landed_unit_cost,
        total_cost=landed_unit_cost * quantity,
    )

    return product


def compute_purchase_line_shares(purchase):
    """Pure computation, no writes: for every line item in `purchase`,
    proportionally distributes shared_extra_costs by each line's subtotal
    share (quantity * unit_price) and computes the resulting landed unit
    cost. Returns a list of (line_item, extra_cost_share, landed_unit_cost)
    tuples, in line-item order.

    Used both to preview a purchase before it's applied (e.g. by
    PurchaseSerializer) and by apply_purchase() to actually restock -
    single source of truth for the split math so the two never drift.

    Worked example: 5 Displays @350 (subtotal 1750) + 1 Front Cover @350
    (subtotal 350), shared_extra_costs 150 (combined subtotal 2100):
        display_share = 150 * (1750/2100) = 125.00
        cover_share    = 150 * (350/2100)  = 25.00
        display landed_unit_cost = (1750 + 125) / 5 = 375.00
        cover landed_unit_cost   = (350 + 25) / 1   = 375.00
    """
    line_items = list(purchase.line_items.select_related("product"))
    if not line_items:
        return []

    total_subtotal = sum((item.subtotal for item in line_items), Decimal("0"))
    shared_extra_costs = Decimal(purchase.shared_extra_costs)

    results = []
    remaining_extra = shared_extra_costs
    for index, item in enumerate(line_items):
        is_last = index == len(line_items) - 1

        if total_subtotal <= 0:
            # Nothing to proportion against (e.g. every unit price is 0) -
            # split evenly instead of silently dropping the cost.
            extra_share = (
                remaining_extra if is_last
                else (shared_extra_costs / len(line_items)).quantize(TWO_PLACES, rounding=ROUND_HALF_UP)
            )
        elif is_last:
            # Last line absorbs the rounding remainder so the shares
            # always sum exactly to shared_extra_costs.
            extra_share = remaining_extra
        else:
            extra_share = (shared_extra_costs * item.subtotal / total_subtotal).quantize(
                TWO_PLACES, rounding=ROUND_HALF_UP,
            )
        remaining_extra -= extra_share

        landed_unit_cost = compute_landed_unit_cost(item.quantity, item.unit_price, extra_share)
        results.append((item, extra_share, landed_unit_cost))

    return results


def apply_purchase(purchase):
    """Restocks every product in `purchase` via the existing
    restock_product(), using compute_purchase_line_shares() for each
    line's proportional share of shared_extra_costs.

    Idempotent guard: raises if this purchase has already been processed,
    since re-running it would double-restock every line.
    """
    if purchase.is_processed:
        raise ValueError(f"Purchase #{purchase.id} has already been processed - it cannot be applied twice.")

    shares = compute_purchase_line_shares(purchase)
    if not shares:
        raise ValueError("Purchase has no line items to restock.")

    with transaction.atomic():
        for item, extra_share, _landed_unit_cost in shares:
            restock_product(item.product, item.quantity, item.unit_price, extra_costs=extra_share)

        purchase.processed_at = timezone.now()
        purchase.save(update_fields=["processed_at", "updated_at"])

    return purchase


DEFAULT_LOW_STOCK_THRESHOLD = 5


def low_stock_products(threshold=DEFAULT_LOW_STOCK_THRESHOLD):
    """Products at or below `threshold` units on hand, lowest first."""
    from apps.products.models import Product

    return list(
        Product.objects.filter(current_stock_quantity__lte=threshold).order_by("current_stock_quantity")
    )
