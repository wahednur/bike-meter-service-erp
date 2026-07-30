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


def add_installment_payment(loan, amount_paid, payment_date, installment_number, attachment=None, user=None):
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
        attachment=attachment,
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


def compute_loan_installment_schedule(loan):
    """Every installment 1..total_installments for this loan: its due date
    (a fixed schedule of one installment per period (weekly/monthly)
    starting from start_date - e.g. a monthly loan's 3rd installment is
    due 3 months after start_date) and whether it's actually been paid.

    "Paid" is determined by which installment_numbers have a matching
    LoanInstallmentPayment - not by how many payments exist in total. That
    distinction matters whenever installments are recorded out of order or
    with a gap (e.g. installment 3 paid before installment 2 ever was): a
    plain count would silently assume installments 1..N were paid in
    order and point "next due" at an installment that's actually already
    settled, or skip past one that's still open."""
    from apps.loans.models import Loan

    paid_numbers = set(loan.installment_payments.values_list("installment_number", flat=True).distinct())

    schedule = []
    for installment_number in range(1, loan.total_installments + 1):
        if loan.installment_frequency == Loan.InstallmentFrequency.WEEKLY:
            due_date = loan.start_date + timedelta(weeks=installment_number)
        else:
            due_date = _add_months(loan.start_date, installment_number)
        schedule.append({
            "installment_number": installment_number,
            "due_date": due_date,
            "is_paid": installment_number in paid_numbers,
        })
    return schedule


def compute_next_installment_due_date(loan):
    """The due date of the earliest still-unpaid installment - see
    compute_loan_installment_schedule() for how "unpaid" is determined.
    Returns None once every installment has a payment."""
    next_unpaid = next((row for row in compute_loan_installment_schedule(loan) if not row["is_paid"]), None)
    return next_unpaid["due_date"] if next_unpaid else None


def compute_next_installment(loan, reference_date=None):
    """The single earliest unpaid installment for this loan - its number,
    due date, and whether that due date has already passed. For a
    per-loan "what's next" display (e.g. the Loan detail page) - as
    opposed to upcoming_installments() below, which is the cross-loan
    dashboard alert list and can surface an overdue installment *and* a
    separate upcoming one side by side for the same loan. Returns None
    once every installment has been paid."""
    reference_date = reference_date or timezone.now().date()
    next_unpaid = next((row for row in compute_loan_installment_schedule(loan) if not row["is_paid"]), None)
    if next_unpaid is None:
        return None
    return {
        "installment_number": next_unpaid["installment_number"],
        "due_date": next_unpaid["due_date"],
        "is_overdue": next_unpaid["due_date"] < reference_date,
    }


def _installment_alert_row(loan, installment_row, is_overdue):
    return {
        "loan_id": loan.id,
        "lender_name": loan.lender_name,
        "installment_number": installment_row["installment_number"],
        "due_date": installment_row["due_date"],
        "installment_amount": loan.installment_amount,
        "is_overdue": is_overdue,
        # Not exposed by UpcomingInstallmentSerializer (it only reads its
        # own declared fields) - kept here so callers that need the actual
        # Loan instance (e.g. apps.notifications.services, to create a
        # Notification against it) don't have to re-fetch it by loan_id.
        "loan": loan,
    }


def upcoming_installments(within_days=7, reference_date=None):
    """Loan installment alerts, soonest first.

    Each loan can contribute up to *two* rows, not just one - and one
    never silently replaces the other:
      - its earliest unpaid installment that's already overdue
        (due_date < reference_date), if any. Always included regardless
        of `within_days` - a loan already behind stays worth flagging no
        matter how the lookahead window is tuned.
      - its earliest unpaid installment that isn't due yet, if that due
        date falls within the next `within_days` days of `reference_date`
        - or unconditionally, if `within_days` is None.

    Both can appear for the same loan at once - e.g. installment 3 is
    unpaid and overdue *and* installment 4 is unpaid and due in 3 days.
    Previously this function only ever computed a single "next" due date
    per loan (the earliest unpaid installment), so whenever that one was
    overdue, a genuinely upcoming later installment was never reported at
    all - not filtered out, just never looked at. `is_overdue`
    distinguishes the two cases on each row so callers don't have to
    compare dates themselves.

    `within_days=None` (used by the admin dashboard widget) disables the
    upcoming-side window entirely, so every loan with an unpaid
    installment always has *some* row here - its overdue one, its next
    upcoming one however far out, or both - the same "always show what's
    next" guarantee the Loan detail page's Next Installment card already
    has, rather than a loan silently vanishing from the dashboard just
    because its next installment happens to fall a few days past a fixed
    lookahead. Notification generation still passes a real `within_days`
    so reminders stay bounded to a sensible timeframe - nobody wants a
    "due in 4 months" notification today."""
    from apps.loans.models import Loan

    reference_date = reference_date or timezone.now().date()
    horizon = None if within_days is None else reference_date + timedelta(days=within_days)

    rows = []
    for loan in Loan.objects.all():
        unpaid = [row for row in compute_loan_installment_schedule(loan) if not row["is_paid"]]
        overdue = next((row for row in unpaid if row["due_date"] < reference_date), None)
        upcoming = next((row for row in unpaid if row["due_date"] >= reference_date), None)

        if overdue is not None:
            rows.append(_installment_alert_row(loan, overdue, is_overdue=True))
        if upcoming is not None and (horizon is None or upcoming["due_date"] <= horizon):
            rows.append(_installment_alert_row(loan, upcoming, is_overdue=False))

    rows.sort(key=lambda r: (r["due_date"], r["is_overdue"]))
    return rows
