from types import SimpleNamespace

from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.audit import services as audit_services
from apps.audit.context import set_current_request
from apps.audit.models import AuditLog
from apps.customers.models import Customer


class AuditLogSignalTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="audituser@test.local", password="pass12345", name="Audit User")
        set_current_request(SimpleNamespace(user=self.user))

    def tearDown(self):
        set_current_request(None)

    def test_create_is_logged_with_correct_user(self):
        customer = Customer.objects.create(name="Test Co", phone="01700000090")
        log = AuditLog.objects.filter(object_id=str(customer.pk), content_type__model="customer").latest("created_at")
        self.assertEqual(log.action, AuditLog.Action.CREATE)
        self.assertEqual(log.created_by, self.user)
        self.assertEqual(log.changed_fields, [])
        self.assertEqual(log.object_repr, "Test Co")

    def test_update_logs_changed_fields(self):
        customer = Customer.objects.create(name="Test Co", phone="01700000091")
        AuditLog.objects.filter(object_id=str(customer.pk)).delete()  # clear the CREATE entry for a clean check

        customer.address = "New Address"
        customer.save()

        log = AuditLog.objects.filter(object_id=str(customer.pk)).latest("created_at")
        self.assertEqual(log.action, AuditLog.Action.UPDATE)
        self.assertIn("address", log.changed_fields)

    def test_no_op_save_does_not_log(self):
        customer = Customer.objects.create(name="Test Co", phone="01700000092")
        count_before = AuditLog.objects.filter(object_id=str(customer.pk)).count()

        customer.save()  # nothing actually changed

        count_after = AuditLog.objects.filter(object_id=str(customer.pk)).count()
        self.assertEqual(count_before, count_after)

    def test_soft_delete_is_logged_as_delete_not_update(self):
        customer = Customer.objects.create(name="Test Co", phone="01700000093")
        customer.delete()  # BaseModel soft delete - internally just a save()

        log = AuditLog.objects.filter(object_id=str(customer.pk)).latest("created_at")
        self.assertEqual(log.action, AuditLog.Action.DELETE)
        self.assertIn("is_deleted", log.changed_fields)

    def test_hard_delete_is_logged(self):
        customer = Customer.objects.create(name="Test Co", phone="01700000094")
        pk = customer.pk
        customer.hard_delete()

        log = AuditLog.objects.filter(object_id=str(pk)).latest("created_at")
        self.assertEqual(log.action, AuditLog.Action.DELETE)

    def test_no_self_referential_logging(self):
        Customer.objects.create(name="Test Co", phone="01700000095")
        self.assertEqual(AuditLog.objects.filter(content_type__app_label="audit").count(), 0)

    def test_django_internal_models_not_tracked(self):
        from django.contrib.auth.models import Group

        before = AuditLog.objects.count()
        Group.objects.create(name="Test Group XYZ")
        after = AuditLog.objects.count()
        self.assertEqual(before, after)

    def test_no_current_request_logs_with_null_user(self):
        set_current_request(None)
        customer = Customer.objects.create(name="No Context Co", phone="01700000096")
        log = AuditLog.objects.filter(object_id=str(customer.pk)).latest("created_at")
        self.assertIsNone(log.created_by)


