from django.urls import path

from apps.shop_profile.views import ShopProfileView

urlpatterns = [
    path("shop-profile/", ShopProfileView.as_view(), name="shop-profile"),
]
