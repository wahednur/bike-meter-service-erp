from rest_framework import serializers

from apps.ecommerce.models import Order, OrderItem
from apps.products.models import Product


class PublicProductSerializer(serializers.ModelSerializer):
    """Public storefront listing - name/image/price ONLY. Never expose
    buy_price, profit_margin, supplier, or current_stock_quantity here."""

    price = serializers.DecimalField(source="sale_price", max_digits=10, decimal_places=2, read_only=True)

    class Meta:
        model = Product
        fields = ["id", "name", "image", "price"]
        read_only_fields = fields


class OrderItemSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source="product.name", read_only=True)
    line_total = serializers.ReadOnlyField()

    class Meta:
        model = OrderItem
        fields = ["id", "product", "product_name", "quantity", "price_charged", "line_total"]
        read_only_fields = fields


class OrderSerializer(serializers.ModelSerializer):
    """Used for both public order tracking and staff order management.
    price_charged only ever snapshots sale_price, so this never leaks
    cost/profit either."""

    items = OrderItemSerializer(many=True, read_only=True)

    class Meta:
        model = Order
        fields = [
            "id", "order_no", "tracking_token", "status",
            "customer_name", "customer_phone", "customer_address",
            "total_amount", "items", "created_at", "updated_at",
        ]
        read_only_fields = fields


class PlaceOrderItemInputSerializer(serializers.Serializer):
    product = serializers.PrimaryKeyRelatedField(queryset=Product.objects.all())
    quantity = serializers.IntegerField(min_value=1)


class PlaceOrderInputSerializer(serializers.Serializer):
    customer_name = serializers.CharField(max_length=150)
    customer_phone = serializers.CharField(max_length=20)
    customer_address = serializers.CharField()
    items = PlaceOrderItemInputSerializer(many=True)

    def validate_items(self, value):
        if not value:
            raise serializers.ValidationError("Order must contain at least one item.")
        return value


class OrderStatusUpdateInputSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=Order.Status.choices)
