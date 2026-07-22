from django.contrib import admin

from apps.shop_profile.models import ShopProfile


@admin.register(ShopProfile)
class ShopProfileAdmin(admin.ModelAdmin):
    list_display = ["shop_name", "phone"]
    readonly_fields = ["created_at", "updated_at"]

    def has_add_permission(self, request):
        # Singleton - block adding a second row from the admin.
        return not ShopProfile.objects.exists()

    def has_delete_permission(self, request, obj=None):
        return False
