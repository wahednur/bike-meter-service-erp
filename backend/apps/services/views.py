from rest_framework import viewsets

from apps.accounts.permissions import IsAdminOrHasModelPermission
from apps.services.models import Service, ServiceCategory
from apps.services.serializers import (
    ServiceCategorySerializer,
    ServiceListSerializer,
    ServiceSerializer,
)


class ServiceCategoryViewSet(viewsets.ModelViewSet):
    """Full CRUD, restricted to Admin or Staff explicitly granted
    add/change/delete/view_servicecategory permission."""

    queryset = ServiceCategory.objects.all().order_by("name")
    serializer_class = ServiceCategorySerializer
    permission_classes = [IsAdminOrHasModelPermission]

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def perform_destroy(self, instance):
        instance.delete()  # soft delete, see BaseModel.delete()


class ServiceViewSet(viewsets.ModelViewSet):
    """Full CRUD, restricted to Admin or Staff explicitly granted
    add/change/delete/view_service permission."""

    queryset = Service.objects.select_related("category").order_by("category__name", "name")
    permission_classes = [IsAdminOrHasModelPermission]

    def get_serializer_class(self):
        if self.action == "list":
            return ServiceListSerializer
        return ServiceSerializer

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def perform_destroy(self, instance):
        instance.delete()  # soft delete, see BaseModel.delete()
