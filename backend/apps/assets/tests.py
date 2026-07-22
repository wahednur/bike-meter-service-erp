from datetime import date
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from apps.assets import services as asset_services
from apps.assets.models import Asset, AssetIncident
from apps.customers.models import Customer
from apps.invoices import services as invoice_services
from apps.services.models import Service, ServiceCategory

User = get_user_model()


class AssetStatsTests(TestCase):
    """apps.assets.services.compute_asset_stats() - real revenue via the
    opt-in InvoiceServiceLine.asset_used tag, instead of the old permanent
    total_revenue_generated=0 stub."""

    def setUp(self):
        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000050")
        category = ServiceCategory.objects.create(name=ServiceCategory.Name.METER_REPAIR)
        self.repair_service = Service.objects.create(
            category=category, name="Main board repair", service_price="2000.00",
        )
        self.asset = Asset.objects.create(
            name="Soldering Iron", purchase_price=Decimal("5000.00"), purchase_date=date.today(),
        )

    def test_asset_never_used_shows_not_linked_not_zero_value(self):
        stats = asset_services.compute_asset_stats(self.asset)

        self.assertEqual(stats["total_jobs_count"], 0)
        self.assertFalse(stats["has_usage"])
        self.assertEqual(stats["total_revenue_generated"], Decimal("0"))
        # cost_recovered must be False here, but for the RIGHT reason
        # (has_usage is False) - not because revenue fell short.
        self.assertFalse(stats["cost_recovered"])

    def test_tagging_a_service_line_generates_real_revenue(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(
            invoice, self.repair_service, price_charged=Decimal("2000.00"), asset_used=self.asset,
        )

        stats = asset_services.compute_asset_stats(self.asset)
        self.assertTrue(stats["has_usage"])
        self.assertEqual(stats["total_jobs_count"], 1)
        self.assertEqual(stats["total_revenue_generated"], Decimal("2000.00"))

    def test_untagged_service_lines_are_not_counted(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        # No asset_used - this repair didn't name a specific tool.
        invoice_services.add_service_line(invoice, self.repair_service, price_charged=Decimal("2000.00"))

        stats = asset_services.compute_asset_stats(self.asset)
        self.assertFalse(stats["has_usage"])
        self.assertEqual(stats["total_revenue_generated"], Decimal("0"))

    def test_cost_recovered_true_once_revenue_matches_purchase_price(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        for _ in range(3):
            invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
            invoice_services.add_service_line(
                invoice, self.repair_service, price_charged=Decimal("2000.00"), asset_used=self.asset,
            )
            invoice_services.add_payment(invoice, amount=Decimal("2000.00"), payment_method="CASH")

        stats = asset_services.compute_asset_stats(self.asset)
        self.assertEqual(stats["total_revenue_generated"], Decimal("6000.00"))
        self.assertTrue(stats["cost_recovered"])  # 6000 >= 5000 purchase_price

    def test_cost_recovered_accounts_for_incident_repair_costs_too(self):
        """total_cost_incurred = purchase_price + incident costs - revenue
        must cover the incident cost as well, not just the original purchase."""
        AssetIncident.objects.create(
            asset=self.asset, type=AssetIncident.Type.REPAIRED, cost=Decimal("1500.00"), date=date.today(),
        )
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(
            invoice, self.repair_service, price_charged=Decimal("6000.00"), asset_used=self.asset,
        )

        stats = asset_services.compute_asset_stats(self.asset)
        self.assertEqual(stats["total_cost_incurred"], Decimal("6500.00"))  # 5000 + 1500
        self.assertTrue(stats["has_usage"])
        self.assertFalse(stats["cost_recovered"])  # 6000 revenue < 6500 total cost


class CostRecoveryReportTests(TestCase):
    def setUp(self):
        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000051")
        category = ServiceCategory.objects.create(name=ServiceCategory.Name.METER_REPAIR)
        self.repair_service = Service.objects.create(
            category=category, name="Main board repair", service_price="2000.00",
        )

    def test_unused_asset_reports_not_linked_status(self):
        Asset.objects.create(name="Multimeter", purchase_price=Decimal("3000.00"), purchase_date=date.today())

        rows = asset_services.build_cost_recovery_report()
        row = next(r for r in rows if r["type"] == "asset" and r["name"] == "Multimeter")

        self.assertEqual(row["status"], "NOT_LINKED")
        self.assertFalse(row["has_usage"])
        self.assertFalse(row["cost_recovered"])

    def test_used_asset_reports_real_profit_loss_status(self):
        asset = Asset.objects.create(name="Soldering Iron", purchase_price=Decimal("500.00"), purchase_date=date.today())
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(
            invoice, self.repair_service, price_charged=Decimal("2000.00"), asset_used=asset,
        )

        rows = asset_services.build_cost_recovery_report()
        row = next(r for r in rows if r["type"] == "asset" and r["id"] == asset.id)

        self.assertTrue(row["has_usage"])
        self.assertEqual(row["total_revenue"], Decimal("2000.00"))
        self.assertEqual(row["status"], "PROFIT")
        self.assertTrue(row["cost_recovered"])


class AssetDescriptionApiTests(TestCase):
    def setUp(self):
        self.admin = User.objects.create_superuser(email="asset_desc_admin@test.local", password="pass12345", name="Admin")
        self.client = APIClient()
        self.client.force_authenticate(self.admin)

    def test_description_is_optional_and_round_trips(self):
        response = self.client.post(
            "/api/assets/",
            {
                "name": "Soldering Iron", "purchase_price": "500.00", "purchase_date": "2026-07-22",
                "description": "60W adjustable-temperature iron, kept at the repair bench.",
            },
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["description"], "60W adjustable-temperature iron, kept at the repair bench.")

        asset_id = response.data["id"]
        detail_response = self.client.get(f"/api/assets/{asset_id}/")
        self.assertEqual(detail_response.data["description"], "60W adjustable-temperature iron, kept at the repair bench.")

    def test_description_defaults_to_blank(self):
        asset = Asset.objects.create(name="Multimeter", purchase_price=Decimal("1200.00"), purchase_date=date.today())
        response = self.client.get(f"/api/assets/{asset.id}/")
        self.assertEqual(response.data["description"], "")
