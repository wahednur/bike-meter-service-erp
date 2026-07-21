from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.accounts.permissions import IsAdminOrHasModelPermission
from apps.customers import services as customer_services
from apps.customers.models import Customer
from apps.customers.serializers import CustomerLedgerSerializer, CustomerSerializer


class CustomerViewSet(viewsets.ModelViewSet):
    """Full CRUD, restricted to Admin or Staff explicitly granted
    add/change/delete/view_customer permission."""

    queryset = Customer.objects.all().order_by("name")
    serializer_class = CustomerSerializer
    permission_classes = [IsAdminOrHasModelPermission]

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def perform_destroy(self, instance):
        instance.delete()  # soft delete, see BaseModel.delete()

    @action(detail=True, methods=["get"])
    def ledger(self, request, pk=None):
        """All of this customer's invoices, plus total billed/paid/due.
        Optional ?from_date=&to_date= (YYYY-MM-DD) to scope to a window."""
        customer = self.get_object()
        from apps.reports.utils import get_date_range

        from_date, to_date = get_date_range(request)
        ledger_data = customer_services.build_customer_ledger(customer, from_date, to_date)
        return Response(CustomerLedgerSerializer(ledger_data).data)
