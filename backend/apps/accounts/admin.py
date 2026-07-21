from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from apps.accounts.models import User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    ordering = ["name"]
    list_display = ["name", "email", "phone", "role", "is_active", "is_deleted"]
    list_filter = ["role", "is_active", "is_deleted"]
    search_fields = ["name", "email", "phone"]
    readonly_fields = ["id", "created_at", "updated_at"]

    fieldsets = (
        (None, {"fields": ("email", "phone", "password")}),
        ("Personal info", {"fields": ("name",)}),
        ("Role & status", {"fields": ("role", "is_active", "is_deleted", "deleted_at")}),
        ("Permissions", {"fields": ("is_staff", "is_superuser", "groups", "user_permissions")}),
        ("Audit", {"fields": ("created_by", "created_at", "updated_at")}),
    )
    add_fieldsets = (
        (None, {
            "classes": ("wide",),
            "fields": ("email", "phone", "name", "role", "password1", "password2"),
        }),
    )
