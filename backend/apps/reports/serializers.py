from rest_framework import serializers


class IncomeReportRowSerializer(serializers.Serializer):
    period_start = serializers.DateField()
    income = serializers.DecimalField(max_digits=14, decimal_places=2)


class IncomeReportSerializer(serializers.Serializer):
    period = serializers.CharField()
    rows = IncomeReportRowSerializer(many=True)
    total_income = serializers.DecimalField(max_digits=14, decimal_places=2)


class ExpenseBreakdownSerializer(serializers.Serializer):
    product_restocks = serializers.DecimalField(max_digits=14, decimal_places=2)
    asset_purchases = serializers.DecimalField(max_digits=14, decimal_places=2)
    device_purchases = serializers.DecimalField(max_digits=14, decimal_places=2)
    other_expenses = serializers.DecimalField(max_digits=14, decimal_places=2)


class ExpenseReportRowSerializer(serializers.Serializer):
    period_start = serializers.DateField()
    expense = serializers.DecimalField(max_digits=14, decimal_places=2)


class ExpenseReportSerializer(serializers.Serializer):
    period = serializers.CharField()
    rows = ExpenseReportRowSerializer(many=True)
    total_expenses = serializers.DecimalField(max_digits=14, decimal_places=2)
    breakdown = ExpenseBreakdownSerializer()


class SalesReportRowSerializer(serializers.Serializer):
    type = serializers.CharField()
    date = serializers.DateField()
    invoice_no = serializers.CharField()
    customer_name = serializers.CharField()
    item_name = serializers.CharField()
    quantity = serializers.IntegerField()
    unit_price = serializers.DecimalField(max_digits=10, decimal_places=2)
    line_total = serializers.DecimalField(max_digits=12, decimal_places=2)


class SalesReportSerializer(serializers.Serializer):
    rows = SalesReportRowSerializer(many=True)
    total_sales = serializers.DecimalField(max_digits=14, decimal_places=2)
    line_count = serializers.IntegerField()


class PurchaseReportRowSerializer(serializers.Serializer):
    type = serializers.CharField()
    date = serializers.DateField()
    name = serializers.CharField()
    supplier_name = serializers.CharField(allow_null=True)
    quantity = serializers.IntegerField()
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)


class PurchaseReportSerializer(serializers.Serializer):
    rows = PurchaseReportRowSerializer(many=True)
    total_purchases = serializers.DecimalField(max_digits=14, decimal_places=2)
    transaction_count = serializers.IntegerField()


class ProfitLossReportSerializer(serializers.Serializer):
    total_income = serializers.DecimalField(max_digits=14, decimal_places=2)
    total_expenses = serializers.DecimalField(max_digits=14, decimal_places=2)
    expense_breakdown = ExpenseBreakdownSerializer()
    profit_loss = serializers.DecimalField(max_digits=14, decimal_places=2)
    status = serializers.CharField()


class StockReportRowSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    sku = serializers.CharField()
    current_stock_quantity = serializers.IntegerField()
    buy_price = serializers.DecimalField(max_digits=10, decimal_places=2)
    sale_price = serializers.DecimalField(max_digits=10, decimal_places=2)
    stock_value = serializers.DecimalField(max_digits=12, decimal_places=2)
    potential_sale_value = serializers.DecimalField(max_digits=12, decimal_places=2)


class StockReportSerializer(serializers.Serializer):
    rows = StockReportRowSerializer(many=True)
    total_products = serializers.IntegerField()
    total_stock_value = serializers.DecimalField(max_digits=14, decimal_places=2)
    total_potential_sale_value = serializers.DecimalField(max_digits=14, decimal_places=2)


class DueReportRowSerializer(serializers.Serializer):
    invoice_no = serializers.CharField()
    customer_name = serializers.CharField()
    status = serializers.CharField()
    created_date = serializers.DateField()
    total_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    paid_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    due_amount = serializers.DecimalField(max_digits=12, decimal_places=2)


class DueReportSerializer(serializers.Serializer):
    rows = DueReportRowSerializer(many=True)
    invoice_count = serializers.IntegerField()
    total_due = serializers.DecimalField(max_digits=14, decimal_places=2)


class WaivedRowSerializer(serializers.Serializer):
    customer_id = serializers.IntegerField()
    customer_name = serializers.CharField()
    invoice_count = serializers.IntegerField()
    total_waived_amount = serializers.DecimalField(max_digits=14, decimal_places=2)


class WaivedReportSerializer(serializers.Serializer):
    rows = WaivedRowSerializer(many=True)
    customer_count = serializers.IntegerField()
    total_waived_amount = serializers.DecimalField(max_digits=14, decimal_places=2)


class TopCustomerRowSerializer(serializers.Serializer):
    customer_id = serializers.IntegerField()
    customer_name = serializers.CharField()
    invoice_count = serializers.IntegerField()
    total_billed_amount = serializers.DecimalField(max_digits=14, decimal_places=2)
    total_paid_amount = serializers.DecimalField(max_digits=14, decimal_places=2)
    total_due_amount = serializers.DecimalField(max_digits=14, decimal_places=2)


