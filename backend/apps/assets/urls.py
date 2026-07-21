from rest_framework.routers import DefaultRouter

from apps.assets.views import AssetIncidentViewSet, AssetViewSet

router = DefaultRouter()
router.register("assets", AssetViewSet, basename="asset")
router.register("asset-incidents", AssetIncidentViewSet, basename="assetincident")

urlpatterns = router.urls
