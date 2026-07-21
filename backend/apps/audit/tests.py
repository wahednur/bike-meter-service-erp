from types import SimpleNamespace

from django.test import TestCase

from apps.accounts.models import User
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
