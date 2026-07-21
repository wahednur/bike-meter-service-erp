import calendar
from datetime import timedelta
from decimal import Decimal

from django.db.models import Sum
from django.utils import timezone

from apps.loans.exceptions import LoanError


def compute_loan_stats(loan):
    """installments_paid_count/installments_remaining/amount_paid_so_far/
    amount_remaining for one loan, derived from its installment payments."""
    payments = loan.installment_payments.all()

    installments_paid_count = payments.values("installment_number").distinct().count()
    amount_paid_so_far = payments.aggregate(total=Sum("amount_paid"))["total"] or Decimal("0")
    total_payable = loan.total_payable

    return {
        "installments_paid_count": installments_paid_count,
        "installments_remaining": max(loan.total_installments - installments_paid_count, 0),
        "amount_paid_so_far": amount_paid_so_far,
        "amount_remaining": total_payable - amount_paid_so_far,
    }


def add_installment_payment(loan, amount_paid, payment_date, installment_number, user=None):
    """Records one installment payment against a loan, after checking it's
    a real installment number for this loan and won't overpay the loan."""
    from apps.loans.models import LoanInstallmentPayment

    amount_paid = Decimal(amount_paid)
    if amount_paid <= 0:
        raise LoanError("amount_paid must be positive.")

    if not (1 <= installment_number <= loan.total_installments):
        raise LoanError(f"installment_number must be between 1 and {loan.total_installments}.")

    stats = compute_loan_stats(loan)
    if amount_paid > stats["amount_remaining"]:
        raise LoanError(
            f"Payment of {amount_paid} exceeds the remaining balance of {stats['amount_remaining']}."
        )

    return LoanInstallmentPayment.objects.create(
        loan=loan,
        amount_paid=amount_paid,
        payment_date=payment_date,
        installment_number=installment_number,
        created_by=user,
    )


def _add_months(base_date, months):
    """base_date + N calendar months, clamping the day for short months
    (e.g. Jan 31 + 1 month -> Feb 28). No python-dateutil dependency needed
    for just this one calculation."""
    month_index = base_date.month - 1 + months
    year = base_date.year + month_index // 12
    month = month_index % 12 + 1
    day = min(base_date.day, calendar.monthrange(year, month)[1])
    return base_date.replace(year=year, month=month, day=day)


def compute_next_installment_due_date(loan):
    """The due date of the next unpaid installment, assuming a fixed
    schedule of one installment per period (weekly/monthly) starting from
    start_date - e.g. a monthly loan's 3rd installment is due 3 months
    after start_date, regardless of when installments 1-2 actually got
    paid. Returns None once the loan is fully paid off."""
    from apps.loans.models import Loan

    stats = compute_loan_stats(loan)
    paid_count = stats["installments_paid_count"]
    if paid_count >= loan.total_installments:
        return None

    installment_number = paid_count + 1
    if loan.installment_frequency == Loan.InstallmentFrequency.WEEKLY:
        return loan.start_date + timedelta(weeks=installment_number)
    return _add_months(loan.start_date, installment_number)


def upcoming_installments(within_days=7, reference_date=None):
    """Every loan whose next unpaid installment falls due within
    `within_days` of `reference_date` (defaults to today), soonest first."""
    from apps.loans.models import Loan

    reference_date = reference_date or timezone.now().date()
    horizon = reference_date + timedelta(days=within_days)

    rows = []
    for loan in Loan.objects.all():
        due_date = compute_next_installment_due_date(loan)
        if due_date is None or due_date > horizon:
            continue
        stats = compute_loan_stats(loan)
        rows.append({
            "loan_id": loan.id,
            "lender_name": loan.lender_name,
            "installment_number": stats["installments_paid_count"] + 1,
            "due_date": due_date,
            "installment_amount": loan.installment_amount,
        })

    rows.sort(key=lambda r: r["due_date"])
    return rows
