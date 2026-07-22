from decimal import Decimal

from rest_framework import serializers

from apps.products.models import Product, Purchase, PurchaseLineItem
from apps.suppliers.models import Supplier


class ProductSerializer(serializers.ModelSerializer):
    profit_margin = serializers.ReadOnlyField()

    class Meta:
        model = Product
        fields = [
            "id", "name", "sku", "supplier", "buy_price", "sale_price", "image", "description",
            "current_stock_quantity", "profit_margin",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "created_by"]


class RestockSerializer(serializers.Serializer):
    """Input for POST /products/{id}/restock/ - adds stock and recalculates
    buy_price as a weighted average via apps.products.services.restock_product()."""

    quantity = serializers.IntegerField(min_value=1)
    unit_price = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=0)
    extra_costs = serializers.DecimalField(
        max_digits=10, decimal_places=2, min_value=0, required=False, default=Decimal("0"),
    )


class StockAdjustmentSerializer(serializers.Serializer):
    """Input for POST /products/{id}/adjust-stock/ - a plain quantity
    correction (recount, damage, loss) that does NOT touch buy_price.
    Use the restock endpoint instead when new stock has actually arrived."""

    delta = serializers.IntegerField()


# --- multi-product purchase (delivery charge split across products) -----------

class PurchaseLineItemSerializer(serializers.ModelSerializer):
    """Read-only. extra_cost_share/landed_unit_cost are injected by
    PurchaseSerializer.to_representation() from
    apps.products.services.compute_purchase_line_shares() - the same
    function apply_purchase() uses to actually restock, so what you see
    here is exactly what gets applied."""

    product_name = serializers.ReadOnlyField(source="product.name")
    subtotal = serializers.ReadOnlyField()

    class Meta:
        model = PurchaseLineItem
        fields = ["id", "purchase", "product", "product_name", "quantity", "unit_price", "subtotal"]
        read_only_fields = fields


class PurchaseSerializer(serializers.ModelSerializer):
    supplier_name = serializers.ReadOnlyField(source="supplier.name")
    is_processed = serializers.ReadOnlyField()
    line_items = PurchaseLineItemSerializer(many=True, read_only=True)

    class Meta:
        model = Purchase
        fields = [
            "id", "supplier", "supplier_name", "purchase_date", "shared_extra_costs", "note",
            "is_processed", "processed_at", "line_items",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = fields

    def to_representation(self, instance):
        from apps.products.services import compute_purchase_line_shares

        data = super().to_representation(instance)
        share_by_line_id = {
            item.id: (extra_share, landed_unit_cost)
            for item, extra_share, landed_unit_cost in compute_purchase_line_shares(instance)
        }
        for line in data["line_items"]:
            extra_share, landed_unit_cost = share_by_line_id.get(line["id"], (Decimal("0"), Decimal(line["unit_price"])))
            line["extra_cost_share"] = str(extra_share)
            line["landed_unit_cost"] = str(landed_unit_cost)
        return data


class PurchaseLineItemInputSerializer(serializers.Serializer):
    product = serializers.PrimaryKeyRelatedField(queryset=Product.objects.all())
    quantity = serializers.IntegerField(min_value=1)
    unit_price = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=0)


class CreatePurchaseInputSerializer(serializers.Serializer):
    """POST /api/purchases/ - creates the Purchase + its PurchaseLineItems
    and immediately applies it (restocks every product, splitting
    shared_extra_costs proportionally) - see
    apps.products.services.apply_purchase(). There's no separate
    draft/confirm step; once created, a purchase is processed."""

    supplier = serializers.PrimaryKeyRelatedField(queryset=Supplier.objects.all())
    purchase_date = serializers.DateField()
    shared_extra_costs = serializers.DecimalField(
        max_digits=10, decimal_places=2, min_value=0, required=False, default=Decimal("0"),
    )
    note = serializers.CharField(required=False, allow_blank=True, default="")
    line_items = PurchaseLineItemInputSerializer(many=True)

    def validate_line_items(self, value):
        if not value:
            raise serializers.ValidationError("A purchase must have at least one line item.")
        return value
