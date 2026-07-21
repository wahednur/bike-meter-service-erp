from decimal import Decimal

from rest_framework import serializers

from apps.audit.models import AuditLogEntry
from apps.customers.models import Customer
from apps.invoices.models import (
    Invoice,
    InvoiceMeterEntry,
    InvoicePayment,
    InvoiceProductLine,
    InvoiceServiceLine,
)
from apps.meters.models import MileageCorrectionDevice, Meter
from apps.products.models import Product
from apps.services.models import Service


# --- read serializers ---------------------------------------------------------

class InvoiceMeterEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = InvoiceMeterEntry
        fields = [
            "id", "invoice", "meter", "serial_number", "condition_note",
            "previous_km", "current_km", "mileage_correction_device", "paid_share",
            "service_date", "created_at", "updated_at", "created_by",
        ]
        read_only_fields = fields


class InvoiceServiceLineSerializer(serializers.ModelSerializer):
    class Meta:
        model = InvoiceServiceLine
        fields = [
            "id", "invoice", "meter_entry", "service", "price_charged",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = fields


class InvoiceProductLineSerializer(serializers.ModelSerializer):
    line_total = serializers.ReadOnlyField()

    class Meta:
        model = InvoiceProductLine
        fields = [
            "id", "invoice", "product", "quantity", "price_charged", "line_total",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = fields


class InvoicePaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = InvoicePayment
        fields = [
            "id", "invoice", "amount", "payment_method", "payment_date", "note",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = fields


class AuditLogEntrySerializer(serializers.ModelSerializer):
    user = serializers.CharField(source="created_by.name", default=None, read_only=True)

    class Meta:
        model = AuditLogEntry
        fields = ["id", "action", "description", "user", "created_at"]
        read_only_fields = fields


class InvoiceSerializer(serializers.ModelSerializer):
    outstanding_amount = serializers.ReadOnlyField()

    class Meta:
        model = Invoice
        fields = [
            "id", "customer", "invoice_no", "status", "total_amount", "paid_amount",
            "outstanding_amount", "created_date", "public_share_token",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = [
            "id", "invoice_no", "status", "total_amount", "paid_amount", "outstanding_amount",
            "created_date", "public_share_token", "created_at", "updated_at", "created_by",
        ]


class InvoiceDetailSerializer(InvoiceSerializer):
    meter_entries = InvoiceMeterEntrySerializer(many=True, read_only=True)
    service_lines = InvoiceServiceLineSerializer(many=True, read_only=True)
    product_lines = InvoiceProductLineSerializer(many=True, read_only=True)
    payments = InvoicePaymentSerializer(many=True, read_only=True)
    history = AuditLogEntrySerializer(source="audit_logs", many=True, read_only=True)

    class Meta(InvoiceSerializer.Meta):
        fields = InvoiceSerializer.Meta.fields + [
            "meter_entries", "service_lines", "product_lines", "payments", "history",
        ]


# --- write-input serializers (validation only - service layer does the save) --

class StartInvoiceInputSerializer(serializers.Serializer):
    """POST /api/invoices/start/ - rule (a): reuses the customer's open
    invoice if there is one, otherwise creates a new one."""

    customer = serializers.PrimaryKeyRelatedField(queryset=Customer.objects.all())


class AddMeterEntryInputSerializer(serializers.Serializer):
    meter = serializers.PrimaryKeyRelatedField(queryset=Meter.objects.all())
    serial_number = serializers.CharField(max_length=100)
    condition_note = serializers.CharField(required=False, allow_blank=True, default="")
    previous_km = serializers.IntegerField(required=False, allow_null=True, min_value=0, default=None)
    current_km = serializers.IntegerField(required=False, allow_null=True, min_value=0, default=None)
    mileage_correction_device = serializers.PrimaryKeyRelatedField(
        queryset=MileageCorrectionDevice.objects.all(), required=False, allow_null=True, default=None,
    )


class AddServiceLineInputSerializer(serializers.Serializer):
    service = serializers.PrimaryKeyRelatedField(queryset=Service.objects.all())
    meter_entry = serializers.PrimaryKeyRelatedField(
        queryset=InvoiceMeterEntry.objects.all(), required=False, allow_null=True, default=None,
    )
    price_charged = serializers.DecimalField(
        max_digits=10, decimal_places=2, min_value=0, required=False, allow_null=True, default=None,
    )


class AddProductLineInputSerializer(serializers.Serializer):
    product = serializers.PrimaryKeyRelatedField(queryset=Product.objects.all())
    quantity = serializers.IntegerField(min_value=1)
    price_charged = serializers.DecimalField(
        max_digits=10, decimal_places=2, min_value=0, required=False, allow_null=True, default=None,
    )


class AddPaymentInputSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=Decimal("0.01"))
    payment_method = serializers.ChoiceField(
        choices=InvoicePayment.PaymentMethod.choices, default=InvoicePayment.PaymentMethod.CASH,
    )
    payment_date = serializers.DateTimeField(required=False, allow_null=True, default=None)
    note = serializers.CharField(required=False, allow_blank=True, default="")
