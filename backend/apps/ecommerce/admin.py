from django.contrib import admin

from apps.ecommerce.models import Order, OrderItem


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ["order_no", "customer_name", "customer_phone", "status", "total_amount", "created_at"]
    list_filter = ["status"]
    search_fields = ["order_no", "customer_name", "customer_phone", "tracking_token"]
    readonly_fields = ["order_no", "tracking_token", "total_amount", "created_at", "updated_at"]
    inlines = [OrderItemInline]
