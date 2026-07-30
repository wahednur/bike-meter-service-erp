from datetime import date, datetime, timezone as dt_timezone
from decimal import Decimal
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from apps.loans import services as loan_services
from apps.loans.exceptions import LoanError
from apps.loans.models import Loan

User = get_user_model()


class LoanServiceTests(TestCase):
    def setUp(self):
        self.loan = Loan.objects.create(
            lender_name="City Bank",
            lender_type=Loan.LenderType.BANK,
            loan_amount=Decimal("100000.00"),
            deposit_amount=Decimal("5000.00"),
            interest_amount=Decimal("15000.00"),
            total_installments=12,
            installment_amount=Decimal("10000.00"),
            installment_frequency=Loan.InstallmentFrequency.MONTHLY,
            start_date=date(2026, 1, 1),
        )

    def test_total_payable_is_computed_not_stored(self):
        self.assertEqual(self.loan.total_payable, Decimal("120000.00"))
        self.assertNotIn("total_payable", [f.name for f in Loan._meta.get_fields()])

    def test_stats_start_at_zero_paid(self):
        stats = loan_services.compute_loan_stats(self.loan)
        self.assertEqual(stats["installments_paid_count"], 0)
        self.assertEqual(stats["installments_remaining"], 12)
        self.assertEqual(stats["amount_paid_so_far"], Decimal("0"))
        self.assertEqual(stats["amount_remaining"], Decimal("120000.00"))

    def test_add_installment_payment_updates_stats(self):
        loan_services.add_installment_payment(
            self.loan, amount_paid=Decimal("10000.00"), payment_date=date(2026, 2, 1), installment_number=1,
        )
        loan_services.add_installment_payment(
            self.loan, amount_paid=Decimal("10000.00"), payment_date=date(2026, 3, 1), installment_number=2,
        )

        stats = loan_services.compute_loan_stats(self.loan)
        self.assertEqual(stats["installments_paid_count"], 2)
        self.assertEqual(stats["installments_remaining"], 10)
        self.assertEqual(stats["amount_paid_so_far"], Decimal("20000.00"))
        self.assertEqual(stats["amount_remaining"], Decimal("100000.00"))

    def test_rejects_installment_number_out_of_range(self):
        with self.assertRaises(LoanError):
            loan_services.add_installment_payment(
                self.loan, amount_paid=Decimal("10000.00"), payment_date=date(2026, 2, 1), installment_number=13,
            )
        with self.assertRaises(LoanError):
            loan_services.add_installment_payment(
                self.loan, amount_paid=Decimal("10000.00"), payment_date=date(2026, 2, 1), installment_number=0,
            )

    def test_rejects_payment_exceeding_remaining_balance(self):
        with self.assertRaises(LoanError):
            loan_services.add_installment_payment(
                self.loan, amount_paid=Decimal("130000.00"), payment_date=date(2026, 2, 1), installment_number=1,
            )

    def test_rejects_non_positive_amount(self):
        with self.assertRaises(LoanError):
            loan_services.add_installment_payment(
                self.loan, amount_paid=Decimal("0.00"), payment_date=date(2026, 2, 1), installment_number=1,
            )

    def test_multiple_loans_from_different_lenders_are_independent(self):
        other_loan = Loan.objects.create(
            lender_name="Grameen Support NGO",
            lender_type=Loan.LenderType.NGO,
            loan_amount=Decimal("30000.00"),
            deposit_amount=Decimal("0"),
            interest_amount=Decimal("3000.00"),
            total_installments=6,
            installment_amount=Decimal("5500.00"),
            installment_frequency=Loan.InstallmentFrequency.WEEKLY,
            start_date=date(2026, 3, 1),
        )
        loan_services.add_installment_payment(
            other_loan, amount_paid=Decimal("5500.00"), payment_date=date(2026, 3, 8), installment_number=1,
        )

        # the first loan (City Bank) must be untouched by the NGO loan's payment
        stats = loan_services.compute_loan_stats(self.loan)
        self.assertEqual(stats["amount_paid_so_far"], Decimal("0"))

        other_stats = loan_services.compute_loan_stats(other_loan)
        self.assertEqual(other_stats["amount_paid_so_far"], Decimal("5500.00"))
        self.assertEqual(Loan.objects.count(), 2)

    # --- installment due-date scheduling -----------------------------------

    def test_next_installment_due_date_monthly(self):
        # start_date=2026-01-01, MONTHLY, 0 paid -> installment 1 due one month later
        self.assertEqual(loan_services.compute_next_installment_due_date(self.loan), date(2026, 2, 1))

        loan_services.add_installment_payment(
            self.loan, amount_paid=Decimal("10000.00"), payment_date=date(2026, 2, 1), installment_number=1,
        )
        # installment 2 due two months after start_date
        self.assertEqual(loan_services.compute_next_installment_due_date(self.loan), date(2026, 3, 1))

    def test_next_installment_due_date_weekly(self):
        weekly_loan = Loan.objects.create(
            lender_name="Grameen Support NGO", lender_type=Loan.LenderType.NGO,
            loan_amount=Decimal("30000.00"), interest_amount=Decimal("3000.00"),
            total_installments=6, installment_amount=Decimal("5500.00"),
            installment_frequency=Loan.InstallmentFrequency.WEEKLY, start_date=date(2026, 3, 1),
        )
        self.assertEqual(loan_services.compute_next_installment_due_date(weekly_loan), date(2026, 3, 8))

    def test_next_installment_due_date_clamps_short_months(self):
        month_end_loan = Loan.objects.create(
            lender_name="City Bank", lender_type=Loan.LenderType.BANK,
            loan_amount=Decimal("50000.00"), interest_amount=Decimal("5000.00"),
            total_installments=10, installment_amount=Decimal("5000.00"),
            installment_frequency=Loan.InstallmentFrequency.MONTHLY, start_date=date(2026, 1, 31),
        )
        # Jan 31 + 1 month -> Feb has only 28 days in 2026 (not a leap year)
        self.assertEqual(loan_services.compute_next_installment_due_date(month_end_loan), date(2026, 2, 28))

    def test_next_installment_due_date_none_once_fully_paid(self):
        for i in range(1, 13):
            loan_services.add_installment_payment(
                self.loan, amount_paid=Decimal("10000.00"), payment_date=date(2026, 1, i), installment_number=i,
            )
        self.assertIsNone(loan_services.compute_next_installment_due_date(self.loan))

    def test_upcoming_installments_filters_by_window(self):
        weekly_loan = Loan.objects.create(
            lender_name="Grameen Support NGO", lender_type=Loan.LenderType.NGO,
            loan_amount=Decimal("30000.00"), interest_amount=Decimal("3000.00"),
            total_installments=6, installment_amount=Decimal("5500.00"),
            installment_frequency=Loan.InstallmentFrequency.WEEKLY, start_date=date(2026, 1, 15),
        )
        # weekly_loan's next installment is due 2026-01-22 (start + 1 week)
        # self.loan's (monthly, start 2026-01-01) next installment is due 2026-02-01
        reference_date = date(2026, 1, 20)
        # relative to reference_date: weekly due in 2 days, monthly due in 12 days

        rows_wide = loan_services.upcoming_installments(within_days=14, reference_date=reference_date)
        loan_ids_wide = [r["loan_id"] for r in rows_wide]
        self.assertIn(weekly_loan.id, loan_ids_wide)
        self.assertIn(self.loan.id, loan_ids_wide)

        rows_narrow = loan_services.upcoming_installments(within_days=5, reference_date=reference_date)
        loan_ids_narrow = [r["loan_id"] for r in rows_narrow]
        self.assertIn(weekly_loan.id, loan_ids_narrow)
        self.assertNotIn(self.loan.id, loan_ids_narrow)

    def test_upcoming_installments_default_window_is_next_7_days(self):
        # Reproduces the dashboard "Upcoming Loan Installments" scenario:
        # reference_date is the 27th, one loan's next installment is due on
        # the 29th (2 days out - must appear), another's is due 10 days out
        # (must NOT appear), using the default within_days=7 window.
        reference_date = date(2026, 7, 27)

        due_soon_loan = Loan.objects.create(
            lender_name="Due Soon Bank", lender_type=Loan.LenderType.BANK,
            loan_amount=Decimal("20000.00"), interest_amount=Decimal("2000.00"),
            total_installments=6, installment_amount=Decimal("3666.67"),
            installment_frequency=Loan.InstallmentFrequency.MONTHLY, start_date=date(2026, 6, 29),
        )
        # due_soon_loan's next installment is due 2026-07-29 (start + 1 month) - 2 days from reference_date

        due_later_loan = Loan.objects.create(
            lender_name="Due Later Bank", lender_type=Loan.LenderType.BANK,
            loan_amount=Decimal("20000.00"), interest_amount=Decimal("2000.00"),
            total_installments=6, installment_amount=Decimal("3666.67"),
            installment_frequency=Loan.InstallmentFrequency.MONTHLY, start_date=date(2026, 7, 6),
        )
        # due_later_loan's next installment is due 2026-08-06 (start + 1 month) - 10 days from reference_date

        rows = loan_services.upcoming_installments(reference_date=reference_date)
        loan_ids = [r["loan_id"] for r in rows]

        self.assertIn(due_soon_loan.id, loan_ids)
        self.assertNotIn(due_later_loan.id, loan_ids)

    def test_within_days_none_disables_the_upcoming_window_entirely(self):
        """Regression test: a loan due 10 days out is excluded with the
        default 7-day window (as above), but with within_days=None (what
        the admin dashboard now uses) it must show up regardless of how
        far out it is - a caught-up loan should never silently vanish
        just because its next installment falls a bit past a fixed
        lookahead."""
        reference_date = date(2026, 7, 27)

        due_later_loan = Loan.objects.create(
            lender_name="Due Later Bank", lender_type=Loan.LenderType.BANK,
            loan_amount=Decimal("20000.00"), interest_amount=Decimal("2000.00"),
            total_installments=6, installment_amount=Decimal("3666.67"),
            installment_frequency=Loan.InstallmentFrequency.MONTHLY, start_date=date(2026, 7, 6),
        )
        # due_later_loan's next installment is due 2026-08-06 - 10 days out

        rows = loan_services.upcoming_installments(within_days=None, reference_date=reference_date)
        loan_rows = [r for r in rows if r["loan_id"] == due_later_loan.id]

        self.assertEqual(len(loan_rows), 1)
        self.assertFalse(loan_rows[0]["is_overdue"])
        self.assertEqual(loan_rows[0]["due_date"], date(2026, 8, 6))


