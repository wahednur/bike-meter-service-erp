from decimal import ROUND_HALF_UP, Decimal

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


DEFAULT_LOW_STOCK_THRESHOLD = 5


def low_stock_products(threshold=DEFAULT_LOW_STOCK_THRESHOLD):
    """Products at or below `threshold` units on hand, lowest first."""
    from apps.products.models import Product

    return list(
        Product.objects.filter(current_stock_quantity__lte=threshold).order_by("current_stock_quantity")
    )
