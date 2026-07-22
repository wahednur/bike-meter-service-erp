import json

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from rest_framework.test import APIClient

from apps.customers.models import Customer

User = get_user_model()


def make_csv(content):
    return SimpleUploadedFile("customers.csv", content.encode("utf-8"), content_type="text/csv")


class CustomerDescriptionApiTests(TestCase):
    def setUp(self):
        self.admin = User.objects.create_superuser(email="customer_desc_admin@test.local", password="pass12345", name="Admin")
        self.client = APIClient()
        self.client.force_authenticate(self.admin)

    def test_description_is_optional_and_round_trips(self):
        response = self.client.post(
            "/api/customers/",
            {"name": "Karim Motors", "phone": "01710000060", "description": "Regular walk-in, prefers cash."},
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["description"], "Regular walk-in, prefers cash.")

        customer_id = response.data["id"]
        detail_response = self.client.get(f"/api/customers/{customer_id}/")
        self.assertEqual(detail_response.data["description"], "Regular walk-in, prefers cash.")

    def test_description_defaults_to_blank(self):
        customer = Customer.objects.create(name="Jasim Uddin", phone="01710000061")
        response = self.client.get(f"/api/customers/{customer.id}/")
        self.assertEqual(response.data["description"], "")


class CustomerCsvImportApiTests(TestCase):
    def setUp(self):
        self.admin = User.objects.create_superuser(email="csv_import_admin@test.local", password="pass12345", name="Admin")
        self.client = APIClient()
        self.client.force_authenticate(self.admin)

    def test_preview_returns_headers_and_first_five_rows_without_creating(self):
        rows = "\n".join(f"Row {i} Name,0171000{i:04d},addr {i}" for i in range(7))
        content = "Customer Name,Mobile,Address\n" + rows
        response = self.client.post(
            "/api/customers/import/preview/",
            {"file": make_csv(content)},
            format="multipart",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["headers"], ["Customer Name", "Mobile", "Address"])
        self.assertEqual(len(response.data["rows"]), 5)
        self.assertEqual(response.data["rows"][0]["Customer Name"], "Row 0 Name")
        self.assertEqual(Customer.objects.count(), 0)

    def test_import_creates_customers_using_mapping_and_ignores_extra_columns(self):
        content = (
            "Customer Name,Mobile,Notes\n"
            "Karim Motors,01710000070,ignore me\n"
            "Rahim Traders,01710000071,ignore this too\n"
        )
        mapping = json.dumps({"name": "Customer Name", "phone": "Mobile"})
        response = self.client.post(
            "/api/customers/import/",
            {"file": make_csv(content), "column_mapping": mapping},
            format="multipart",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["total"], 2)
        self.assertEqual(response.data["created_count"], 2)
        self.assertEqual(response.data["skipped_count"], 0)
        self.assertEqual(response.data["failed_count"], 0)
        self.assertTrue(Customer.objects.filter(phone="01710000070", name="Karim Motors").exists())

    def test_import_skips_duplicate_phone_and_reports_it(self):
        Customer.objects.create(name="Existing Co", phone="01710000080")
        content = "Name,Phone\nNew Name,01710000080\n"
        mapping = json.dumps({"name": "Name", "phone": "Phone"})
        response = self.client.post(
            "/api/customers/import/",
            {"file": make_csv(content), "column_mapping": mapping},
            format="multipart",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["created_count"], 0)
        self.assertEqual(response.data["skipped_count"], 1)
        self.assertEqual(response.data["skipped"][0]["phone"], "01710000080")
        self.assertEqual(Customer.objects.filter(phone="01710000080").count(), 1)

    def test_import_fails_row_missing_name_or_phone(self):
        content = "Name,Phone\n,01710000090\nGood Name,\n"
        mapping = json.dumps({"name": "Name", "phone": "Phone"})
        response = self.client.post(
            "/api/customers/import/",
            {"file": make_csv(content), "column_mapping": mapping},
            format="multipart",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["created_count"], 0)
        self.assertEqual(response.data["failed_count"], 2)
        self.assertEqual(response.data["failed"][0]["row"], 2)
        self.assertEqual(response.data["failed"][1]["row"], 3)

    def test_import_requires_name_and_phone_in_mapping(self):
        content = "Name,Phone\nSome Name,0171\n"
        mapping = json.dumps({"name": "Name"})
        response = self.client.post(
            "/api/customers/import/",
            {"file": make_csv(content), "column_mapping": mapping},
            format="multipart",
        )
        self.assertEqual(response.status_code, 400)
