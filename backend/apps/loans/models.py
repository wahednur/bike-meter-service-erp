from decimal import Decimal

from django.db import models

from apps.common.models import BaseModel


class Loan(BaseModel):
    class LenderType(models.TextChoices):
        BANK = "BANK", "Bank"
        NGO = "NGO", "NGO"

    class InstallmentFrequency(models.TextChoices):
        WEEKLY = "WEEKLY", "Weekly"
        MONTHLY = "MONTHLY", "Monthly"

    lender_name = models.CharField(max_length=150)
    lender_type = models.CharField(max_length=10, choices=LenderType.choices)
    loan_amount = models.DecimalField(max_digits=12, decimal_places=2)
    deposit_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    interest_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total_installments = models.PositiveIntegerField()
    installment_amount = models.DecimalField(max_digits=10, decimal_places=2)
    installment_frequency = models.CharField(max_length=10, choices=InstallmentFrequency.choices)
    start_date = models.DateField()

    class Meta:
        ordering = ["-start_date"]

    def __str__(self):
        return f"{self.lender_name} ({self.get_lender_type_display()})"

    @property
    def total_payable(self):
        # Defensive Decimal() coercion: a freshly-constructed instance (not
        # yet round-tripped through the DB) can still hold plain strings on
        # its Decimal fields if it was created with string kwargs - Django
        # only coerces to Decimal on load, not on assignment.
        return Decimal(self.loan_amount) + Decimal(self.deposit_amount) + Decimal(self.interest_amount)


class LoanInstallmentPayment(BaseModel):
    loan = models.ForeignKey(Loan, on_delete=models.CASCADE, related_name="installment_payments")
    amount_paid = models.DecimalField(max_digits=10, decimal_places=2)
    payment_date = models.DateField()
    installment_number = models.PositiveIntegerField()
    # Optional proof of payment (receipt photo or PDF) - see
    # LoanInstallmentPaymentSerializer.validate_attachment() for the
    # image/pdf + 20KB size restrictions enforced on upload.
    attachment = models.FileField(upload_to="loan-installment-payments/", null=True, blank=True)

    class Meta:
        ordering = ["installment_number"]

    def __str__(self):
        return f"Installment #{self.installment_number} for {self.loan.lender_name}"
