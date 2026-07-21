from rest_framework import status, viewsets
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from apps.accounts.models import User
from apps.accounts.permissions import IsAdmin
from apps.accounts.serializers import (
    LoginSerializer,
    LogoutSerializer,
    UserCreateSerializer,
    UserSerializer,
)


class LoginView(TokenObtainPairView):
    """POST {identifier, password} -> {access, refresh, user}."""

    permission_classes = [AllowAny]
    serializer_class = LoginSerializer


class RefreshView(TokenRefreshView):
    """POST {refresh} -> {access}. Provided by SimpleJWT as-is."""

    permission_classes = [AllowAny]


class LogoutView(viewsets.ViewSet):
    """POST {refresh} -> blacklists the refresh token so it can no longer be used."""

    permission_classes = [AllowAny]

    def create(self, request):
        serializer = LogoutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(status=status.HTTP_205_RESET_CONTENT)


class UserViewSet(viewsets.ModelViewSet):
    """System user management (Admin/Staff accounts).

    Only Admins may create, update, or remove system users - this is where
    "Admin can do everything, including creating other system users" is
    enforced at the API level.
    """

    queryset = User.objects.filter(is_deleted=False).order_by("name")
    permission_classes = [IsAdmin]

    def get_serializer_class(self):
        if self.action == "create":
            return UserCreateSerializer
        return UserSerializer

    def perform_destroy(self, instance):
        instance.delete()  # soft delete, see User.delete()
