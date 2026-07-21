from datetime import date, datetime
from decimal import Decimal

from django.test import TestCase
from django.utils import timezone

from apps.assets.models import Asset, AssetIncident
from apps.customers.models import Customer
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

        data = report_services.admin_dashboard_summary(low_stock_threshold=5, upcoming_days=10)

        self.assertEqual(data["today_income"], Decimal("100.00"))
        self.assertEqual(data["pending_dues"]["invoice_count"], 1)
        self.assertGreaterEqual(data["red_listed_customers_count"], 1)
        self.assertTrue(any(p["sku"] == "LOWSTOCK-1" for p in data["low_stock_products"]))
        self.assertEqual(len(data["upcoming_loan_installments"]), 1)
