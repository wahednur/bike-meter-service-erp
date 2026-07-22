import shutil
import tempfile
from datetime import date
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from apps.products import services as product_services
from apps.products.models import Product, Purchase, PurchaseLineItem
from apps.suppliers.models import Supplier

User = get_user_model()

# 1x1 transparent GIF - the smallest valid image Pillow/ImageField will accept.
MINIMAL_GIF = (
    b"GIF89a\x01\x00\x01\x00\x80\x00\x00\x00\x00\x00\xff\xff\xff!\xf9\x04"
    b"\x01\x00\x00\x00\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x02D\x01\x00;"
)

# Uploaded test images must never land in the real backend/media/ directory -
# override MEDIA_ROOT to a throwaway temp dir for the whole test run and
# clean it up afterward (see tearDownModule below).
_TEST_MEDIA_ROOT = tempfile.mkdtemp(prefix="bike_meter_erp_test_media_")


def tearDownModule():
    shutil.rmtree(_TEST_MEDIA_ROOT, ignore_errors=True)


class ApplyPurchaseTests(TestCase):
    """apps.products.services.apply_purchase() - proportional
    shared_extra_costs distribution across a multi-product purchase,
    then restocking every line via the existing restock_product()."""

    def setUp(self):
        self.supplier = Supplier.objects.create(name="ABC Traders", phone="01810000030")
        self.display = Product.objects.create(
            name="SF Display", sku="DISPLAY-1", supplier=self.supplier,
            buy_price="0.00", sale_price="600.00", current_stock_quantity=0,
        )
        self.front_cover = Product.objects.create(
            name="Front Cover", sku="COVER-1", supplier=self.supplier,
            buy_price="0.00", sale_price="500.00", current_stock_quantity=0,
        )

    def test_worked_example_delivery_charge_splits_proportionally_not_equally(self):
        """5 Displays @350 (subtotal 1750) + 1 Front Cover @350 (subtotal
        350), shared delivery 150 -> split 125/25 by value share (5:1),
        NOT 75/75 even split. Both land at 375.00/unit in this example
        because 1750/5 == 350/1 == 350 before the delivery charge - the
        proportional split still produces the mathematically correct
        landed cost per unit, it just happens to coincide here."""
        purchase = Purchase.objects.create(
            supplier=self.supplier, purchase_date=date.today(), shared_extra_costs=Decimal("150.00"),
        )
        PurchaseLineItem.objects.create(purchase=purchase, product=self.display, quantity=5, unit_price=Decimal("350.00"))
        PurchaseLineItem.objects.create(purchase=purchase, product=self.front_cover, quantity=1, unit_price=Decimal("350.00"))

        product_services.apply_purchase(purchase)

        self.display.refresh_from_db()
        self.front_cover.refresh_from_db()

        self.assertEqual(self.display.current_stock_quantity, 5)
        self.assertEqual(self.display.buy_price, Decimal("375.00"))
        self.assertEqual(self.front_cover.current_stock_quantity, 1)
        self.assertEqual(self.front_cover.buy_price, Decimal("375.00"))

        display_event = self.display.restock_events.latest("restocked_at")
        cover_event = self.front_cover.restock_events.latest("restocked_at")
        self.assertEqual(display_event.extra_costs, Decimal("125.00"))
        self.assertEqual(cover_event.extra_costs, Decimal("25.00"))
        # The two shares must sum exactly to the shared delivery charge.
        self.assertEqual(display_event.extra_costs + cover_event.extra_costs, Decimal("150.00"))

    def test_uneven_split_favors_the_higher_value_line_and_remainder_goes_to_last_line(self):
        """3 Displays @350 (subtotal 1050) + 2 Front Covers @250 (subtotal
        500), shared cost 100 over a combined subtotal of 1550 - not a
        clean division, so the remainder must land on the last line so
        the shares still sum exactly to 100.00."""
        purchase = Purchase.objects.create(
            supplier=self.supplier, purchase_date=date.today(), shared_extra_costs=Decimal("100.00"),
        )
        PurchaseLineItem.objects.create(purchase=purchase, product=self.display, quantity=3, unit_price=Decimal("350.00"))
        PurchaseLineItem.objects.create(purchase=purchase, product=self.front_cover, quantity=2, unit_price=Decimal("250.00"))

        product_services.apply_purchase(purchase)

        display_event = self.display.restock_events.latest("restocked_at")
        cover_event = self.front_cover.restock_events.latest("restocked_at")

        # 100 * 1050/1550 = 67.741935... -> 67.74 (first line, rounded)
        self.assertEqual(display_event.extra_costs, Decimal("67.74"))
        # Remainder absorbed by the last line: 100.00 - 67.74 = 32.26
        self.assertEqual(cover_event.extra_costs, Decimal("32.26"))
        self.assertEqual(display_event.extra_costs + cover_event.extra_costs, Decimal("100.00"))

    def test_single_line_item_absorbs_the_entire_shared_cost(self):
        purchase = Purchase.objects.create(
            supplier=self.supplier, purchase_date=date.today(), shared_extra_costs=Decimal("150.00"),
        )
        PurchaseLineItem.objects.create(purchase=purchase, product=self.display, quantity=5, unit_price=Decimal("350.00"))

        product_services.apply_purchase(purchase)

        self.display.refresh_from_db()
        # (5*350 + 150) / 5 = 380.00 - matches compute_landed_unit_cost()'s
        # own single-product worked example.
        self.assertEqual(self.display.buy_price, Decimal("380.00"))

    def test_restocking_existing_stock_still_uses_weighted_average(self):
        self.display.buy_price = Decimal("300.00")
        self.display.current_stock_quantity = 5
        self.display.save()

        purchase = Purchase.objects.create(
            supplier=self.supplier, purchase_date=date.today(), shared_extra_costs=Decimal("0.00"),
        )
        PurchaseLineItem.objects.create(purchase=purchase, product=self.display, quantity=5, unit_price=Decimal("350.00"))

        product_services.apply_purchase(purchase)

        self.display.refresh_from_db()
        # ((5*300) + (5*350)) / 10 = 325.00
        self.assertEqual(self.display.buy_price, Decimal("325.00"))
        self.assertEqual(self.display.current_stock_quantity, 10)

    def test_apply_purchase_marks_processed_at(self):
        purchase = Purchase.objects.create(
            supplier=self.supplier, purchase_date=date.today(), shared_extra_costs=Decimal("0.00"),
        )
        PurchaseLineItem.objects.create(purchase=purchase, product=self.display, quantity=1, unit_price=Decimal("350.00"))

        self.assertFalse(purchase.is_processed)
        product_services.apply_purchase(purchase)
        purchase.refresh_from_db()
        self.assertTrue(purchase.is_processed)
        self.assertIsNotNone(purchase.processed_at)

    def test_cannot_apply_the_same_purchase_twice(self):
        purchase = Purchase.objects.create(
            supplier=self.supplier, purchase_date=date.today(), shared_extra_costs=Decimal("0.00"),
        )
        PurchaseLineItem.objects.create(purchase=purchase, product=self.display, quantity=5, unit_price=Decimal("350.00"))

        product_services.apply_purchase(purchase)
        with self.assertRaises(ValueError):
            product_services.apply_purchase(purchase)

        self.display.refresh_from_db()
        self.assertEqual(self.display.current_stock_quantity, 5)  # not double-restocked

    def test_apply_purchase_rejects_empty_purchase(self):
        purchase = Purchase.objects.create(
            supplier=self.supplier, purchase_date=date.today(), shared_extra_costs=Decimal("0.00"),
        )
        with self.assertRaises(ValueError):
            product_services.apply_purchase(purchase)


