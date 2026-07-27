from datetime import date, timedelta
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

    def test_installment_number_matches_the_due_date_even_with_a_payment_gap(self):
        """Regression test: installment 3 is paid while 1-2 aren't - the
        notification must name installment 1 (the actual earliest unpaid
        one, via loan_services.upcoming_installments()), not "however many
        payments exist + 1" = 2, which would mismatch the due date it's
        paired with (installment 1's date, not installment 2's)."""
        from apps.loans import services as loan_services

        loan = Loan.objects.create(
            lender_name="Grameen Support NGO", lender_type=Loan.LenderType.NGO,
            loan_amount=Decimal("30000.00"), interest_amount=Decimal("3000.00"),
            total_installments=6, installment_amount=Decimal("5500.00"),
            installment_frequency=Loan.InstallmentFrequency.WEEKLY, start_date=date.today(),
        )
        loan_services.add_installment_payment(
            loan, amount_paid=Decimal("5500.00"), payment_date=date.today(), installment_number=3,
        )

        created = notification_services.generate_loan_installment_notifications(upcoming_days=45)

        self.assertEqual(len(created), 1)
        self.assertIn("Installment #1", created[0].title)
        self.assertNotIn("Installment #2", created[0].title)

    def test_overdue_and_upcoming_installments_on_the_same_loan_both_notify(self):
        """A loan with installment #1 overdue and unpaid, and installment
        #4 separately upcoming within the window (installments #2-#3 are
        paid, so they don't count as "the next one") - both must generate
        their own notification, not just the more urgent (overdue) one.
        Re-running the same day must not duplicate either."""
        from apps.loans import services as loan_services

        loan = Loan.objects.create(
            lender_name="Pridim Foundation", lender_type=Loan.LenderType.NGO,
            loan_amount=Decimal("20000.00"), interest_amount=Decimal("2000.00"),
            total_installments=4, installment_amount=Decimal("5500.00"),
            installment_frequency=Loan.InstallmentFrequency.WEEKLY,
            start_date=date.today() - timedelta(days=9),
        )
        # weekly from (today - 9 days): #1 due today-2 (overdue), #2 due
        # today+5, #3 due today+12, #4 due today+19.
        for installment_number in (2, 3):
            loan_services.add_installment_payment(
                loan, amount_paid=Decimal("5500.00"), payment_date=date.today(),
                installment_number=installment_number,
            )

        created = notification_services.generate_loan_installment_notifications(upcoming_days=25)

        self.assertEqual(len(created), 2)
        overdue_notification = next(n for n in created if "#1" in n.title)
        upcoming_notification = next(n for n in created if "#4" in n.title)

        self.assertEqual(overdue_notification.due_date, date.today() - timedelta(days=2))
        self.assertIn("#1", overdue_notification.message)
        self.assertEqual(upcoming_notification.due_date, date.today() + timedelta(days=19))
        self.assertIn("#4", upcoming_notification.message)

        # Re-running the same day must not create duplicates of either -
        # the per-(loan, due_date) guard must not let the overdue
        # notification's existence suppress the separate upcoming one.
        second_run = notification_services.generate_loan_installment_notifications(upcoming_days=25)
        self.assertEqual(second_run, [])
        self.assertEqual(
            Notification.objects.filter(
                type=Notification.Type.LOAN_INSTALLMENT_DUE, object_id=str(loan.pk),
            ).count(),
            2,
        )

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
