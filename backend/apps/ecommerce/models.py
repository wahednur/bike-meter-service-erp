from django.db import models

from apps.common.models import BaseModel
from apps.products.models import Product


class Order(BaseModel):
    """A public storefront order - no login required to place one, so
    the customer's name/phone/address are plain fields here, not linked to
    the in-person-service Customer model (kept simple for now; matching
    online orders to existing service customers is a later expansion)."""

    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        CONFIRMED = "CONFIRMED", "Confirmed"
        SHIPPED = "SHIPPED", "Shipped"
        DELIVERED = "DELIVERED", "Delivered"
        CANCELLED = "CANCELLED", "Cancelled"

    order_no = models.CharField(max_length=30, unique=True, editable=False)
    tracking_token = models.CharField(max_length=16, unique=True, editable=False)

    customer_name = models.CharField(max_length=150)
    customer_phone = models.CharField(max_length=20)
    customer_address = models.TextField()

    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING)
    total_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0, editable=False)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return self.order_no

    def save(self, *args, **kwargs):
        # Safety net, same pattern as Invoice - normal path sets these
        # explicitly via apps.ecommerce.services.place_order().
        if not self.order_no or not self.tracking_token:
            from apps.ecommerce.services import generate_order_no, generate_tracking_token

            if not self.order_no:
                self.order_no = generate_order_no()
            if not self.tracking_token:
                self.tracking_token = generate_tracking_token()
        super().save(*args, **kwargs)


class OrderItem(BaseModel):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name="items")
    product = models.ForeignKey(Product, on_delete=models.PROTECT, related_name="order_items")
    quantity = models.PositiveIntegerField()
    price_charged = models.DecimalField(max_digits=10, decimal_places=2)

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"{self.quantity} x {self.product.name} on {self.order.order_no}"

    @property
    def line_total(self):
        return self.price_charged * self.quantity
