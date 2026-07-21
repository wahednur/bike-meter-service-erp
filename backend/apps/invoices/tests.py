from datetime import date
from decimal import Decimal

from django.test import TestCase

from apps.customers.models import Customer
from apps.invoices import services as invoice_services
from apps.invoices.exceptions import InvoiceError
from apps.invoices.models import Invoice
from apps.meters.models import MileageCorrectionDevice, Meter
from apps.products.models import Product
from apps.services.models import Service, ServiceCategory
from apps.suppliers.models import Supplier


class InvoiceServiceTests(TestCase):
    def setUp(self):
        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000001")

        self.mcu_meter = Meter.objects.create(
            brand="Bajaj", model="Discover 125", cc=125,
            memory_type=Meter.MemoryType.MCU, ic_mcu_model="R5F10CMEL", sales_price="1500.00",
        )
        self.eeprom_meter = Meter.objects.create(
            brand="Yamaha", model="FZ V2", cc=150,
            memory_type=Meter.MemoryType.EEPROM, ic_mcu_model="93C66", sales_price="1800.00",
        )

        # VVDI Prog / RT809F already exist via the meters data migration seed.
        self.vvdi, _ = MileageCorrectionDevice.objects.get_or_create(
            name="VVDI Prog",
            defaults={
                "purchase_price": "70000.00", "purchase_date": date.today(),
                "memory_type_support": MileageCorrectionDevice.MemoryTypeSupport.MCU,
            },
        )
        self.rt809f, _ = MileageCorrectionDevice.objects.get_or_create(
            name="RT809F",
            defaults={
                "purchase_price": "7500.00", "purchase_date": date.today(),
                "memory_type_support": MileageCorrectionDevice.MemoryTypeSupport.EEPROM,
            },
        )

        self.mc_category = ServiceCategory.objects.create(name=ServiceCategory.Name.MILEAGE_CORRECTION)
        self.repair_category = ServiceCategory.objects.create(name=ServiceCategory.Name.METER_REPAIR)
        self.mc_service = Service.objects.create(
            category=self.mc_category, name="Mileage Correction", service_price="500.00",
        )
        self.repair_service = Service.objects.create(
            category=self.repair_category, name="LED IC problem repair", service_price="300.00",
        )

        self.supplier = Supplier.objects.create(name="ABC Traders", phone="01810000001")
        self.product = Product.objects.create(
            name="Meter Casing", sku="CASING-1", supplier=self.supplier,
            buy_price="50.00", sale_price="150.00", current_stock_quantity=10,
        )

    # --- rule (a): one open invoice per customer -----------------------------

    def test_get_or_create_open_invoice_reuses_open_invoice(self):
        invoice1, created1 = invoice_services.get_or_create_open_invoice(self.customer)
        invoice2, created2 = invoice_services.get_or_create_open_invoice(self.customer)

        self.assertTrue(created1)
        self.assertFalse(created2)
        self.assertEqual(invoice1.id, invoice2.id)
        self.assertEqual(Invoice.objects.filter(customer=self.customer).count(), 1)

    def test_new_invoice_created_only_after_previous_is_fully_paid(self):
        invoice1, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice1, self.repair_service, price_charged=Decimal("300.00"))
        invoice_services.add_payment(invoice1, amount=Decimal("300.00"), payment_method="CASH")
        invoice1.refresh_from_db()
        self.assertEqual(invoice1.status, Invoice.Status.PAID)

        invoice2, created2 = invoice_services.get_or_create_open_invoice(self.customer)
        self.assertTrue(created2)
        self.assertNotEqual(invoice1.id, invoice2.id)

    # --- rule (c): mileage correction device must match meter memory_type ----

    def test_mileage_correction_device_must_match_meter_memory_type(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)

        with self.assertRaises(InvoiceError):
            invoice_services.add_meter_entry(
                invoice, self.mcu_meter, serial_number="MCU-001", mileage_correction_device=self.rt809f,
            )

        # correct device for an MCU meter succeeds
        entry = invoice_services.add_meter_entry(
            invoice, self.mcu_meter, serial_number="MCU-001", mileage_correction_device=self.vvdi,
        )
        self.assertEqual(entry.mileage_correction_device, self.vvdi)

    def test_eeprom_meter_rejects_vvdi_prog(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        with self.assertRaises(InvoiceError):
            invoice_services.add_meter_entry(
                invoice, self.eeprom_meter, serial_number="EEP-001", mileage_correction_device=self.vvdi,
            )

    # --- Mileage Correction service requires meter entry km/condition data ---

    def test_mileage_correction_service_requires_km_and_condition_note(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        entry = invoice_services.add_meter_entry(invoice, self.mcu_meter, serial_number="MCU-002")

        with self.assertRaises(InvoiceError):
            invoice_services.add_service_line(invoice, self.mc_service, meter_entry=entry)

        entry.previous_km, entry.current_km, entry.condition_note = 12000, 8000, "Casing intact, screen fine"
        entry.save()
        line = invoice_services.add_service_line(invoice, self.mc_service, meter_entry=entry)
        self.assertEqual(line.service, self.mc_service)

    def test_mileage_correction_service_without_meter_entry_rejected(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        with self.assertRaises(InvoiceError):
            invoice_services.add_service_line(invoice, self.mc_service, meter_entry=None)

    # --- rule (b): even split of paid_amount across meter entries ------------

    def test_split_payment_across_meters_matches_worked_example(self):
        """3 meters: 400 + 400 + 500 = 1300 total, customer pays 1200 ->
        each meter entry's paid_share should be 1200 / 3 = 400.00."""
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)

        entry1 = invoice_services.add_meter_entry(invoice, self.mcu_meter, serial_number="A")
        entry2 = invoice_services.add_meter_entry(invoice, self.eeprom_meter, serial_number="B")
        entry3 = invoice_services.add_meter_entry(invoice, self.mcu_meter, serial_number="C")

        invoice_services.add_service_line(invoice, self.repair_service, meter_entry=entry1, price_charged=Decimal("400.00"))
        invoice_services.add_service_line(invoice, self.repair_service, meter_entry=entry2, price_charged=Decimal("400.00"))
        invoice_services.add_service_line(invoice, self.repair_service, meter_entry=entry3, price_charged=Decimal("500.00"))

        invoice.refresh_from_db()
        self.assertEqual(invoice.total_amount, Decimal("1300.00"))

        invoice_services.add_payment(invoice, amount=Decimal("1200.00"), payment_method="CASH")

        invoice.refresh_from_db()
        self.assertEqual(invoice.paid_amount, Decimal("1200.00"))
        self.assertEqual(invoice.status, Invoice.Status.PARTIAL)

        for entry in (entry1, entry2, entry3):
            entry.refresh_from_db()
            self.assertEqual(entry.paid_share, Decimal("400.00"))

    def test_split_payment_across_meters_distributes_rounding_remainder(self):
        """1000 split 3 ways doesn't divide evenly - the leftover cent must
        land on exactly one entry so the shares still sum to paid_amount."""
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        entries = [
            invoice_services.add_meter_entry(invoice, self.mcu_meter, serial_number=f"R{i}") for i in range(3)
        ]
        for entry in entries:
            invoice_services.add_service_line(invoice, self.repair_service, meter_entry=entry, price_charged=Decimal("400.00"))

        invoice_services.add_payment(invoice, amount=Decimal("1000.00"), payment_method="CASH")

        shares = []
        for entry in entries:
            entry.refresh_from_db()
            shares.append(entry.paid_share)

        self.assertEqual(sum(shares), Decimal("1000.00"))
        self.assertEqual(sorted(shares), [Decimal("333.33"), Decimal("333.33"), Decimal("333.34")])

    def test_split_payment_recomputed_when_meter_added_after_payment(self):
        """Invoice must stay PARTIAL (not PAID) here so it's still editable -
        adding a second meter should re-split the existing payment."""
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        entry1 = invoice_services.add_meter_entry(invoice, self.mcu_meter, serial_number="X1")
        invoice_services.add_service_line(invoice, self.repair_service, meter_entry=entry1, price_charged=Decimal("300.00"))
        invoice_services.add_payment(invoice, amount=Decimal("200.00"), payment_method="CASH")

        entry1.refresh_from_db()
        self.assertEqual(entry1.paid_share, Decimal("200.00"))

        invoice.refresh_from_db()
        self.assertEqual(invoice.status, Invoice.Status.PARTIAL)

        entry2 = invoice_services.add_meter_entry(invoice, self.eeprom_meter, serial_number="X2")

        entry1.refresh_from_db()
        entry2.refresh_from_db()
        self.assertEqual(entry1.paid_share, Decimal("100.00"))
        self.assertEqual(entry2.paid_share, Decimal("100.00"))

    # --- rule (f): status auto-update -----------------------------------------

    def test_status_transitions_unpaid_partial_paid(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        self.assertEqual(invoice.status, Invoice.Status.UNPAID)

        invoice_services.add_service_line(invoice, self.repair_service, price_charged=Decimal("500.00"))
        invoice.refresh_from_db()
        self.assertEqual(invoice.status, Invoice.Status.UNPAID)  # total>0 but nothing paid yet

        invoice_services.add_payment(invoice, amount=Decimal("200.00"), payment_method="CASH")
        invoice.refresh_from_db()
        self.assertEqual(invoice.status, Invoice.Status.PARTIAL)

        invoice_services.add_payment(invoice, amount=Decimal("300.00"), payment_method="CASH")
        invoice.refresh_from_db()
        self.assertEqual(invoice.status, Invoice.Status.PAID)

    def test_payment_exceeding_outstanding_balance_rejected(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.repair_service, price_charged=Decimal("300.00"))
        with self.assertRaises(InvoiceError):
            invoice_services.add_payment(invoice, amount=Decimal("400.00"), payment_method="CASH")

    def test_cannot_edit_invoice_once_fully_paid(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.repair_service, price_charged=Decimal("300.00"))
        invoice_services.add_payment(invoice, amount=Decimal("300.00"), payment_method="CASH")
        invoice.refresh_from_db()

        with self.assertRaises(InvoiceError):
            invoice_services.add_meter_entry(invoice, self.mcu_meter, serial_number="LATE-1")

    # --- rule (g): red-list on consecutive shortfall invoices ------------------

    def _add_and_fully_pay(self, service_price, with_shortfall):
        """Opens (or reuses) the customer's open invoice, bills one service
        line, and pays it off fully - either in two installments (leaving a
        PARTIAL period, i.e. had_shortfall=True) or in one shot (never
        PARTIAL, had_shortfall stays False)."""
        service_price = Decimal(service_price)
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.repair_service, price_charged=service_price)

        if with_shortfall:
            invoice_services.add_payment(invoice, amount=service_price - Decimal("50"), payment_method="CASH")
            invoice_services.add_payment(invoice, amount=Decimal("50"), payment_method="CASH")
        else:
            invoice_services.add_payment(invoice, amount=service_price, payment_method="CASH")

        invoice.refresh_from_db()
        return invoice

    def test_invoice_paid_in_one_shot_has_no_shortfall_flag(self):
        invoice = self._add_and_fully_pay("300.00", with_shortfall=False)
        self.assertFalse(invoice.had_shortfall)

    def test_invoice_underpaid_then_settled_keeps_shortfall_flag(self):
        invoice = self._add_and_fully_pay("300.00", with_shortfall=True)
        self.assertTrue(invoice.had_shortfall)
        self.assertEqual(invoice.status, Invoice.Status.PAID)

    def test_single_shortfall_invoice_does_not_redlist(self):
        self._add_and_fully_pay("300.00", with_shortfall=True)
        self.customer.refresh_from_db()
        self.assertFalse(self.customer.is_red_listed)

    def test_two_consecutive_shortfall_invoices_redlist_customer(self):
        self._add_and_fully_pay("300.00", with_shortfall=True)
        self.customer.refresh_from_db()
        self.assertFalse(self.customer.is_red_listed)

        self._add_and_fully_pay("300.00", with_shortfall=True)
        self.customer.refresh_from_db()
        self.assertTrue(self.customer.is_red_listed)

    def test_non_consecutive_shortfalls_do_not_redlist(self):
        self._add_and_fully_pay("300.00", with_shortfall=True)
        self._add_and_fully_pay("300.00", with_shortfall=False)  # breaks the streak
        self._add_and_fully_pay("300.00", with_shortfall=True)
        self.customer.refresh_from_db()
        self.assertFalse(self.customer.is_red_listed)

    def test_clean_invoice_breaks_streak_and_clears_redlist(self):
        self._add_and_fully_pay("300.00", with_shortfall=True)
        self._add_and_fully_pay("300.00", with_shortfall=True)
        self.customer.refresh_from_db()
        self.assertTrue(self.customer.is_red_listed)

        self._add_and_fully_pay("300.00", with_shortfall=False)
        self.customer.refresh_from_db()
        self.assertFalse(self.customer.is_red_listed)

    # --- product lines: stock integration -------------------------------------

    def test_add_product_line_decrements_stock(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_product_line(invoice, self.product, quantity=3)

        self.product.refresh_from_db()
        self.assertEqual(self.product.current_stock_quantity, 7)

        invoice.refresh_from_db()
        self.assertEqual(invoice.total_amount, Decimal("450.00"))  # 3 x 150.00

    def test_add_product_line_rejects_insufficient_stock(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        with self.assertRaises(InvoiceError):
            invoice_services.add_product_line(invoice, self.product, quantity=999)

    # --- rule (e): public share token ------------------------------------------

    def test_public_share_token_is_urlsafe_and_unique(self):
        invoice1, _ = invoice_services.get_or_create_open_invoice(self.customer)

        customer2 = Customer.objects.create(name="Rahim", phone="01710000002")
        invoice2, _ = invoice_services.get_or_create_open_invoice(customer2)

        self.assertNotEqual(invoice1.public_share_token, invoice2.public_share_token)
        for token in (invoice1.public_share_token, invoice2.public_share_token):
            self.assertTrue(1 <= len(token) <= 16)
            self.assertRegex(token, r"^[A-Za-z0-9_-]+$")

    # --- rule (d): edit history log ---------------------------------------------

    def test_edit_history_is_logged(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        entry = invoice_services.add_meter_entry(invoice, self.mcu_meter, serial_number="H1")
        invoice_services.add_service_line(invoice, self.repair_service, meter_entry=entry, price_charged=Decimal("300.00"))
        invoice_services.add_payment(invoice, amount=Decimal("300.00"), payment_method="CASH")

        actions = list(invoice.audit_logs.order_by("created_at").values_list("action", flat=True))
        self.assertEqual(
            actions,
            ["invoice_created", "meter_entry_added", "service_line_added", "payment_added"],
        )