class BuildAuditFeedTests(TestCase):
    """apps.audit.services.build_audit_feed() - merges the automatic
    AuditLog trail with hand-curated AuditLogEntry business events into one
    sorted, uniformly-shaped feed."""

    def setUp(self):
        self.user = User.objects.create_user(email="feeduser@test.local", password="pass12345", name="Feed User")
        set_current_request(SimpleNamespace(user=self.user))

    def tearDown(self):
        set_current_request(None)

    def test_feed_contains_both_sources_sorted_newest_first(self):
        customer = Customer.objects.create(name="Karim Mia", phone="01700000100")
        audit_services.log_action(customer, "payment_added", "Payment of 500.00 recorded via CASH.", user=self.user)

        rows = audit_services.build_audit_feed()
        sources = {row["source"] for row in rows}
        self.assertEqual(sources, {"AUTO", "BUSINESS_EVENT"})

        timestamps = [row["timestamp"] for row in rows]
        self.assertEqual(timestamps, sorted(timestamps, reverse=True))

    def test_automatic_entry_shape(self):
        Customer.objects.create(name="Karim Mia", phone="01700000101")

        rows = audit_services.build_audit_feed(model="customer", action="CREATE")
        self.assertEqual(len(rows), 1)
        row = rows[0]

        self.assertTrue(row["id"].startswith("auto-"))
        self.assertEqual(row["user"], "Feed User")
        self.assertEqual(row["source"], "AUTO")
        self.assertEqual(row["model"], "customer")
        self.assertEqual(row["model_display"], "Customer")
        self.assertEqual(row["object_id"], str(Customer.objects.get(name="Karim Mia").pk))
        self.assertEqual(row["record"], "Customer: Karim Mia")
        self.assertEqual(row["action"], "CREATE")
        self.assertEqual(row["action_display"], "Create")
        self.assertEqual(row["summary"], "Record created.")

    def test_business_event_entry_shape(self):
        customer = Customer.objects.create(name="Karim Mia", phone="01700000102")
        audit_services.log_action(
            customer, "customer_red_listed", "Karim Mia red-listed: 2 consecutive invoices had a payment shortfall.",
            user=self.user,
        )

        rows = audit_services.build_audit_feed(action="customer_red_listed")
        self.assertEqual(len(rows), 1)
        row = rows[0]

        self.assertTrue(row["id"].startswith("event-"))
        self.assertEqual(row["user"], "Feed User")
        self.assertEqual(row["source"], "BUSINESS_EVENT")
        self.assertEqual(row["model"], "customer")
        self.assertEqual(row["model_display"], "Customer")
        self.assertEqual(row["object_id"], str(customer.pk))
        self.assertEqual(row["record"], "Customer: Karim Mia")
        self.assertEqual(row["action"], "customer_red_listed")
        self.assertEqual(row["action_display"], "Customer Red Listed")
        self.assertEqual(row["summary"], "Karim Mia red-listed: 2 consecutive invoices had a payment shortfall.")

    def test_update_summary_lists_changed_fields(self):
        customer = Customer.objects.create(name="Karim Mia", phone="01700000103")
        customer.address = "New Address"
        customer.save()

        rows = audit_services.build_audit_feed(model="customer", action="UPDATE")
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["summary"], "Changed: address.")

    def test_soft_deleted_record_still_shows_a_readable_name_in_business_event(self):
        """AuditLogEntry doesn't freeze a repr like AuditLog does - the feed
        must still resolve a soft-deleted record's name via all_objects,
        not silently drop it or show a bare id."""
        customer = Customer.objects.create(name="Karim Mia", phone="01700000104")
        audit_services.log_action(customer, "payment_added", "Payment of 100.00.", user=self.user)
        customer.delete()  # soft delete - row still exists

        rows = audit_services.build_audit_feed(action="payment_added")
        self.assertEqual(rows[0]["record"], "Customer: Karim Mia")

    def test_hard_deleted_record_falls_back_gracefully_in_business_event(self):
        customer = Customer.objects.create(name="Karim Mia", phone="01700000105")
        audit_services.log_action(customer, "payment_added", "Payment of 100.00.", user=self.user)
        customer_pk = customer.pk
        customer.hard_delete()

        rows = audit_services.build_audit_feed(action="payment_added")
        self.assertEqual(rows[0]["record"], f"Customer #{customer_pk} (deleted)")

    def test_filter_by_date_range_excludes_out_of_range_entries(self):
        from datetime import timedelta

        from django.utils import timezone

        customer = Customer.objects.create(name="Karim Mia", phone="01700000106")
        AuditLog.objects.filter(object_id=str(customer.pk)).update(
            created_at=timezone.now() - timedelta(days=30),
        )

        today = timezone.now().date()
        rows = audit_services.build_audit_feed(from_date=today, to_date=today, model="customer")
        self.assertEqual(rows, [])

    def test_filter_by_user_only_returns_that_users_entries(self):
        other_user = User.objects.create_user(email="otheruser@test.local", password="pass12345", name="Other User")
        Customer.objects.create(name="Karim Mia", phone="01700000107")

        set_current_request(SimpleNamespace(user=other_user))
        Customer.objects.create(name="Rahim Uddin", phone="01700000108")

        rows = audit_services.build_audit_feed(user_id=str(self.user.id), model="customer", action="CREATE")
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["record"], "Customer: Karim Mia")

    def test_filter_by_model_excludes_other_models(self):
        from apps.suppliers.models import Supplier

        Customer.objects.create(name="Karim Mia", phone="01700000109")
        Supplier.objects.create(name="ABC Traders", phone="01800000109")

        rows = audit_services.build_audit_feed(model="supplier")
        self.assertTrue(all(row["model"] == "supplier" for row in rows))
        self.assertTrue(any(row["record"].startswith("Supplier:") for row in rows))


class AuditLogViewApiTests(TestCase):
    """GET /api/audit/log/ - Admin only, paginated."""

    def setUp(self):
        self.admin = User.objects.create_superuser(email="audit_admin@test.local", password="pass12345", name="Admin")
        self.staff = User.objects.create_user(email="audit_staff@test.local", password="pass12345", name="Staff")
        self.admin_client = APIClient()
        self.admin_client.force_authenticate(self.admin)
        self.staff_client = APIClient()
        self.staff_client.force_authenticate(self.staff)

    def test_staff_forbidden(self):
        response = self.staff_client.get("/api/audit/log/")
        self.assertEqual(response.status_code, 403)

    def test_admin_sees_merged_paginated_feed(self):
        customer = Customer.objects.create(name="Karim Mia", phone="01700000110", created_by=self.admin)

        response = self.admin_client.get("/api/audit/log/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("count", response.data)
        self.assertIn("page", response.data)
        self.assertIn("page_size", response.data)
        self.assertIn("total_pages", response.data)
        self.assertGreaterEqual(response.data["count"], 1)
        self.assertGreaterEqual(len(response.data["results"]), 1)
        matching = [row for row in response.data["results"] if row["model"] == "customer"]
        self.assertEqual(matching[0]["object_id"], str(customer.pk))

    def test_page_size_is_capped_and_respected(self):
        for i in range(5):
            Customer.objects.create(name=f"Customer {i}", phone=f"0170000012{i}", created_by=self.admin)

        response = self.admin_client.get("/api/audit/log/?page_size=2")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["page_size"], 2)
        self.assertEqual(len(response.data["results"]), 2)
        self.assertGreaterEqual(response.data["total_pages"], 3)

    def test_invalid_user_filter_is_rejected(self):
        response = self.admin_client.get("/api/audit/log/?user=not-a-uuid")
        self.assertEqual(response.status_code, 400)

    def test_filter_by_model_and_action(self):
        Customer.objects.create(name="Karim Mia", phone="01700000130", created_by=self.admin)

        response = self.admin_client.get("/api/audit/log/?model=customer&action=CREATE")
        self.assertEqual(response.status_code, 200)
        self.assertTrue(all(row["model"] == "customer" and row["action"] == "CREATE" for row in response.data["results"]))
