from rest_framework.routers import DefaultRouter

from apps.products.views import ProductViewSet, PurchaseViewSet

router = DefaultRouter()
router.register("products", ProductViewSet, basename="product")
router.register("purchases", PurchaseViewSet, basename="purchase")

urlpatterns = router.urls
