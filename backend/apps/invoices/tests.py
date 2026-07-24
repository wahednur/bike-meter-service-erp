from datetime import date
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from apps.assets.models import Asset
from apps.customers.models import Customer
from apps.invoices import services as invoice_services
from apps.invoices.exceptions import InvoiceError
from apps.invoices.models import Invoice
from apps.meters.models import MileageCorrectionDevice, Meter
from apps.products.models import Product
from apps.services.models import Service, ServiceCategory
from apps.shop_profile.models import ShopProfile
from apps.suppliers.models import Supplier

User = get_user_model()


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


class PublicInvoiceViewTests(TestCase):
    """HTTP-level: the no-auth share link must hide the mileage correction
    device entirely and carry shop branding for the footer. The meter is
    nested inside its service line's meter_entry_detail (rule 1) - there's
    no top-level meter list to check anymore."""

    def setUp(self):
        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000021")
        self.meter = Meter.objects.create(
            brand="Bajaj", model="Discover 125", cc=125,
            memory_type=Meter.MemoryType.MCU, ic_mcu_model="R5F10CMEL", sales_price="1500.00",
        )
        self.vvdi, _ = MileageCorrectionDevice.objects.get_or_create(
            name="VVDI Prog",
            defaults={
                "purchase_price": "70000.00", "purchase_date": date.today(),
                "memory_type_support": MileageCorrectionDevice.MemoryTypeSupport.MCU,
            },
        )
        mc_category = ServiceCategory.objects.create(name=ServiceCategory.Name.MILEAGE_CORRECTION)
        self.mc_service = Service.objects.create(
            category=mc_category, name="Mileage Correction", service_price="500.00",
        )
        self.invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(
            self.invoice, self.mc_service, meter=self.meter, serial_number="H1",
            previous_km=2000, current_km=1000, condition_note="fine",
            mileage_correction_device=self.vvdi,
        )
        self.client = APIClient()  # deliberately unauthenticated

    def test_public_response_hides_device_and_includes_shop_branding(self):
        ShopProfile.load()
        profile = ShopProfile.objects.get(pk=1)
        profile.shop_name = "Test Shop"
        profile.invoice_footer_text = "Thanks for visiting"
        profile.save()

        response = self.client.get(f"/api/public/invoices/{self.invoice.public_share_token}/")
        self.assertEqual(response.status_code, 200)
        self.assertNotIn("meter_entries", response.data)

        entry = response.data["service_lines"][0]["meter_entry_detail"]
        self.assertEqual(entry["meter_brand"], "Bajaj")
        self.assertNotIn("mileage_correction_device", entry)
        self.assertNotIn("mileage_correction_device_name", entry)

        self.assertEqual(response.data["shop_name"], "Test Shop")
        self.assertEqual(response.data["invoice_footer_text"], "Thanks for visiting")
        self.assertIn("due_amount", response.data)


class InvoiceDeleteApiTests(TestCase):
    """DELETE /api/invoices/{id}/ must soft delete (never hard delete),
    excluding the invoice from list/retrieve but keeping the row in the
    database - and must refuse to remove a fully paid invoice."""

    def setUp(self):
        self.admin = User.objects.create_superuser(email="invoice_admin@test.local", password="pass12345", name="Admin")
        self.client = APIClient()
        self.client.force_authenticate(self.admin)
        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000031")

    def test_delete_soft_deletes_unpaid_invoice(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_id = invoice.id

        response = self.client.delete(f"/api/invoices/{invoice_id}/")
        self.assertEqual(response.status_code, 204)

        self.assertFalse(Invoice.objects.filter(id=invoice_id).exists())
        stored = Invoice.all_objects.get(id=invoice_id)
        self.assertTrue(stored.is_deleted)
        self.assertIsNotNone(stored.deleted_at)

        list_response = self.client.get("/api/invoices/")
        returned_ids = [row["id"] for row in list_response.data]
        self.assertNotIn(invoice_id, returned_ids)

    def test_delete_rejected_for_fully_paid_invoice(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        meter = Meter.objects.create(
            brand="Bajaj", model="Discover 125", cc=125,
            memory_type=Meter.MemoryType.MCU, ic_mcu_model="R5F10CMEL", sales_price="1500.00",
        )
        entry = invoice_services.add_meter_entry(invoice, meter, serial_number="H1")
        category = ServiceCategory.objects.create(name=ServiceCategory.Name.METER_REPAIR)
        service = Service.objects.create(category=category, name="Repair", service_price="300.00")
        invoice_services.add_service_line(invoice, service, meter_entry=entry, price_charged=Decimal("300.00"))
        invoice_services.add_payment(invoice, amount=Decimal("300.00"), payment_method="CASH")
        invoice.refresh_from_db()
        self.assertEqual(invoice.status, Invoice.Status.PAID)

        response = self.client.delete(f"/api/invoices/{invoice.id}/")
        self.assertEqual(response.status_code, 400)
        self.assertTrue(Invoice.objects.filter(id=invoice.id).exists())


class InvoiceDiscountServiceTests(TestCase):
    """apps.invoices.services.apply_discount() - fixed-BDT invoice-level
    discount, folded into total_amount = (services + products) - discount."""

    def setUp(self):
        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000041")
        self.admin = User.objects.create_superuser(email="discount_admin@test.local", password="pass12345", name="Admin")
        category = ServiceCategory.objects.create(name=ServiceCategory.Name.METER_REPAIR)
        self.service = Service.objects.create(category=category, name="Repair", service_price="1300.00")

    def test_worked_example_1300_minus_100_discount_1000_paid_leaves_200_due(self):
        """The exact scenario from the spec: 1300 BDT of work, 100 BDT
        discount -> total_amount 1200, customer pays 1000 -> due 200 (not 300)."""
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("1300.00"))

        invoice_services.apply_discount(invoice, discount_amount=Decimal("100.00"), discount_note="Loyal customer", user=self.admin)
        invoice.refresh_from_db()
        self.assertEqual(invoice.discount_amount, Decimal("100.00"))
        self.assertEqual(invoice.discount_note, "Loyal customer")
        self.assertEqual(invoice.total_amount, Decimal("1200.00"))

        invoice_services.add_payment(invoice, amount=Decimal("1000.00"), payment_method="CASH")
        invoice.refresh_from_db()

        self.assertEqual(invoice.paid_amount, Decimal("1000.00"))
        self.assertEqual(invoice.outstanding_amount, Decimal("200.00"))
        self.assertEqual(invoice.status, Invoice.Status.PARTIAL)

    def test_discount_applied_after_payment_still_recomputes_due_correctly(self):
        """Order shouldn't matter: paying first, then discounting, produces
        the same 1200 total / 200 due as discounting first."""
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("1300.00"))
        invoice_services.add_payment(invoice, amount=Decimal("1000.00"), payment_method="CASH")

        invoice_services.apply_discount(invoice, discount_amount=Decimal("100.00"), user=self.admin)
        invoice.refresh_from_db()

        self.assertEqual(invoice.total_amount, Decimal("1200.00"))
        self.assertEqual(invoice.outstanding_amount, Decimal("200.00"))
        self.assertEqual(invoice.status, Invoice.Status.PARTIAL)

    def test_discount_equal_to_full_amount_zeroes_out_the_total(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("1300.00"))

        invoice_services.apply_discount(invoice, discount_amount=Decimal("1300.00"), user=self.admin)
        invoice.refresh_from_db()

        self.assertEqual(invoice.total_amount, Decimal("0.00"))
        self.assertEqual(invoice.outstanding_amount, Decimal("0.00"))
        # Pre-existing determine_status() behavior, unrelated to discounts:
        # paid_amount<=0 is checked first, so a fully-discounted invoice with
        # no actual InvoicePayment stays UNPAID rather than PAID even though
        # nothing is owed. Not something this change alters.
        self.assertEqual(invoice.status, Invoice.Status.UNPAID)

    def test_discount_cannot_exceed_gross_total(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("1300.00"))

        with self.assertRaises(InvoiceError):
            invoice_services.apply_discount(invoice, discount_amount=Decimal("1301.00"), user=self.admin)

    def test_discount_cannot_drop_total_below_already_paid(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("1300.00"))
        invoice_services.add_payment(invoice, amount=Decimal("1000.00"), payment_method="CASH")

        # total would become 1300 - 400 = 900, below the 1000 already paid.
        with self.assertRaises(InvoiceError):
            invoice_services.apply_discount(invoice, discount_amount=Decimal("400.00"), user=self.admin)

    def test_discount_rejected_on_non_editable_invoice(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("1300.00"))
        invoice_services.add_payment(invoice, amount=Decimal("1300.00"), payment_method="CASH")
        invoice.refresh_from_db()
        self.assertEqual(invoice.status, Invoice.Status.PAID)

        with self.assertRaises(InvoiceError):
            invoice_services.apply_discount(invoice, discount_amount=Decimal("50.00"), user=self.admin)

    def test_discount_rejected_when_negative(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("1300.00"))

        with self.assertRaises(InvoiceError):
            invoice_services.apply_discount(invoice, discount_amount=Decimal("-10.00"), user=self.admin)

    def test_discount_applied_is_logged_with_amount_note_and_user(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("1300.00"))

        invoice_services.apply_discount(invoice, discount_amount=Decimal("100.00"), discount_note="Regular", user=self.admin)

        entry = invoice.audit_logs.filter(action="discount_applied").latest("created_at")
        self.assertEqual(entry.created_by, self.admin)
        self.assertIn("100.00", entry.description)
        self.assertIn("Regular", entry.description)


