from django.contrib import admin

from apps.audit.models import AuditLog, AuditLogEntry


@admin.register(AuditLogEntry)
class AuditLogEntryAdmin(admin.ModelAdmin):
    list_display = ["action", "content_type", "object_id", "created_by", "created_at"]
    list_filter = ["content_type", "action"]
    readonly_fields = ["content_type", "object_id", "action", "description", "created_at", "created_by"]

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ["action", "content_type", "object_id", "object_repr", "created_by", "created_at"]
    list_filter = ["content_type", "action"]
    search_fields = ["object_repr", "object_id"]
    readonly_fields = [
        "content_type", "object_id", "object_repr", "action", "changed_fields", "created_at", "created_by",
    ]

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False
