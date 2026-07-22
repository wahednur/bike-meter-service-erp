from django.db import models

from apps.common.models import BaseModel


class Expense(BaseModel):
    """A manual operating expense (rent, electricity, transport, etc.) -
    distinct from product restocks / asset / device purchases, which are
    already tracked on their own models and rolled into expense_report()
    separately. See apps.reports.services.expense_report()'s "other_expenses"
    breakdown bucket, which sums these in alongside those."""

    class Category(models.TextChoices):
        RENT = "RENT", "Rent"
        ELECTRICITY = "ELECTRICITY", "Electricity"
        TRANSPORT = "TRANSPORT", "Transport"
        MISC = "MISC", "Misc"

    category = models.CharField(max_length=20, choices=Category.choices)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    date = models.DateField()
    note = models.TextField(blank=True)

    class Meta:
        ordering = ["-date"]

    def __str__(self):
        return f"{self.get_category_display()} - {self.amount} on {self.date}"