class UpdateInstallmentPaymentServiceTests(TestCase):
    """apps.loans.services.update_installment_payment() - corrects an
    existing payment in place, enforcing the same rules as
    add_installment_payment() except the overpayment check must exclude
    the payment's own current amount (it's being revised, not added on
    top of what's already recorded)."""

    def setUp(self):
        self.loan = Loan.objects.create(
            lender_name="City Bank", lender_type=Loan.LenderType.BANK,
            loan_amount=Decimal("100000.00"), deposit_amount=Decimal("5000.00"), interest_amount=Decimal("15000.00"),
            total_installments=12, installment_amount=Decimal("10000.00"),
            installment_frequency=Loan.InstallmentFrequency.MONTHLY, start_date=date(2026, 1, 1),
        )
        self.payment = loan_services.add_installment_payment(
            self.loan, amount_paid=Decimal("10000.00"), payment_date=date(2026, 2, 1), installment_number=1,
        )

    def test_corrects_amount_date_and_installment_number(self):
        loan_services.update_installment_payment(
            self.payment, amount_paid=Decimal("9500.00"), payment_date=date(2026, 2, 3), installment_number=2,
        )
        self.payment.refresh_from_db()
        self.assertEqual(self.payment.amount_paid, Decimal("9500.00"))
        self.assertEqual(self.payment.payment_date, date(2026, 2, 3))
        self.assertEqual(self.payment.installment_number, 2)

    def test_resaving_the_same_amount_does_not_look_like_an_overpayment(self):
        """Regression: without excluding the payment's own prior amount
        from "already paid", re-submitting the same value (or even a
        larger one that still fits the loan) would be wrongly rejected as
        exceeding the remaining balance, since the payment is already
        counted in amount_remaining."""
        loan_services.update_installment_payment(
            self.payment, amount_paid=Decimal("10000.00"), payment_date=self.payment.payment_date,
            installment_number=self.payment.installment_number,
        )
        stats = loan_services.compute_loan_stats(self.loan)
        self.assertEqual(stats["amount_paid_so_far"], Decimal("10000.00"))

    def test_can_raise_amount_up_to_the_true_remaining_balance(self):
        # With only this one payment recorded, excluding its own 10000 from
        # "already paid" leaves the full total_payable (120000) available.
        loan_services.update_installment_payment(
            self.payment, amount_paid=Decimal("120000.00"), payment_date=self.payment.payment_date,
            installment_number=self.payment.installment_number,
        )
        self.payment.refresh_from_db()
        self.assertEqual(self.payment.amount_paid, Decimal("120000.00"))

    def test_rejects_amount_exceeding_true_remaining_balance(self):
        with self.assertRaises(LoanError):
            loan_services.update_installment_payment(
                self.payment, amount_paid=Decimal("120000.01"), payment_date=self.payment.payment_date,
                installment_number=self.payment.installment_number,
            )

    def test_rejects_installment_number_out_of_range(self):
        with self.assertRaises(LoanError):
            loan_services.update_installment_payment(
                self.payment, amount_paid=self.payment.amount_paid, payment_date=self.payment.payment_date,
                installment_number=13,
            )

    def test_rejects_non_positive_amount(self):
        with self.assertRaises(LoanError):
            loan_services.update_installment_payment(
                self.payment, amount_paid=Decimal("0.00"), payment_date=self.payment.payment_date,
                installment_number=self.payment.installment_number,
            )

    def test_attachment_left_alone_when_not_provided(self):
        loan_services.update_installment_payment(
            self.payment, amount_paid=Decimal("9000.00"), payment_date=self.payment.payment_date,
            installment_number=self.payment.installment_number,
        )
        self.payment.refresh_from_db()
        self.assertFalse(self.payment.attachment)


