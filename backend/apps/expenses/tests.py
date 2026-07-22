from datetime import date
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from apps.expenses.models import Expense

User = get_user_model()


class ExpenseModelTests(TestCase):
    def test_str_includes_category_display_and_amount(self):
        expense = Expense.objects.create(category=Expense.Category.RENT, amount=Decimal("5000.00"), date=date(2026, 7, 1))
        self.assertIn("Rent", str(expense))
        self.assertIn("5000.00", str(expense))


class ExpenseApiTests(TestCase):
    def setUp(self):
        self.admin = User.objects.create_superuser(email="expense_admin@test.local", password="pass12345", name="Admin")
        self.client = APIClient()
        self.client.force_authenticate(self.admin)

    def test_create_and_list_expense(self):
        response = self.client.post(
            "/api/expenses/",
            {"category": "ELECTRICITY", "amount": "1200.50", "date": "2026-07-10", "note": "July bill"},
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["category_display"], "Electricity")
        self.assertEqual(response.data["created_by"], self.admin.id)

        response = self.client.get("/api/expenses/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)

    def test_list_filters_by_date_range(self):
        Expense.objects.create(category=Expense.Category.RENT, amount=Decimal("5000"), date=date(2026, 6, 1))
        Expense.objects.create(category=Expense.Category.TRANSPORT, amount=Decimal("300"), date=date(2026, 7, 15))

        response = self.client.get("/api/expenses/?date_from=2026-07-01&date_to=2026-07-31")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["category"], "TRANSPORT")

    def test_soft_delete_excludes_from_list(self):
        expense = Expense.objects.create(category=Expense.Category.MISC, amount=Decimal("100"), date=date(2026, 7, 1))
        response = self.client.delete(f"/api/expenses/{expense.id}/")
        self.assertEqual(response.status_code, 204)

        response = self.client.get("/api/expenses/")
        self.assertEqual(len(response.data), 0)
        self.assertTrue(Expense.all_objects.get(id=expense.id).is_deleted)
