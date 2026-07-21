from django.contrib import admin

from apps.invoices.models import (
    Invoice,
    InvoiceMeterEntry,
    InvoicePayment,
    InvoiceProductLine,
    InvoiceServiceLine,
)


class InvoiceMeterEntryInline(admin.TabularInline):
    model = InvoiceMeterEntry
    extra = 0
    readonly_fields = ["service_date", "paid_share"]


class InvoiceServiceLineInline(admin.TabularInline):
    model = InvoiceServiceLine
    extra = 0


class InvoiceProductLineInline(admin.TabularInline):
    model = InvoiceProductLine
    extra = 0


class InvoicePaymentInline(admin.TabularInline):
    model = InvoicePayment
    extra = 0


@admin.register(Invoice)
class InvoiceAdmin(admin.ModelAdmin):
    list_display = ["invoice_no", "customer", "status", "total_amount", "paid_amount", "created_date"]
    list_filter = ["status", "created_date"]
    search_fields = ["invoice_no", "customer__name", "customer__phone", "public_share_token"]
    readonly_fields = [
        "invoice_no", "total_amount", "paid_amount", "public_share_token",
        "created_date", "created_at", "updated_at",
    ]
    inlines = [InvoiceMeterEntryInline, InvoiceServiceLineInline, InvoiceProductLineInline, InvoicePaymentInline]
