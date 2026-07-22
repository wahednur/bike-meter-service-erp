from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

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