class InvoiceDiscountApiTests(TestCase):
    """POST /api/invoices/{id}/discount/ - Admin only."""

    def setUp(self):
        self.admin = User.objects.create_superuser(email="discount_api_admin@test.local", password="pass12345", name="Admin")
        self.staff = User.objects.create_user(email="discount_api_staff@test.local", password="pass12345", name="Staff")
        self.admin_client = APIClient()
        self.admin_client.force_authenticate(self.admin)
        self.staff_client = APIClient()
        self.staff_client.force_authenticate(self.staff)

        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000042")
        category = ServiceCategory.objects.create(name=ServiceCategory.Name.METER_REPAIR)
        self.service = Service.objects.create(category=category, name="Repair", service_price="1300.00")
        self.invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(self.invoice, self.service, price_charged=Decimal("1300.00"))

    def test_admin_can_apply_discount(self):
        response = self.admin_client.post(
            f"/api/invoices/{self.invoice.id}/discount/",
            {"discount_amount": "100.00", "discount_note": "Loyal customer"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["discount_amount"], "100.00")
        self.assertEqual(response.data["discount_note"], "Loyal customer")
        self.assertEqual(response.data["total_amount"], "1200.00")

    def test_staff_cannot_apply_discount(self):
        response = self.staff_client.post(
            f"/api/invoices/{self.invoice.id}/discount/",
            {"discount_amount": "100.00"},
            format="json",
        )
        self.assertEqual(response.status_code, 403)
        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.discount_amount, Decimal("0.00"))

    def test_discount_shown_on_invoice_list(self):
        invoice_services.apply_discount(self.invoice, discount_amount=Decimal("100.00"), user=self.admin)

        response = self.admin_client.get("/api/invoices/")
        self.assertEqual(response.status_code, 200)
        row = next(r for r in response.data if r["id"] == self.invoice.id)
        self.assertEqual(row["discount_amount"], "100.00")

    def test_public_invoice_shows_discount_but_hides_who_applied_it(self):
        invoice_services.apply_discount(self.invoice, discount_amount=Decimal("100.00"), discount_note="Loyal customer", user=self.admin)

        public_client = APIClient()  # deliberately unauthenticated
        response = public_client.get(f"/api/public/invoices/{self.invoice.public_share_token}/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["discount_amount"], "100.00")
        self.assertEqual(response.data["discount_note"], "Loyal customer")

        discount_entry = next(h for h in response.data["history"] if h["action"] == "discount_applied")
        self.assertNotIn("user", discount_entry)


class InvoiceServiceLineAssetUsedApiTests(TestCase):
    """POST /api/invoices/{id}/service-lines/ accepts an optional
    asset_used, and it round-trips through the serializer."""

    def setUp(self):
        self.admin = User.objects.create_superuser(email="asset_used_admin@test.local", password="pass12345", name="Admin")
        self.client = APIClient()
        self.client.force_authenticate(self.admin)

        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000043")
        category = ServiceCategory.objects.create(name=ServiceCategory.Name.METER_REPAIR)
        self.service = Service.objects.create(category=category, name="Repair", service_price="300.00")
        self.asset = Asset.objects.create(name="Soldering Iron", purchase_price="500.00", purchase_date=date.today())
        self.invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)

    def test_add_service_line_with_asset_used(self):
        response = self.client.post(
            f"/api/invoices/{self.invoice.id}/service-lines/",
            {"service": self.service.id, "asset_used": self.asset.id},
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["asset_used"], self.asset.id)
        self.assertEqual(response.data["asset_used_name"], "Soldering Iron")

    def test_add_service_line_without_asset_used_defaults_to_null(self):
        response = self.client.post(
            f"/api/invoices/{self.invoice.id}/service-lines/",
            {"service": self.service.id},
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        self.assertIsNone(response.data["asset_used"])
        self.assertIsNone(response.data["asset_used_name"])


class MergedAddServiceLineTests(TestCase):
    """apps.invoices.services.add_service_line() - the merged meter+service
    flow (rule i): for a Mileage Correction service with no pre-existing
    meter_entry, this creates the InvoiceMeterEntry and InvoiceServiceLine
    together in one call, with price defaulting to the meter's sales_price."""

    def setUp(self):
        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000051")
        self.meter = Meter.objects.create(
            brand="Bajaj", model="Discover 125", cc=125,
            memory_type=Meter.MemoryType.MCU, ic_mcu_model="R5F10CMEL", sales_price="1500.00",
        )
        self.vvdi, _ = MileageCorrectionDevice.objects.get_or_create(
            name="VVDI Prog",
            defaults={
                "purchase_price": "70000.00", "purchase_date": date.today(),
                "memory_type_support": MileageCorrectionDevice.MemoryTypeSupport.MCU,
            },
        )
        mc_category = ServiceCategory.objects.create(name=ServiceCategory.Name.MILEAGE_CORRECTION)
        self.mc_service = Service.objects.create(
            category=mc_category, name="Mileage Correction", service_price="500.00",
        )
        repair_category = ServiceCategory.objects.create(name=ServiceCategory.Name.METER_REPAIR)
        self.repair_service = Service.objects.create(
            category=repair_category, name="LED IC problem repair", service_price="300.00",
        )
        self.invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)

    def test_merged_call_creates_meter_entry_and_service_line_together(self):
        line = invoice_services.add_service_line(
            self.invoice, self.mc_service,
            meter=self.meter, serial_number="MC-001", condition_note="Casing fine",
            previous_km=15000, current_km=8000, mileage_correction_device=self.vvdi,
        )

        self.assertIsNotNone(line.meter_entry)
        self.assertEqual(line.meter_entry.meter, self.meter)
        self.assertEqual(line.meter_entry.serial_number, "MC-001")
        self.assertEqual(line.meter_entry.previous_km, 15000)
        self.assertEqual(line.meter_entry.current_km, 8000)
        self.assertEqual(line.meter_entry.mileage_correction_device, self.vvdi)
        self.assertEqual(self.invoice.meter_entries.count(), 1)

    def test_price_defaults_to_meter_sales_price_when_blank(self):
        line = invoice_services.add_service_line(
            self.invoice, self.mc_service,
            meter=self.meter, serial_number="MC-002", condition_note="Fine",
            previous_km=15000, current_km=8000,
        )
        line.refresh_from_db()
        self.assertEqual(line.price_charged, Decimal("1500.00"))  # meter.sales_price, not service_price

    def test_explicit_price_overrides_default_instead_of_adding(self):
        line = invoice_services.add_service_line(
            self.invoice, self.mc_service,
            meter=self.meter, serial_number="MC-003", condition_note="Fine",
            previous_km=15000, current_km=8000, price_charged=Decimal("1200.00"),
        )
        self.assertEqual(line.price_charged, Decimal("1200.00"))

    def test_regular_service_price_still_defaults_to_service_price(self):
        line = invoice_services.add_service_line(self.invoice, self.repair_service)
        line.refresh_from_db()
        self.assertEqual(line.price_charged, Decimal("300.00"))
        self.assertIsNone(line.meter_entry)

    def test_merged_call_requires_meter_when_no_meter_entry_given(self):
        with self.assertRaises(InvoiceError):
            invoice_services.add_service_line(
                self.invoice, self.mc_service, serial_number="MC-004", previous_km=1, current_km=1, condition_note="x",
            )

    def test_merged_call_still_enforces_condition_note(self):
        with self.assertRaises(InvoiceError):
            invoice_services.add_service_line(self.invoice, self.mc_service, meter=self.meter, serial_number="MC-005")

    def test_merged_call_allows_missing_previous_and_current_km(self):
        line = invoice_services.add_service_line(
            self.invoice, self.mc_service, meter=self.meter, serial_number="MC-005b", condition_note="fine",
        )
        self.assertIsNone(line.meter_entry.previous_km)
        self.assertIsNone(line.meter_entry.current_km)

    def test_merged_call_rejects_current_km_greater_than_previous_km(self):
        with self.assertRaises(InvoiceError):
            invoice_services.add_service_line(
                self.invoice, self.mc_service, meter=self.meter, serial_number="MC-005c",
                condition_note="fine", previous_km=1000, current_km=2000,
            )

    def test_merged_call_still_enforces_device_memory_type_match(self):
        rt809f, _ = MileageCorrectionDevice.objects.get_or_create(
            name="RT809F",
            defaults={
                "purchase_price": "7500.00", "purchase_date": date.today(),
                "memory_type_support": MileageCorrectionDevice.MemoryTypeSupport.EEPROM,
            },
        )
        with self.assertRaises(InvoiceError):
            invoice_services.add_service_line(
                self.invoice, self.mc_service, meter=self.meter, serial_number="MC-006",
                condition_note="fine", previous_km=1, current_km=1, mileage_correction_device=rt809f,
            )

    def test_merged_call_rejected_on_non_editable_invoice(self):
        invoice_services.add_service_line(self.invoice, self.repair_service, price_charged=Decimal("300.00"))
        invoice_services.add_payment(self.invoice, amount=Decimal("300.00"), payment_method="CASH")
        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.status, Invoice.Status.PAID)

        with self.assertRaises(InvoiceError):
            invoice_services.add_service_line(
                self.invoice, self.mc_service, meter=self.meter, serial_number="LATE",
                condition_note="x", previous_km=1, current_km=1,
            )


