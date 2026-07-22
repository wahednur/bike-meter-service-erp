from rest_framework import serializers

from apps.expenses.models import Expense


class ExpenseSerializer(serializers.ModelSerializer):
    category_display = serializers.CharField(source="get_category_display", read_only=True)

    class Meta:
        model = Expense
        fields = [
            "id", "category", "category_display", "amount", "date", "note",
            "created_at", "updated_at", "created_by",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "created_by"]
