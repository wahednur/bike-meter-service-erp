from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.accounts.permissions import IsAdminOrHasModelPermission
from apps.suppliers import services as supplier_services
from apps.suppliers.models import Supplier
from apps.suppliers.serializers import SupplierLedgerSerializer, SupplierSerializer


class SupplierViewSet(viewsets.ModelViewSet):
    """Full CRUD, restricted to Admin or Staff explicitly granted
    add/change/delete/view_supplier permission."""

    queryset = Supplier.objects.all().order_by("name")
    serializer_class = SupplierSerializer
    permission_classes = [IsAdminOrHasModelPermission]

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def perform_destroy(self, instance):
        instance.delete()  # soft delete, see BaseModel.delete()

    @action(detail=True, methods=["get"])
    def ledger(self, request, pk=None):
        """All products bought from this supplier, current stock value,
        and payment status (not yet tracked - see build_supplier_ledger).
        Optional ?from_date=&to_date= (YYYY-MM-DD) scopes purchases_in_range."""
        supplier = self.get_object()
        from apps.reports.utils import get_date_range

        from_date, to_date = get_date_range(request)
        ledger_data = supplier_services.build_supplier_ledger(supplier, from_date, to_date)
        return Response(SupplierLedgerSerializer(ledger_data).data)
