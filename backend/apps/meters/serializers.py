from rest_framework import serializers

from apps.meters.models import MileageCorrectionDevice, Meter


class MeterSerializer(serializers.ModelSerializer):
    title = serializers.ReadOnlyField()

    class Meta:
        model = Meter
        fields = [
            "id", "brand", "model", "cc", "memory_type", "ic_mcu_model",
            "title", "sales_price", "image",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "created_by"]

    @staticmethod
    def validate_mileage_correction_tool(memory_type, tool):
        """Business rule, not yet wired to anything: MCU meters can only be
        mileage-corrected with "VVDI Prog"; EEPROM meters allow RT809F,
        TOP2013, UPA USB 1.3, or EasyPro2025.

        Once the Invoice app exists, invoice creation for a mileage
        correction service will call this with the meter's memory_type and
        the chosen tool before allowing the line item to be saved.
        """
        allowed = Meter.ALLOWED_CORRECTION_TOOLS.get(memory_type, [])
        if tool not in allowed:
            raise serializers.ValidationError(
                f"'{tool}' cannot be used to correct mileage on a {memory_type} "
                f"meter. Allowed tools: {', '.join(allowed)}."
            )
        return tool


class MeterListSerializer(MeterSerializer):
    """Used for the list endpoint - adds per-meter service/sales stats.

    These are hardcoded to 0/None until the Invoice/Service apps exist to
    actually track services performed and sales made per meter.
    """

    service_quantity = serializers.SerializerMethodField()
    total_sale_price = serializers.SerializerMethodField()
    average_sale_price = serializers.SerializerMethodField()

    class Meta(MeterSerializer.Meta):
        fields = MeterSerializer.Meta.fields + [
            "service_quantity", "total_sale_price", "average_sale_price",
        ]

    def get_service_quantity(self, obj):
        return 0

    def get_total_sale_price(self, obj):
        return None

    def get_average_sale_price(self, obj):
        return None


class MileageCorrectionDeviceSerializer(serializers.ModelSerializer):
    """CRUD serializer with per-device job/revenue stats, now computed for
    real from Invoice data - see apps.meters.services.compute_mileage_correction_device_stats().
    """

    total_jobs_count = serializers.SerializerMethodField()
    total_revenue_generated = serializers.SerializerMethodField()
    cost_recovered = serializers.SerializerMethodField()

    class Meta:
        model = MileageCorrectionDevice
        fields = [
            "id", "name", "purchase_price", "purchase_date", "memory_type_support",
            "total_jobs_count", "total_revenue_generated", "cost_recovered",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "created_by"]

    def get_total_jobs_count(self, obj):
        from apps.meters.services import compute_mileage_correction_device_stats

        return compute_mileage_correction_device_stats(obj)["total_jobs_count"]

    def get_total_revenue_generated(self, obj):
        from apps.meters.services import compute_mileage_correction_device_stats

        return compute_mileage_correction_device_stats(obj)["total_revenue_generated"]

    def get_cost_recovered(self, obj):
        from apps.meters.services import compute_mileage_correction_device_stats

        return compute_mileage_correction_device_stats(obj)["cost_recovered"]
