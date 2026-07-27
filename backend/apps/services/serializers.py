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
        """Business rule: if `service`'s category is Mileage Correction,
        meter_condition_note (a list of condition tags) is required on the
        invoice line item - at least one tag, preset or custom. Only
        applies when creating a *new* meter entry inline for the line; an
        already-existing entry passed in here has already gone through
        InvoiceMeterEntry.save()'s own ["Good"] default, so it can never
        actually be empty by this point. previous_km/current_km are
        optional (some jobs don't have this info available at entry time)
        and independent of each other - no relational rule between them.
        A mileage correction job's whole point is rolling an inflated
        odometer reading back down, so current_km < previous_km is the
        normal, expected case, not an error.
        """
        if not service.requires_mileage_correction_fields:
            return

        if not meter_condition_note:
            raise serializers.ValidationError(
                "meter_condition_note required for a Mileage Correction service."
            )


class ServiceListSerializer(ServiceSerializer):
    """Used for the list endpoint - adds per-service, all-time sales stats
    (every InvoiceServiceLine ever billed for this service). See
    apps.reports.services.service_performance_report for the date-range-
    filterable, ranked version of the same numbers."""

    total_service_quantity = serializers.SerializerMethodField()
    total_sale_price = serializers.SerializerMethodField()
    average_sale_price = serializers.SerializerMethodField()

    class Meta(ServiceSerializer.Meta):
        fields = ServiceSerializer.Meta.fields + [
            "total_service_quantity", "total_sale_price", "average_sale_price",
        ]

    def get_total_service_quantity(self, obj):
        return obj.invoice_lines.count()

    def get_total_sale_price(self, obj):
        from django.db.models import Sum

        return obj.invoice_lines.aggregate(total=Sum("price_charged"))["total"] or 0

    def get_average_sale_price(self, obj):
        quantity = self.get_total_service_quantity(obj)
        if not quantity:
            return 0
        return self.get_total_sale_price(obj) / quantity
