from django.shortcuts import get_object_or_404
from rest_framework import mixins, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import IsAdminOrHasModelPermission
from apps.invoices import services as invoice_services
from apps.invoices.exceptions import InvoiceError
from apps.invoices.models import Invoice
from apps.invoices.serializers import (
    AddMeterEntryInputSerializer,
    AddPaymentInputSerializer,
    AddProductLineInputSerializer,
    AddServiceLineInputSerializer,
    InvoiceDetailSerializer,
    InvoiceMeterEntrySerializer,
    InvoicePaymentSerializer,
    InvoiceProductLineSerializer,
    InvoiceSerializer,
    InvoiceServiceLineSerializer,
    StartInvoiceInputSerializer,
)


class InvoiceViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    """Read-only for the base resource - invoices are never created or
    edited via raw POST/PUT/PATCH on /invoices/. Every mutation goes
    through a dedicated action below, which calls the service layer so
    rules (a)-(f) are always enforced."""

    queryset = Invoice.objects.select_related("customer").all()
    permission_classes = [IsAdminOrHasModelPermission]

    def get_serializer_class(self):
        if self.action == "retrieve":
            return InvoiceDetailSerializer
        return InvoiceSerializer

    def get_queryset(self):
        qs = super().get_queryset()
        params = self.request.query_params

        status_param = params.get("status")
        if status_param:
            qs = qs.filter(status=status_param.upper())

        customer_id = params.get("customer")
        if customer_id:
            qs = qs.filter(customer_id=customer_id)

        date_from = params.get("date_from")
        if date_from:
            qs = qs.filter(created_date__gte=date_from)

        date_to = params.get("date_to")
        if date_to:
            qs = qs.filter(created_date__lte=date_to)

        return qs.order_by("-created_at")

    @action(detail=False, methods=["post"])
    def start(self, request):
        """Rule (a): open a visit for a customer - reuses their open
        invoice if there is one, otherwise creates a new one."""
        serializer = StartInvoiceInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        invoice, created = invoice_services.get_or_create_open_invoice(
            serializer.validated_data["customer"], user=request.user,
        )
        return Response(InvoiceDetailSerializer(invoice).data, status=201 if created else 200)

    @action(detail=True, methods=["post"], url_path="meter-entries")
    def add_meter_entry(self, request, pk=None):
        invoice = self.get_object()
        serializer = AddMeterEntryInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            entry = invoice_services.add_meter_entry(invoice, user=request.user, **serializer.validated_data)
        except InvoiceError as exc:
            raise ValidationError(str(exc))
        return Response(InvoiceMeterEntrySerializer(entry).data, status=201)

    @action(detail=True, methods=["post"], url_path="service-lines")
    def add_service_line(self, request, pk=None):
        invoice = self.get_object()
        serializer = AddServiceLineInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            line = invoice_services.add_service_line(invoice, user=request.user, **serializer.validated_data)
        except InvoiceError as exc:
            raise ValidationError(str(exc))
        return Response(InvoiceServiceLineSerializer(line).data, status=201)

    @action(detail=True, methods=["post"], url_path="product-lines")
    def add_product_line(self, request, pk=None):
        invoice = self.get_object()
        serializer = AddProductLineInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            line = invoice_services.add_product_line(invoice, user=request.user, **serializer.validated_data)
        except InvoiceError as exc:
            raise ValidationError(str(exc))
        return Response(InvoiceProductLineSerializer(line).data, status=201)

    @action(detail=True, methods=["post"])
    def payments(self, request, pk=None):
        invoice = self.get_object()
        serializer = AddPaymentInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            payment = invoice_services.add_payment(invoice, user=request.user, **serializer.validated_data)
        except InvoiceError as exc:
            raise ValidationError(str(exc))
        return Response(InvoicePaymentSerializer(payment).data, status=201)

    @action(detail=True, methods=["post"])
    def cancel(self, request, pk=None):
        invoice = self.get_object()
        try:
            invoice_services.cancel_invoice(invoice, user=request.user)
        except InvoiceError as exc:
            raise ValidationError(str(exc))
        return Response(InvoiceDetailSerializer(invoice).data)


class PublicInvoiceView(APIView):
    """GET /api/public/invoices/<token>/ - read-only, no auth. This is the
    customer-facing share link (rule e); it must never accept writes."""

    permission_classes = [AllowAny]

    def get(self, request, token):
        invoice = get_object_or_404(Invoice, public_share_token=token)
        return Response(InvoiceDetailSerializer(invoice).data)
