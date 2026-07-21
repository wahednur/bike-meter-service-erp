from django.shortcuts import get_object_or_404
from rest_framework import mixins, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import IsAdminOrHasModelPermission
from apps.ecommerce import services as ecommerce_services
from apps.ecommerce.exceptions import EcommerceError
from apps.ecommerce.models import Order
from apps.ecommerce.serializers import (
    OrderSerializer,
    OrderStatusUpdateInputSerializer,
    PlaceOrderInputSerializer,
    PublicProductSerializer,
)
from apps.products.models import Product


class PublicProductViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    """Public storefront listing - no auth. Only in-stock products are
    shown, and never cost/profit fields (see PublicProductSerializer)."""

    queryset = Product.objects.filter(current_stock_quantity__gt=0).order_by("name")
    serializer_class = PublicProductSerializer
    permission_classes = [AllowAny]

    def get_serializer_context(self):
        return {"request": self.request}  # absolute image URLs for a public frontend


class PlaceOrderView(APIView):
    """POST /api/public/orders/ - no auth required. Returns the created
    order, including tracking_token, so the customer can check status
    later via PublicOrderTrackingView."""

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = PlaceOrderInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        try:
            order = ecommerce_services.place_order(
                customer_name=data["customer_name"],
                customer_phone=data["customer_phone"],
                customer_address=data["customer_address"],
                items=data["items"],
            )
        except EcommerceError as exc:
            raise ValidationError(str(exc))
        return Response(OrderSerializer(order).data, status=201)


class PublicOrderTrackingView(APIView):
    """GET /api/public/orders/<token>/ - no auth, read-only order status
    tracking by the token returned at placement time."""

    permission_classes = [AllowAny]

    def get(self, request, token):
        order = get_object_or_404(Order, tracking_token=token)
        return Response(OrderSerializer(order).data)


class OrderViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    """Staff-side order management. Orders are only ever created through
    the public placement flow, never directly here - this is read plus a
    status-update action. Optional ?status= filter."""

    queryset = Order.objects.prefetch_related("items", "items__product").order_by("-created_at")
    serializer_class = OrderSerializer
    permission_classes = [IsAdminOrHasModelPermission]

    def get_queryset(self):
        qs = super().get_queryset()
        status_param = self.request.query_params.get("status")
        if status_param:
            qs = qs.filter(status=status_param.upper())
        return qs

    @action(detail=True, methods=["post"])
    def status(self, request, pk=None):
        order = self.get_object()
        serializer = OrderStatusUpdateInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            ecommerce_services.update_order_status(order, serializer.validated_data["status"], user=request.user)
        except EcommerceError as exc:
            raise ValidationError(str(exc))
        return Response(OrderSerializer(order).data)
