from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from apps.customers.models import Customer
from apps.invoices import services as invoice_services
from apps.meters.models import Meter

User = get_user_model()


class MeterDescriptionApiTests(TestCase):
    def setUp(self):
        self.admin = User.objects.create_superuser(email="meter_desc_admin@test.local", password="pass12345", name="Admin")
        self.client = APIClient()
        self.client.force_authenticate(self.admin)

    def test_description_is_optional_and_round_trips(self):
        response = self.client.post(
            "/api/meters/",
            {
                "brand": "Bajaj", "model": "Discover 125", "cc": 125,
                "memory_type": "MCU", "ic_mcu_model": "R5F10CMEL", "sales_price": "1500.00",
                "description": "Common 5-gear model, EEPROM variant also exists.",
            },
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["description"], "Common 5-gear model, EEPROM variant also exists.")

        meter_id = response.data["id"]
        list_response = self.client.get("/api/meters/")
        row = next(r for r in list_response.data if r["id"] == meter_id)
        self.assertEqual(row["description"], "Common 5-gear model, EEPROM variant also exists.")

    def test_description_defaults_to_blank(self):
        meter = Meter.objects.create(
            brand="Yamaha", model="FZ V2", cc=150,
            memory_type=Meter.MemoryType.EEPROM, ic_mcu_model="93C66", sales_price="1800.00",
        )
        response = self.client.get(f"/api/meters/{meter.id}/")
        self.assertEqual(response.data["description"], "")


class MeterServiceHistoryApiTests(TestCase):
    """GET /api/meters/{id}/service-history/ - the itemized visit list
    behind the (already-existing) aggregated /stats/ endpoint, added so the
    frontend meter detail page can show each visit's condition_note tags."""

    def setUp(self):
        self.admin = User.objects.create_superuser(email="meter_history_admin@test.local", password="pass12345", name="Admin")
        self.client = APIClient()
        self.client.force_authenticate(self.admin)

        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000090")
        self.meter = Meter.objects.create(
            brand="Bajaj", model="Discover 125", cc=125,
            memory_type=Meter.MemoryType.MCU, ic_mcu_model="R5F10CMEL", sales_price="1500.00",
        )

    def test_returns_one_row_per_visit_with_condition_tags_newest_first(self):
        # Two visits for the same meter, on the same invoice - service_date
        # is auto_now_add, so the second entry created is the newer one.
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        older_entry = invoice_services.add_meter_entry(
            invoice, self.meter, serial_number="MCU-090", condition_note=["Water Damage"],
        )
        newer_entry = invoice_services.add_meter_entry(
            invoice, self.meter, serial_number="MCU-091",
            condition_note=["Power IC Problem", "Display Problem"],
        )

        response = self.client.get(f"/api/meters/{self.meter.id}/service-history/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual([row["id"] for row in response.data], [newer_entry.id, older_entry.id])

        newest = response.data[0]
        self.assertEqual(newest["condition_note"], ["Power IC Problem", "Display Problem"])
        self.assertEqual(newest["invoice_id"], invoice.id)
        self.assertEqual(newest["customer_name"], "Karim Motors")

    def test_empty_when_meter_never_serviced(self):
        response = self.client.get(f"/api/meters/{self.meter.id}/service-history/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, [])
