from django.contrib import admin

from apps.loans.models import Loan, LoanInstallmentPayment


class LoanInstallmentPaymentInline(admin.TabularInline):
    model = LoanInstallmentPayment
    extra = 0


@admin.register(Loan)
class LoanAdmin(admin.ModelAdmin):
    list_display = [
        "lender_name", "lender_type", "loan_amount", "total_installments",
        "installment_frequency", "start_date", "is_deleted",
    ]
    list_filter = ["lender_type", "installment_frequency", "is_deleted"]
    search_fields = ["lender_name"]
    readonly_fields = ["created_at", "updated_at"]
    inlines = [LoanInstallmentPaymentInline]


@admin.register(LoanInstallmentPayment)
class LoanInstallmentPaymentAdmin(admin.ModelAdmin):
    list_display = ["loan", "installment_number", "amount_paid", "payment_date", "is_deleted"]
    list_filter = ["is_deleted"]
    readonly_fields = ["created_at", "updated_at"]
