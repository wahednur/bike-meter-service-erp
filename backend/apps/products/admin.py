from django.contrib import admin

from apps.products.models import Product, ProductRestockEvent


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = [
        "name", "sku", "supplier", "buy_price", "sale_price",
        "current_stock_quantity", "is_deleted",
    ]
    list_filter = ["supplier", "is_deleted"]
    search_fields = ["name", "sku"]
    readonly_fields = ["created_at", "updated_at"]


@admin.register(ProductRestockEvent)
class ProductRestockEventAdmin(admin.ModelAdmin):
    list_display = ["product", "quantity", "unit_price", "extra_costs", "landed_unit_cost", "total_cost", "restocked_at"]
    list_filter = ["product"]
    readonly_fields = [f.name for f in ProductRestockEvent._meta.fields]

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False
