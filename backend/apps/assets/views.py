from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.accounts.permissions import IsAdminOrHasModelPermission
from apps.assets import services as asset_services
from apps.assets.models import Asset, AssetIncident
from apps.assets.serializers import (
    AssetIncidentSerializer,
    AssetSerializer,
    CostRecoveryReportItemSerializer,
)


class AssetViewSet(viewsets.ModelViewSet):
    """Full CRUD, restricted to Admin or Staff explicitly granted
    add/change/delete/view_asset permission."""

    queryset = Asset.objects.select_related("supplier").order_by("name")
    serializer_class = AssetSerializer
    permission_classes = [IsAdminOrHasModelPermission]

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def perform_destroy(self, instance):
        instance.delete()  # soft delete, see BaseModel.delete()

    @action(detail=False, methods=["get"], url_path="cost-recovery-report")
    def cost_recovery_report(self, request):
        """purchase_price vs. revenue earned, and profit/loss status, for
        every Asset and every MileageCorrectionDevice (Phase 4)."""
        rows = asset_services.build_cost_recovery_report()
        return Response(CostRecoveryReportItemSerializer(rows, many=True).data)


class AssetIncidentViewSet(viewsets.ModelViewSet):
    """Full CRUD, restricted to Admin or Staff explicitly granted
    add/change/delete/view_assetincident permission. Filter by ?asset=<id>."""

    queryset = AssetIncident.objects.select_related("asset").order_by("-date")
    serializer_class = AssetIncidentSerializer
    permission_classes = [IsAdminOrHasModelPermission]

    def get_queryset(self):
        qs = super().get_queryset()
        asset_id = self.request.query_params.get("asset")
        if asset_id:
            qs = qs.filter(asset_id=asset_id)
        return qs

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def perform_destroy(self, instance):
        instance.delete()  # soft delete, see BaseModel.delete()
