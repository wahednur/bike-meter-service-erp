from django.contrib import admin

from apps.services.models import Service, ServiceCategory


@admin.register(ServiceCategory)
class ServiceCategoryAdmin(admin.ModelAdmin):
    list_display = ["name", "is_deleted"]
    list_filter = ["is_deleted"]
    readonly_fields = ["created_at", "updated_at"]


@admin.register(Service)
class ServiceAdmin(admin.ModelAdmin):
    list_display = ["name", "category", "service_price", "is_deleted"]
    list_filter = ["category", "is_deleted"]
    search_fields = ["name", "description"]
    readonly_fields = ["created_at", "updated_at"]
