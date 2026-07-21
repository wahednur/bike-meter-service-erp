import secrets
from decimal import Decimal

from django.db import IntegrityError, transaction
from django.utils import timezone

from apps.ecommerce.exceptions import EcommerceError


def generate_order_no():
    """ORD-<year>-<5 digit sequence>, sequential per year - same pattern as
    apps.invoices.services.generate_invoice_no()."""
    from apps.ecommerce.models import Order

    prefix = f"ORD-{timezone.now().year}-"
    last = Order.all_objects.filter(order_no__startswith=prefix).order_by("-order_no").first()
    next_seq = int(last.order_no.rsplit("-", 1)[-1]) + 1 if last else 1
    return f"{prefix}{next_seq:05d}"


def generate_tracking_token(length=10):
    """Short, URL-safe, cryptographically random token - lets a customer
    check their order status with no login, so it must not be guessable.
    Same approach as apps.invoices.services.generate_public_share_token()."""
    from apps.ecommerce.models import Order

    while True:
        token = secrets.token_urlsafe(8)[:length]
        if not Order.all_objects.filter(tracking_token=token).exists():
            return token


def place_order(customer_name, customer_phone, customer_address, items):
    """The public storefront checkout path - no login required. `items` is
    a list of {"product": Product instance, "quantity": int}.

    Stock is checked up front, then the whole order (Order + OrderItems +
    stock decrements) is written inside one transaction, so a failure
    partway through never leaves a half-created order or stock decremented
    for items that were never actually confirmed.
    """
    from apps.ecommerce.models import Order, OrderItem

    if not items:
        raise EcommerceError("Order must contain at least one item.")

    for item in items:
        if item["quantity"] <= 0:
            raise EcommerceError("quantity must be positive.")
        product = item["product"]
        if product.current_stock_quantity < item["quantity"]:
            raise EcommerceError(
                f"Not enough stock for {product.name}: "
                f"{product.current_stock_quantity} available, {item['quantity']} requested."
            )

    for _ in range(5):
        try:
            with transaction.atomic():
                order = Order.objects.create(
                    customer_name=customer_name,
                    customer_phone=customer_phone,
                    customer_address=customer_address,
                )

                total = Decimal("0")
                for item in items:
                    product = item["product"]
                    quantity = item["quantity"]
                    price_charged = Decimal(product.sale_price)

                    OrderItem.objects.create(
                        order=order, product=product, quantity=quantity, price_charged=price_charged,
                    )

                    product.current_stock_quantity -= quantity
                    product.save(update_fields=["current_stock_quantity", "updated_at"])

                    total += price_charged * quantity

                order.total_amount = total
                order.save(update_fields=["total_amount", "updated_at"])
            return order
        except IntegrityError:
            continue  # order_no/tracking_token collision - retry with fresh values

    raise EcommerceError("Could not generate a unique order number, please retry.")


def update_order_status(order, status, user=None):
    """Staff-side status update. Kept deliberately simple for now: no
    state-machine validation of allowed transitions, and cancelling an
    order does NOT restore stock - both are natural follow-ups once this
    needs to handle real fulfillment/returns."""
    from apps.ecommerce.models import Order

    valid_statuses = [choice[0] for choice in Order.Status.choices]
    if status not in valid_statuses:
        raise EcommerceError(f"status must be one of: {', '.join(valid_statuses)}.")

    order.status = status
    order.save(update_fields=["status", "updated_at"])
    return order
