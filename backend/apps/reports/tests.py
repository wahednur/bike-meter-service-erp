import calendar
from datetime import date, datetime, timedelta
from decimal import ROUND_HALF_UP, Decimal

from django.test import SimpleTestCase, TestCase
from django.utils import timezone

from apps.assets.models import Asset, AssetIncident
from apps.customers.models import Customer
from apps.expenses.models import Expense
from apps.invoices import services as invoice_services
from apps.invoices.models import Invoice
from apps.loans import services as loan_services
from apps.loans.models import Loan
from apps.meters.models import MileageCorrectionDevice, Meter
from apps.products import services as product_services
from apps.products.models import Product, ProductRestockEvent
from apps.reports import services as report_services
from apps.reports.exceptions import ReportError
from apps.services.models import Service, ServiceCategory
from apps.suppliers.models import Supplier


def _aware(y, m, d):
    return timezone.make_aware(datetime(y, m, d, 12, 0))


class ReportServiceTests(TestCase):
    def setUp(self):
        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000010")
        self.supplier = Supplier.objects.create(name="ABC Traders", phone="01810000010")

        category = ServiceCategory.objects.create(name=ServiceCategory.Name.METER_REPAIR)
        self.service = Service.objects.create(category=category, name="LED Repair", service_price="300.00")

        self.product = Product.objects.create(
            name="Meter Casing", sku="CASING-RPT-1", supplier=self.supplier,
            sale_price="150.00", current_stock_quantity=0,
        )

        # Pin the pre-seeded mileage correction devices (meters data
        # migration) to a fixed, safely-out-of-range purchase_date so
        # date-filtered tests below don't depend on today's wall-clock date.
        MileageCorrectionDevice.objects.update(purchase_date=date(2020, 1, 1))

    def _restock_on(self, product, quantity, unit_price, when):
        """restock_product logs restocked_at via auto_now_add, so to test
        date-range filtering we create it then push the timestamp back with
        a bare queryset .update() (bypasses per-instance auto_now_add)."""
        product_services.restock_product(product, quantity=quantity, unit_price=Decimal(unit_price))
        event = product.restock_events.latest("restocked_at")
        ProductRestockEvent.objects.filter(pk=event.pk).update(restocked_at=timezone.make_aware(datetime.combine(when, datetime.min.time())))
        return event

    def _pay_invoice(self, invoice, amount, when):
        return invoice_services.add_payment(invoice, amount=Decimal(amount), payment_method="CASH", payment_date=_aware(*when))

    # --- income report -----------------------------------------------------

    def test_income_report_buckets_by_day_and_totals(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("1000.00"))

        self._pay_invoice(invoice, "300.00", (2026, 6, 1))
        self._pay_invoice(invoice, "200.00", (2026, 6, 1))
        self._pay_invoice(invoice, "150.00", (2026, 6, 2))

        data = report_services.income_report("daily", from_date=date(2026, 6, 1), to_date=date(2026, 6, 2))
        self.assertEqual(data["total_income"], Decimal("650.00"))
        self.assertEqual(len(data["rows"]), 2)
        self.assertEqual(data["rows"][0]["income"], Decimal("500.00"))
        self.assertEqual(data["rows"][1]["income"], Decimal("150.00"))

    def test_income_report_total_period_has_no_rows(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("300.00"))
        self._pay_invoice(invoice, "300.00", (2026, 6, 1))

        data = report_services.income_report("total")
        self.assertEqual(data["rows"], [])
        self.assertEqual(data["total_income"], Decimal("300.00"))

    def test_income_report_rejects_unknown_period(self):
        with self.assertRaises(ReportError):
            report_services.income_report("fortnightly")

    def test_income_report_excludes_payments_outside_range(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("1000.00"))
        self._pay_invoice(invoice, "400.00", (2026, 5, 1))
        self._pay_invoice(invoice, "100.00", (2026, 6, 15))

        data = report_services.income_report("total", from_date=date(2026, 6, 1), to_date=date(2026, 6, 30))
        self.assertEqual(data["total_income"], Decimal("100.00"))

    # --- expense report (combines 3 sources) --------------------------------

    def test_expense_report_combines_product_asset_and_device_purchases(self):
        self._restock_on(self.product, quantity=10, unit_price="80.00", when=date(2026, 6, 1))

        Asset.objects.create(
            name="Soldering Iron", purchase_price=Decimal("2500.00"), purchase_date=date(2026, 6, 1),
        )
        vvdi = MileageCorrectionDevice.objects.get(name="VVDI Prog")
        MileageCorrectionDevice.objects.filter(pk=vvdi.pk).update(purchase_date=date(2026, 6, 2))

        data = report_services.expense_report("total", from_date=date(2026, 6, 1), to_date=date(2026, 6, 30))
        self.assertEqual(data["breakdown"]["product_restocks"], Decimal("800.00"))
        self.assertEqual(data["breakdown"]["asset_purchases"], Decimal("2500.00"))
        self.assertEqual(data["breakdown"]["device_purchases"], Decimal("70000.00"))
        self.assertEqual(data["total_expenses"], Decimal("73300.00"))

    def test_expense_report_daily_buckets_sum_across_sources(self):
        self._restock_on(self.product, quantity=5, unit_price="100.00", when=date(2026, 6, 1))
        Asset.objects.create(name="Multimeter", purchase_price=Decimal("500.00"), purchase_date=date(2026, 6, 1))

        data = report_services.expense_report("daily", from_date=date(2026, 6, 1), to_date=date(2026, 6, 1))
        self.assertEqual(len(data["rows"]), 1)
        self.assertEqual(data["rows"][0]["expense"], Decimal("1000.00"))  # 500 restock + 500 asset

    def test_expense_report_rejects_yearly_period(self):
        with self.assertRaises(ReportError):
            report_services.expense_report("yearly")

    # --- profit/loss ---------------------------------------------------------

    def test_profit_loss_report_income_minus_expenses(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("5000.00"))
        self._pay_invoice(invoice, "5000.00", (2026, 6, 1))

        Asset.objects.create(name="Tool Kit", purchase_price=Decimal("1200.00"), purchase_date=date(2026, 6, 1))

        data = report_services.profit_loss_report(from_date=date(2026, 6, 1), to_date=date(2026, 6, 30))
        self.assertEqual(data["total_income"], Decimal("5000.00"))
        self.assertEqual(data["total_expenses"], Decimal("1200.00"))
        self.assertEqual(data["profit_loss"], Decimal("3800.00"))
        self.assertEqual(data["status"], "PROFIT")

    # --- stock report ----------------------------------------------------------

    def test_stock_report_computes_stock_and_potential_sale_value(self):
        product_services.restock_product(self.product, quantity=10, unit_price=Decimal("80.00"))

        data = report_services.stock_report()
        row = next(r for r in data["rows"] if r["sku"] == "CASING-RPT-1")
        self.assertEqual(row["current_stock_quantity"], 10)
        self.assertEqual(row["stock_value"], Decimal("800.00"))  # 80 buy_price x 10
        self.assertEqual(row["potential_sale_value"], Decimal("1500.00"))  # 150 sale_price x 10

    # --- due report ------------------------------------------------------------

    def test_due_report_only_lists_unpaid_and_partial_invoices(self):
        paid_invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(paid_invoice, self.service, price_charged=Decimal("300.00"))
        invoice_services.add_payment(paid_invoice, amount=Decimal("300.00"), payment_method="CASH")

        other_customer = Customer.objects.create(name="Nasrin Akter", phone="01710000011")
        partial_invoice, _ = invoice_services.get_or_create_open_invoice(other_customer)
        invoice_services.add_service_line(partial_invoice, self.service, price_charged=Decimal("1000.00"))
        invoice_services.add_payment(partial_invoice, amount=Decimal("400.00"), payment_method="CASH")

        data = report_services.due_report()
        invoice_nos = [row["invoice_no"] for row in data["rows"]]
        self.assertNotIn(paid_invoice.invoice_no, invoice_nos)
        self.assertIn(partial_invoice.invoice_no, invoice_nos)
        self.assertEqual(data["total_due"], Decimal("600.00"))

    # --- cashbook ----------------------------------------------------------------

    def test_cashbook_running_balance_and_totals(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("1000.00"))
        self._pay_invoice(invoice, "1000.00", (2026, 6, 2))

        Loan.objects.create(
            lender_name="City Bank", lender_type=Loan.LenderType.BANK,
            loan_amount=Decimal("50000.00"), total_installments=10,
            installment_amount=Decimal("5000.00"), installment_frequency=Loan.InstallmentFrequency.MONTHLY,
            start_date=date(2026, 6, 1),
        )
        Asset.objects.create(name="Drill", purchase_price=Decimal("300.00"), purchase_date=date(2026, 6, 3))

        data = report_services.cashbook_report(from_date=date(2026, 6, 1), to_date=date(2026, 6, 30))
        dates_in_order = [e["date"] for e in data["entries"]]
        self.assertEqual(dates_in_order, sorted(dates_in_order))

        self.assertEqual(data["total_in"], Decimal("51000.00"))  # 1000 payment + 50000 loan
        self.assertEqual(data["total_out"], Decimal("300.00"))
        self.assertEqual(data["net"], Decimal("50700.00"))
        # running balance after the last (chronologically final) entry equals net
        self.assertEqual(data["entries"][-1]["running_balance"], data["net"])

    # --- dashboard summary ---------------------------------------------------------

    def test_dashboard_summary_aggregates_consistently(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("300.00"))
        self._pay_invoice(invoice, "300.00", (2026, 6, 1))

        data = report_services.dashboard_summary(from_date=date(2026, 6, 1), to_date=date(2026, 6, 30))
        self.assertEqual(data["income"]["total"], Decimal("300.00"))
        self.assertEqual(data["profit_loss"]["total_income"], Decimal("300.00"))
        self.assertIn("stock", data)
        self.assertIn("loans", data)

    # --- admin dashboard (operational snapshot) -------------------------------

    def test_admin_dashboard_summary_aggregates_operational_metrics(self):
        self.customer.is_red_listed = True
        self.customer.save()

        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("300.00"))
        invoice_services.add_payment(invoice, amount=Decimal("100.00"), payment_method="CASH")

        Product.objects.create(
            name="Rare Bulb", sku="LOWSTOCK-1", supplier=self.supplier,
            sale_price="50.00", current_stock_quantity=2,
        )

        Loan.objects.create(
            lender_name="City Bank", lender_type=Loan.LenderType.BANK,
            loan_amount=Decimal("20000.00"), interest_amount=Decimal("2000.00"),
            total_installments=4, installment_amount=Decimal("5500.00"),
            installment_frequency=Loan.InstallmentFrequency.WEEKLY, start_date=timezone.now().date(),
        )

        today = timezone.now().date()
        Expense.objects.create(category=Expense.Category.RENT, amount=Decimal("5000.00"), date=today)
        Expense.objects.create(category=Expense.Category.ELECTRICITY, amount=Decimal("1200.00"), date=today)
        # 45 days always falls outside the current week AND month, regardless
        # of which real-world day this suite happens to run on.
        Expense.objects.create(
            category=Expense.Category.MISC, amount=Decimal("9999.00"), date=today - timedelta(days=45),
        )

        data = report_services.admin_dashboard_summary(low_stock_threshold=5, upcoming_days=10)

        self.assertEqual(data["today_income"], Decimal("100.00"))
        self.assertEqual(data["today_invoice_count"], 1)
        self.assertEqual(data["today_total_amount"], Decimal("300.00"))
        self.assertEqual(data["total_income_all_time"], Decimal("100.00"))
        self.assertEqual(data["pending_dues"]["invoice_count"], 1)
        self.assertGreaterEqual(data["red_listed_customers_count"], 1)
        self.assertTrue(any(p["sku"] == "LOWSTOCK-1" for p in data["low_stock_products"]))
        self.assertEqual(len(data["upcoming_loan_installments"]), 1)

        # Manual-expense fields (apps.expenses.Expense only) and net profit.
        self.assertEqual(data["today_expense"], Decimal("6200.00"))  # rent + electricity
        self.assertEqual(data["this_week_expense"], Decimal("6200.00"))  # 45-day-old misc excluded
        self.assertEqual(data["this_month_expense"], Decimal("6200.00"))  # 45-day-old misc excluded
        self.assertEqual(data["total_expense_all_time"], Decimal("16199.00"))  # + the 45-day-old misc
        self.assertEqual(data["net_profit_today"], Decimal("100.00") - Decimal("6200.00"))

        # Income run-rate projection fields - the only payment made anywhere
        # in this test is today's ৳100.00, so it's unambiguously this week's
        # AND this month's income too, regardless of what day this suite
        # happens to run on.
        self.assertEqual(data["this_week_income"], Decimal("100.00"))
        self.assertEqual(data["this_month_income"], Decimal("100.00"))
        days_elapsed = today.day
        days_in_month = calendar.monthrange(today.year, today.month)[1]
        expected_prediction = ((Decimal("100.00") / days_elapsed) * days_in_month).quantize(
            Decimal("0.01"), rounding=ROUND_HALF_UP,
        )
        self.assertEqual(data["predicted_month_income"], expected_prediction)
        self.assertEqual(data["income_prediction_gap"], expected_prediction - Decimal("100.00"))
        self.assertEqual(data["is_early_month_estimate"], days_elapsed < 5)
        self.assertEqual(data["top_expense_category_this_month"]["category"], Expense.Category.RENT)
        self.assertEqual(data["top_expense_category_this_month"]["amount"], Decimal("5000.00"))

    # --- top customers report ---------------------------------------------------

    def test_top_customers_report_sorts_by_billed_amount_by_default(self):
        other_customer = Customer.objects.create(name="Nasrin Akter", phone="01710000012")

        # self.customer: 3 fully-settled invoices, 300 each = 900 total.
        for _ in range(3):
            invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
            invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("300.00"))
            invoice_services.add_payment(invoice, amount=Decimal("300.00"), payment_method="CASH")

        # other_customer: one big invoice, partially paid.
        big_invoice, _ = invoice_services.get_or_create_open_invoice(other_customer)
        invoice_services.add_service_line(big_invoice, self.service, price_charged=Decimal("2000.00"))
        invoice_services.add_payment(big_invoice, amount=Decimal("500.00"), payment_method="CASH")

        data = report_services.top_customers_report()
        names_by_billed = [row["customer_name"] for row in data["rows"]]
        self.assertEqual(names_by_billed[0], "Nasrin Akter")  # 2000 > 900
        other_row = next(r for r in data["rows"] if r["customer_name"] == "Nasrin Akter")
        self.assertEqual(other_row["invoice_count"], 1)
        self.assertEqual(other_row["total_billed_amount"], Decimal("2000.00"))
        self.assertEqual(other_row["total_paid_amount"], Decimal("500.00"))
        self.assertEqual(other_row["total_due_amount"], Decimal("1500.00"))

        data_by_count = report_services.top_customers_report(sort_by="invoice_count")
        names_by_count = [row["customer_name"] for row in data_by_count["rows"]]
        self.assertEqual(names_by_count[0], "Karim Motors")  # 3 invoices > 1

    def test_top_customers_report_excludes_cancelled_invoices(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("500.00"))
        invoice_services.cancel_invoice(invoice)

        data = report_services.top_customers_report()
        self.assertEqual(data["rows"], [])

    def test_top_customers_report_rejects_unknown_sort_field(self):
        with self.assertRaises(ReportError):
            report_services.top_customers_report(sort_by="not_a_field")

    # --- payment delay report -----------------------------------------------------

    def test_payment_delay_report_ranks_longest_outstanding_first(self):
        other_customer = Customer.objects.create(name="Nasrin Akter", phone="01710000013")
        today = timezone.now().date()

        unpaid_invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(unpaid_invoice, self.service, price_charged=Decimal("300.00"))
        Invoice.objects.filter(pk=unpaid_invoice.pk).update(created_date=today - timedelta(days=10))

        partial_invoice, _ = invoice_services.get_or_create_open_invoice(other_customer)
        invoice_services.add_service_line(partial_invoice, self.service, price_charged=Decimal("1000.00"))
        Invoice.objects.filter(pk=partial_invoice.pk).update(created_date=today - timedelta(days=20))
        invoice_services.add_payment(
            partial_invoice, amount=Decimal("400.00"), payment_method="CASH",
            payment_date=_aware(today.year, today.month, today.day) - timedelta(days=3),
        )

        data = report_services.payment_delay_report()
        self.assertEqual(len(data["rows"]), 2)

        first, second = data["rows"]
        self.assertEqual(first["customer_name"], "Karim Motors")  # unpaid since creation, 10 days
        self.assertEqual(first["days_delayed"], 10)
        self.assertEqual(first["invoice_nos"], [unpaid_invoice.invoice_no])
        self.assertEqual(first["amount_due"], Decimal("300.00"))

        self.assertEqual(second["customer_name"], "Nasrin Akter")  # partial paid 3 days ago
        self.assertEqual(second["days_delayed"], 3)
        self.assertEqual(second["amount_due"], Decimal("600.00"))

    def test_payment_delay_report_excludes_fully_paid_invoices(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("300.00"))
        invoice_services.add_payment(invoice, amount=Decimal("300.00"), payment_method="CASH")

        data = report_services.payment_delay_report()
        self.assertEqual(data["rows"], [])

    # --- service performance report ------------------------------------------------

    def test_service_performance_report_ranks_by_revenue(self):
        battery_service = Service.objects.create(
            category=self.service.category, name="Battery Replacement", service_price="1000.00",
        )

        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("300.00"))
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("500.00"))
        invoice_services.add_service_line(invoice, battery_service, price_charged=Decimal("1000.00"))

        data = report_services.service_performance_report()
        names = [row["service_name"] for row in data["rows"]]
        self.assertEqual(names[0], "Battery Replacement")  # 1000 > 800

        led_row = next(r for r in data["rows"] if r["service_name"] == "LED Repair")
        self.assertEqual(led_row["times_performed"], 2)
        self.assertEqual(led_row["total_revenue"], Decimal("800.00"))
        self.assertEqual(led_row["average_price"], Decimal("400.00"))

    def test_service_performance_report_excludes_lines_outside_date_range(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        line = invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("300.00"))
        from apps.invoices.models import InvoiceServiceLine

        InvoiceServiceLine.objects.filter(pk=line.pk).update(created_at=_aware(2020, 1, 1))

        data = report_services.service_performance_report(
            from_date=date(2026, 1, 1), to_date=date(2026, 12, 31),
        )
        self.assertEqual(data["rows"], [])

    # --- waived report (rule 13) ---------------------------------------------

    def test_waived_report_totals_force_closed_invoices_by_customer(self):
        customer2 = Customer.objects.create(name="Rahim Traders", phone="01710000011")

        invoice1, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice1, self.service, price_charged=Decimal("1000.00"))
        invoice_services.add_payment(invoice1, amount=Decimal("700.00"), payment_method="CASH")
        invoice1.refresh_from_db()
        invoice_services.force_close_invoice(invoice1, note="accepted shortfall 1")

        invoice2, _ = invoice_services.get_or_create_open_invoice(customer2)
        invoice_services.add_service_line(invoice2, self.service, price_charged=Decimal("500.00"))
        invoice_services.add_payment(invoice2, amount=Decimal("100.00"), payment_method="CASH")
        invoice2.refresh_from_db()
        invoice_services.force_close_invoice(invoice2, note="accepted shortfall 2")

        # A normal discount must never show up here.
        invoice3, _ = invoice_services.get_or_create_open_invoice(Customer.objects.create(name="Jamal", phone="01710000012"))
        invoice_services.add_service_line(invoice3, self.service, price_charged=Decimal("1000.00"))
        invoice_services.apply_discount(invoice3, discount_amount=Decimal("100.00"))

        data = report_services.waived_report()
        self.assertEqual(data["customer_count"], 2)
        self.assertEqual(data["total_waived_amount"], Decimal("700.00"))  # 300 + 400

        row_by_customer = {row["customer_name"]: row for row in data["rows"]}
        self.assertEqual(row_by_customer["Karim Motors"]["total_waived_amount"], Decimal("300.00"))
        self.assertEqual(row_by_customer["Rahim Traders"]["total_waived_amount"], Decimal("400.00"))

    def test_waived_report_filters_by_date_range(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("1000.00"))
        invoice_services.add_payment(invoice, amount=Decimal("600.00"), payment_method="CASH")
        invoice.refresh_from_db()
        invoice_services.force_close_invoice(invoice, note="old shortfall")
        Invoice.objects.filter(pk=invoice.pk).update(created_date=date(2020, 1, 1))

        data = report_services.waived_report(from_date=date(2026, 1, 1), to_date=date(2026, 12, 31))
        self.assertEqual(data["rows"], [])
        self.assertEqual(data["total_waived_amount"], Decimal("0"))


