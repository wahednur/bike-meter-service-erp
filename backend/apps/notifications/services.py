from django.contrib.contenttypes.models import ContentType
from django.utils import timezone


def _already_notified_today(notif_type, obj, due_date=None):
    """Idempotency guard: running the daily check more than once on the
    same day (or the scheduler firing twice) shouldn't spam duplicate
    notifications for the same object.

    `due_date`, when given, narrows the guard to "already notified today
    about *this* due date on this object" rather than "already notified
    today about this object at all" - needed for loan installments, where
    a single loan can have two notification-worthy installments on the
    same day (one overdue, one separately upcoming), each with its own
    due date. Without this, creating the overdue notification first would
    make this guard report "already notified today" for the loan and
    silently swallow the separate upcoming notification too. Not passed
    for due-invoice notifications, which have no such multiplicity - an
    invoice has exactly one outstanding-balance state at a time."""
    from apps.notifications.models import Notification

    qs = Notification.objects.filter(
        type=notif_type,
        content_type=ContentType.objects.get_for_model(obj),
        object_id=str(obj.pk),
        created_at__date=timezone.now().date(),
    )
    if due_date is not None:
        qs = qs.filter(due_date=due_date)
    return qs.exists()


def generate_due_invoice_notifications():
    """One notification per currently Unpaid/Partial Paid invoice, unless
    it's already been notified today."""
    from apps.invoices.models import Invoice
    from apps.notifications.models import Notification

    created = []
    due_invoices = Invoice.objects.filter(
        status__in=[Invoice.Status.UNPAID, Invoice.Status.PARTIAL]
    ).select_related("customer")

    for invoice in due_invoices:
        if _already_notified_today(Notification.Type.DUE_INVOICE, invoice):
            continue
        due_amount = invoice.outstanding_amount
        notification = Notification.objects.create(
            type=Notification.Type.DUE_INVOICE,
            title=f"Invoice {invoice.invoice_no} due",
            message=(
                f"{invoice.customer.name} has an outstanding balance of {due_amount} "
                f"on invoice {invoice.invoice_no} ({invoice.get_status_display()})."
            ),
            content_type=ContentType.objects.get_for_model(invoice),
            object_id=str(invoice.pk),
            due_date=invoice.created_date,
        )
        created.append(notification)
    return created


def generate_loan_installment_notifications(upcoming_days=7):
    """One notification per (loan, installment) that's either overdue and
    unpaid, or newly due within `upcoming_days` - unless that specific
    installment has already been notified about today.

    Reuses apps.loans.services.upcoming_installments() wholesale - the
    exact same overdue/upcoming split that powers the "Upcoming Loan
    Installments" dashboard widget - rather than re-deriving due
    dates/payment status here. (This used to recompute the installment
    number separately via `stats["installments_paid_count"] + 1`, a
    count-based shortcut that could name the wrong installment whenever
    payments were recorded out of order, and it only ever considered a
    single "next" installment per loan - so a loan with installment #1
    overdue and installment #4 separately due in 3 days would only ever
    generate a notification about #1, forever, for as long as #1 stayed
    unpaid. upcoming_installments() already solves both problems.)

    Because a loan can surface two rows here (one overdue, one upcoming),
    the "already notified today" guard is keyed per (loan, due_date), not
    just per loan - see _already_notified_today()'s due_date param -
    otherwise notifying about the overdue installment first would block
    the separate upcoming notification from ever being created today."""
    from apps.loans import services as loan_services
    from apps.notifications.models import Notification

    created = []
    today = timezone.now().date()
    for row in loan_services.upcoming_installments(within_days=upcoming_days, reference_date=today):
        loan = row["loan"]
        if _already_notified_today(Notification.Type.LOAN_INSTALLMENT_DUE, loan, due_date=row["due_date"]):
            continue

        notification = Notification.objects.create(
            type=Notification.Type.LOAN_INSTALLMENT_DUE,
            title=f"Installment #{row['installment_number']} due for {loan.lender_name}",
            message=(
                f"Installment #{row['installment_number']} of {row['installment_amount']} for the "
                f"{loan.lender_name} loan is due on {row['due_date']}."
            ),
            content_type=ContentType.objects.get_for_model(loan),
            object_id=str(loan.pk),
            due_date=row["due_date"],
        )
        created.append(notification)
    return created


def run_daily_notification_check(upcoming_days=7):
    """The single entry point the management command (and, later, a
    Celery beat task if this project grows into needing one) calls."""
    invoice_notifications = generate_due_invoice_notifications()
    loan_notifications = generate_loan_installment_notifications(upcoming_days=upcoming_days)
    return {
        "due_invoice_notifications_created": len(invoice_notifications),
        "loan_installment_notifications_created": len(loan_notifications),
    }
