from decimal import Decimal

from rest_framework import serializers

from apps.assets.models import Asset
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
    meter_title = serializers.ReadOnlyField(source="meter.title")
    mileage_correction_device_name = serializers.CharField(
        source="mileage_correction_device.name", default=None, read_only=True,
    )

    class Meta:
        model = InvoiceMeterEntry
        fields = [
            "id", "invoice", "meter", "meter_title", "serial_number", "condition_note",
            "previous_km", "current_km", "mileage_correction_device", "mileage_correction_device_name",
            "paid_share", "service_date", "created_at", "updated_at", "created_by",
        ]
        read_only_fields = fields


class PublicInvoiceMeterEntrySerializer(InvoiceMeterEntrySerializer):
    """Same as InvoiceMeterEntrySerializer but for the public share-link
    view - the shop owner doesn't want customers seeing which programmer
    was used to do a mileage correction, so both the raw FK and its
    human-readable name are dropped entirely (not just nulled out)."""

    class Meta(InvoiceMeterEntrySerializer.Meta):
        fields = [
            f for f in InvoiceMeterEntrySerializer.Meta.fields
            if f not in ("mileage_correction_device", "mileage_correction_device_name")
        ]
        read_only_fields = fields


class InvoiceServiceLineSerializer(serializers.ModelSerializer):
    service_name = serializers.ReadOnlyField(source="service.name")
    asset_used_name = serializers.CharField(source="asset_used.name", default=None, read_only=True)
    # Full nested entry (not just the id) - the merged add-service endpoint
    # may have just created this entry inline, so the caller can render
    # everything from this one response without a follow-up GET. Null when
    # this line has no linked meter entry.
    meter_entry_detail = InvoiceMeterEntrySerializer(source="meter_entry", read_only=True)

    class Meta:
        model = InvoiceServiceLine
        fields = [
            "id", "invoice", "meter_entry", "meter_entry_detail", "service", "service_name", "price_charged",
            "asset_used", "asset_used_name",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = fields


class PublicInvoiceServiceLineSerializer(InvoiceServiceLineSerializer):
    """Same as InvoiceServiceLineSerializer but for the public share-link
    view - meter_entry_detail must go through PublicInvoiceMeterEntrySerializer
    too, or the nested object would leak the mileage correction device the
    top-level meter_entries list already hides (see PublicInvoiceMeterEntrySerializer)."""

    meter_entry_detail = PublicInvoiceMeterEntrySerializer(source="meter_entry", read_only=True)


class InvoiceProductLineSerializer(serializers.ModelSerializer):
    line_total = serializers.ReadOnlyField()
    product_name = serializers.ReadOnlyField(source="product.name")

    class Meta:
        model = InvoiceProductLine
        fields = [
            "id", "invoice", "product", "product_name", "quantity", "price_charged", "line_total",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = fields


class InvoicePaymentSerializer(serializers.ModelSerializer):
    # Convenience fields for the cross-invoice payments list (GET
    # /api/payments/) - harmless on the per-invoice add-payment response
    # too, same "*_name" pattern used on the other line-item serializers.
    invoice_no = serializers.ReadOnlyField(source="invoice.invoice_no")
    customer_name = serializers.ReadOnlyField(source="invoice.customer.name")

    class Meta:
        model = InvoicePayment
        fields = [
            "id", "invoice", "invoice_no", "customer_name", "amount", "payment_method", "payment_date", "note",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = fields


class AuditLogEntrySerializer(serializers.ModelSerializer):
    user = serializers.CharField(source="created_by.name", default=None, read_only=True)

    class Meta:
        model = AuditLogEntry
        fields = ["id", "action", "description", "user", "created_at"]
        read_only_fields = fields


class PublicAuditLogEntrySerializer(serializers.ModelSerializer):
    """Same as AuditLogEntrySerializer but without `user` - the public
    share link must never reveal which internal staff/admin member
    performed an action (e.g. who applied a discount)."""

    class Meta:
        model = AuditLogEntry
        fields = ["id", "action", "description", "created_at"]
        read_only_fields = fields


class InvoiceSerializer(serializers.ModelSerializer):
    # A plain ReadOnlyField() would pass the raw Decimal straight through to
    # DRF's JSON encoder, which renders bare Decimals as floats (670.0) -
    # unlike total_amount/paid_amount, which get DecimalField's string
    # coercion ("1570.00"). Use DecimalField here too so all three money
    # fields are consistently decimal strings on the wire.
    #
    # Exposed as "due_amount" on the wire (matching due_report's field name),
    # while staying "outstanding_amount" as the underlying model property -
    # every service-layer caller (due_report, customer ledger, etc.) already
    # depends on that property name, so only the API-facing name changes.
    due_amount = serializers.DecimalField(
        max_digits=10, decimal_places=2, read_only=True, source="outstanding_amount",
    )
    customer_name = serializers.ReadOnlyField(source="customer.name")
    customer_phone = serializers.ReadOnlyField(source="customer.phone")

    class Meta:
        model = Invoice
        fields = [
            "id", "customer", "customer_name", "customer_phone", "invoice_no", "status",
            "total_amount", "paid_amount", "due_amount", "discount_amount", "discount_note",
            "created_date", "public_share_token", "created_at", "updated_at", "created_by",
        ]
        read_only_fields = [
            "id", "invoice_no", "status", "total_amount", "paid_amount", "due_amount",
            "discount_amount", "discount_note",
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


class PublicInvoiceDetailSerializer(InvoiceDetailSerializer):
    """Served by the no-auth public share-link view. Identical to
    InvoiceDetailSerializer except meter_entries goes through
    PublicInvoiceMeterEntrySerializer (drops the mileage correction device
    fields entirely), plus shop_name/invoice_footer_text so the public page
    can render branding/a footer without needing its own authenticated call
    to the (Staff/Admin-only) shop-profile endpoint."""

    meter_entries = PublicInvoiceMeterEntrySerializer(many=True, read_only=True)
    service_lines = PublicInvoiceServiceLineSerializer(many=True, read_only=True)
    history = PublicAuditLogEntrySerializer(source="audit_logs", many=True, read_only=True)

    def to_representation(self, instance):
        from apps.shop_profile.models import ShopProfile

        data = super().to_representation(instance)
        profile = ShopProfile.load()
        data["shop_name"] = profile.shop_name
        data["invoice_footer_text"] = profile.invoice_footer_text
        return data


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
    """POST /api/invoices/{id}/service-lines/ - the merged endpoint.

    For a Mileage Correction service, either pass `meter_entry` (an id of
    an entry already on this invoice) or, to create the meter entry and
    the service line together in one call, pass `meter` plus the usual
    meter-entry fields (serial_number/condition_note/previous_km/
    current_km/mileage_correction_device) instead. Leaving `price_charged`
    blank defaults it to the meter's sales_price for a Mileage Correction
    service, or the service's service_price otherwise - see
    apps.invoices.services.add_service_line()."""

    service = serializers.PrimaryKeyRelatedField(queryset=Service.objects.all())
    meter_entry = serializers.PrimaryKeyRelatedField(
        queryset=InvoiceMeterEntry.objects.all(), required=False, allow_null=True, default=None,
    )
    price_charged = serializers.DecimalField(
        max_digits=10, decimal_places=2, min_value=0, required=False, allow_null=True, default=None,
    )
    asset_used = serializers.PrimaryKeyRelatedField(
        queryset=Asset.objects.all(), required=False, allow_null=True, default=None,
    )

    # Meter-entry fields, used only when `service` is a Mileage Correction
    # service and no existing `meter_entry` was supplied above.
    meter = serializers.PrimaryKeyRelatedField(queryset=Meter.objects.all(), required=False, allow_null=True, default=None)
    serial_number = serializers.CharField(max_length=100, required=False, allow_blank=True, default="")
    condition_note = serializers.CharField(required=False, allow_blank=True, default="")
    previous_km = serializers.IntegerField(required=False, allow_null=True, min_value=0, default=None)
    current_km = serializers.IntegerField(required=False, allow_null=True, min_value=0, default=None)
    mileage_correction_device = serializers.PrimaryKeyRelatedField(
        queryset=MileageCorrectionDevice.objects.all(), required=False, allow_null=True, default=None,
    )


class UpdateServiceLineInputSerializer(serializers.Serializer):
    """PATCH /api/invoices/{id}/service-lines/{line_id}/ - every field is
    optional; a field left out of the request body is left untouched on
    the line (and, for the meter-entry fields, on its linked
    InvoiceMeterEntry). None of these fields declare a `default`, so DRF
    omits any key the client didn't send from validated_data entirely -
    that's what lets apps.invoices.services.update_service_line() tell
    "not provided" apart from "explicitly cleared" (e.g. asset_used=null)."""

    price_charged = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=0, required=False)
    asset_used = serializers.PrimaryKeyRelatedField(queryset=Asset.objects.all(), required=False, allow_null=True)
    serial_number = serializers.CharField(max_length=100, required=False, allow_blank=True)
    condition_note = serializers.CharField(required=False, allow_blank=True)
    previous_km = serializers.IntegerField(required=False, allow_null=True, min_value=0)
    current_km = serializers.IntegerField(required=False, allow_null=True, min_value=0)
    mileage_correction_device = serializers.PrimaryKeyRelatedField(
        queryset=MileageCorrectionDevice.objects.all(), required=False, allow_null=True,
    )


class UpdateProductLineInputSerializer(serializers.Serializer):
    """PATCH /api/invoices/{id}/product-lines/{line_id}/ - see
    UpdateServiceLineInputSerializer's docstring for why neither field
    declares a `default`."""

    quantity = serializers.IntegerField(required=False, min_value=1)
    price_charged = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=0, required=False)


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


class ApplyDiscountInputSerializer(serializers.Serializer):
    """POST /api/invoices/{id}/discount/ - Admin only (see IsAdmin on the
    view action). A fixed BDT amount, never a percentage. Applies or
    updates the invoice's single discount_amount/discount_note."""

    discount_amount = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=Decimal("0"))
    discount_note = serializers.CharField(required=False, allow_blank=True, default="")
