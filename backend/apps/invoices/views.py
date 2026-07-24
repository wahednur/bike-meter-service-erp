from django.shortcuts import get_object_or_404
from rest_framework import mixins, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import IsAdmin, IsAdminOrHasModelPermission
from apps.audit.services import log_action
from apps.invoices import services as invoice_services
from apps.invoices.exceptions import InvoiceError
from apps.invoices.models import Invoice, InvoicePayment, InvoiceProductLine, InvoiceServiceLine
from apps.invoices.serializers import (
    AddMeterEntryInputSerializer,
    AddPaymentInputSerializer,
    AddProductLineInputSerializer,
    AddServiceLineInputSerializer,
    ApplyDiscountInputSerializer,
    ForceCloseInvoiceInputSerializer,
    InvoiceDetailSerializer,
    InvoiceMeterEntrySerializer,
    InvoicePaymentSerializer,
    InvoiceProductLineSerializer,
    InvoiceSerializer,
    InvoiceServiceLineSerializer,
    PublicInvoiceDetailSerializer,
    ReasonInputSerializer,
    StartInvoiceInputSerializer,
    UpdateInvoiceCreatedDateInputSerializer,
    UpdatePaymentInputSerializer,
    UpdateProductLineInputSerializer,
    UpdateServiceLineInputSerializer,
)


def _require_admin_for_forced_edit(request, invoice):
    """Rule 14: editing/deleting on a Paid or force-closed invoice is
    Admin-only, regardless of the regular add/change permission that
    otherwise governs this endpoint while the invoice is open. Reuses
    IsAdmin's own check rather than duplicating the role logic."""
    if invoice.is_editable:
        return
    if not IsAdmin().has_permission(request, None):
        raise PermissionDenied("Editing a Paid invoice requires Admin.")


