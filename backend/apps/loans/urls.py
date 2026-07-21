from rest_framework.routers import DefaultRouter

from apps.loans.views import LoanInstallmentPaymentViewSet, LoanViewSet

router = DefaultRouter()
router.register("loans", LoanViewSet, basename="loan")
router.register("loan-installment-payments", LoanInstallmentPaymentViewSet, basename="loaninstallmentpayment")

urlpatterns = router.urls
