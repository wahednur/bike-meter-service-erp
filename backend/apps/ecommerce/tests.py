from decimal import Decimal

from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.ecommerce import services as ecommerce_services
from apps.ecommerce.exceptions import EcommerceError
from apps.ecommerce.models import Order
from apps.products.models import Product
from apps.suppliers.models import Supplier


class EcommerceServiceTests(TestCase):
    def setUp(self):
        self.supplier = Supplier.objects.create(name="ABC Traders", phone="01810000020")
        self.product_a = Product.objects.create(
            name="Headlight Bulb", sku="BULB-ECOM-1", supplier=self.supplier,
            buy_price="60.00", sale_price="120.00", current_stock_quantity=10,
        )
        self.product_b = Product.objects.create(
            name="Meter Casing", sku="CASING-ECOM-1", supplier=self.supplier,
            buy_price="80.00", sale_price="150.00", current_stock_quantity=3,
        )

    def test_place_order_success_decrements_stock_and_computes_total(self):
        order = ecommerce_services.place_order(
            customer_name="Jasim Uddin", customer_phone="01722223333", customer_address="Mirpur, Dhaka",
            items=[{"product": self.product_a, "quantity": 2}, {"product": self.product_b, "quantity": 1}],
        )

        self.product_a.refresh_from_db()
        self.product_b.refresh_from_db()
        self.assertEqual(self.product_a.current_stock_quantity, 8)
        self.assertEqual(self.product_b.current_stock_quantity, 2)

        self.assertEqual(order.total_amount, Decimal("390.00"))  # 2x120 + 1x150
        self.assertEqual(order.status, Order.Status.PENDING)
        self.assertEqual(order.items.count(), 2)
        self.assertTrue(order.order_no.startswith("ORD-"))
        self.assertTrue(len(order.tracking_token) > 0)

    def test_place_order_rejects_empty_items(self):
        with self.assertRaises(EcommerceError):
            ecommerce_services.place_order(
                customer_name="Jasim", customer_phone="017", customer_address="Dhaka", items=[],
            )

    def test_place_order_rejects_insufficient_stock(self):
        with self.assertRaises(EcommerceError):
            ecommerce_services.place_order(
                customer_name="Jasim", customer_phone="017", customer_address="Dhaka",
                items=[{"product": self.product_b, "quantity": 999}],
            )
        self.product_b.refresh_from_db()
        self.assertEqual(self.product_b.current_stock_quantity, 3)  # untouched

    def test_place_order_multi_item_failure_leaves_no_partial_order_or_stock_change(self):
        """product_a has plenty of stock, product_b doesn't - the whole
        order must be rejected, with NEITHER product's stock touched."""
        orders_before = Order.objects.count()

        with self.assertRaises(EcommerceError):
            ecommerce_services.place_order(
                customer_name="Jasim", customer_phone="017", customer_address="Dhaka",
                items=[{"product": self.product_a, "quantity": 2}, {"product": self.product_b, "quantity": 999}],
            )

        self.product_a.refresh_from_db()
        self.product_b.refresh_from_db()
        self.assertEqual(self.product_a.current_stock_quantity, 10)
        self.assertEqual(self.product_b.current_stock_quantity, 3)
        self.assertEqual(Order.objects.count(), orders_before)

    def test_order_no_and_tracking_token_are_unique_across_orders(self):
        order1 = ecommerce_services.place_order(
            customer_name="A", customer_phone="017", customer_address="Dhaka",
            items=[{"product": self.product_a, "quantity": 1}],
        )
        order2 = ecommerce_services.place_order(
            customer_name="B", customer_phone="018", customer_address="Dhaka",
            items=[{"product": self.product_a, "quantity": 1}],
        )
        self.assertNotEqual(order1.order_no, order2.order_no)
        self.assertNotEqual(order1.tracking_token, order2.tracking_token)

    def test_update_order_status(self):
        order = ecommerce_services.place_order(
            customer_name="Jasim", customer_phone="017", customer_address="Dhaka",
            items=[{"product": self.product_a, "quantity": 1}],
        )
        ecommerce_services.update_order_status(order, Order.Status.CONFIRMED)
        order.refresh_from_db()
        self.assertEqual(order.status, Order.Status.CONFIRMED)

    def test_update_order_status_rejects_invalid_value(self):
        order = ecommerce_services.place_order(
            customer_name="Jasim", customer_phone="017", customer_address="Dhaka",
            items=[{"product": self.product_a, "quantity": 1}],
        )
        with self.assertRaises(EcommerceError):
            ecommerce_services.update_order_status(order, "NOT_A_REAL_STATUS")


