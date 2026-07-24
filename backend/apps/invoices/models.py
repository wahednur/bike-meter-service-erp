from datetime import date

from django.contrib.contenttypes.fields import GenericRelation
from django.db import models
from django.utils import timezone

from apps.assets.models import Asset
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
    # Defaults to today but editable - Admin only, see
    # apps.invoices.services.update_invoice_created_date() - e.g. to
    # backdate an invoice entered a day late.
    created_date = models.DateField(default=date.today)
    public_share_token = models.CharField(max_length=16, unique=True, editable=False)

    # Fixed BDT amount (never a percentage), applied at the invoice level -
    # not per line item. Admin-only, see apps.invoices.services.apply_discount().
    # total_amount is computed as (services + products) - discount_amount - waived_amount.
    discount_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0, editable=False)
    discount_note = models.TextField(blank=True, editable=False)

    # A deliberately accepted shortfall at closing time (rule 11/force_close_invoice()) -
    # distinct from discount_amount, which is a reduction given upfront. Only
    # ever set once, by force_close_invoice(); never user-editable directly.
    waived_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0, editable=False)
    waived_note = models.TextField(blank=True, editable=False)

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
    serial_number = models.CharField(max_length=100, blank=True, null=True)
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
    # The labor/service portion of this line's charge.
    price_charged = models.DecimalField(max_digits=10, decimal_places=2)

    # Combination repairs (e.g. Display Repair - polarizer paper only vs a
    # full panel swap) bill a part alongside the labor. Kept as two
    # independent, independently-editable amounts rather than folded into
    # price_charged, so the shop can see/adjust labor and parts separately.
    # product_used is optional - most service lines have neither.
    product_used = models.ForeignKey(
        Product, on_delete=models.PROTECT, null=True, blank=True, related_name="invoice_service_lines",
    )
    product_price = models.DecimalField(max_digits=10, decimal_places=2, default=0)

    # Opt-in: which shop tool/accessory (e.g. a soldering iron) was used to
    # perform this repair, if the shop owner bothered to tag it. Not every
    # service names one - see apps.assets.services.compute_asset_stats(),
    # which treats zero tagged lines as "not yet linked", not "worthless".
    asset_used = models.ForeignKey(
        Asset, on_delete=models.PROTECT, null=True, blank=True, related_name="invoice_service_lines_as_tool",
    )

    # When the work was actually done - independent of created_at (when
    # this row was entered) or the invoice's own created_date.
    added_date = models.DateField(default=date.today)

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"{self.service.name} on {self.invoice.invoice_no}"

    @property
    def line_total(self):
        return self.price_charged + self.product_price


class InvoiceProductLine(BaseModel):
    invoice = models.ForeignKey(Invoice, on_delete=models.CASCADE, related_name="product_lines")
    product = models.ForeignKey(Product, on_delete=models.PROTECT, related_name="invoice_lines")
    quantity = models.PositiveIntegerField(default=1)
    price_charged = models.DecimalField(max_digits=10, decimal_places=2)

    # When the product was actually sold - independent of created_at or the
    # invoice's own created_date. Defaults to today, editable.
    added_date = models.DateField(default=date.today)

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