class MergedAddServiceLineApiTests(TestCase):
    """HTTP-level: POST /api/invoices/{id}/service-lines/ with the merged
    meter+service payload, and the response shape it returns."""

    def setUp(self):
        self.admin = User.objects.create_superuser(email="merged_admin@test.local", password="pass12345", name="Admin")
        self.client = APIClient()
        self.client.force_authenticate(self.admin)

        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000052")
        self.meter = Meter.objects.create(
            brand="Bajaj", model="Discover 125", cc=125,
            memory_type=Meter.MemoryType.MCU, ic_mcu_model="R5F10CMEL", sales_price="1500.00",
        )
        mc_category = ServiceCategory.objects.create(name=ServiceCategory.Name.MILEAGE_CORRECTION)
        self.mc_service = Service.objects.create(
            category=mc_category, name="Mileage Correction", service_price="500.00",
        )
        self.invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)

    def test_merged_request_shape_returns_line_with_nested_meter_entry(self):
        response = self.client.post(
            f"/api/invoices/{self.invoice.id}/service-lines/",
            {
                "service": self.mc_service.id,
                "meter": self.meter.id,
                "serial_number": "MC-100",
                "condition_note": "Casing intact, screen fine",
                "previous_km": 15000,
                "current_km": 8000,
            },
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["price_charged"], "1500.00")  # defaulted from meter.sales_price
        self.assertIsNotNone(response.data["meter_entry"])
        entry = response.data["meter_entry_detail"]
        self.assertEqual(entry["serial_number"], "MC-100")
        self.assertEqual(entry["previous_km"], 15000)
        self.assertEqual(entry["current_km"], 8000)

        # one call, one meter entry - no separate meter-entries POST needed
        self.assertEqual(self.invoice.meter_entries.count(), 1)

    def test_meter_entry_added_is_logged_alongside_service_line_added(self):
        self.client.post(
            f"/api/invoices/{self.invoice.id}/service-lines/",
            {
                "service": self.mc_service.id, "meter": self.meter.id, "serial_number": "MC-101",
                "condition_note": "fine", "previous_km": 1000, "current_km": 500,
            },
            format="json",
        )
        actions = list(self.invoice.audit_logs.order_by("created_at").values_list("action", flat=True))
        self.assertEqual(actions, ["invoice_created", "meter_entry_added", "service_line_added"])