class UpdateInstallmentPaymentApiTests(TestCase):
    """PATCH /api/loan-installment-payments/{id}/ - the endpoint backing
    the Loan detail page's installment "Edit" action."""

    def setUp(self):
        self.admin = User.objects.create_superuser(email="loan_edit_admin@test.local", password="pass12345", name="Admin")
        self.client = APIClient()
        self.client.force_authenticate(self.admin)

        self.loan = Loan.objects.create(
            lender_name="City Bank", lender_type=Loan.LenderType.BANK,
            loan_amount=Decimal("100000.00"), deposit_amount=Decimal("5000.00"), interest_amount=Decimal("15000.00"),
            total_installments=12, installment_amount=Decimal("10000.00"),
            installment_frequency=Loan.InstallmentFrequency.MONTHLY, start_date=date(2026, 1, 1),
        )
        self.payment = loan_services.add_installment_payment(
            self.loan, amount_paid=Decimal("10000.00"), payment_date=date(2026, 2, 1), installment_number=1,
        )

    def test_patch_corrects_amount_paid(self):
        response = self.client.patch(
            f"/api/loan-installment-payments/{self.payment.id}/", {"amount_paid": "9500.00"},
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["amount_paid"], "9500.00")
        self.payment.refresh_from_db()
        self.assertEqual(self.payment.amount_paid, Decimal("9500.00"))

    def test_patch_rejects_overpayment_beyond_true_remaining_balance(self):
        response = self.client.patch(
            f"/api/loan-installment-payments/{self.payment.id}/", {"amount_paid": "999999.00"},
        )
        self.assertEqual(response.status_code, 400)

    def test_patch_rejects_installment_number_out_of_range(self):
        response = self.client.patch(
            f"/api/loan-installment-payments/{self.payment.id}/", {"installment_number": 99},
        )
        self.assertEqual(response.status_code, 400)

    def test_patch_without_amount_paid_leaves_it_unchanged(self):
        response = self.client.patch(
            f"/api/loan-installment-payments/{self.payment.id}/", {"payment_date": "2026-02-05"},
        )
        self.assertEqual(response.status_code, 200)
        self.payment.refresh_from_db()
        self.assertEqual(self.payment.amount_paid, Decimal("10000.00"))
        self.assertEqual(self.payment.payment_date, date(2026, 2, 5))


