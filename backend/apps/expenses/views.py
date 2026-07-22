from rest_framework import viewsets

from apps.accounts.permissions import IsAdminOrHasModelPermission
from apps.expenses.models import Expense
from apps.expenses.serializers import ExpenseSerializer


class ExpenseViewSet(viewsets.ModelViewSet):
    """Full CRUD, restricted to Admin or Staff explicitly granted
    add/change/delete/view_expense permission. List supports ?date_from=
    &date_to= filtering on the expense's own `date` field, matching every
    other report/list endpoint's date-range convention in this project."""

    queryset = Expense.objects.all().order_by("-date")
    serializer_class = ExpenseSerializer
    permission_classes = [IsAdminOrHasModelPermission]

    def get_queryset(self):
        qs = super().get_queryset()
        params = self.request.query_params

        category = params.get("category")
        if category:
            qs = qs.filter(category=category.upper())

        date_from = params.get("date_from")
        if date_from:
            qs = qs.filter(date__gte=date_from)

        date_to = params.get("date_to")
        if date_to:
            qs = qs.filter(date__lte=date_to)

        return qs

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    def perform_destroy(self, instance):
        instance.delete()  # soft delete, see BaseModel.delete()