class EditDeleteLineItemTests(TestCase):
    """apps.invoices.services.update_service_line/delete_service_line/
    update_product_line/delete_product_line (rule j)."""

    def setUp(self):
        self.admin = User.objects.create_superuser(email="editline_admin@test.local", password="pass12345", name="Admin")
        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000053")
        self.meter = Meter.objects.create(
            brand="Bajaj", model="Discover 125", cc=125,
            memory_type=Meter.MemoryType.MCU, ic_mcu_model="R5F10CMEL", sales_price="1500.00",
        )
        mc_category = ServiceCategory.objects.create(name=ServiceCategory.Name.MILEAGE_CORRECTION)
        self.mc_service = Service.objects.create(
            category=mc_category, name="Mileage Correction", service_price="500.00",
        )
        repair_category = ServiceCategory.objects.create(name=ServiceCategory.Name.METER_REPAIR)
        self.repair_service = Service.objects.create(category=repair_category, name="Repair", service_price="300.00")
        self.supplier = Supplier.objects.create(name="ABC Traders", phone="01810000053")
        self.product = Product.objects.create(
            name="Meter Casing", sku="CASING-53", supplier=self.supplier,
            buy_price="50.00", sale_price="150.00", current_stock_quantity=10,
        )
        self.invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)

    # --- update_service_line ---------------------------------------------------

    def test_update_service_line_previous_km_updates_linked_meter_entry(self):
        line = invoice_services.add_service_line(
            self.invoice, self.mc_service, meter=self.meter, serial_number="MC-1",
            condition_note="fine", previous_km=15000, current_km=8000,
        )
        invoice_services.update_service_line(self.invoice, line, previous_km=14500, user=self.admin)

        line.meter_entry.refresh_from_db()
        self.assertEqual(line.meter_entry.previous_km, 14500)
        self.assertEqual(line.meter_entry.current_km, 8000)  # untouched

        entry = self.invoice.audit_logs.filter(action="service_line_updated").latest("created_at")
        self.assertIn("previous_km", entry.description)
        self.assertEqual(entry.created_by, self.admin)

    def test_update_service_line_price_recalculates_invoice_totals(self):
        line = invoice_services.add_service_line(self.invoice, self.repair_service, price_charged=Decimal("300.00"))
        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.total_amount, Decimal("300.00"))

        invoice_services.update_service_line(self.invoice, line, price_charged=Decimal("450.00"), user=self.admin)
        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.total_amount, Decimal("450.00"))

    def test_update_service_line_without_meter_entry_rejects_km_fields(self):
        line = invoice_services.add_service_line(self.invoice, self.repair_service, price_charged=Decimal("300.00"))
        with self.assertRaises(InvoiceError):
            invoice_services.update_service_line(self.invoice, line, previous_km=100)

    def test_update_service_line_rejected_on_non_editable_invoice(self):
        line = invoice_services.add_service_line(self.invoice, self.repair_service, price_charged=Decimal("300.00"))
        invoice_services.add_payment(self.invoice, amount=Decimal("300.00"), payment_method="CASH")
        self.invoice.refresh_from_db()

        with self.assertRaises(InvoiceError):
            invoice_services.update_service_line(self.invoice, line, price_charged=Decimal("100.00"))

    # --- delete_service_line ----------------------------------------------------

    def test_delete_mileage_correction_line_also_removes_meter_entry(self):
        line = invoice_services.add_service_line(
            self.invoice, self.mc_service, meter=self.meter, serial_number="MC-2",
            condition_note="fine", previous_km=15000, current_km=8000,
        )
        entry_id = line.meter_entry_id
        invoice_services.delete_service_line(self.invoice, line, user=self.admin)

        self.assertFalse(self.invoice.service_lines.filter(pk=line.pk).exists())
        self.assertFalse(self.invoice.meter_entries.filter(pk=entry_id).exists())

        entry = self.invoice.audit_logs.filter(action="service_line_deleted").latest("created_at")
        self.assertIn("meter entry", entry.description)

    def test_delete_service_line_keeps_meter_entry_if_another_line_still_uses_it(self):
        mc_line = invoice_services.add_service_line(
            self.invoice, self.mc_service, meter=self.meter, serial_number="MC-3",
            condition_note="fine", previous_km=15000, current_km=8000,
        )
        entry = mc_line.meter_entry
        other_line = invoice_services.add_service_line(
            self.invoice, self.repair_service, meter_entry=entry, price_charged=Decimal("300.00"),
        )

        invoice_services.delete_service_line(self.invoice, mc_line, user=self.admin)

        self.assertTrue(self.invoice.meter_entries.filter(pk=entry.pk).exists())
        self.assertTrue(self.invoice.service_lines.filter(pk=other_line.pk).exists())

    def test_delete_service_line_recalculates_totals(self):
        line1 = invoice_services.add_service_line(self.invoice, self.repair_service, price_charged=Decimal("300.00"))
        invoice_services.add_service_line(self.invoice, self.repair_service, price_charged=Decimal("200.00"))
        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.total_amount, Decimal("500.00"))

        invoice_services.delete_service_line(self.invoice, line1, user=self.admin)
        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.total_amount, Decimal("200.00"))

    def test_delete_service_line_rejected_on_non_editable_invoice(self):
        line = invoice_services.add_service_line(self.invoice, self.repair_service, price_charged=Decimal("300.00"))
        invoice_services.add_payment(self.invoice, amount=Decimal("300.00"), payment_method="CASH")
        self.invoice.refresh_from_db()

        with self.assertRaises(InvoiceError):
            invoice_services.delete_service_line(self.invoice, line)

    # --- update_product_line / delete_product_line ------------------------------

    def test_update_product_line_quantity_adjusts_stock_and_totals(self):
        line = invoice_services.add_product_line(self.invoice, self.product, quantity=2)
        self.product.refresh_from_db()
        self.assertEqual(self.product.current_stock_quantity, 8)

        invoice_services.update_product_line(self.invoice, line, quantity=5, user=self.admin)
        self.product.refresh_from_db()
        self.assertEqual(self.product.current_stock_quantity, 5)  # 10 - 5

        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.total_amount, Decimal("750.00"))  # 5 x 150

    def test_update_product_line_rejects_insufficient_stock(self):
        line = invoice_services.add_product_line(self.invoice, self.product, quantity=2)
        with self.assertRaises(InvoiceError):
            invoice_services.update_product_line(self.invoice, line, quantity=999)

    def test_delete_product_line_restores_stock_and_recalculates(self):
        line = invoice_services.add_product_line(self.invoice, self.product, quantity=3)
        self.product.refresh_from_db()
        self.assertEqual(self.product.current_stock_quantity, 7)
        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.total_amount, Decimal("450.00"))

        invoice_services.delete_product_line(self.invoice, line, user=self.admin)

        self.product.refresh_from_db()
        self.assertEqual(self.product.current_stock_quantity, 10)
        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.total_amount, Decimal("0.00"))

        entry = self.invoice.audit_logs.filter(action="product_line_deleted").latest("created_at")
        self.assertEqual(entry.created_by, self.admin)

    def test_delete_product_line_rejected_on_non_editable_invoice(self):
        line = invoice_services.add_product_line(self.invoice, self.product, quantity=1)
        invoice_services.add_payment(self.invoice, amount=Decimal("150.00"), payment_method="CASH")
        self.invoice.refresh_from_db()

        with self.assertRaises(InvoiceError):
            invoice_services.delete_product_line(self.invoice, line)


class EditDeleteLineItemApiTests(TestCase):
    """HTTP-level: PATCH/DELETE on the new nested line-item routes."""

    def setUp(self):
        self.admin = User.objects.create_superuser(email="editline_api_admin@test.local", password="pass12345", name="Admin")
        self.client = APIClient()
        self.client.force_authenticate(self.admin)

        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000054")
        self.meter = Meter.objects.create(
            brand="Bajaj", model="Discover 125", cc=125,
            memory_type=Meter.MemoryType.MCU, ic_mcu_model="R5F10CMEL", sales_price="1500.00",
        )
        mc_category = ServiceCategory.objects.create(name=ServiceCategory.Name.MILEAGE_CORRECTION)
        self.mc_service = Service.objects.create(
            category=mc_category, name="Mileage Correction", service_price="500.00",
        )
        self.supplier = Supplier.objects.create(name="ABC Traders", phone="01810000054")
        self.product = Product.objects.create(
            name="Meter Casing", sku="CASING-54", supplier=self.supplier,
            buy_price="50.00", sale_price="150.00", current_stock_quantity=10,
        )
        self.invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)

    def test_patch_service_line_updates_previous_km(self):
        line = invoice_services.add_service_line(
            self.invoice, self.mc_service, meter=self.meter, serial_number="MC-9",
            condition_note="fine", previous_km=15000, current_km=8000,
        )
        response = self.client.patch(
            f"/api/invoices/{self.invoice.id}/service-lines/{line.id}/",
            {"previous_km": 14500}, format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["meter_entry_detail"]["previous_km"], 14500)

    def test_delete_service_line_returns_204(self):
        line = invoice_services.add_service_line(
            self.invoice, self.mc_service, meter=self.meter, serial_number="MC-10",
            condition_note="fine", previous_km=15000, current_km=8000,
        )
        response = self.client.delete(f"/api/invoices/{self.invoice.id}/service-lines/{line.id}/")
        self.assertEqual(response.status_code, 204)
        self.assertFalse(self.invoice.service_lines.filter(pk=line.id).exists())

    def test_patch_product_line_updates_quantity(self):
        line = invoice_services.add_product_line(self.invoice, self.product, quantity=2)
        response = self.client.patch(
            f"/api/invoices/{self.invoice.id}/product-lines/{line.id}/",
            {"quantity": 4}, format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["quantity"], 4)
        self.assertEqual(response.data["line_total"], Decimal("600.00"))

    def test_delete_product_line_returns_204(self):
        line = invoice_services.add_product_line(self.invoice, self.product, quantity=1)
        response = self.client.delete(f"/api/invoices/{self.invoice.id}/product-lines/{line.id}/")
        self.assertEqual(response.status_code, 204)
        self.assertFalse(self.invoice.product_lines.filter(pk=line.id).exists())


