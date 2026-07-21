from rest_framework import viewsets

from apps.accounts.permissions import IsAdmin, IsAdminOrHasModelPermission
from apps.meters.models import MileageCorrectionDevice, Meter
from apps.meters.serializers import (
    MeterListSerializer,
    MeterSerializer,
    MileageCorrectionDeviceSerializer,
)


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


class MileageCorrectionDeviceViewSet(viewsets.ModelViewSet):
    """Full CRUD, Admin only - these devices don't change often."""

    queryset = MileageCorrectionDevice.objects.all().order_by("name")
    serializer_class = MileageCorrectionDeviceSerializer
    permission_classes = [IsAdmin]

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def perform_destroy(self, instance):
        instance.delete()  # soft delete, see BaseModel.delete()
