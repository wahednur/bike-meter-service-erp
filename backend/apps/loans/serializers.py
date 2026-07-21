from rest_framework import serializers

from apps.loans import services as loan_services
from apps.loans.models import Loan, LoanInstallmentPayment


class LoanInstallmentPaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = LoanInstallmentPayment
        fields = [
            "id", "loan", "amount_paid", "payment_date", "installment_number",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "created_by"]


class LoanSerializer(serializers.ModelSerializer):
    """Used for both list and detail - every loan already carries its full
    computed summary, so the list endpoint doubles as an overview of all
    loans across every lender."""

    total_payable = serializers.ReadOnlyField()
    installments_paid_count = serializers.SerializerMethodField()
    installments_remaining = serializers.SerializerMethodField()
    amount_paid_so_far = serializers.SerializerMethodField()
    amount_remaining = serializers.SerializerMethodField()

    class Meta:
        model = Loan
        fields = [
            "id", "lender_name", "lender_type", "loan_amount", "deposit_amount", "interest_amount",
            "total_payable", "total_installments", "installment_amount", "installment_frequency",
            "start_date", "installments_paid_count", "installments_remaining",
            "amount_paid_so_far", "amount_remaining",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "created_by"]

    def get_installments_paid_count(self, obj):
        return loan_services.compute_loan_stats(obj)["installments_paid_count"]

    def get_installments_remaining(self, obj):
        return loan_services.compute_loan_stats(obj)["installments_remaining"]

    def get_amount_paid_so_far(self, obj):
        return loan_services.compute_loan_stats(obj)["amount_paid_so_far"]

    def get_amount_remaining(self, obj):
        return loan_services.compute_loan_stats(obj)["amount_remaining"]
