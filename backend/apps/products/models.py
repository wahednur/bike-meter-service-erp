from django.db import models

from apps.common.models import BaseModel
from apps.suppliers.models import Supplier


class Product(BaseModel):
    """A stocked item bought from a Supplier. Restocking an existing product
    must go through apps.products.services.restock_product() - never create
    a second Product row for the same item."""

    name = models.CharField(max_length=150)
    sku = models.CharField(max_length=50, unique=True)
    supplier = models.ForeignKey(Supplier, on_delete=models.PROTECT, related_name="products")
    buy_price = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    sale_price = models.DecimalField(max_digits=10, decimal_places=2)
    image = models.ImageField(upload_to="products/", null=True, blank=True)
    current_stock_quantity = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return f"{self.name} ({self.sku})"

    @property
    def profit_margin(self):
        return self.sale_price - self.buy_price


class ProductRestockEvent(BaseModel):
    """One restock transaction, logged automatically by
    apps.products.services.restock_product(). Product itself only stores a
    running weighted-average buy_price and current stock count - this is
    what lets reports show WHEN and how much was actually spent restocking,
    instead of only ever knowing today's average cost."""

    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name="restock_events")
    quantity = models.PositiveIntegerField()
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    extra_costs = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    landed_unit_cost = models.DecimalField(max_digits=10, decimal_places=2)
    total_cost = models.DecimalField(max_digits=12, decimal_places=2)
    restocked_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-restocked_at"]

    def __str__(self):
        return f"{self.quantity} x {self.product.name} on {self.restocked_at:%Y-%m-%d}"
