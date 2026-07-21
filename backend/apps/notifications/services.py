from django.contrib.contenttypes.models import ContentType
from django.utils import timezone


def _already_notified_today(notif_type, obj):
    """Idempotency guard: running the daily check more than once on the
    same day (or the scheduler firing twice) shouldn't spam duplicate
    notifications for the same object."""
    from apps.notifications.models import Notification

    return Notification.objects.filter(
        type=notif_type,
        content_type=ContentType.objects.get_for_model(obj),
        object_id=str(obj.pk),
        created_at__date=timezone.now().date(),
    ).exists()


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
    """One notification per loan whose next unpaid installment is due
    within `upcoming_days`, unless it's already been notified today."""
    from apps.loans import services as loan_services
    from apps.loans.models import Loan
    from apps.notifications.models import Notification

    created = []
    for loan in Loan.objects.all():
        due_date = loan_services.compute_next_installment_due_date(loan)
        if due_date is None:
            continue

        today = timezone.now().date()
        if (due_date - today).days > upcoming_days:
            continue

        if _already_notified_today(Notification.Type.LOAN_INSTALLMENT_DUE, loan):
            continue

        stats = loan_services.compute_loan_stats(loan)
        installment_number = stats["installments_paid_count"] + 1
        notification = Notification.objects.create(
            type=Notification.Type.LOAN_INSTALLMENT_DUE,
            title=f"Installment #{installment_number} due for {loan.lender_name}",
            message=(
                f"Installment #{installment_number} of {loan.installment_amount} for the "
                f"{loan.lender_name} loan is due on {due_date}."
            ),
            content_type=ContentType.objects.get_for_model(loan),
            object_id=str(loan.pk),
            due_date=due_date,
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