class TopCustomersReportSerializer(serializers.Serializer):
    rows = TopCustomerRowSerializer(many=True)
    customer_count = serializers.IntegerField()
    sort_by = serializers.CharField()


class PaymentDelayRowSerializer(serializers.Serializer):
    customer_id = serializers.IntegerField()
    customer_name = serializers.CharField()
    invoice_nos = serializers.ListField(child=serializers.CharField())
    days_delayed = serializers.IntegerField()
    amount_due = serializers.DecimalField(max_digits=14, decimal_places=2)


class PaymentDelayReportSerializer(serializers.Serializer):
    rows = PaymentDelayRowSerializer(many=True)
    customer_count = serializers.IntegerField()


class ServicePerformanceRowSerializer(serializers.Serializer):
    service_id = serializers.IntegerField()
    service_name = serializers.CharField()
    times_performed = serializers.IntegerField()
    total_revenue = serializers.DecimalField(max_digits=14, decimal_places=2)
    average_price = serializers.DecimalField(max_digits=10, decimal_places=2)


class ServicePerformanceReportSerializer(serializers.Serializer):
    rows = ServicePerformanceRowSerializer(many=True)
    service_count = serializers.IntegerField()


class CashbookEntrySerializer(serializers.Serializer):
    date = serializers.DateField()
    direction = serializers.CharField()
    category = serializers.CharField()
    description = serializers.CharField()
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    running_balance = serializers.DecimalField(max_digits=14, decimal_places=2)


class CashbookReportSerializer(serializers.Serializer):
    entries = CashbookEntrySerializer(many=True)
    total_in = serializers.DecimalField(max_digits=14, decimal_places=2)
    total_out = serializers.DecimalField(max_digits=14, decimal_places=2)
    net = serializers.DecimalField(max_digits=14, decimal_places=2)


class DashboardSummarySerializer(serializers.Serializer):
    from_date = serializers.DateField(allow_null=True)
    to_date = serializers.DateField(allow_null=True)
    income = serializers.DictField()
    expenses = serializers.DictField()
    profit_loss = ProfitLossReportSerializer()
    sales = serializers.DictField()
    purchases = serializers.DictField()
    stock = serializers.DictField()
    due = serializers.DictField()
    cashbook = serializers.DictField()
    loans = serializers.DictField()


class PendingDuesSerializer(serializers.Serializer):
    invoice_count = serializers.IntegerField()
    total_due = serializers.DecimalField(max_digits=14, decimal_places=2)


class LowStockProductSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    sku = serializers.CharField()
    current_stock_quantity = serializers.IntegerField()


class UpcomingInstallmentSerializer(serializers.Serializer):
    loan_id = serializers.IntegerField()
    lender_name = serializers.CharField()
    installment_number = serializers.IntegerField()
    due_date = serializers.DateField()
    installment_amount = serializers.DecimalField(max_digits=10, decimal_places=2)
    is_overdue = serializers.BooleanField()


class TopExpenseCategorySerializer(serializers.Serializer):
    category = serializers.CharField()
    category_display = serializers.CharField()
    amount = serializers.DecimalField(max_digits=14, decimal_places=2)


class AdminDashboardSummarySerializer(serializers.Serializer):
    date = serializers.DateField()
    today_income = serializers.DecimalField(max_digits=14, decimal_places=2)
    today_invoice_count = serializers.IntegerField()
    today_total_amount = serializers.DecimalField(max_digits=14, decimal_places=2)
    total_income_all_time = serializers.DecimalField(max_digits=14, decimal_places=2)
    pending_dues = PendingDuesSerializer()
    red_listed_customers_count = serializers.IntegerField()
    low_stock_products = LowStockProductSerializer(many=True)
    low_stock_threshold = serializers.IntegerField()
    upcoming_loan_installments = UpcomingInstallmentSerializer(many=True)
    upcoming_days = serializers.IntegerField()
    today_expense = serializers.DecimalField(max_digits=14, decimal_places=2)
    this_week_expense = serializers.DecimalField(max_digits=14, decimal_places=2)
    this_month_expense = serializers.DecimalField(max_digits=14, decimal_places=2)
    total_expense_all_time = serializers.DecimalField(max_digits=14, decimal_places=2)
    net_profit_today = serializers.DecimalField(max_digits=14, decimal_places=2)
    top_expense_category_this_month = TopExpenseCategorySerializer(allow_null=True)
    this_week_income = serializers.DecimalField(max_digits=14, decimal_places=2)
    this_month_income = serializers.DecimalField(max_digits=14, decimal_places=2)
    predicted_month_income = serializers.DecimalField(max_digits=14, decimal_places=2)
    income_prediction_gap = serializers.DecimalField(max_digits=14, decimal_places=2)
    is_early_month_estimate = serializers.BooleanField()