class ProjectMonthIncomeTests(SimpleTestCase):
    """apps.reports.services.project_month_income() - the plain run-rate
    projection behind the admin dashboard's predicted_month_income /
    income_prediction_gap / is_early_month_estimate fields. Pure function,
    no DB access, so exact days-elapsed/days-in-month scenarios (including
    the 1st-of-the-month edge case) can be tested directly instead of
    depending on whatever day this suite happens to run on."""

    def test_worked_example_day_10_of_30_day_month(self):
        predicted, gap, is_early = report_services.project_month_income(
            this_month_income=Decimal("5000.00"), days_elapsed=10, days_in_month=30,
        )
        self.assertEqual(predicted, Decimal("15000.00"))  # (5000 / 10) * 30
        self.assertEqual(gap, Decimal("10000.00"))  # 15000 - 5000
        self.assertFalse(is_early)

    def test_first_day_of_month_does_not_divide_by_zero(self):
        predicted, gap, is_early = report_services.project_month_income(
            this_month_income=Decimal("500.00"), days_elapsed=1, days_in_month=31,
        )
        self.assertEqual(predicted, Decimal("15500.00"))  # (500 / 1) * 31
        self.assertEqual(gap, Decimal("15000.00"))
        self.assertTrue(is_early)  # day 1 is well under the 5-day threshold

    def test_is_early_month_estimate_flips_off_at_day_5(self):
        _, _, is_early_day_4 = report_services.project_month_income(
            this_month_income=Decimal("400.00"), days_elapsed=4, days_in_month=30,
        )
        _, _, is_early_day_5 = report_services.project_month_income(
            this_month_income=Decimal("500.00"), days_elapsed=5, days_in_month=30,
        )
        self.assertTrue(is_early_day_4)
        self.assertFalse(is_early_day_5)

    def test_zero_income_so_far_predicts_zero_not_an_error(self):
        predicted, gap, _ = report_services.project_month_income(
            this_month_income=Decimal("0.00"), days_elapsed=1, days_in_month=28,
        )
        self.assertEqual(predicted, Decimal("0.00"))
        self.assertEqual(gap, Decimal("0.00"))

    def test_rounds_to_two_decimal_places(self):
        # 1000 / 3 = 333.333... - projected across 30 days should round
        # half-up to the nearest cent, not truncate or stay unrounded.
        predicted, gap, _ = report_services.project_month_income(
            this_month_income=Decimal("1000.00"), days_elapsed=3, days_in_month=30,
        )
        self.assertEqual(predicted, Decimal("10000.00"))  # (1000 / 3) * 30 == 10000 exactly
        self.assertEqual(gap, Decimal("9000.00"))
