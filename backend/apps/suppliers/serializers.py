from rest_framework import serializers

from apps.suppliers.models import Supplier


class SupplierSerializer(serializers.ModelSerializer):
    class Meta:
        model = Supplier
        fields = [
            "id", "name", "phone", "address", "note",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "created_by"]


class SupplierLedgerProductSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    sku = serializers.CharField()
    buy_price = serializers.DecimalField(max_digits=10, decimal_places=2)
    sale_price = serializers.DecimalField(max_digits=10, decimal_places=2)
    current_stock_quantity = serializers.IntegerField()
    stock_value = serializers.SerializerMethodField()

    def get_stock_value(self, obj):
        return obj.buy_price * obj.current_stock_quantity


class SupplierLedgerSerializer(serializers.Serializer):
    supplier = SupplierSerializer()
    products = SupplierLedgerProductSerializer(many=True)
    total_purchase_amount = serializers.DecimalField(max_digits=14, decimal_places=2)
    purchases_in_range = serializers.DecimalField(max_digits=14, decimal_places=2)
    payment_status = serializers.CharField()
