from rest_framework import serializers

from apps.assets.models import Asset, AssetIncident


class AssetSerializer(serializers.ModelSerializer):
    class Meta:
        model = Asset
        fields = [
            "id", "name", "purchase_price", "purchase_date", "supplier",
            "has_warranty", "warranty_note",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "created_by"]


class AssetIncidentSerializer(serializers.ModelSerializer):
    class Meta:
        model = AssetIncident
        fields = ["id", "asset", "type", "cost", "date", "note", "created_at", "updated_at", "created_by"]
        read_only_fields = ["id", "created_at", "updated_at", "created_by"]


class CostRecoveryReportItemSerializer(serializers.Serializer):
    """One row of the combined Asset + MileageCorrectionDevice cost
    recovery report - see apps.assets.services.build_cost_recovery_report()."""

    type = serializers.CharField()
    id = serializers.IntegerField()
    name = serializers.CharField()
    purchase_price = serializers.DecimalField(max_digits=10, decimal_places=2)
    total_incident_cost = serializers.DecimalField(max_digits=10, decimal_places=2)
    total_cost_incurred = serializers.DecimalField(max_digits=12, decimal_places=2)
    total_revenue = serializers.DecimalField(max_digits=12, decimal_places=2)
    profit_loss = serializers.DecimalField(max_digits=12, decimal_places=2)
    status = serializers.CharField()
    cost_recovered = serializers.BooleanField()
