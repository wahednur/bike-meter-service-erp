from django.core.management.base import BaseCommand

from apps.notifications import services as notification_services


class Command(BaseCommand):
    help = (
        "Daily check: creates due-invoice and upcoming loan-installment "
        "notifications. Run once per day via cron / Windows Task Scheduler "
        "(or swap for a Celery beat task later without changing the logic - "
        "it all lives in apps.notifications.services)."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            "--upcoming-days", type=int, default=7,
            help="How many days ahead counts as 'upcoming' for loan installments (default: 7).",
        )

    def handle(self, *args, **options):
        result = notification_services.run_daily_notification_check(upcoming_days=options["upcoming_days"])
        self.stdout.write(self.style.SUCCESS(
            f"Created {result['due_invoice_notifications_created']} due-invoice notification(s) and "
            f"{result['loan_installment_notifications_created']} loan-installment notification(s)."
        ))
