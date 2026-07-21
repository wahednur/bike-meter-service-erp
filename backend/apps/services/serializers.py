from rest_framework import serializers

from apps.services.models import Service, ServiceCategory


class ServiceCategorySerializer(serializers.ModelSerializer):
    name_display = serializers.CharField(source="get_name_display", read_only=True)

    class Meta:
        model = ServiceCategory
        fields = ["id", "name", "name_display", "created_at", "updated_at", "created_by"]
        read_only_fields = ["id", "created_at", "updated_at", "created_by"]


class ServiceSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source="category.get_name_display", read_only=True)

    class Meta:
        model = Service
        fields = [
            "id", "category", "category_name", "name", "service_price", "image", "description",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "created_by"]

    @staticmethod
    def validate_invoice_line_fields(service, previous_km, current_km, meter_condition_note):
        """Business rule, not yet wired to anything: if `service`'s category
        is Mileage Correction, previous_km, current_km, and
        meter_condition_note are all required on the invoice line item.

        Once the Invoice app exists, invoice line-item creation will call
        this before allowing the line item to be saved.
        """
        if not service.requires_mileage_correction_fields:
            return

        missing = [
            field_name
            for field_name, value in (
                ("previous_km", previous_km),
                ("current_km", current_km),
                ("meter_condition_note", meter_condition_note),
            )
            if value in (None, "")
        ]
        if missing:
            raise serializers.ValidationError(
                f"{', '.join(missing)} required for a Mileage Correction service."
            )


class ServiceListSerializer(ServiceSerializer):
    """Used for the list endpoint - adds per-service sales stats.

    These are hardcoded to 0 until the Invoice app exists to actually track
    how many times each service has been sold.
    """

    total_service_quantity = serializers.SerializerMethodField()
    total_sale_price = serializers.SerializerMethodField()
    average_sale_price = serializers.SerializerMethodField()

    class Meta(ServiceSerializer.Meta):
        fields = ServiceSerializer.Meta.fields + [
            "total_service_quantity", "total_sale_price", "average_sale_price",
        ]

    def get_total_service_quantity(self, obj):
        return 0

    def get_total_sale_price(self, obj):
        return 0

    def get_average_sale_price(self, obj):
        return 0
