from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.accounts.permissions import IsAdmin, IsAdminOrHasModelPermission
from apps.meters.models import MileageCorrectionDevice, Meter
from apps.meters.serializers import (
    MeterListSerializer,
    MeterSerializer,
    MeterServiceHistoryEntrySerializer,
    MeterServiceStatsSerializer,
    MileageCorrectionDeviceSerializer,
)
from apps.meters.services import compute_meter_service_history, compute_meter_service_stats


class MeterViewSet(viewsets.ModelViewSet):
    """Full CRUD, restricted to Admin or Staff explicitly granted
    add/change/delete/view_meter permission."""

    queryset = Meter.objects.all().order_by("brand", "model")
    permission_classes = [IsAdminOrHasModelPermission]

    def get_serializer_class(self):
        if self.action == "list":
            return MeterListSerializer
        return MeterSerializer

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def perform_destroy(self, instance):
        instance.delete()  # soft delete, see BaseModel.delete()

    @action(detail=True, methods=["get"])
    def stats(self, request, pk=None):
        meter = self.get_object()
        stats = compute_meter_service_stats(meter)
        return Response(MeterServiceStatsSerializer(stats).data)

    @action(detail=True, methods=["get"], url_path="service-history")
    def service_history(self, request, pk=None):
        meter = self.get_object()
        history = compute_meter_service_history(meter)
        return Response(MeterServiceHistoryEntrySerializer(history, many=True).data)


class MileageCorrectionDeviceViewSet(viewsets.ModelViewSet):
    """Full CRUD, Admin only - these devices don't change often."""

    queryset = MileageCorrectionDevice.objects.all().order_by("name")
    serializer_class = MileageCorrectionDeviceSerializer
    permission_classes = [IsAdmin]

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def perform_destroy(self, instance):
        instance.delete()  # soft delete, see BaseModel.delete()
