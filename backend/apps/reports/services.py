"""Read-only reporting functions pulling from the Invoice, Product, Loan,
and Asset apps. Kept out of views, like every other business-logic layer in
this project, so each report is independently unit-testable.

Every function accepts optional from_date/to_date (datetime.date, already
parsed - see apps.reports.utils.get_date_range) and filters against the
most meaningful date field for that data (a payment's payment_date, a line
item's created_at, a purchase's purchase_date, etc.) - NOT always the
parent Invoice's created_date, since an invoice can stay open and gain new
line items across many separate visits (see apps.invoices rule a).
"""
from decimal import ROUND_HALF_UP, Decimal

from django.db.models import Count, Sum
from django.db.models.functions import TruncDate, TruncMonth, TruncWeek, TruncYear
from django.utils import timezone

from apps.reports.exceptions import ReportError

INCOME_TRUNC_FUNCS = {
    "daily": TruncDate,
    "weekly": TruncWeek,
    "monthly": TruncMonth,
    "yearly": TruncYear,
}

EXPENSE_TRUNC_FUNCS = {
    "daily": TruncDate,
    "weekly": TruncWeek,
    "monthly": TruncMonth,
}


def _profit_loss_status(value):
    if value > 0:
        return "PROFIT"
    if value < 0:
        return "LOSS"
    return "BREAK_EVEN"


# --- Income Report: Daily/Weekly/Monthly/Yearly/Total -----------------------

def income_report(period, from_date=None, to_date=None):
    """Income = money actually received from customers (InvoicePayment).
    Loan proceeds are deliberately excluded - that's borrowed capital, not
    earned revenue (see cashbook_report, which does include it)."""
    from apps.invoices.models import InvoicePayment

    payments = InvoicePayment.objects.all()
    if from_date:
        payments = payments.filter(payment_date__date__gte=from_date)
    if to_date:
        payments = payments.filter(payment_date__date__lte=to_date)

    total_income = payments.aggregate(total=Sum("amount"))["total"] or Decimal("0")

    if period == "total":
        return {"period": "total", "rows": [], "total_income": total_income}

    trunc_func = INCOME_TRUNC_FUNCS.get(period)
    if trunc_func is None:
        raise ReportError("period must be one of: daily, weekly, monthly, yearly, total.")

    rows = (
        payments.annotate(bucket=trunc_func("payment_date"))
        .values("bucket")
        .annotate(income=Sum("amount"))
        .order_by("bucket")
    )
    return {
        "period": period,
        "rows": [{"period_start": row["bucket"], "income": row["income"]} for row in rows],
        "total_income": total_income,
    }


# --- Expense Report: Daily/Weekly/Monthly ------------------------------------

def _expense_components(from_date=None, to_date=None):
    """The three sources that make up "expenses" per the spec: product
    restocks, asset purchases, device purchases - each pre-filtered to the
    date range, returned as querysets so callers can both aggregate totals
    and iterate individual transactions (purchase_report reuses this)."""
    from apps.assets.models import Asset
    from apps.meters.models import MileageCorrectionDevice
    from apps.products.models import ProductRestockEvent

    restocks = ProductRestockEvent.objects.all()
    if from_date:
        restocks = restocks.filter(restocked_at__date__gte=from_date)
    if to_date:
        restocks = restocks.filter(restocked_at__date__lte=to_date)

    assets = Asset.objects.all()
    if from_date:
        assets = assets.filter(purchase_date__gte=from_date)
    if to_date:
        assets = assets.filter(purchase_date__lte=to_date)

    devices = MileageCorrectionDevice.objects.all()
    if from_date:
        devices = devices.filter(purchase_date__gte=from_date)
    if to_date:
        devices = devices.filter(purchase_date__lte=to_date)

    return restocks, assets, devices


