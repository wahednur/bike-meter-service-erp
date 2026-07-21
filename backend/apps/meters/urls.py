from rest_framework.routers import DefaultRouter

from apps.meters.views import MeterViewSet, MileageCorrectionDeviceViewSet

router = DefaultRouter()
router.register("meters", MeterViewSet, basename="meter")
router.register("mileage-correction-devices", MileageCorrectionDeviceViewSet, basename="mileagecorrectiondevice")

urlpatterns = router.urls