class WorkedExampleMergedFlowTests(TestCase):
    """The exact scenario from the spec: add a Mileage Correction service
    with a blank price (defaults to the meter's sales_price), edit that
    line's previous_km, then delete a different product line - checking
    total_amount/due_amount recalculate correctly at every step."""

    def setUp(self):
        self.admin = User.objects.create_superuser(email="worked_example_admin@test.local", password="pass12345", name="Admin")
        self.client = APIClient()
        self.client.force_authenticate(self.admin)

        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000055")
        self.meter = Meter.objects.create(
            brand="Bajaj", model="Discover 125", cc=125,
            memory_type=Meter.MemoryType.MCU, ic_mcu_model="R5F10CMEL", sales_price="1500.00",
        )
        mc_category = ServiceCategory.objects.create(name=ServiceCategory.Name.MILEAGE_CORRECTION)
        self.mc_service = Service.objects.create(
            category=mc_category, name="Mileage Correction", service_price="500.00",
        )
        self.supplier = Supplier.objects.create(name="ABC Traders", phone="01810000055")
        self.product = Product.objects.create(
            name="Meter Casing", sku="CASING-55", supplier=self.supplier,
            buy_price="50.00", sale_price="150.00", current_stock_quantity=10,
        )

    def test_worked_example(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)

        # Step 0: a product line already on the invoice, to be deleted later.
        product_response = self.client.post(
            f"/api/invoices/{invoice.id}/product-lines/",
            {"product": self.product.id, "quantity": 2},
            format="json",
        )
        self.assertEqual(product_response.status_code, 201)
        product_line_id = product_response.data["id"]
        invoice.refresh_from_db()
        self.assertEqual(invoice.total_amount, Decimal("300.00"))  # 2 x 150.00
        self.assertEqual(invoice.outstanding_amount, Decimal("300.00"))

        # Step 1: add the Mileage Correction service, meter picked, price blank.
        service_response = self.client.post(
            f"/api/invoices/{invoice.id}/service-lines/",
            {
                "service": self.mc_service.id, "meter": self.meter.id, "serial_number": "MC-WORKED-1",
                "condition_note": "Casing intact, screen fine", "previous_km": 15000, "current_km": 8000,
            },
            format="json",
        )
        self.assertEqual(service_response.status_code, 201)
        self.assertEqual(service_response.data["price_charged"], "1500.00")  # defaulted from meter.sales_price
        service_line_id = service_response.data["id"]

        invoice.refresh_from_db()
        self.assertEqual(invoice.total_amount, Decimal("1800.00"))  # 300 (product) + 1500 (meter default)
        self.assertEqual(invoice.outstanding_amount, Decimal("1800.00"))

        # Step 2: edit that line's previous_km.
        edit_response = self.client.patch(
            f"/api/invoices/{invoice.id}/service-lines/{service_line_id}/",
            {"previous_km": 14750},
            format="json",
        )
        self.assertEqual(edit_response.status_code, 200)
        self.assertEqual(edit_response.data["meter_entry_detail"]["previous_km"], 14750)
        self.assertEqual(edit_response.data["price_charged"], "1500.00")  # unaffected by the km edit

        invoice.refresh_from_db()
        self.assertEqual(invoice.total_amount, Decimal("1800.00"))  # unchanged - price wasn't edited
        self.assertEqual(invoice.outstanding_amount, Decimal("1800.00"))

        # Step 3: delete the (different) product line.
        delete_response = self.client.delete(f"/api/invoices/{invoice.id}/product-lines/{product_line_id}/")
        self.assertEqual(delete_response.status_code, 204)

        invoice.refresh_from_db()
        self.assertEqual(invoice.total_amount, Decimal("1500.00"))  # product line gone, only the meter service left
        self.assertEqual(invoice.outstanding_amount, Decimal("1500.00"))
        self.assertEqual(invoice.paid_amount, Decimal("0.00"))

        self.product.refresh_from_db()
        self.assertEqual(self.product.current_stock_quantity, 10)  # 2 units restored

        # Every step logged to the audit trail.
        actions = list(invoice.audit_logs.order_by("created_at").values_list("action", flat=True))
        self.assertEqual(
            actions,
            [
                "invoice_created", "product_line_added", "meter_entry_added", "service_line_added",
                "service_line_updated", "product_line_deleted",
            ],
        )


# =====================================================================================
# Phase 5: nested meter structure, product_used/product_price, added_date, created_date,
# replace, force-close/waived_amount, and editing a Paid invoice with a reason.
# =====================================================================================

class NestedMeterStructureTests(TestCase):
    """Rule 1: a mileage-correction line's meter lives entirely inside its
    service_lines entry (meter_entry_detail) - there is no top-level meter
    list/section anywhere, internal or public."""

    def setUp(self):
        self.admin = User.objects.create_superuser(email="nested_admin@test.local", password="pass12345", name="Admin")
        self.client = APIClient()
        self.client.force_authenticate(self.admin)

        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000060")
        self.meter = Meter.objects.create(
            brand="Bajaj", model="Discover 125", cc=125,
            memory_type=Meter.MemoryType.MCU, ic_mcu_model="R5F10CMEL", sales_price="1500.00",
        )
        mc_category = ServiceCategory.objects.create(name=ServiceCategory.Name.MILEAGE_CORRECTION)
        self.mc_service = Service.objects.create(category=mc_category, name="Mileage Correction", service_price="500.00")
        self.invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)

    def test_invoice_detail_has_no_top_level_meter_entries_key(self):
        invoice_services.add_service_line(
            self.invoice, self.mc_service, meter=self.meter, serial_number="MC-1",
            condition_note="fine", previous_km=15000, current_km=8000,
        )
        response = self.client.get(f"/api/invoices/{self.invoice.id}/")
        self.assertEqual(response.status_code, 200)
        self.assertNotIn("meter_entries", response.data)

    def test_meter_entry_detail_exposes_brand_model_cc(self):
        invoice_services.add_service_line(
            self.invoice, self.mc_service, meter=self.meter, serial_number="MC-2",
            condition_note="fine", previous_km=15000, current_km=8000,
        )
        response = self.client.get(f"/api/invoices/{self.invoice.id}/")
        entry = response.data["service_lines"][0]["meter_entry_detail"]
        self.assertEqual(entry["meter_brand"], "Bajaj")
        self.assertEqual(entry["meter_model"], "Discover 125")
        self.assertEqual(entry["meter_cc"], 125)
        self.assertEqual(entry["serial_number"], "MC-2")
        self.assertEqual(entry["previous_km"], 15000)
        self.assertEqual(entry["current_km"], 8000)
        self.assertEqual(entry["condition_note"], "fine")

    def test_regular_service_line_has_null_meter_entry_detail(self):
        repair_category = ServiceCategory.objects.create(name=ServiceCategory.Name.METER_REPAIR)
        repair_service = Service.objects.create(category=repair_category, name="Repair", service_price="300.00")
        invoice_services.add_service_line(self.invoice, repair_service, price_charged=Decimal("300.00"))

        response = self.client.get(f"/api/invoices/{self.invoice.id}/")
        self.assertIsNone(response.data["service_lines"][0]["meter_entry_detail"])
        self.assertIsNone(response.data["service_lines"][0]["meter_entry"])