def expense_report(period, from_date=None, to_date=None):
    """Expenses = product buy costs (ProductRestockEvent) + asset purchases
    + mileage correction device purchases + manual operating expenses
    (apps.expenses.Expense - rent, electricity, transport, misc). Does NOT
    include AssetIncident repair/damage costs or loan installment
    repayments - those are real cash outflows too, but weren't part of the
    spec's expense definition; they do show up in cashbook_report, which is
    meant to be exhaustive."""
    from apps.expenses.models import Expense

    restocks, assets, devices = _expense_components(from_date, to_date)

    manual_expenses = Expense.objects.all()
    if from_date:
        manual_expenses = manual_expenses.filter(date__gte=from_date)
    if to_date:
        manual_expenses = manual_expenses.filter(date__lte=to_date)

    product_total = restocks.aggregate(total=Sum("total_cost"))["total"] or Decimal("0")
    asset_total = assets.aggregate(total=Sum("purchase_price"))["total"] or Decimal("0")
    device_total = devices.aggregate(total=Sum("purchase_price"))["total"] or Decimal("0")
    manual_total = manual_expenses.aggregate(total=Sum("amount"))["total"] or Decimal("0")
    total_expenses = product_total + asset_total + device_total + manual_total

    breakdown = {
        "product_restocks": product_total,
        "asset_purchases": asset_total,
        "device_purchases": device_total,
        "other_expenses": manual_total,
    }

    if period == "total":
        return {"period": "total", "rows": [], "total_expenses": total_expenses, "breakdown": breakdown}

    trunc_func = EXPENSE_TRUNC_FUNCS.get(period)
    if trunc_func is None:
        raise ReportError("period must be one of: daily, weekly, monthly, total.")

    buckets = {}

    def _accumulate(queryset, date_field, amount_field):
        rows = (
            queryset.annotate(bucket=trunc_func(date_field))
            .values("bucket")
            .annotate(total=Sum(amount_field))
        )
        for row in rows:
            buckets[row["bucket"]] = buckets.get(row["bucket"], Decimal("0")) + (row["total"] or Decimal("0"))

    _accumulate(restocks, "restocked_at", "total_cost")
    _accumulate(assets, "purchase_date", "purchase_price")
    _accumulate(devices, "purchase_date", "purchase_price")
    _accumulate(manual_expenses, "date", "amount")

    rows = [{"period_start": bucket, "expense": amount} for bucket, amount in sorted(buckets.items())]
    return {"period": period, "rows": rows, "total_expenses": total_expenses, "breakdown": breakdown}


# --- Sales Report / Purchase Report ------------------------------------------

def sales_report(from_date=None, to_date=None):
    """Every billed line item (service + product) across all invoices,
    filtered by when it was actually added to an invoice - not the parent
    invoice's creation date, since an invoice can stay open across visits."""
    from apps.invoices.models import InvoiceProductLine, InvoiceServiceLine

    service_lines = InvoiceServiceLine.objects.select_related("invoice", "invoice__customer", "service")
    product_lines = InvoiceProductLine.objects.select_related("invoice", "invoice__customer", "product")

    if from_date:
        service_lines = service_lines.filter(created_at__date__gte=from_date)
        product_lines = product_lines.filter(created_at__date__gte=from_date)
    if to_date:
        service_lines = service_lines.filter(created_at__date__lte=to_date)
        product_lines = product_lines.filter(created_at__date__lte=to_date)

    rows = []
    for line in service_lines:
        rows.append({
            "type": "service",
            "date": line.created_at.date(),
            "invoice_no": line.invoice.invoice_no,
            "customer_name": line.invoice.customer.name,
            "item_name": line.service.name,
            "quantity": 1,
            "unit_price": line.price_charged,
            "line_total": line.price_charged,
        })
    for line in product_lines:
        rows.append({
            "type": "product",
            "date": line.created_at.date(),
            "invoice_no": line.invoice.invoice_no,
            "customer_name": line.invoice.customer.name,
            "item_name": line.product.name,
            "quantity": line.quantity,
            "unit_price": line.price_charged,
            "line_total": line.line_total,
        })

    rows.sort(key=lambda r: r["date"])
    total_sales = sum((r["line_total"] for r in rows), Decimal("0"))
    return {"rows": rows, "total_sales": total_sales, "line_count": len(rows)}


