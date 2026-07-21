from django.contrib import admin

from apps.assets.models import Asset, AssetIncident


class AssetIncidentInline(admin.TabularInline):
    model = AssetIncident
    extra = 0


@admin.register(Asset)
class AssetAdmin(admin.ModelAdmin):
    list_display = ["name", "purchase_price", "purchase_date", "supplier", "has_warranty", "is_deleted"]
    list_filter = ["has_warranty", "supplier", "is_deleted"]
    search_fields = ["name"]
    readonly_fields = ["created_at", "updated_at"]
    inlines = [AssetIncidentInline]


@admin.register(AssetIncident)
class AssetIncidentAdmin(admin.ModelAdmin):
    list_display = ["asset", "type", "cost", "date", "is_deleted"]
    list_filter = ["type", "is_deleted"]
    readonly_fields = ["created_at", "updated_at"]
