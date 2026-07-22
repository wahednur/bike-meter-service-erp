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
    description = models.TextField(blank=True)
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


class Purchase(BaseModel):
    """One trip to a supplier that may cover several different products at
    once, sharing a single incidental cost (delivery, packaging) across all
    of them. See apps.products.services.apply_purchase(), which splits
    shared_extra_costs proportionally across the line items by each line's
    subtotal share, then restocks every product via the existing
    restock_product() - never call restock_product() directly for a line
    item that belongs to a Purchase."""

    supplier = models.ForeignKey(Supplier, on_delete=models.PROTECT, related_name="purchases")
    purchase_date = models.DateField()
    shared_extra_costs = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    note = models.TextField(blank=True)

    # Set by apply_purchase() once its line items have been restocked -
    # guards against silently double-restocking the same purchase.
    processed_at = models.DateTimeField(null=True, blank=True, editable=False)

    class Meta:
        ordering = ["-purchase_date"]

    def __str__(self):
        return f"Purchase from {self.supplier.name} on {self.purchase_date}"

    @property
    def is_processed(self):
        return self.processed_at is not None


class PurchaseLineItem(BaseModel):
    """One product within a Purchase, at the price actually paid for it -
    before any share of the purchase's shared_extra_costs is folded in."""

    purchase = models.ForeignKey(Purchase, on_delete=models.CASCADE, related_name="line_items")
    product = models.ForeignKey(Product, on_delete=models.PROTECT, related_name="purchase_line_items")
    quantity = models.PositiveIntegerField()
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)

    class Meta:
        ordering = ["id"]

    def __str__(self):
        return f"{self.quantity} x {self.product.name} @ {self.unit_price}"

    @property
    def subtotal(self):
        return self.unit_price * self.quantity