def purchase_report(from_date=None, to_date=None):
    """Every purchase transaction (product restocks + asset purchases +
    device purchases) - the itemized version of expense_report's totals."""
    restocks, assets, devices = _expense_components(from_date, to_date)

    rows = []
    for r in restocks.select_related("product", "product__supplier"):
        rows.append({
            "type": "product_restock",
            "date": r.restocked_at.date(),
            "name": r.product.name,
            "supplier_name": r.product.supplier.name if r.product.supplier else None,
            "quantity": r.quantity,
            "amount": r.total_cost,
        })
    for a in assets.select_related("supplier"):
        rows.append({
            "type": "asset",
            "date": a.purchase_date,
            "name": a.name,
            "supplier_name": a.supplier.name if a.supplier else None,
            "quantity": 1,
            "amount": a.purchase_price,
        })
    for d in devices:
        rows.append({
            "type": "mileage_correction_device",
            "date": d.purchase_date,
            "name": d.name,
            "supplier_name": None,
            "quantity": 1,
            "amount": d.purchase_price,
        })

    rows.sort(key=lambda r: r["date"])
    total_purchases = sum((r["amount"] for r in rows), Decimal("0"))
    return {"rows": rows, "total_purchases": total_purchases, "transaction_count": len(rows)}


# --- Profit/Loss Report ------------------------------------------------------

def profit_loss_report(from_date=None, to_date=None):
    income_data = income_report("total", from_date, to_date)
    expense_data = expense_report("total", from_date, to_date)

    total_income = income_data["total_income"]
    total_expenses = expense_data["total_expenses"]
    profit_loss = total_income - total_expenses

    return {
        "total_income": total_income,
        "total_expenses": total_expenses,
        "expense_breakdown": expense_data["breakdown"],
        "profit_loss": profit_loss,
        "status": _profit_loss_status(profit_loss),
    }


# --- Stock Report (current snapshot, no date filtering) ----------------------

def stock_report():
    """Product-wise current quantity + value. This is a live snapshot -
    there's no historical stock-level log, so it doesn't accept a date
    range (unlike every other report here)."""
    from apps.products.models import Product

    rows = []
    total_stock_value = Decimal("0")
    total_potential_sale_value = Decimal("0")

    for p in Product.objects.select_related("supplier").order_by("name"):
        stock_value = p.buy_price * p.current_stock_quantity
        potential_sale_value = p.sale_price * p.current_stock_quantity
        total_stock_value += stock_value
        total_potential_sale_value += potential_sale_value
        rows.append({
            "id": p.id,
            "name": p.name,
            "sku": p.sku,
            "current_stock_quantity": p.current_stock_quantity,
            "buy_price": p.buy_price,
            "sale_price": p.sale_price,
            "stock_value": stock_value,
            "potential_sale_value": potential_sale_value,
        })

    return {
        "rows": rows,
        "total_products": len(rows),
        "total_stock_value": total_stock_value,
        "total_potential_sale_value": total_potential_sale_value,
    }


# --- Due Report ---------------------------------------------------------------

def due_report(from_date=None, to_date=None):
    """Every Unpaid/Partial Paid invoice and how much is still due."""
    from apps.invoices.models import Invoice

    invoices = Invoice.objects.filter(
        status__in=[Invoice.Status.UNPAID, Invoice.Status.PARTIAL]
    ).select_related("customer")
    if from_date:
        invoices = invoices.filter(created_date__gte=from_date)
    if to_date:
        invoices = invoices.filter(created_date__lte=to_date)

    rows = []
    total_due = Decimal("0")
    for inv in invoices.order_by("created_date"):
        due_amount = inv.outstanding_amount
        total_due += due_amount
        rows.append({
            "invoice_no": inv.invoice_no,
            "customer_name": inv.customer.name,
            "status": inv.status,
            "created_date": inv.created_date,
            "total_amount": inv.total_amount,
            "paid_amount": inv.paid_amount,
            "due_amount": due_amount,
        })

    return {"rows": rows, "invoice_count": len(rows), "total_due": total_due}


# --- Top Customers Report ------------------------------------------------------

TOP_CUSTOMERS_SORT_FIELDS = {
    "total_billed_amount": "total_billed_amount",
    "invoice_count": "invoice_count",
}