class OverdueVsUpcomingInstallmentTests(TestCase):
    """Regression coverage for the "Upcoming Loan Installments" bug report:
    a weekly loan (Pridim Foundation) starting 2026-07-02 has installments
    due 7/9, 7/16, 7/23, 7/30. With "today" mocked as 2026-07-27 (3 days
    before the 7/30 due date), the widget was showing an already-passed
    installment instead of the 7/30 one."""

    def setUp(self):
        self.loan = Loan.objects.create(
            lender_name="Pridim Foundation", lender_type=Loan.LenderType.NGO,
            loan_amount=Decimal("20000.00"), interest_amount=Decimal("2000.00"),
            total_installments=4, installment_amount=Decimal("5500.00"),
            installment_frequency=Loan.InstallmentFrequency.WEEKLY, start_date=date(2026, 7, 2),
        )
        self.reference_date = date(2026, 7, 27)

    def test_schedule_generates_correct_weekly_due_dates(self):
        # Confirms item 2: no off-by-one/off-by-a-week error - installment
        # 1 is due start_date + 1 week, not start_date itself or +2 weeks.
        schedule = loan_services.compute_loan_installment_schedule(self.loan)
        self.assertEqual(
            [row["due_date"] for row in schedule],
            [date(2026, 7, 9), date(2026, 7, 16), date(2026, 7, 23), date(2026, 7, 30)],
        )

    def test_first_three_paid_next_installment_is_the_30th_not_overdue(self):
        """The 4th installment's PAYMENT MARKINGS matter: installments 1-3
        are recorded paid, so the 4th (7/30) - not an earlier one - must
        be identified as next, and correctly flagged as upcoming rather
        than overdue."""
        for installment_number in (1, 2, 3):
            loan_services.add_installment_payment(
                self.loan, amount_paid=Decimal("5500.00"),
                payment_date=date(2026, 7, 9), installment_number=installment_number,
            )

        self.assertEqual(loan_services.compute_next_installment_due_date(self.loan), date(2026, 7, 30))

        rows = loan_services.upcoming_installments(reference_date=self.reference_date)
        loan_rows = [r for r in rows if r["loan_id"] == self.loan.id]

        self.assertEqual(len(loan_rows), 1)
        self.assertEqual(loan_rows[0]["installment_number"], 4)
        self.assertEqual(loan_rows[0]["due_date"], date(2026, 7, 30))
        self.assertFalse(loan_rows[0]["is_overdue"])

    def test_all_unpaid_surfaces_both_the_overdue_and_the_upcoming_installment(self):
        """No payments recorded at all: installment 1 (7/9) is overdue and
        unpaid, AND installment 4 (7/30) is the next upcoming one - both
        must show up as separate rows, not one replacing the other."""
        self.assertEqual(loan_services.compute_next_installment_due_date(self.loan), date(2026, 7, 9))

        rows = loan_services.upcoming_installments(reference_date=self.reference_date)
        loan_rows = [r for r in rows if r["loan_id"] == self.loan.id]

        self.assertEqual(len(loan_rows), 2)
        overdue_row = next(r for r in loan_rows if r["is_overdue"])
        upcoming_row = next(r for r in loan_rows if not r["is_overdue"])

        self.assertEqual(overdue_row["installment_number"], 1)
        self.assertEqual(overdue_row["due_date"], date(2026, 7, 9))

        self.assertEqual(upcoming_row["installment_number"], 4)
        self.assertEqual(upcoming_row["due_date"], date(2026, 7, 30))

    def test_out_of_order_payment_does_not_confuse_next_due_date(self):
        """Answers item 1 directly: installment 3 is marked paid while 1
        and 2 are not. A count-based "however many payments exist" shortcut
        (paid_count + 1) would assume installments 1-2 were paid and wrongly
        point "next" at installment 3 - which is actually already settled.
        The correct next-unpaid is installment 1."""
        loan_services.add_installment_payment(
            self.loan, amount_paid=Decimal("5500.00"), payment_date=date(2026, 7, 23), installment_number=3,
        )

        self.assertEqual(loan_services.compute_next_installment_due_date(self.loan), date(2026, 7, 9))


