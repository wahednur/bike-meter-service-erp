from datetime import date
from decimal import Decimal

from django.test import TestCase

from apps.loans import services as loan_services
from apps.loans.exceptions import LoanError
from apps.loans.models import Loan


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
