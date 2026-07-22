from django.db import transaction
from django.db.models import Avg, Count, F
from rest_framework import mixins, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response

from apps.accounts.permissions import IsAdminOrHasModelPermission
from apps.products.models import Product, Purchase, PurchaseLineItem
from apps.products.serializers import (
    CreatePurchaseInputSerializer,
    ProductSerializer,
    PurchaseSerializer,
    RestockSerializer,
    StockAdjustmentSerializer,
)
from apps.products.services import apply_purchase, restock_product


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
        return Response(ProductSerializer(product, context=self.get_serializer_context()).data)

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
        return Response(ProductSerializer(product, context=self.get_serializer_context()).data)

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


class PurchaseViewSet(
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    mixins.CreateModelMixin,
    viewsets.GenericViewSet,
):
    """Multi-product purchase entry: POST creates the Purchase + its
    PurchaseLineItems and immediately applies it (restocks every product,
    splitting shared_extra_costs proportionally by each line's subtotal
    share) - see apps.products.services.apply_purchase(). There's no
    separate draft/confirm step or update/delete; once created, a
    purchase is processed and its effects on stock/cost are permanent,
    same as a single-product restock today."""

    queryset = (
        Purchase.objects.select_related("supplier")
        .prefetch_related("line_items", "line_items__product")
        .order_by("-purchase_date")
    )
    permission_classes = [IsAdminOrHasModelPermission]

    def get_serializer_class(self):
        if self.action == "create":
            return CreatePurchaseInputSerializer
        return PurchaseSerializer

    def create(self, request, *args, **kwargs):
        serializer = CreatePurchaseInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            with transaction.atomic():
                purchase = Purchase.objects.create(
                    supplier=data["supplier"],
                    purchase_date=data["purchase_date"],
                    shared_extra_costs=data["shared_extra_costs"],
                    note=data["note"],
                    created_by=request.user,
                )
                for item in data["line_items"]:
                    PurchaseLineItem.objects.create(
                        purchase=purchase,
                        product=item["product"],
                        quantity=item["quantity"],
                        unit_price=item["unit_price"],
                        created_by=request.user,
                    )
                apply_purchase(purchase)
        except ValueError as exc:
            raise ValidationError(str(exc))

        return Response(PurchaseSerializer(purchase).data, status=201)
