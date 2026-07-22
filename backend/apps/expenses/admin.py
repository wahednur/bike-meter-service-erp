from django.contrib import admin

from apps.expenses.models import Expense


@admin.register(Expense)
class ExpenseAdmin(admin.ModelAdmin):
    list_display = ["category", "amount", "date", "created_by", "is_deleted"]
    list_filter = ["category", "is_deleted"]
    search_fields = ["note"]
    readonly_fields = ["created_at", "updated_at"]
