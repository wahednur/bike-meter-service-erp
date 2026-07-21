from django.contrib import admin

from apps.meters.models import MileageCorrectionDevice, Meter


@admin.register(Meter)
class MeterAdmin(admin.ModelAdmin):
    list_display = ["title", "brand", "model", "cc", "memory_type", "sales_price", "is_deleted"]
    list_filter = ["brand", "memory_type", "is_deleted"]
    search_fields = ["brand", "model", "ic_mcu_model"]
    readonly_fields = ["created_at", "updated_at"]


@admin.register(MileageCorrectionDevice)
class MileageCorrectionDeviceAdmin(admin.ModelAdmin):
    list_display = ["name", "purchase_price", "purchase_date", "memory_type_support", "is_deleted"]
    list_filter = ["memory_type_support", "is_deleted"]
    search_fields = ["name"]
    readonly_fields = ["created_at", "updated_at"]
