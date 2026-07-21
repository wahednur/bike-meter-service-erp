from django.contrib import admin

from apps.customers.models import Customer


@admin.register(Customer)
class CustomerAdmin(admin.ModelAdmin):
    list_display = ["name", "phone", "email", "is_red_listed", "is_deleted"]
    list_filter = ["is_red_listed", "is_deleted"]
    search_fields = ["name", "phone", "email"]
    readonly_fields = ["created_at", "updated_at"]
