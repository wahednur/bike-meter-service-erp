from django.urls import path
from rest_framework.routers import DefaultRouter

from apps.invoices.views import InvoiceViewSet, PublicInvoiceView

router = DefaultRouter()
router.register("invoices", InvoiceViewSet, basename="invoice")

urlpatterns = router.urls + [
    path("public/invoices/<str:token>/", PublicInvoiceView.as_view(), name="public-invoice"),
]
