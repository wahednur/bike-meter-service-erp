from decimal import Decimal

from rest_framework import serializers

from apps.products.models import Product


class ProductSerializer(serializers.ModelSerializer):
    profit_margin = serializers.ReadOnlyField()

    class Meta:
        model = Product
        fields = [
            "id", "name", "sku", "supplier", "buy_price", "sale_price", "image",
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
