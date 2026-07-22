import json

from rest_framework import serializers

from apps.customers.models import Customer


class CustomerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Customer
        fields = [
            "id", "name", "phone", "address", "description", "email", "is_red_listed",
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


class CustomerCsvUploadSerializer(serializers.Serializer):
    file = serializers.FileField()

    def validate_file(self, value):
        if not value.name.lower().endswith(".csv"):
            raise serializers.ValidationError("File must be a .csv file.")
        return value


class CustomerCsvImportSerializer(CustomerCsvUploadSerializer):
    # Sent as a JSON-encoded string form field alongside the file, e.g.
    # column_mapping='{"name": "Customer Name", "phone": "Mobile"}'
    column_mapping = serializers.CharField()

    def validate_column_mapping(self, value):
        try:
            mapping = json.loads(value)
        except (TypeError, ValueError):
            raise serializers.ValidationError("column_mapping must be valid JSON.")
        if not isinstance(mapping, dict) or not mapping:
            raise serializers.ValidationError("column_mapping must be a non-empty JSON object.")
        if not mapping.get("name") or not mapping.get("phone"):
            raise serializers.ValidationError("column_mapping must map both 'name' and 'phone' to a CSV column.")
        return mapping


class CustomerCsvPreviewResponseSerializer(serializers.Serializer):
    headers = serializers.ListField(child=serializers.CharField())
    rows = serializers.ListField(child=serializers.DictField())


class CustomerCsvSkippedRowSerializer(serializers.Serializer):
    row = serializers.IntegerField()
    phone = serializers.CharField()
    reason = serializers.CharField()


class CustomerCsvFailedRowSerializer(serializers.Serializer):
    row = serializers.IntegerField()
    reason = serializers.CharField()


class CustomerCsvImportResponseSerializer(serializers.Serializer):
    total = serializers.IntegerField()
    created_count = serializers.IntegerField()
    skipped_count = serializers.IntegerField()
    failed_count = serializers.IntegerField()
    created = CustomerSerializer(many=True)
    skipped = CustomerCsvSkippedRowSerializer(many=True)
    failed = CustomerCsvFailedRowSerializer(many=True)