class EcommerceApiTests(TestCase):
    """End-to-end: public storefront (no auth) + staff order management (auth)."""

    def setUp(self):
        self.supplier = Supplier.objects.create(name="ABC Traders", phone="01810000021")
        self.in_stock = Product.objects.create(
            name="Headlight Bulb", sku="BULB-ECOM-2", supplier=self.supplier,
            buy_price="60.00", sale_price="120.00", current_stock_quantity=10,
        )
        self.out_of_stock = Product.objects.create(
            name="Rare Sensor", sku="SENSOR-ECOM-1", supplier=self.supplier,
            buy_price="200.00", sale_price="350.00", current_stock_quantity=0,
        )
        self.admin = User.objects.create_superuser(email="ecom_admin@test.local", password="pass12345", name="Ecom Admin")
        self.public_client = APIClient()  # deliberately not authenticated
        self.staff_client = APIClient()
        self.staff_client.force_authenticate(user=self.admin)

    def test_public_product_list_excludes_out_of_stock_and_cost_fields(self):
        response = self.public_client.get("/api/public/products/")
        self.assertEqual(response.status_code, 200)
        body = response.json()

        skus_returned = [p["name"] for p in body]
        self.assertIn("Headlight Bulb", skus_returned)
        self.assertNotIn("Rare Sensor", skus_returned)  # out of stock, hidden

        product_data = body[0]
        self.assertEqual(set(product_data.keys()), {"id", "name", "image", "price"})
        self.assertNotIn("buy_price", product_data)
        self.assertNotIn("profit_margin", product_data)
        self.assertNotIn("current_stock_quantity", product_data)
        self.assertNotIn("supplier", product_data)

    def test_full_public_order_and_staff_fulfillment_flow(self):
        # 1. anonymous customer places an order, no auth
        place_response = self.public_client.post("/api/public/orders/", {
            "customer_name": "Jasim Uddin", "customer_phone": "01722223333", "customer_address": "Mirpur, Dhaka",
            "items": [{"product": self.in_stock.id, "quantity": 2}],
        }, format="json")
        self.assertEqual(place_response.status_code, 201)
        order_data = place_response.json()
        token = order_data["tracking_token"]
        self.assertEqual(order_data["status"], "PENDING")
        self.assertEqual(order_data["total_amount"], "240.00")

        # 2. anonymous customer tracks the order by token, no auth
        track_response = self.public_client.get(f"/api/public/orders/{token}/")
        self.assertEqual(track_response.status_code, 200)
        self.assertEqual(track_response.json()["status"], "PENDING")

        # 3. an unauthenticated user cannot list staff orders
        forbidden_response = self.public_client.get("/api/orders/")
        self.assertIn(forbidden_response.status_code, (401, 403))

        # 4. staff sees the order and updates its status
        staff_list = self.staff_client.get("/api/orders/")
        self.assertEqual(staff_list.status_code, 200)
        self.assertEqual(len(staff_list.json()), 1)

        order_id = order_data["id"]
        status_response = self.staff_client.post(f"/api/orders/{order_id}/status/", {"status": "CONFIRMED"}, format="json")
        self.assertEqual(status_response.status_code, 200)
        self.assertEqual(status_response.json()["status"], "CONFIRMED")

        # 5. tracking now reflects the updated status
        track_again = self.public_client.get(f"/api/public/orders/{token}/")
        self.assertEqual(track_again.json()["status"], "CONFIRMED")
