from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from apps.shop_profile.models import ShopProfile

User = get_user_model()


class ShopProfileModelTests(TestCase):
    def test_load_creates_and_pins_singleton(self):
        profile = ShopProfile.load()
        self.assertEqual(profile.pk, 1)
        self.assertEqual(profile.shop_name, "Nurain Motorcycle Meter Service Center")
        self.assertEqual(profile.invoice_footer_text, "Development by Wahed Nur")

        again = ShopProfile.load()
        self.assertEqual(again.pk, profile.pk)
        self.assertEqual(ShopProfile.objects.count(), 1)

    def test_delete_is_a_no_op(self):
        profile = ShopProfile.load()
        profile.delete()
        self.assertTrue(ShopProfile.objects.filter(pk=1).exists())


class ShopProfileApiTests(TestCase):
    def setUp(self):
        self.admin = User.objects.create_superuser(email="shop_admin@test.local", password="pass12345", name="Admin")
        self.staff = User.objects.create_user(
            email="shop_staff@test.local", phone="01700000099", password="pass12345",
            name="Staff", role=User.Role.STAFF,
        )
        self.admin_client = APIClient()
        self.admin_client.force_authenticate(self.admin)
        self.staff_client = APIClient()
        self.staff_client.force_authenticate(self.staff)

    def test_admin_can_get_and_update(self):
        response = self.admin_client.get("/api/shop-profile/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["shop_name"], "Nurain Motorcycle Meter Service Center")

        response = self.admin_client.patch("/api/shop-profile/", {"phone": "01911000000"}, format="json")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["phone"], "01911000000")

        # Still a single row after the update.
        self.assertEqual(ShopProfile.objects.count(), 1)

    def test_staff_can_read_but_not_update(self):
        response = self.staff_client.get("/api/shop-profile/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["shop_name"], "Nurain Motorcycle Meter Service Center")

        response = self.staff_client.patch("/api/shop-profile/", {"phone": "01911000000"}, format="json")
        self.assertEqual(response.status_code, 403)

    def test_unauthenticated_rejected(self):
        response = APIClient().get("/api/shop-profile/")
        self.assertEqual(response.status_code, 401)
