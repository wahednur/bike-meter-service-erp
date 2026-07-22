from django.urls import path
from rest_framework.routers import DefaultRouter

from apps.invoices.views import InvoiceViewSet, PaymentViewSet, PublicInvoiceView

router = DefaultRouter()
router.register("invoices", InvoiceViewSet, basename="invoice")
router.register("payments", PaymentViewSet, basename="payment")

urlpatterns = router.urls + [
    path("public/invoices/<str:token>/", PublicInvoiceView.as_view(), name="public-invoice"),
    # Edit/delete a single line item. Not DRF @action routes (those can only
    # add a static suffix after the detail pk, not a second dynamic id), so
    # they're wired up directly against the two plain methods on
    # InvoiceViewSet - see update_service_line()'s docstring in views.py.
    path(
        "invoices/<int:pk>/service-lines/<int:line_pk>/",
        InvoiceViewSet.as_view({"patch": "update_service_line", "delete": "destroy_service_line"}),
        name="invoice-service-line-detail",
    ),
    path(
        "invoices/<int:pk>/product-lines/<int:line_pk>/",
        InvoiceViewSet.as_view({"patch": "update_product_line", "delete": "destroy_product_line"}),
        name="invoice-product-line-detail",
    ),
]
