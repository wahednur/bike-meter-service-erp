from rest_framework import serializers

from apps.customers.models import Customer


class CustomerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Customer
        fields = [
            "id", "name", "phone", "address", "email", "is_red_listed",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "created_by"]


class CustomerLedgerInvoiceSerializer(serializers.Serializer):
    """A trimmed view of an Invoice for the ledger - just enough to show
    the customer's billing history without pulling in every line item."""

    id = serializers.IntegerField()
    invoice_no = serializers.CharField()
    status = serializers.CharField()
    created_date = serializers.DateField()
    total_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    paid_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    outstanding_amount = serializers.DecimalField(max_digits=12, decimal_places=2)


class CustomerLedgerSerializer(serializers.Serializer):
    customer = CustomerSerializer()
    invoices = CustomerLedgerInvoiceSerializer(many=True)
    total_billed = serializers.DecimalField(max_digits=12, decimal_places=2)
    total_paid = serializers.DecimalField(max_digits=12, decimal_places=2)
    total_due = serializers.DecimalField(max_digits=12, decimal_places=2)
