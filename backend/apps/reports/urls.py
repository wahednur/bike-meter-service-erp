from django.urls import path

from apps.reports.views import (
    AdminDashboardView,
    CashbookReportView,
    CustomerLedgerReportView,
    DashboardSummaryView,
    DueReportView,
    ExpenseReportView,
    IncomeReportView,
    ProfitLossReportView,
    PurchaseReportView,
    SalesReportView,
    StockReportView,
    SupplierLedgerReportView,
)

urlpatterns = [
    path("reports/income/", IncomeReportView.as_view(), name="report-income"),
    path("reports/expenses/", ExpenseReportView.as_view(), name="report-expenses"),
    path("reports/sales/", SalesReportView.as_view(), name="report-sales"),
    path("reports/purchases/", PurchaseReportView.as_view(), name="report-purchases"),
    path("reports/profit-loss/", ProfitLossReportView.as_view(), name="report-profit-loss"),
    path("reports/stock/", StockReportView.as_view(), name="report-stock"),
    path("reports/due/", DueReportView.as_view(), name="report-due"),
    path("reports/cashbook/", CashbookReportView.as_view(), name="report-cashbook"),
    path("reports/customer-ledger/<int:customer_id>/", CustomerLedgerReportView.as_view(), name="report-customer-ledger"),
    path("reports/supplier-ledger/<int:supplier_id>/", SupplierLedgerReportView.as_view(), name="report-supplier-ledger"),
    path("reports/summary/", DashboardSummaryView.as_view(), name="report-summary"),
    path("reports/admin-dashboard/", AdminDashboardView.as_view(), name="report-admin-dashboard"),
]