def _mock_today(year, month, day):
    """Pins timezone.now() (and so every reference_date=None default in
    apps.loans.services) to a fixed date, rather than depending on the
    real wall clock - the same "today" used throughout this test needs to
    be deterministic regardless of when the suite actually runs."""
    return patch(
        "apps.loans.services.timezone.now",
        return_value=datetime(year, month, day, 12, 0, tzinfo=dt_timezone.utc),
    )


class LoanDetailApiNextInstallmentTests(TestCase):
    """GET /api/loans/{id}/ - next_installment_number/due_date/is_overdue
    (the Loan detail page's "Next Installment" card), same Pridim
    Foundation scenario as OverdueVsUpcomingInstallmentTests above. "Today"
    is mocked to 2026-07-27 throughout, rather than relying on the clock."""

    def setUp(self):
        self.admin = User.objects.create_superuser(email="loan_detail_admin@test.local", password="pass12345", name="Admin")
        self.client = APIClient()
        self.client.force_authenticate(self.admin)

        self.loan = Loan.objects.create(
            lender_name="Pridim Foundation", lender_type=Loan.LenderType.NGO,
            loan_amount=Decimal("20000.00"), interest_amount=Decimal("2000.00"),
            total_installments=4, installment_amount=Decimal("5500.00"),
            installment_frequency=Loan.InstallmentFrequency.WEEKLY, start_date=date(2026, 7, 2),
        )

    def test_first_three_paid_next_installment_is_the_30th_not_overdue(self):
        for installment_number in (1, 2, 3):
            loan_services.add_installment_payment(
                self.loan, amount_paid=Decimal("5500.00"),
                payment_date=date(2026, 7, 9), installment_number=installment_number,
            )

        with _mock_today(2026, 7, 27):
            response = self.client.get(f"/api/loans/{self.loan.id}/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["next_installment_number"], 4)
        self.assertEqual(response.data["next_installment_due_date"], date(2026, 7, 30))
        self.assertFalse(response.data["next_installment_is_overdue"])

    def test_nothing_paid_next_installment_is_overdue(self):
        with _mock_today(2026, 7, 27):
            response = self.client.get(f"/api/loans/{self.loan.id}/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["next_installment_number"], 1)
        self.assertEqual(response.data["next_installment_due_date"], date(2026, 7, 9))
        self.assertTrue(response.data["next_installment_is_overdue"])

    def test_next_installment_fields_are_null_once_fully_paid(self):
        for installment_number in (1, 2, 3, 4):
            loan_services.add_installment_payment(
                self.loan, amount_paid=Decimal("5500.00"),
                payment_date=date(2026, 7, 9), installment_number=installment_number,
            )

        with _mock_today(2026, 7, 27):
            response = self.client.get(f"/api/loans/{self.loan.id}/")

        self.assertEqual(response.status_code, 200)
        self.assertIsNone(response.data["next_installment_number"])
        self.assertIsNone(response.data["next_installment_due_date"])
        self.assertIsNone(response.data["next_installment_is_overdue"])