def top_customers_report(from_date=None, to_date=None, sort_by="total_billed_amount"):
    """Ranks customers by how much work they've brought in - every non-cancelled
    invoice's total_amount within the date range. A cancelled invoice never
    represents completed work, so it's excluded here the same way it's
    excluded from the red-list shortfall streak (see
    apps.invoices.services._consecutive_shortfall_streak)."""
    from apps.invoices.models import Invoice

    if sort_by not in TOP_CUSTOMERS_SORT_FIELDS:
        raise ReportError(f"sort_by must be one of: {', '.join(TOP_CUSTOMERS_SORT_FIELDS)}.")

    invoices = Invoice.objects.exclude(status=Invoice.Status.CANCELLED)
    if from_date:
        invoices = invoices.filter(created_date__gte=from_date)
    if to_date:
        invoices = invoices.filter(created_date__lte=to_date)

    grouped = (
        invoices.values("customer_id", "customer__name")
        .annotate(
            invoice_count=Count("id"),
            total_billed_amount=Sum("total_amount"),
            total_paid_amount=Sum("paid_amount"),
        )
        .order_by(f"-{TOP_CUSTOMERS_SORT_FIELDS[sort_by]}")
    )

    rows = [
        {
            "customer_id": row["customer_id"],
            "customer_name": row["customer__name"],
            "invoice_count": row["invoice_count"],
            "total_billed_amount": row["total_billed_amount"],
            "total_paid_amount": row["total_paid_amount"],
            "total_due_amount": row["total_billed_amount"] - row["total_paid_amount"],
        }
        for row in grouped
    ]
    return {"rows": rows, "customer_count": len(rows), "sort_by": sort_by}


# --- Payment Delay Report -------------------------------------------------------

def payment_delay_report(from_date=None, to_date=None):
    """For every customer with at least one Unpaid/Partial Paid invoice
    (within the date range, filtered on created_date like due_report), how
    long has that money been outstanding? Per invoice, the delay clock
    starts at the invoice's creation if it's never received a single
    payment (Unpaid), or at the most recent payment if it has (Partial
    Paid - the customer paid *something*, so the gap is measured from
    their last contact, not the invoice's birth). Customers are then
    ranked by their single longest-outstanding invoice, first."""
    from apps.invoices.models import Invoice

    invoices = Invoice.objects.filter(
        status__in=[Invoice.Status.UNPAID, Invoice.Status.PARTIAL]
    ).select_related("customer").prefetch_related("payments")
    if from_date:
        invoices = invoices.filter(created_date__gte=from_date)
    if to_date:
        invoices = invoices.filter(created_date__lte=to_date)

    today = timezone.now().date()
    by_customer = {}
    for inv in invoices:
        if inv.status == Invoice.Status.PARTIAL:
            last_payment = max((p.payment_date for p in inv.payments.all()), default=None)
            gap_start = last_payment.date() if last_payment else inv.created_date
        else:
            gap_start = inv.created_date
        days_delayed = (today - gap_start).days

        bucket = by_customer.setdefault(inv.customer_id, {
            "customer_id": inv.customer_id,
            "customer_name": inv.customer.name,
            "invoice_nos": [],
            "days_delayed": 0,
            "amount_due": Decimal("0"),
        })
        bucket["invoice_nos"].append(inv.invoice_no)
        bucket["days_delayed"] = max(bucket["days_delayed"], days_delayed)
        bucket["amount_due"] += inv.outstanding_amount

    rows = sorted(by_customer.values(), key=lambda r: r["days_delayed"], reverse=True)
    return {"rows": rows, "customer_count": len(rows)}


# --- Service Performance Report -------------------------------------------------

def service_performance_report(from_date=None, to_date=None):
    """Per-service equivalent of compute_meter_service_stats /
    compute_mileage_correction_device_stats (apps.meters.services), but
    date-range filterable and covering every service rather than one
    meter/device at a time. Filtered on the line item's own created_at,
    not the parent invoice's created_date - same reasoning as
    sales_report (an invoice can stay open and gain lines across visits)."""
    from apps.invoices.models import InvoiceServiceLine

    lines = InvoiceServiceLine.objects.select_related("service")
    if from_date:
        lines = lines.filter(created_at__date__gte=from_date)
    if to_date:
        lines = lines.filter(created_at__date__lte=to_date)

    grouped = (
        lines.values("service_id", "service__name")
        .annotate(times_performed=Count("id"), total_revenue=Sum("price_charged"))
        .order_by("-total_revenue")
    )

    rows = [
        {
            "service_id": row["service_id"],
            "service_name": row["service__name"],
            "times_performed": row["times_performed"],
            "total_revenue": row["total_revenue"],
            "average_price": (
                (row["total_revenue"] / row["times_performed"]).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
                if row["times_performed"] else Decimal("0")
            ),
        }
        for row in grouped
    ]
    return {"rows": rows, "service_count": len(rows)}


