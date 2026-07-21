from django.db.models import Avg, Count, F
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response

from apps.accounts.permissions import IsAdminOrHasModelPermission
from apps.products.models import Product
from apps.products.serializers import (
    ProductSerializer,
    RestockSerializer,
    StockAdjustmentSerializer,
)
from apps.products.services import restock_product


class ProductViewSet(viewsets.ModelViewSet):
    """Full CRUD, restricted to Admin or Staff explicitly granted
    add/change/delete/view_product permission, plus restock/adjust-stock
    actions and a supplier profit analysis report."""

    queryset = Product.objects.select_related("supplier").order_by("name")
    serializer_class = ProductSerializer
    permission_classes = [IsAdminOrHasModelPermission]

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def perform_destroy(self, instance):
        instance.delete()  # soft delete, see BaseModel.delete()

    @action(detail=True, methods=["post"])
    def restock(self, request, pk=None):
        """New stock arriving for an existing product. Adds quantity and
        recalculates buy_price as a weighted average - see
        apps.products.services.restock_product()."""
        product = self.get_object()
        serializer = RestockSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        restock_product(
            product,
            quantity=serializer.validated_data["quantity"],
            unit_price=serializer.validated_data["unit_price"],
            extra_costs=serializer.validated_data["extra_costs"],
        )
        return Response(ProductSerializer(product).data)

    @action(detail=True, methods=["post"], url_path="adjust-stock")
    def adjust_stock(self, request, pk=None):
        """Plain quantity correction (recount, damage, loss) that does not
        touch buy_price. Use `restock` when new stock has actually arrived."""
        product = self.get_object()
        serializer = StockAdjustmentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        delta = serializer.validated_data["delta"]
        new_quantity = product.current_stock_quantity + delta
        if new_quantity < 0:
            raise ValidationError("Adjustment would result in negative stock.")

        product.current_stock_quantity = new_quantity
        product.save(update_fields=["current_stock_quantity", "updated_at"])
        return Response(ProductSerializer(product).data)

    @action(detail=False, methods=["get"], url_path="supplier-profit-analysis")
    def supplier_profit_analysis(self, request):
        """Average profit margin (sale_price - buy_price) per supplier,
        best margin first."""
        rows = (
            Product.objects.values("supplier_id", "supplier__name")
            .annotate(
                product_count=Count("id"),
                avg_buy_price=Avg("buy_price"),
                avg_sale_price=Avg("sale_price"),
                avg_profit_margin=Avg(F("sale_price") - F("buy_price")),
            )
            .order_by("-avg_profit_margin")
        )
        data = [
            {
                "supplier_id": row["supplier_id"],
                "supplier_name": row["supplier__name"],
                "product_count": row["product_count"],
                "avg_buy_price": row["avg_buy_price"],
                "avg_sale_price": row["avg_sale_price"],
                "avg_profit_margin": row["avg_profit_margin"],
            }
            for row in rows
        ]
        return Response(data)