class OptionalSerialNumberTests(TestCase):
    """Rule 2: InvoiceMeterEntry.serial_number is now optional."""

    def setUp(self):
        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000061")
        self.meter = Meter.objects.create(
            brand="Bajaj", model="Discover 125", cc=125,
            memory_type=Meter.MemoryType.MCU, ic_mcu_model="R5F10CMEL", sales_price="1500.00",
        )
        mc_category = ServiceCategory.objects.create(name=ServiceCategory.Name.MILEAGE_CORRECTION)
        self.mc_service = Service.objects.create(category=mc_category, name="Mileage Correction", service_price="500.00")
        self.invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)

    def test_service_line_creates_meter_entry_without_serial_number(self):
        line = invoice_services.add_service_line(
            self.invoice, self.mc_service, meter=self.meter,
            condition_note="fine", previous_km=15000, current_km=8000,
        )
        self.assertIsNone(line.meter_entry.serial_number)


class CombinationRepairProductTests(TestCase):
    """Rule 7: service_charge (price_charged) and product_price are two
    independent, independently-editable amounts on an InvoiceServiceLine."""

    def setUp(self):
        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000062")
        self.supplier = Supplier.objects.create(name="ABC Traders", phone="01810000062")
        display_category = ServiceCategory.objects.create(name=ServiceCategory.Name.DISPLAY_REPAIR)
        self.display_service = Service.objects.create(
            category=display_category, name="Display Repair", service_price="200.00",
        )
        self.polarizer = Product.objects.create(
            name="Polarizer Paper", sku="POLAR-1", supplier=self.supplier,
            buy_price="20.00", sale_price="80.00", current_stock_quantity=10,
        )
        self.panel = Product.objects.create(
            name="Display Panel", sku="PANEL-1", supplier=self.supplier,
            buy_price="300.00", sale_price="900.00", current_stock_quantity=5,
        )
        self.invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)

    def test_product_price_defaults_from_product_used_and_decrements_stock(self):
        line = invoice_services.add_service_line(
            self.invoice, self.display_service, product_used=self.polarizer,
        )
        line.refresh_from_db()
        self.assertEqual(line.price_charged, Decimal("200.00"))  # service_charge default
        self.assertEqual(line.product_price, Decimal("80.00"))  # product default
        self.assertEqual(line.line_total, Decimal("280.00"))

        self.polarizer.refresh_from_db()
        self.assertEqual(self.polarizer.current_stock_quantity, 9)

    def test_both_amounts_freely_overridable_independently(self):
        line = invoice_services.add_service_line(
            self.invoice, self.display_service, product_used=self.panel,
            price_charged=Decimal("250.00"), product_price=Decimal("850.00"),
        )
        self.assertEqual(line.price_charged, Decimal("250.00"))
        self.assertEqual(line.product_price, Decimal("850.00"))

    def test_no_product_used_defaults_product_price_to_zero(self):
        line = invoice_services.add_service_line(self.invoice, self.display_service)
        self.assertEqual(line.product_price, Decimal("0"))

    def test_gross_total_includes_both_amounts(self):
        invoice_services.add_service_line(
            self.invoice, self.display_service, product_used=self.polarizer,
        )
        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.total_amount, Decimal("280.00"))  # 200 + 80

    def test_replacing_product_used_swaps_stock_and_redefaults_price(self):
        line = invoice_services.add_service_line(
            self.invoice, self.display_service, product_used=self.polarizer,
        )
        self.polarizer.refresh_from_db()
        self.assertEqual(self.polarizer.current_stock_quantity, 9)

        invoice_services.update_service_line(self.invoice, line, product_used=self.panel)

        self.polarizer.refresh_from_db()
        self.panel.refresh_from_db()
        self.assertEqual(self.polarizer.current_stock_quantity, 10)  # restored
        self.assertEqual(self.panel.current_stock_quantity, 4)  # deducted

        line.refresh_from_db()
        self.assertEqual(line.product_used, self.panel)
        self.assertEqual(line.product_price, Decimal("900.00"))  # re-defaulted

    def test_deleting_line_restores_product_used_stock(self):
        line = invoice_services.add_service_line(
            self.invoice, self.display_service, product_used=self.panel,
        )
        self.panel.refresh_from_db()
        self.assertEqual(self.panel.current_stock_quantity, 4)

        invoice_services.delete_service_line(self.invoice, line)

        self.panel.refresh_from_db()
        self.assertEqual(self.panel.current_stock_quantity, 5)


class ServiceLineReplaceTests(TestCase):
    """Rule 8: `service` is a field on the edit endpoint - replacing which
    service a line bills is an update, not a delete+recreate."""

    def setUp(self):
        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000063")
        self.meter = Meter.objects.create(
            brand="Bajaj", model="Discover 125", cc=125,
            memory_type=Meter.MemoryType.MCU, ic_mcu_model="R5F10CMEL", sales_price="1500.00",
        )
        mc_category = ServiceCategory.objects.create(name=ServiceCategory.Name.MILEAGE_CORRECTION)
        self.mc_service = Service.objects.create(category=mc_category, name="Mileage Correction", service_price="500.00")
        repair_category = ServiceCategory.objects.create(name=ServiceCategory.Name.METER_REPAIR)
        self.repair_service = Service.objects.create(category=repair_category, name="Repair", service_price="300.00")
        self.other_repair_service = Service.objects.create(category=repair_category, name="Other Repair", service_price="250.00")
        self.invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)

    def test_replace_regular_service_with_another_regular_service(self):
        line = invoice_services.add_service_line(self.invoice, self.repair_service, price_charged=Decimal("300.00"))
        invoice_services.update_service_line(self.invoice, line, service=self.other_repair_service)

        line.refresh_from_db()
        self.assertEqual(line.service, self.other_repair_service)
        self.assertEqual(line.price_charged, Decimal("300.00"))  # untouched unless explicitly changed

    def test_replace_regular_service_with_mileage_correction_creates_meter_entry(self):
        line = invoice_services.add_service_line(self.invoice, self.repair_service, price_charged=Decimal("300.00"))

        invoice_services.update_service_line(
            self.invoice, line, service=self.mc_service, meter=self.meter,
            serial_number="R-1", condition_note="fine", previous_km=1000, current_km=500,
        )

        line.refresh_from_db()
        self.assertEqual(line.service, self.mc_service)
        self.assertIsNotNone(line.meter_entry)
        self.assertEqual(line.meter_entry.meter, self.meter)

    def test_replace_mileage_correction_with_regular_service_detaches_and_removes_meter_entry(self):
        line = invoice_services.add_service_line(
            self.invoice, self.mc_service, meter=self.meter, serial_number="R-2",
            condition_note="fine", previous_km=1000, current_km=500,
        )
        entry_id = line.meter_entry_id

        invoice_services.update_service_line(self.invoice, line, service=self.repair_service)

        line.refresh_from_db()
        self.assertEqual(line.service, self.repair_service)
        self.assertIsNone(line.meter_entry)
        self.assertFalse(self.invoice.meter_entries.filter(pk=entry_id).exists())

    def test_replace_mileage_correction_keeps_meter_entry_if_shared_with_another_line(self):
        mc_line = invoice_services.add_service_line(
            self.invoice, self.mc_service, meter=self.meter, serial_number="R-3",
            condition_note="fine", previous_km=1000, current_km=500,
        )
        entry = mc_line.meter_entry
        other_line = invoice_services.add_service_line(
            self.invoice, self.repair_service, meter_entry=entry, price_charged=Decimal("300.00"),
        )

        invoice_services.update_service_line(self.invoice, mc_line, service=self.other_repair_service)

        self.assertTrue(self.invoice.meter_entries.filter(pk=entry.id).exists())
        other_line.refresh_from_db()
        self.assertEqual(other_line.meter_entry_id, entry.id)