class InvoiceViewSet(
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    mixins.DestroyModelMixin,
    viewsets.GenericViewSet,
):
    """Read-only for create/update on the base resource - invoices are never
    created or edited via raw POST/PUT/PATCH on /invoices/. Every mutation
    goes through a dedicated action below, which calls the service layer so
    rules (a)-(f) are always enforced. DELETE is allowed (soft delete only,
    see BaseModel.delete()), same restriction as cancel: a fully paid
    invoice is a settled financial record and cannot be removed."""

    queryset = Invoice.objects.select_related("customer").all()
    permission_classes = [IsAdminOrHasModelPermission]

    def get_serializer_class(self):
        if self.action == "retrieve":
            return InvoiceDetailSerializer
        return InvoiceSerializer

    def perform_destroy(self, instance):
        if instance.status == Invoice.Status.PAID:
            raise ValidationError("A fully paid invoice cannot be deleted.")
        instance.delete()  # soft delete, see BaseModel.delete()
        log_action(instance, "invoice_deleted", "Invoice deleted.", user=self.request.user)

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
        """Kept for backward compatibility and internal use (the merged
        add_service_line() below calls the same service function directly
        for a Mileage Correction service). Not an intended frontend entry
        point going forward - new work should go through POST
        .../service-lines/, which creates the InvoiceMeterEntry and the
        InvoiceServiceLine together in one call."""
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
        """The merged endpoint: for a Mileage Correction service, pass
        `meter` + serial_number/condition_note/previous_km/current_km/
        mileage_correction_device instead of a pre-existing `meter_entry`,
        and this creates both records together. See
        AddServiceLineInputSerializer's docstring for the full shape,
        including the product_used/product_price combination-repair
        fields."""
        invoice = self.get_object()
        serializer = AddServiceLineInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            line = invoice_services.add_service_line(invoice, user=request.user, **serializer.validated_data)
        except InvoiceError as exc:
            raise ValidationError(str(exc))
        return Response(InvoiceServiceLineSerializer(line).data, status=201)

    def update_service_line(self, request, pk=None, line_pk=None):
        """PATCH /api/invoices/{pk}/service-lines/{line_pk}/ - not a DRF
        @action (needs a second id in the URL, which the @action/router
        machinery doesn't support), so it's wired up directly in urls.py
        via InvoiceViewSet.as_view({...}). Also doubles as the "replace"
        endpoint (pass `service` to swap which service this line bills)
        and, with a `reason`, the Admin-only path to edit a Paid invoice."""
        invoice = self.get_object()
        line = get_object_or_404(InvoiceServiceLine, pk=line_pk, invoice=invoice)
        serializer = UpdateServiceLineInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        _require_admin_for_forced_edit(request, invoice)
        try:
            invoice_services.update_service_line(invoice, line, user=request.user, **serializer.validated_data)
        except InvoiceError as exc:
            raise ValidationError(str(exc))
        line.refresh_from_db()
        return Response(InvoiceServiceLineSerializer(line).data)

    def destroy_service_line(self, request, pk=None, line_pk=None):
        """DELETE /api/invoices/{pk}/service-lines/{line_pk}/ - see
        update_service_line() above for why this isn't a DRF @action."""
        invoice = self.get_object()
        line = get_object_or_404(InvoiceServiceLine, pk=line_pk, invoice=invoice)
        serializer = ReasonInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        _require_admin_for_forced_edit(request, invoice)
        try:
            invoice_services.delete_service_line(invoice, line, user=request.user, **serializer.validated_data)
        except InvoiceError as exc:
            raise ValidationError(str(exc))
        return Response(status=204)

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

    def update_product_line(self, request, pk=None, line_pk=None):
        """PATCH /api/invoices/{pk}/product-lines/{line_pk}/ - see
        update_service_line() above for why this isn't a DRF @action; same
        "replace" (pass `product`) and Admin-only forced-edit support."""
        invoice = self.get_object()
        line = get_object_or_404(InvoiceProductLine, pk=line_pk, invoice=invoice)
        serializer = UpdateProductLineInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        _require_admin_for_forced_edit(request, invoice)
        try:
            invoice_services.update_product_line(invoice, line, user=request.user, **serializer.validated_data)
        except InvoiceError as exc:
            raise ValidationError(str(exc))
        line.refresh_from_db()
        return Response(InvoiceProductLineSerializer(line).data)

    def destroy_product_line(self, request, pk=None, line_pk=None):
        """DELETE /api/invoices/{pk}/product-lines/{line_pk}/ - see
        update_service_line() above for why this isn't a DRF @action."""
        invoice = self.get_object()
        line = get_object_or_404(InvoiceProductLine, pk=line_pk, invoice=invoice)
        serializer = ReasonInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        _require_admin_for_forced_edit(request, invoice)
        try:
            invoice_services.delete_product_line(invoice, line, user=request.user, **serializer.validated_data)
        except InvoiceError as exc:
            raise ValidationError(str(exc))
        return Response(status=204)

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

    def update_payment(self, request, pk=None, payment_pk=None):
        """PATCH /api/invoices/{pk}/payments/{payment_pk}/ - correcting a
        payment, mainly meant for the Admin-only Paid-invoice path (rule 14,
        `reason` required in that case). Not a DRF @action - see
        update_service_line() above."""
        invoice = self.get_object()
        payment = get_object_or_404(InvoicePayment, pk=payment_pk, invoice=invoice)
        serializer = UpdatePaymentInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        _require_admin_for_forced_edit(request, invoice)
        try:
            invoice_services.update_payment(invoice, payment, user=request.user, **serializer.validated_data)
        except InvoiceError as exc:
            raise ValidationError(str(exc))
        payment.refresh_from_db()
        return Response(InvoicePaymentSerializer(payment).data)

    def destroy_payment(self, request, pk=None, payment_pk=None):
        """DELETE /api/invoices/{pk}/payments/{payment_pk}/ - see
        update_payment() above."""
        invoice = self.get_object()
        payment = get_object_or_404(InvoicePayment, pk=payment_pk, invoice=invoice)
        serializer = ReasonInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        _require_admin_for_forced_edit(request, invoice)
        try:
            invoice_services.delete_payment(invoice, payment, user=request.user, **serializer.validated_data)
        except InvoiceError as exc:
            raise ValidationError(str(exc))
        return Response(status=204)

    @action(detail=True, methods=["post"])
    def cancel(self, request, pk=None):
        invoice = self.get_object()
        try:
            invoice_services.cancel_invoice(invoice, user=request.user)
        except InvoiceError as exc:
            raise ValidationError(str(exc))
        return Response(InvoiceDetailSerializer(invoice).data)

    @action(detail=True, methods=["post"], permission_classes=[IsAdmin])
    def discount(self, request, pk=None):
        """Apply or update the invoice's fixed-BDT discount. Admin only -
        Staff cannot give discounts, since this affects revenue directly."""
        invoice = self.get_object()
        serializer = ApplyDiscountInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            invoice_services.apply_discount(invoice, user=request.user, **serializer.validated_data)
        except InvoiceError as exc:
            raise ValidationError(str(exc))
        return Response(InvoiceDetailSerializer(invoice).data)

    @action(detail=True, methods=["post"], url_path="force-close", permission_classes=[IsAdmin])
    def force_close(self, request, pk=None):
        """Rule 11: Admin-only "accept the remaining balance as final"
        write-off. Records the waived amount separately from any discount
        and marks the invoice Paid - see
        apps.invoices.services.force_close_invoice()."""
        invoice = self.get_object()
        serializer = ForceCloseInvoiceInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            invoice_services.force_close_invoice(invoice, user=request.user, **serializer.validated_data)
        except InvoiceError as exc:
            raise ValidationError(str(exc))
        return Response(InvoiceDetailSerializer(invoice).data)

    @action(detail=True, methods=["post"], url_path="created-date", permission_classes=[IsAdmin])
    def update_created_date(self, request, pk=None):
        """Rule 3: Admin-only edit of created_date, audit-logged with the
        old/new value. `reason` is required if the invoice is Paid/
        force-closed (rule 14)."""
        invoice = self.get_object()
        serializer = UpdateInvoiceCreatedDateInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            invoice_services.update_invoice_created_date(invoice, user=request.user, **serializer.validated_data)
        except InvoiceError as exc:
            raise ValidationError(str(exc))
        return Response(InvoiceDetailSerializer(invoice).data)


class PaymentViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    """GET /api/payments/ - every InvoicePayment across every invoice, for a
    general "Payments" page. Read-only: new payments are still only ever
    recorded via POST /api/invoices/{id}/payments/, since that's what
    enforces the overpayment guard and triggers the per-meter split/red-list
    recalculation - this view exists purely to look across invoices."""

    queryset = InvoicePayment.objects.select_related("invoice", "invoice__customer").all()
    serializer_class = InvoicePaymentSerializer
    permission_classes = [IsAdminOrHasModelPermission]

    def get_queryset(self):
        qs = super().get_queryset()
        params = self.request.query_params

        customer_id = params.get("customer")
        if customer_id:
            qs = qs.filter(invoice__customer_id=customer_id)

        date_from = params.get("date_from")
        if date_from:
            qs = qs.filter(payment_date__date__gte=date_from)

        date_to = params.get("date_to")
        if date_to:
            qs = qs.filter(payment_date__date__lte=date_to)

        return qs.order_by("-payment_date")


class PublicInvoiceView(APIView):
    """GET /api/public/invoices/<token>/ - read-only, no auth. This is the
    customer-facing share link (rule e); it must never accept writes."""

    permission_classes = [AllowAny]

    def get(self, request, token):
        invoice = get_object_or_404(Invoice, public_share_token=token)
        return Response(PublicInvoiceDetailSerializer(invoice).data)