# --- Cashbook: every money movement, chronologically --------------------------

def cashbook_report(from_date=None, to_date=None):
    """Unlike income/expense (operating performance), this is literal cash
    flow: it also includes loan disbursements/repayments (financing
    activity) and asset incident repair costs, which those two reports
    deliberately exclude. running_balance is relative to the start of the
    filtered window (or the true all-time balance if no from_date is set)."""
    from apps.assets.models import Asset, AssetIncident
    from apps.invoices.models import InvoicePayment
    from apps.loans.models import Loan, LoanInstallmentPayment
    from apps.meters.models import MileageCorrectionDevice
    from apps.products.models import ProductRestockEvent

    entries = []

    payments = InvoicePayment.objects.select_related("invoice", "invoice__customer")
    if from_date:
        payments = payments.filter(payment_date__date__gte=from_date)
    if to_date:
        payments = payments.filter(payment_date__date__lte=to_date)
    for p in payments:
        entries.append({
            "date": p.payment_date.date(), "direction": "IN", "category": "customer_payment",
            "description": f"Payment from {p.invoice.customer.name} ({p.invoice.invoice_no})",
            "amount": p.amount,
        })

    loans = Loan.objects.all()
    if from_date:
        loans = loans.filter(start_date__gte=from_date)
    if to_date:
        loans = loans.filter(start_date__lte=to_date)
    for loan in loans:
        entries.append({
            "date": loan.start_date, "direction": "IN", "category": "loan_disbursement",
            "description": f"Loan received from {loan.lender_name}", "amount": loan.loan_amount,
        })

    restocks = ProductRestockEvent.objects.select_related("product")
    if from_date:
        restocks = restocks.filter(restocked_at__date__gte=from_date)
    if to_date:
        restocks = restocks.filter(restocked_at__date__lte=to_date)
    for r in restocks:
        entries.append({
            "date": r.restocked_at.date(), "direction": "OUT", "category": "product_restock",
            "description": f"Restocked {r.quantity} x {r.product.name}", "amount": r.total_cost,
        })

    assets = Asset.objects.all()
    if from_date:
        assets = assets.filter(purchase_date__gte=from_date)
    if to_date:
        assets = assets.filter(purchase_date__lte=to_date)
    for a in assets:
        entries.append({
            "date": a.purchase_date, "direction": "OUT", "category": "asset_purchase",
            "description": f"Purchased asset: {a.name}", "amount": a.purchase_price,
        })

    incidents = AssetIncident.objects.select_related("asset").filter(cost__gt=0)
    if from_date:
        incidents = incidents.filter(date__gte=from_date)
    if to_date:
        incidents = incidents.filter(date__lte=to_date)
    for i in incidents:
        entries.append({
            "date": i.date, "direction": "OUT", "category": "asset_incident",
            "description": f"{i.get_type_display()} - {i.asset.name}", "amount": i.cost,
        })

    devices = MileageCorrectionDevice.objects.all()
    if from_date:
        devices = devices.filter(purchase_date__gte=from_date)
    if to_date:
        devices = devices.filter(purchase_date__lte=to_date)
    for d in devices:
        entries.append({
            "date": d.purchase_date, "direction": "OUT", "category": "device_purchase",
            "description": f"Purchased device: {d.name}", "amount": d.purchase_price,
        })

    installments = LoanInstallmentPayment.objects.select_related("loan")
    if from_date:
        installments = installments.filter(payment_date__gte=from_date)
    if to_date:
        installments = installments.filter(payment_date__lte=to_date)
    for ip in installments:
        entries.append({
            "date": ip.payment_date, "direction": "OUT", "category": "loan_installment",
            "description": f"Installment #{ip.installment_number} to {ip.loan.lender_name}",
            "amount": ip.amount_paid,
        })

    entries.sort(key=lambda e: e["date"])

    running_balance = Decimal("0")
    total_in = Decimal("0")
    total_out = Decimal("0")
    for e in entries:
        if e["direction"] == "IN":
            running_balance += e["amount"]
            total_in += e["amount"]
        else:
            running_balance -= e["amount"]
            total_out += e["amount"]
        e["running_balance"] = running_balance

    return {"entries": entries, "total_in": total_in, "total_out": total_out, "net": total_in - total_out}


