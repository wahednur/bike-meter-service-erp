from django.contrib.contenttypes.fields import GenericRelation
from django.db import models
from django.utils import timezone

from apps.common.models import BaseModel
from apps.customers.models import Customer
from apps.meters.models import MileageCorrectionDevice, Meter
from apps.products.models import Product
from apps.services.models import Service


class Invoice(BaseModel):
    """One customer visit's running bill. Never create a second open
    invoice for a customer - see apps.invoices.services.get_or_create_open_invoice()
    (rule a). total_amount/paid_amount/status are all computed and kept in
    sync by the service layer; treat them as read-only here."""

    class Status(models.TextChoices):
        UNPAID = "UNPAID", "Unpaid"
        PARTIAL = "PARTIAL", "Partial Paid"
        PAID = "PAID", "Paid"
        CANCELLED = "CANCELLED", "Cancelled"

    customer = models.ForeignKey(Customer, on_delete=models.PROTECT, related_name="invoices")
    invoice_no = models.CharField(max_length=30, unique=True, editable=False)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.UNPAID)
    total_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0, editable=False)
    paid_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0, editable=False)
    created_date = models.DateField(auto_now_add=True)
    public_share_token = models.CharField(max_length=16, unique=True, editable=False)

    # Sticky flag: set True the first time this invoice is ever seen in
    # PARTIAL status (i.e. some meter/service on it received less than its
    # full price at some point), and never cleared even once it's paid off.
    # Feeds the customer red-list rule - see apps.invoices.services.apply_red_list_check().
    had_shortfall = models.BooleanField(default=False, editable=False)

    audit_logs = GenericRelation(
        "audit.AuditLogEntry", content_type_field="content_type", object_id_field="object_id",
    )

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return self.invoice_no

    def save(self, *args, **kwargs):
        # Safety net so invoice_no/public_share_token are always populated
        # regardless of creation path (admin, shell, tests). The normal API
        # path sets these explicitly via apps.invoices.services.create_invoice().
        if not self.invoice_no or not self.public_share_token:
            from apps.invoices.services import generate_invoice_no, generate_public_share_token

            if not self.invoice_no:
                self.invoice_no = generate_invoice_no()
            if not self.public_share_token:
                self.public_share_token = generate_public_share_token()
        super().save(*args, **kwargs)

    @property
    def outstanding_amount(self):
        return self.total_amount - self.paid_amount

    @property
    def is_editable(self):
        return self.status in (self.Status.UNPAID, self.Status.PARTIAL)


class InvoiceMeterEntry(BaseModel):
    """One meter brought in on this invoice/visit."""

    invoice = models.ForeignKey(Invoice, on_delete=models.CASCADE, related_name="meter_entries")
    meter = models.ForeignKey(Meter, on_delete=models.PROTECT, related_name="invoice_entries")
    serial_number = models.CharField(max_length=100)
    condition_note = models.TextField(blank=True)
    previous_km = models.PositiveIntegerField(null=True, blank=True)
    current_km = models.PositiveIntegerField(null=True, blank=True)
    mileage_correction_device = models.ForeignKey(
        MileageCorrectionDevice,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="invoice_entries",
    )
    service_date = models.DateTimeField(auto_now_add=True)

    # Rule (b): this entry's share of invoice.paid_amount, kept in sync by
    # apps.invoices.services.split_payment_across_meters().
    paid_share = models.DecimalField(max_digits=10, decimal_places=2, default=0, editable=False)

    class Meta:
        ordering = ["service_date"]
        verbose_name_plural = "invoice meter entries"

    def __str__(self):
        return f"{self.meter} (serial {self.serial_number}) on {self.invoice.invoice_no}"


class InvoiceServiceLine(BaseModel):
    invoice = models.ForeignKey(Invoice, on_delete=models.CASCADE, related_name="service_lines")
    meter_entry = models.ForeignKey(
        InvoiceMeterEntry,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="service_lines",
    )
    service = models.ForeignKey(Service, on_delete=models.PROTECT, related_name="invoice_lines")
    price_charged = models.DecimalField(max_digits=10, decimal_places=2)

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"{self.service.name} on {self.invoice.invoice_no}"


class InvoiceProductLine(BaseModel):
    invoice = models.ForeignKey(Invoice, on_delete=models.CASCADE, related_name="product_lines")
    product = models.ForeignKey(Product, on_delete=models.PROTECT, related_name="invoice_lines")
    quantity = models.PositiveIntegerField(default=1)
    price_charged = models.DecimalField(max_digits=10, decimal_places=2)

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"{self.quantity} x {self.product.name} on {self.invoice.invoice_no}"

    @property
    def line_total(self):
        return self.price_charged * self.quantity


class InvoicePayment(BaseModel):
    class PaymentMethod(models.TextChoices):
        CASH = "CASH", "Cash"
        BKASH = "BKASH", "bKash"
        NAGAD = "NAGAD", "Nagad"
        BANK_TRANSFER = "BANK_TRANSFER", "Bank Transfer"
        CARD = "CARD", "Card"
        OTHER = "OTHER", "Other"

    invoice = models.ForeignKey(Invoice, on_delete=models.CASCADE, related_name="payments")
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment_method = models.CharField(max_length=20, choices=PaymentMethod.choices, default=PaymentMethod.CASH)
    payment_date = models.DateTimeField(default=timezone.now)
    note = models.TextField(blank=True)

    class Meta:
        ordering = ["payment_date"]

    def __str__(self):
        return f"{self.amount} on {self.invoice.invoice_no}"