class PurchaseApiTests(TestCase):
    """POST /api/purchases/ - creates and immediately applies a purchase."""

    def setUp(self):
        self.admin = User.objects.create_superuser(email="purchase_admin@test.local", password="pass12345", name="Admin")
        self.client = APIClient()
        self.client.force_authenticate(self.admin)

        self.supplier = Supplier.objects.create(name="ABC Traders", phone="01810000031")
        self.display = Product.objects.create(
            name="SF Display", sku="DISPLAY-API-1", supplier=self.supplier,
            buy_price="0.00", sale_price="600.00", current_stock_quantity=0,
        )
        self.front_cover = Product.objects.create(
            name="Front Cover", sku="COVER-API-1", supplier=self.supplier,
            buy_price="0.00", sale_price="500.00", current_stock_quantity=0,
        )

    def test_create_purchase_worked_example(self):
        response = self.client.post(
            "/api/purchases/",
            {
                "supplier": self.supplier.id,
                "purchase_date": "2026-07-22",
                "shared_extra_costs": "150.00",
                "line_items": [
                    {"product": self.display.id, "quantity": 5, "unit_price": "350.00"},
                    {"product": self.front_cover.id, "quantity": 1, "unit_price": "350.00"},
                ],
            },
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        self.assertTrue(response.data["is_processed"])

        lines = {line["product"]: line for line in response.data["line_items"]}
        self.assertEqual(lines[self.display.id]["extra_cost_share"], "125.00")
        self.assertEqual(lines[self.display.id]["landed_unit_cost"], "375.00")
        self.assertEqual(lines[self.front_cover.id]["extra_cost_share"], "25.00")
        self.assertEqual(lines[self.front_cover.id]["landed_unit_cost"], "375.00")

        self.display.refresh_from_db()
        self.front_cover.refresh_from_db()
        self.assertEqual(self.display.current_stock_quantity, 5)
        self.assertEqual(self.display.buy_price, Decimal("375.00"))
        self.assertEqual(self.front_cover.current_stock_quantity, 1)
        self.assertEqual(self.front_cover.buy_price, Decimal("375.00"))

    def test_create_purchase_rejects_empty_line_items(self):
        response = self.client.post(
            "/api/purchases/",
            {
                "supplier": self.supplier.id,
                "purchase_date": "2026-07-22",
                "shared_extra_costs": "0.00",
                "line_items": [],
            },
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(Purchase.objects.count(), 0)

    def test_staff_without_permission_cannot_create_purchase(self):
        staff = User.objects.create_user(email="purchase_staff@test.local", password="pass12345", name="Staff")
        staff_client = APIClient()
        staff_client.force_authenticate(staff)

        response = staff_client.post(
            "/api/purchases/",
            {
                "supplier": self.supplier.id,
                "purchase_date": "2026-07-22",
                "shared_extra_costs": "0.00",
                "line_items": [{"product": self.display.id, "quantity": 1, "unit_price": "350.00"}],
            },
            format="json",
        )
        self.assertEqual(response.status_code, 403)


class ProductDescriptionApiTests(TestCase):
    def setUp(self):
        self.admin = User.objects.create_superuser(email="product_desc_admin@test.local", password="pass12345", name="Admin")
        self.client = APIClient()
        self.client.force_authenticate(self.admin)
        self.supplier = Supplier.objects.create(name="ABC Traders", phone="01810000033")

    def test_description_is_optional_and_round_trips(self):
        response = self.client.post(
            "/api/products/",
            {
                "name": "LED Strip", "sku": "LED-DESC-1", "supplier": self.supplier.id, "sale_price": "120.00",
                "description": "Cool white, 12V, sold per meter.",
            },
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["description"], "Cool white, 12V, sold per meter.")

        product_id = response.data["id"]
        list_response = self.client.get("/api/products/")
        row = next(r for r in list_response.data if r["id"] == product_id)
        self.assertEqual(row["description"], "Cool white, 12V, sold per meter.")

    def test_description_defaults_to_blank(self):
        product = Product.objects.create(
            name="Meter Casing", sku="CASING-DESC-1", supplier=self.supplier,
            buy_price="50.00", sale_price="150.00",
        )
        response = self.client.get(f"/api/products/{product.id}/")
        self.assertEqual(response.data["description"], "")


@override_settings(MEDIA_ROOT=_TEST_MEDIA_ROOT)
class ProductImageAbsoluteUrlApiTests(TestCase):
    """DRF's ImageField only renders an absolute URL when the serializer
    has 'request' in its context. The standard list/retrieve/create/update
    actions get this for free via self.get_serializer(), but restock/
    adjust-stock hand-build ProductSerializer(product) - they must pass
    context=self.get_serializer_context() explicitly or every image URL
    coming back from those two endpoints regresses to a relative path."""

    def setUp(self):
        self.admin = User.objects.create_superuser(email="image_admin@test.local", password="pass12345", name="Admin")
        self.client = APIClient()
        self.client.force_authenticate(self.admin)
        self.supplier = Supplier.objects.create(name="ABC Traders", phone="01810000034")
        self.product = Product.objects.create(
            name="LED Strip", sku="LED-IMG-1", supplier=self.supplier,
            buy_price="50.00", sale_price="100.00", current_stock_quantity=5,
            image=SimpleUploadedFile("test.gif", MINIMAL_GIF, content_type="image/gif"),
        )

    def test_retrieve_returns_absolute_image_url(self):
        response = self.client.get(f"/api/products/{self.product.id}/")
        self.assertTrue(response.data["image"].startswith("http://testserver/media/"))

    def test_restock_response_returns_absolute_image_url(self):
        response = self.client.post(
            f"/api/products/{self.product.id}/restock/",
            {"quantity": 5, "unit_price": "60.00"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data["image"].startswith("http://testserver/media/"))

    def test_adjust_stock_response_returns_absolute_image_url(self):
        response = self.client.post(
            f"/api/products/{self.product.id}/adjust-stock/",
            {"delta": 1},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data["image"].startswith("http://testserver/media/"))
