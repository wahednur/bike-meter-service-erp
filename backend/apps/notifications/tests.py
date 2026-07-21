from datetime import date
from decimal import Decimal

from django.test import TestCase

from apps.customers.models import Customer
from apps.invoices import services as invoice_services
from apps.loans.models import Loan
from apps.notifications import services as notification_services
from apps.notifications.models import Notification
from apps.services.models import Service, ServiceCategory


class NotificationServiceTests(TestCase):
    def setUp(self):
        self.customer = Customer.objects.create(name="Karim Motors", phone="01710000030")
        category = ServiceCategory.objects.create(name=ServiceCategory.Name.METER_REPAIR)
        self.service = Service.objects.create(category=category, name="LED Repair", service_price="300.00")

    def test_generates_notification_for_due_invoice(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("300.00"))

        created = notification_services.generate_due_invoice_notifications()

        self.assertEqual(len(created), 1)
        self.assertEqual(created[0].type, Notification.Type.DUE_INVOICE)
        self.assertIn(invoice.invoice_no, created[0].message)

    def test_no_notification_for_fully_paid_invoice(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("300.00"))
        invoice_services.add_payment(invoice, amount=Decimal("300.00"), payment_method="CASH")

        created = notification_services.generate_due_invoice_notifications()
        self.assertEqual(created, [])

    def test_due_invoice_notification_idempotent_same_day(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("300.00"))

        first_run = notification_services.generate_due_invoice_notifications()
        second_run = notification_services.generate_due_invoice_notifications()

        self.assertEqual(len(first_run), 1)
        self.assertEqual(len(second_run), 0)  # already notified today - no duplicate
        self.assertEqual(
            Notification.objects.filter(type=Notification.Type.DUE_INVOICE).count(), 1,
        )

    def test_generates_notification_for_upcoming_loan_installment(self):
        Loan.objects.create(
            lender_name="City Bank", lender_type=Loan.LenderType.BANK,
            loan_amount=Decimal("50000.00"), interest_amount=Decimal("5000.00"),
            total_installments=10, installment_amount=Decimal("5000.00"),
            installment_frequency=Loan.InstallmentFrequency.MONTHLY,
            start_date=date.today(),  # next installment due in ~1 month - within default 7-day window? No.
        )
        # start_date=today makes the next installment due ~1 month out, which
        # is NOT within the default 7-day window - use a wide window instead
        # to prove the mechanism works without depending on wall-clock month length.
        created = notification_services.generate_loan_installment_notifications(upcoming_days=45)
        self.assertEqual(len(created), 1)
        self.assertEqual(created[0].type, Notification.Type.LOAN_INSTALLMENT_DUE)

    def test_no_loan_notification_outside_window(self):
        Loan.objects.create(
            lender_name="City Bank", lender_type=Loan.LenderType.BANK,
            loan_amount=Decimal("50000.00"), interest_amount=Decimal("5000.00"),
            total_installments=10, installment_amount=Decimal("5000.00"),
            installment_frequency=Loan.InstallmentFrequency.MONTHLY, start_date=date.today(),
        )
        created = notification_services.generate_loan_installment_notifications(upcoming_days=1)
        self.assertEqual(created, [])

    def test_run_daily_notification_check_combines_both(self):
        invoice, _ = invoice_services.get_or_create_open_invoice(self.customer)
        invoice_services.add_service_line(invoice, self.service, price_charged=Decimal("300.00"))

        Loan.objects.create(
            lender_name="City Bank", lender_type=Loan.LenderType.BANK,
            loan_amount=Decimal("50000.00"), interest_amount=Decimal("5000.00"),
            total_installments=10, installment_amount=Decimal("5000.00"),
            installment_frequency=Loan.InstallmentFrequency.WEEKLY, start_date=date.today(),
        )

        result = notification_services.run_daily_notification_check(upcoming_days=10)
        self.assertEqual(result["due_invoice_notifications_created"], 1)
        self.assertEqual(result["loan_installment_notifications_created"], 1)
