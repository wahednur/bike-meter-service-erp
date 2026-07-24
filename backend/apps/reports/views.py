from django.shortcuts import get_object_or_404
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import IsAdmin
from apps.customers import services as customer_services
from apps.customers.models import Customer
from apps.customers.serializers import CustomerLedgerSerializer
from apps.reports import services as report_services
from apps.reports.exceptions import ReportError
from apps.reports.serializers import (
    AdminDashboardSummarySerializer,
    CashbookReportSerializer,
    DashboardSummarySerializer,
    DueReportSerializer,
    ExpenseReportSerializer,
    IncomeReportSerializer,
    PaymentDelayReportSerializer,
    ProfitLossReportSerializer,
    PurchaseReportSerializer,
    SalesReportSerializer,
    ServicePerformanceReportSerializer,
    StockReportSerializer,
    TopCustomersReportSerializer,
    WaivedReportSerializer,
)
from apps.reports.utils import get_date_range
from apps.suppliers import services as supplier_services
from apps.suppliers.models import Supplier
from apps.suppliers.serializers import SupplierLedgerSerializer


class BaseReportView(APIView):
    """Financial reports are management-level data - Admin only, unlike
    most other CRUD in this project which Staff can be granted access to."""

    permission_classes = [IsAdmin]


class IncomeReportView(BaseReportView):
    def get(self, request):
        from_date, to_date = get_date_range(request)
        period = request.query_params.get("period", "daily")
        try:
            data = report_services.income_report(period, from_date, to_date)
        except ReportError as exc:
            raise ValidationError(str(exc))
        return Response(IncomeReportSerializer(data).data)


class ExpenseReportView(BaseReportView):
    def get(self, request):
        from_date, to_date = get_date_range(request)
        period = request.query_params.get("period", "daily")
        try:
            data = report_services.expense_report(period, from_date, to_date)
        except ReportError as exc:
            raise ValidationError(str(exc))
        return Response(ExpenseReportSerializer(data).data)


class SalesReportView(BaseReportView):
    def get(self, request):
        from_date, to_date = get_date_range(request)
        data = report_services.sales_report(from_date, to_date)
        return Response(SalesReportSerializer(data).data)


class PurchaseReportView(BaseReportView):
    def get(self, request):
        from_date, to_date = get_date_range(request)
        data = report_services.purchase_report(from_date, to_date)
        return Response(PurchaseReportSerializer(data).data)


class ProfitLossReportView(BaseReportView):
    def get(self, request):
        from_date, to_date = get_date_range(request)
        data = report_services.profit_loss_report(from_date, to_date)
        return Response(ProfitLossReportSerializer(data).data)


class StockReportView(BaseReportView):
    def get(self, request):
        # from_date/to_date accepted for interface consistency but ignored -
        # stock quantity is a live snapshot, there's no historical stock log.
        data = report_services.stock_report()
        return Response(StockReportSerializer(data).data)


class DueReportView(BaseReportView):
    def get(self, request):
        from_date, to_date = get_date_range(request)
        data = report_services.due_report(from_date, to_date)
        return Response(DueReportSerializer(data).data)


class WaivedReportView(BaseReportView):
    """Rule 13: total waived_amount (force-close write-offs) across
    customers over a date range - separate from the discount totals
    already visible on individual invoices."""

    def get(self, request):
        from_date, to_date = get_date_range(request)
        data = report_services.waived_report(from_date, to_date)
        return Response(WaivedReportSerializer(data).data)


class TopCustomersReportView(BaseReportView):
    def get(self, request):
        from_date, to_date = get_date_range(request)
        sort_by = request.query_params.get("sort_by", "total_billed_amount")
        try:
            data = report_services.top_customers_report(from_date, to_date, sort_by=sort_by)
        except ReportError as exc:
            raise ValidationError(str(exc))
        return Response(TopCustomersReportSerializer(data).data)


class PaymentDelayReportView(BaseReportView):
    def get(self, request):
        from_date, to_date = get_date_range(request)
        data = report_services.payment_delay_report(from_date, to_date)
        return Response(PaymentDelayReportSerializer(data).data)


class ServicePerformanceReportView(BaseReportView):
    def get(self, request):
        from_date, to_date = get_date_range(request)
        data = report_services.service_performance_report(from_date, to_date)
        return Response(ServicePerformanceReportSerializer(data).data)


class CashbookReportView(BaseReportView):
    def get(self, request):
        from_date, to_date = get_date_range(request)
        data = report_services.cashbook_report(from_date, to_date)
        return Response(CashbookReportSerializer(data).data)


class CustomerLedgerReportView(BaseReportView):
    """Wraps apps.customers.services.build_customer_ledger (Phase 8)."""

    def get(self, request, customer_id):
        from_date, to_date = get_date_range(request)
        customer = get_object_or_404(Customer, pk=customer_id)
        data = customer_services.build_customer_ledger(customer, from_date, to_date)
        return Response(CustomerLedgerSerializer(data).data)


class SupplierLedgerReportView(BaseReportView):
    """Wraps apps.suppliers.services.build_supplier_ledger (Phase 8)."""

    def get(self, request, supplier_id):
        from_date, to_date = get_date_range(request)
        supplier = get_object_or_404(Supplier, pk=supplier_id)
        data = supplier_services.build_supplier_ledger(supplier, from_date, to_date)
        return Response(SupplierLedgerSerializer(data).data)


class DashboardSummaryView(BaseReportView):
    def get(self, request):
        from_date, to_date = get_date_range(request)
        data = report_services.dashboard_summary(from_date, to_date)
        return Response(DashboardSummarySerializer(data).data)


class AdminDashboardView(BaseReportView):
    """Today's income, pending dues, red-listed customers, low-stock
    products, and upcoming loan installments - all in one response.
    Distinct from DashboardSummaryView above (a date-range financial
    overview): this one is always "right now", not date-range filterable.
    Optional ?low_stock_threshold=&upcoming_days= override the defaults."""

    def get(self, request):
        low_stock_threshold = request.query_params.get("low_stock_threshold")
        upcoming_days = request.query_params.get("upcoming_days")
        data = report_services.admin_dashboard_summary(
            low_stock_threshold=int(low_stock_threshold) if low_stock_threshold else None,
            upcoming_days=int(upcoming_days) if upcoming_days else 7,
        )
        return Response(AdminDashboardSummarySerializer(data).data)
