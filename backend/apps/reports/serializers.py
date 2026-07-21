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


class AdminDashboardSummarySerializer(serializers.Serializer):
    date = serializers.DateField()
    today_income = serializers.DecimalField(max_digits=14, decimal_places=2)
    pending_dues = PendingDuesSerializer()
    red_listed_customers_count = serializers.IntegerField()
    low_stock_products = LowStockProductSerializer(many=True)
    low_stock_threshold = serializers.IntegerField()
    upcoming_loan_installments = UpcomingInstallmentSerializer(many=True)
    upcoming_days = serializers.IntegerField()
