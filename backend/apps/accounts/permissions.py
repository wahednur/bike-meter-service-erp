from rest_framework.permissions import BasePermission, DjangoModelPermissions

from apps.accounts.models import User


class IsAdmin(BasePermission):
    """Full access. Grants everything, including managing customers, suppliers,
    and other system users."""

    def has_permission(self, request, view):
        user = request.user
        return bool(
            user
            and user.is_authenticated
            and (user.is_superuser or user.role == User.Role.ADMIN)
        )


class IsStaffOrAdmin(BasePermission):
    """Any active system user (Admin or Staff). Use together with
    ``DjangoModelPermissions``/``HasSpecificPermission`` on the view to scope
    what a Staff user is actually allowed to do on that endpoint."""

    def has_permission(self, request, view):
        user = request.user
        return bool(user and user.is_authenticated and user.is_active)


class HasSpecificPermission(BasePermission):
    """Fine-grained Staff permission check.

    Admins (is_superuser=True, set automatically for role=Admin) always pass,
    because Django's permission backend treats superusers as having every
    permission. Staff users only pass if they've been explicitly granted the
    permission codename declared on the view via ``required_permission``,
    through a Django Group or direct user permission.

    Concrete staff permission codenames are not assigned yet - this class is
    the mechanism; grant/deny lists come later per endpoint.
    """

    def has_permission(self, request, view):
        user = request.user
        if not (user and user.is_authenticated and user.is_active):
            return False
        if user.is_superuser or user.role == User.Role.ADMIN:
            return True

        required_permission = getattr(view, "required_permission", None)
        if not required_permission:
            # No specific permission declared on the view: default-deny for Staff.
            return False
        return user.has_perm(required_permission)


class IsAdminOrHasModelPermission(DjangoModelPermissions):
    """Full-CRUD gate for a ModelViewSet: "Admin or permitted Staff".

    Admins pass everything for free: role=Admin auto-sets is_superuser=True
    (see User.save()), and Django's ModelBackend already grants superusers
    every permission without needing rows in auth_permission/groups.

    Staff must hold the model's add/change/delete/view permission (assigned
    via a Django Group) matching the HTTP verb used. Unlike DRF's stock
    DjangoModelPermissions, GET/HEAD/OPTIONS here also require view_<model> -
    by default Staff can't even list/retrieve until granted that permission.
    """

    perms_map = {
        "GET": ["%(app_label)s.view_%(model_name)s"],
        "OPTIONS": ["%(app_label)s.view_%(model_name)s"],
        "HEAD": ["%(app_label)s.view_%(model_name)s"],
        "POST": ["%(app_label)s.add_%(model_name)s"],
        "PUT": ["%(app_label)s.change_%(model_name)s"],
        "PATCH": ["%(app_label)s.change_%(model_name)s"],
        "DELETE": ["%(app_label)s.delete_%(model_name)s"],
    }
