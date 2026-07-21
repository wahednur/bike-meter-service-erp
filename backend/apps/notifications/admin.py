from django.contrib import admin

from apps.notifications.models import Notification


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ["type", "title", "due_date", "is_read", "created_at"]
    list_filter = ["type", "is_read"]
    search_fields = ["title", "message"]
    readonly_fields = ["type", "title", "message", "due_date", "content_type", "object_id", "created_at"]

    def has_add_permission(self, request):
        return False
