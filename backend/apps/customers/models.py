from django.db import models

from apps.common.models import BaseModel


class Customer(BaseModel):
    """Customers never log in - they only exist as records, created by an
    Admin or permitted Staff."""

    RED_LIST_UNDERPAYMENT_THRESHOLD = 3

    name = models.CharField(max_length=150)
    phone = models.CharField(max_length=20, unique=True)
    address = models.TextField(blank=True)

    # Basic profile fields - extendable later.
    email = models.EmailField(null=True, blank=True)

    is_red_listed = models.BooleanField(default=False)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name

    def evaluate_red_list_status(self, underpayment_count, threshold=None):
        """Red-list flagging logic, not yet wired to invoices.

        Once invoice/payment tracking exists, the invoices app will call this
        with the customer's count of invoices that were underpaid, and this
        decides whether the customer should be (or remain) red-listed.
        """
        threshold = self.RED_LIST_UNDERPAYMENT_THRESHOLD if threshold is None else threshold
        should_be_red_listed = underpayment_count >= threshold

        if should_be_red_listed != self.is_red_listed:
            self.is_red_listed = should_be_red_listed
            self.save(update_fields=["is_red_listed"])

        return self.is_red_listed
