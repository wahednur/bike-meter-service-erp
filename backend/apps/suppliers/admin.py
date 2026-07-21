from django.contrib import admin

from apps.suppliers.models import Supplier


@admin.register(Supplier)
class SupplierAdmin(admin.ModelAdmin):
    list_display = ["name", "phone", "is_deleted"]
    list_filter = ["is_deleted"]
    search_fields = ["name", "phone"]
    readonly_fields = ["created_at", "updated_at"]
