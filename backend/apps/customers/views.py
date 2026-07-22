import csv

from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.accounts.permissions import IsAdminOrHasModelPermission
from apps.customers import services as customer_services
from apps.customers.models import Customer
from apps.customers.serializers import (
    CustomerCsvImportResponseSerializer,
    CustomerCsvImportSerializer,
    CustomerCsvPreviewResponseSerializer,
    CustomerCsvUploadSerializer,
    CustomerLedgerSerializer,
    CustomerSerializer,
)


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

    @action(detail=False, methods=["post"], url_path="import/preview")
    def import_preview(self, request):
        """Parses the header row and first 5 data rows of an uploaded CSV so
        the caller can build a column mapping. Creates nothing."""
        upload = CustomerCsvUploadSerializer(data=request.data)
        upload.is_valid(raise_exception=True)

        try:
            preview_data = customer_services.preview_customer_csv(upload.validated_data["file"])
        except (csv.Error, UnicodeDecodeError):
            return Response({"detail": "Could not parse file as CSV."}, status=status.HTTP_400_BAD_REQUEST)

        return Response(CustomerCsvPreviewResponseSerializer(preview_data).data)

    @action(detail=False, methods=["post"], url_path="import")
    def import_customers(self, request):
        """Creates Customers from an uploaded CSV using a column_mapping
        (Customer field -> CSV header). Duplicate phone numbers are skipped
        and rows missing name/phone are marked failed - neither aborts the
        rest of the import."""
        upload = CustomerCsvImportSerializer(data=request.data)
        upload.is_valid(raise_exception=True)

        try:
            result = customer_services.import_customers_from_csv(
                upload.validated_data["file"],
                upload.validated_data["column_mapping"],
                request.user,
            )
        except (csv.Error, UnicodeDecodeError):
            return Response({"detail": "Could not parse file as CSV."}, status=status.HTTP_400_BAD_REQUEST)

        return Response(CustomerCsvImportResponseSerializer(result).data)
