from django.urls import path
from rest_framework.routers import DefaultRouter

from apps.accounts.views import LoginView, LogoutView, RefreshView, UserViewSet

router = DefaultRouter()
router.register("users", UserViewSet, basename="user")

urlpatterns = [
    path("auth/login/", LoginView.as_view(), name="login"),
    path("auth/refresh/", RefreshView.as_view(), name="token_refresh"),
    path("auth/logout/", LogoutView.as_view({"post": "create"}), name="logout"),
    *router.urls,
]
