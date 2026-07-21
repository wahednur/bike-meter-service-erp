from django.urls import path
from rest_framework.routers import DefaultRouter

from apps.ecommerce.views import (
    OrderViewSet,
    PlaceOrderView,
    PublicOrderTrackingView,
    PublicProductViewSet,
)

router = DefaultRouter()
router.register("orders", OrderViewSet, basename="order")
router.register("public/products", PublicProductViewSet, basename="public-product")

urlpatterns = router.urls + [
    path("public/orders/", PlaceOrderView.as_view(), name="public-order-place"),
    path("public/orders/<str:token>/", PublicOrderTrackingView.as_view(), name="public-order-tracking"),
]