class ProductLineReplaceTests(TestCase):
    """Rule 8: `product` is a field on the edit endpoint - replacing which
    product a line is, is an update, not a delete+recreate."""

    def setUp(self):
        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000064")
        self.supplier = Supplier.objects.create(name="ABC Traders", phone="01810000064")
        self.product_a = Product.objects.create(
            name="Meter Casing", sku="CASING-64", supplier=self.supplier,
            buy_price="50.00", sale_price="150.00", current_stock_quantity=10,
        )
        self.product_b = Product.objects.create(
            name="LED Strip", sku="LED-64", supplier=self.supplier,
            buy_price="10.00", sale_price="40.00", current_stock_quantity=20,
        )
        self.invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)

    def test_replace_product_swaps_stock_and_redefaults_price(self):
        line = invoice_services.add_product_line(self.invoice, self.product_a, quantity=2)
        self.product_a.refresh_from_db()
        self.assertEqual(self.product_a.current_stock_quantity, 8)

        invoice_services.update_product_line(self.invoice, line, product=self.product_b)

        self.product_a.refresh_from_db()
        self.product_b.refresh_from_db()
        self.assertEqual(self.product_a.current_stock_quantity, 10)  # fully restored
        self.assertEqual(self.product_b.current_stock_quantity, 18)  # 2 deducted

        line.refresh_from_db()
        self.assertEqual(line.product, self.product_b)
        self.assertEqual(line.price_charged, Decimal("40.00"))  # re-defaulted
        self.assertEqual(line.quantity, 2)

    def test_replace_product_with_new_quantity_in_same_call(self):
        line = invoice_services.add_product_line(self.invoice, self.product_a, quantity=1)
        invoice_services.update_product_line(self.invoice, line, product=self.product_b, quantity=3)

        self.product_a.refresh_from_db()
        self.product_b.refresh_from_db()
        self.assertEqual(self.product_a.current_stock_quantity, 10)
        self.assertEqual(self.product_b.current_stock_quantity, 17)

        line.refresh_from_db()
        self.assertEqual(line.quantity, 3)

    def test_replace_product_rejects_insufficient_stock(self):
        line = invoice_services.add_product_line(self.invoice, self.product_a, quantity=1)
        with self.assertRaises(InvoiceError):
            invoice_services.update_product_line(self.invoice, line, product=self.product_b, quantity=999)


class InvoiceCreatedDateAndAddedDateTests(TestCase):
    """Rules 3 & 4: editable created_date (Admin only, audit logged) on
    Invoice, and added_date on service/product lines."""

    def setUp(self):
        self.admin = User.objects.create_superuser(email="dates_admin@test.local", password="pass12345", name="Admin")
        self.staff = User.objects.create_user(email="dates_staff@test.local", password="pass12345", name="Staff")
        self.admin_client = APIClient()
        self.admin_client.force_authenticate(self.admin)
        self.staff_client = APIClient()
        self.staff_client.force_authenticate(self.staff)

        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000065")
        category = ServiceCategory.objects.create(name=ServiceCategory.Name.METER_REPAIR)
        self.service = Service.objects.create(category=category, name="Repair", service_price="300.00")
        self.supplier = Supplier.objects.create(name="ABC Traders", phone="01810000065")
        self.product = Product.objects.create(
            name="Meter Casing", sku="CASING-65", supplier=self.supplier,
            buy_price="50.00", sale_price="150.00", current_stock_quantity=10,
        )
        self.invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)

    def test_created_date_defaults_to_today(self):
        self.assertEqual(self.invoice.created_date, date.today())

    def test_admin_can_update_created_date_and_it_is_logged(self):
        new_date = date(2026, 1, 5)
        response = self.admin_client.post(
            f"/api/invoices/{self.invoice.id}/created-date/", {"created_date": str(new_date)}, format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.created_date, new_date)

        entry = self.invoice.audit_logs.filter(action="invoice_date_updated").latest("created_at")
        self.assertIn(str(new_date), entry.description)
        self.assertEqual(entry.created_by, self.admin)

    def test_staff_cannot_update_created_date(self):
        response = self.staff_client.post(
            f"/api/invoices/{self.invoice.id}/created-date/", {"created_date": "2026-01-05"}, format="json",
        )
        self.assertEqual(response.status_code, 403)

    def test_service_line_added_date_defaults_to_today_and_is_editable(self):
        line = invoice_services.add_service_line(self.invoice, self.service, price_charged=Decimal("300.00"))
        self.assertEqual(line.added_date, date.today())

        invoice_services.update_service_line(self.invoice, line, added_date=date(2026, 2, 1))
        line.refresh_from_db()
        self.assertEqual(line.added_date, date(2026, 2, 1))

    def test_product_line_added_date_defaults_to_today_and_is_editable(self):
        line = invoice_services.add_product_line(self.invoice, self.product, quantity=1)
        self.assertEqual(line.added_date, date.today())

        invoice_services.update_product_line(self.invoice, line, added_date=date(2026, 2, 2))
        line.refresh_from_db()
        self.assertEqual(line.added_date, date(2026, 2, 2))


class ForceCloseInvoiceTests(TestCase):
    """Rules 11 & 12: force-close write-off records waived_amount
    (separate from discount_amount) and still feeds the red-list check."""

    def setUp(self):
        self.admin = User.objects.create_superuser(email="forceclose_admin@test.local", password="pass12345", name="Admin")
        self.staff = User.objects.create_user(email="forceclose_staff@test.local", password="pass12345", name="Staff")
        self.admin_client = APIClient()
        self.admin_client.force_authenticate(self.admin)
        self.staff_client = APIClient()
        self.staff_client.force_authenticate(self.staff)

        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000066")
        category = ServiceCategory.objects.create(name=ServiceCategory.Name.METER_REPAIR)
        self.service = Service.objects.create(category=category, name="Repair", service_price="1200.00")

    def _open_invoice_with_partial_payment(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("1200.00"))
        invoice_services.add_payment(invoice, amount=Decimal("1000.00"), payment_method="CASH")
        invoice.refresh_from_db()
        return invoice

    # --- worked example (b): force-close with a 200 BDT shortfall -------------

    def test_worked_example_force_close_200_shortfall_records_waived_amount(self):
        invoice = self._open_invoice_with_partial_payment()
        self.assertEqual(invoice.status, Invoice.Status.PARTIAL)
        self.assertEqual(invoice.outstanding_amount, Decimal("200.00"))

        response = self.admin_client.post(
            f"/api/invoices/{invoice.id}/force-close/",
            {"note": "Customer paid 1000 of 1200 and refuses to pay the rest - accepted as final."},
            format="json",
        )
        self.assertEqual(response.status_code, 200)

        invoice.refresh_from_db()
        self.assertEqual(invoice.status, Invoice.Status.PAID)
        self.assertEqual(invoice.waived_amount, Decimal("200.00"))
        self.assertEqual(invoice.discount_amount, Decimal("0.00"))  # never conflated with a discount
        self.assertEqual(invoice.total_amount, Decimal("1000.00"))  # 1200 - 0 discount - 200 waived
        self.assertEqual(invoice.outstanding_amount, Decimal("0.00"))
        self.assertTrue(invoice.had_shortfall)

        entry = invoice.audit_logs.filter(action="invoice_force_closed").latest("created_at")
        self.assertIn("200.00", entry.description)
        self.assertEqual(entry.created_by, self.admin)

    def test_force_close_requires_non_blank_note(self):
        invoice = self._open_invoice_with_partial_payment()
        with self.assertRaises(InvoiceError):
            invoice_services.force_close_invoice(invoice, note="   ")

    def test_force_close_rejects_invoice_with_no_outstanding_balance(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("1200.00"))
        invoice_services.add_payment(invoice, amount=Decimal("1200.00"), payment_method="CASH")
        invoice.refresh_from_db()
        with self.assertRaises(InvoiceError):
            invoice_services.force_close_invoice(invoice, note="nothing to waive")

    def test_staff_cannot_force_close(self):
        invoice = self._open_invoice_with_partial_payment()
        response = self.staff_client.post(
            f"/api/invoices/{invoice.id}/force-close/", {"note": "trying anyway"}, format="json",
        )
        self.assertEqual(response.status_code, 403)

    def test_force_close_redlists_customer_after_two_consecutive_waived_invoices(self):
        invoice1 = self._open_invoice_with_partial_payment()
        invoice_services.force_close_invoice(invoice1, note="first shortfall", user=self.admin)
        self.customer.refresh_from_db()
        self.assertFalse(self.customer.is_red_listed)

        invoice2 = self._open_invoice_with_partial_payment()
        invoice_services.force_close_invoice(invoice2, note="second shortfall", user=self.admin)
        self.customer.refresh_from_db()
        self.assertTrue(self.customer.is_red_listed)

    def test_force_close_from_unpaid_waives_full_amount_and_still_shortfalls(self):
        """Even an invoice that never received a single payment (never
        Partial Paid) counts as a shortfall once force-closed."""
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("1200.00"))
        invoice.refresh_from_db()
        self.assertEqual(invoice.status, Invoice.Status.UNPAID)

        invoice_services.force_close_invoice(invoice, note="customer vanished", user=self.admin)
        invoice.refresh_from_db()
        self.assertEqual(invoice.status, Invoice.Status.PAID)
        self.assertEqual(invoice.waived_amount, Decimal("1200.00"))
        self.assertTrue(invoice.had_shortfall)


