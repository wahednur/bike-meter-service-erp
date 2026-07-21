from rest_framework import status, viewsets
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response

from apps.accounts.permissions import IsAdminOrHasModelPermission
from apps.loans import services as loan_services
from apps.loans.exceptions import LoanError
from apps.loans.models import Loan, LoanInstallmentPayment
from apps.loans.serializers import LoanInstallmentPaymentSerializer, LoanSerializer


class LoanViewSet(viewsets.ModelViewSet):
    """Full CRUD, restricted to Admin or Staff explicitly granted
    add/change/delete/view_loan permission. Supports multiple concurrent
    loans from different lenders - list returns every loan with its full
    computed summary."""

    queryset = Loan.objects.all().order_by("-start_date")
    serializer_class = LoanSerializer
    permission_classes = [IsAdminOrHasModelPermission]

    def get_queryset(self):
        qs = super().get_queryset()
        lender_type = self.request.query_params.get("lender_type")
        if lender_type:
            qs = qs.filter(lender_type=lender_type.upper())
        return qs

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def perform_destroy(self, instance):
        instance.delete()  # soft delete, see BaseModel.delete()


class LoanInstallmentPaymentViewSet(viewsets.ModelViewSet):
    """Full CRUD, restricted to Admin or Staff explicitly granted
    add/change/delete/view_loaninstallmentpayment permission. Filter by
    ?loan=<id>. Creation goes through the service layer so overpayment and
    invalid installment numbers are rejected."""

    queryset = LoanInstallmentPayment.objects.select_related("loan").order_by("-payment_date")
    serializer_class = LoanInstallmentPaymentSerializer
    permission_classes = [IsAdminOrHasModelPermission]

    def get_queryset(self):
        qs = super().get_queryset()
        loan_id = self.request.query_params.get("loan")
        if loan_id:
            qs = qs.filter(loan_id=loan_id)
        return qs

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            payment = loan_services.add_installment_payment(
                loan=serializer.validated_data["loan"],
                amount_paid=serializer.validated_data["amount_paid"],
                payment_date=serializer.validated_data["payment_date"],
                installment_number=serializer.validated_data["installment_number"],
                user=request.user,
            )
        except LoanError as exc:
            raise ValidationError(str(exc))
        return Response(self.get_serializer(payment).data, status=status.HTTP_201_CREATED)

    def perform_destroy(self, instance):
        instance.delete()  # soft delete, see BaseModel.delete()