# --- Dashboard summary ---------------------------------------------------------

def dashboard_summary(from_date=None, to_date=None):
    from apps.loans import services as loan_services
    from apps.loans.models import Loan

    pl_data = profit_loss_report(from_date, to_date)
    sales_data = sales_report(from_date, to_date)
    purchase_data = purchase_report(from_date, to_date)
    stock_data = stock_report()
    due_data = due_report(from_date, to_date)
    cashbook_data = cashbook_report(from_date, to_date)

    active_loan_count = 0
    total_outstanding = Decimal("0")
    for loan in Loan.objects.all():
        stats = loan_services.compute_loan_stats(loan)
        if stats["amount_remaining"] > 0:
            active_loan_count += 1
            total_outstanding += stats["amount_remaining"]

    return {
        "from_date": from_date,
        "to_date": to_date,
        "income": {"total": pl_data["total_income"]},
        "expenses": {"total": pl_data["total_expenses"], "breakdown": pl_data["expense_breakdown"]},
        "profit_loss": pl_data,
        "sales": {"total_amount": sales_data["total_sales"], "line_count": sales_data["line_count"]},
        "purchases": {
            "total_amount": purchase_data["total_purchases"],
            "transaction_count": purchase_data["transaction_count"],
        },
        "stock": {"total_products": stock_data["total_products"], "total_stock_value": stock_data["total_stock_value"]},
        "due": {"invoice_count": due_data["invoice_count"], "total_due": due_data["total_due"]},
        "cashbook": {"total_in": cashbook_data["total_in"], "total_out": cashbook_data["total_out"], "net": cashbook_data["net"]},
        "loans": {"active_loan_count": active_loan_count, "total_outstanding": total_outstanding},
    }


# --- Admin dashboard: today's operational snapshot ------------------------------

def admin_dashboard_summary(low_stock_threshold=None, upcoming_days=7):
    """Distinct from dashboard_summary() above (which is a date-range
    financial P&L-style overview): this is a fixed, always-"right now"
    operational snapshot - today's income, pending dues, red-listed
    customers, low stock, and installments coming due soon. Not
    date-range-filterable, since "today" and "upcoming" are the point."""
    import datetime

    from apps.customers.models import Customer
    from apps.invoices.models import Invoice
    from apps.loans import services as loan_services
    from apps.products import services as product_services

    if low_stock_threshold is None:
        low_stock_threshold = product_services.DEFAULT_LOW_STOCK_THRESHOLD

    today = timezone.now().date()

    today_income_data = income_report("total", from_date=today, to_date=today)
    due_data = due_report()

    # Invoice.created_date is a plain DateField(auto_now_add=True), which
    # Django populates via datetime.date.today() (OS-local calendar day) -
    # NOT timezone.now().date() (UTC calendar day, what `today` above is).
    # The two only diverge for a few hours a day, but that's exactly when a
    # naive comparison would silently drop today's invoices, so match the
    # field's own semantics here rather than reusing `today`.
    invoice_today = datetime.date.today()
    today_invoices = Invoice.objects.filter(created_date=invoice_today)
    today_invoice_count = today_invoices.count()
    today_total_amount = today_invoices.aggregate(total=Sum("total_amount"))["total"] or Decimal("0")
    total_income_all_time = Invoice.objects.aggregate(total=Sum("paid_amount"))["total"] or Decimal("0")

    red_listed_customers_count = Customer.objects.filter(is_red_listed=True).count()

    low_stock_rows = [
        {"id": p.id, "name": p.name, "sku": p.sku, "current_stock_quantity": p.current_stock_quantity}
        for p in product_services.low_stock_products(threshold=low_stock_threshold)
    ]

    upcoming = loan_services.upcoming_installments(within_days=upcoming_days, reference_date=today)

    return {
        "date": today,
        "today_income": today_income_data["total_income"],
        "today_invoice_count": today_invoice_count,
        "today_total_amount": today_total_amount,
        "total_income_all_time": total_income_all_time,
        "pending_dues": {"invoice_count": due_data["invoice_count"], "total_due": due_data["total_due"]},
        "red_listed_customers_count": red_listed_customers_count,
        "low_stock_products": low_stock_rows,
        "low_stock_threshold": low_stock_threshold,
        "upcoming_loan_installments": upcoming,
        "upcoming_days": upcoming_days,
    }