class EditAfterPaidTests(TestCase):
    """Rule 14: Admin + mandatory reason can edit line items/payments/dates
    on a Paid (or force-closed) invoice, fully recalculating and logging."""

    def setUp(self):
        self.admin = User.objects.create_superuser(email="editpaid_admin@test.local", password="pass12345", name="Admin")
        self.staff = User.objects.create_user(email="editpaid_staff@test.local", password="pass12345", name="Staff")
        self.admin_client = APIClient()
        self.admin_client.force_authenticate(self.admin)
        self.staff_client = APIClient()
        self.staff_client.force_authenticate(self.staff)

        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000067")
        category = ServiceCategory.objects.create(name=ServiceCategory.Name.METER_REPAIR)
        self.service = Service.objects.create(category=category, name="Repair", service_price="300.00")
        self.invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        self.line = invoice_services.add_service_line(self.invoice, self.service, price_charged=Decimal("300.00"))
        invoice_services.add_payment(self.invoice, amount=Decimal("300.00"), payment_method="CASH")
        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.status, Invoice.Status.PAID)

    # --- worked example (c): edit one line item on an already-Paid invoice ----

    def test_worked_example_edit_line_item_on_paid_invoice_recalculates_and_logs(self):
        response = self.admin_client.patch(
            f"/api/invoices/{self.invoice.id}/service-lines/{self.line.id}/",
            {"price_charged": "450.00", "reason": "Under-billed by mistake, correcting after the fact."},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["price_charged"], "450.00")

        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.total_amount, Decimal("450.00"))
        self.assertEqual(self.invoice.paid_amount, Decimal("300.00"))
        self.assertEqual(self.invoice.outstanding_amount, Decimal("150.00"))
        # Recalculation flips it back to Partial Paid - it genuinely owes more now.
        self.assertEqual(self.invoice.status, Invoice.Status.PARTIAL)

        actions = list(self.invoice.audit_logs.order_by("created_at").values_list("action", flat=True))
        self.assertIn("service_line_updated", actions)
        self.assertIn("invoice_force_edited", actions)

        forced_entry = self.invoice.audit_logs.filter(action="invoice_force_edited").latest("created_at")
        self.assertIn("Under-billed by mistake", forced_entry.description)
        self.assertEqual(forced_entry.created_by, self.admin)

    def test_edit_paid_invoice_rejected_without_reason(self):
        response = self.admin_client.patch(
            f"/api/invoices/{self.invoice.id}/service-lines/{self.line.id}/",
            {"price_charged": "450.00"}, format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.total_amount, Decimal("300.00"))  # unchanged

    def test_staff_cannot_edit_paid_invoice_even_with_reason(self):
        response = self.staff_client.patch(
            f"/api/invoices/{self.invoice.id}/service-lines/{self.line.id}/",
            {"price_charged": "450.00", "reason": "trying anyway"}, format="json",
        )
        self.assertEqual(response.status_code, 403)

    def test_delete_service_line_on_paid_invoice_requires_reason_and_admin(self):
        response = self.admin_client.delete(
            f"/api/invoices/{self.invoice.id}/service-lines/{self.line.id}/", data={}, format="json",
        )
        self.assertEqual(response.status_code, 400)

        response = self.admin_client.delete(
            f"/api/invoices/{self.invoice.id}/service-lines/{self.line.id}/",
            data={"reason": "Duplicate line, removing after the fact."}, format="json",
        )
        self.assertEqual(response.status_code, 204)
        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.total_amount, Decimal("0.00"))

    def test_cancelled_invoice_cannot_be_edited_even_with_reason(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        line = invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("300.00"))
        invoice_services.cancel_invoice(invoice)

        with self.assertRaises(InvoiceError):
            invoice_services.update_service_line(invoice, line, price_charged=Decimal("500.00"), reason="anything")


class PaymentEditDeleteTests(TestCase):
    """update_payment/delete_payment (rule 14's "payments" case)."""

    def setUp(self):
        self.admin = User.objects.create_superuser(email="payedit_admin@test.local", password="pass12345", name="Admin")
        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000068")
        category = ServiceCategory.objects.create(name=ServiceCategory.Name.METER_REPAIR)
        self.service = Service.objects.create(category=category, name="Repair", service_price="1000.00")
        self.invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(self.invoice, self.service, price_charged=Decimal("1000.00"))

    def test_update_payment_amount_recalculates_status(self):
        payment = invoice_services.add_payment(self.invoice, amount=Decimal("400.00"), payment_method="CASH")
        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.status, Invoice.Status.PARTIAL)

        invoice_services.update_payment(self.invoice, payment, amount=Decimal("1000.00"), user=self.admin)
        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.status, Invoice.Status.PAID)
        self.assertEqual(self.invoice.paid_amount, Decimal("1000.00"))

    def test_update_payment_on_paid_invoice_requires_reason(self):
        payment = invoice_services.add_payment(self.invoice, amount=Decimal("1000.00"), payment_method="CASH")
        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.status, Invoice.Status.PAID)

        with self.assertRaises(InvoiceError):
            invoice_services.update_payment(self.invoice, payment, amount=Decimal("900.00"))

        invoice_services.update_payment(self.invoice, payment, amount=Decimal("900.00"), reason="Recorded wrong amount.")
        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.paid_amount, Decimal("900.00"))
        self.assertEqual(self.invoice.status, Invoice.Status.PARTIAL)

        entry = self.invoice.audit_logs.filter(action="invoice_force_edited").latest("created_at")
        self.assertIn("Recorded wrong amount.", entry.description)

    def test_delete_payment_recalculates_totals(self):
        payment = invoice_services.add_payment(self.invoice, amount=Decimal("1000.00"), payment_method="CASH")
        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.status, Invoice.Status.PAID)

        invoice_services.delete_payment(self.invoice, payment, reason="Payment was never actually received.")
        self.invoice.refresh_from_db()
        self.assertEqual(self.invoice.paid_amount, Decimal("0.00"))
        self.assertEqual(self.invoice.status, Invoice.Status.UNPAID)
