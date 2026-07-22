from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import IsAdmin
from apps.audit import services as audit_services
from apps.audit.serializers import AuditFeedEntrySerializer
from apps.reports.utils import get_date_range

DEFAULT_PAGE_SIZE = 25
MAX_PAGE_SIZE = 100


class AuditLogView(APIView):
    """GET /api/audit/log/ - Admin only (Staff never sees this - it's
    sensitive operational data, e.g. who applied a discount, who deleted a
    customer). Unified, paginated, filterable feed merging the automatic
    model-change trail (AuditLog) with hand-curated business events
    (AuditLogEntry) into one chronological list - see
    apps.audit.services.build_audit_feed().

    Optional filters:
        ?from_date=&to_date=  YYYY-MM-DD, matched against the entry's own
                               timestamp (same convention as every other
                               report in this project).
        ?user=<uuid>           the acting system user's id.
        ?model=<name>          content-type model name, e.g. "invoice",
                                "customer", "product".
        ?action=<value>        "CREATE"/"UPDATE"/"DELETE" for the automatic
                                trail, or a business-event action string
                                (e.g. "payment_added") for the curated one -
                                whichever it matches is where it applies.
    Pagination: ?page= (default 1), ?page_size= (default 25, capped at 100).
    """

    permission_classes = [IsAdmin]

    def get(self, request):
        from_date, to_date = get_date_range(request)

        user_id = request.query_params.get("user")
        if user_id:
            try:
                import uuid

                uuid.UUID(user_id)
            except ValueError:
                raise ValidationError("user must be a valid user id.")

        model = request.query_params.get("model")
        action = request.query_params.get("action")

        page = self._parse_int(request.query_params.get("page"), "page", default=1, minimum=1)
        page_size = self._parse_int(
            request.query_params.get("page_size"), "page_size", default=DEFAULT_PAGE_SIZE, minimum=1,
        )
        page_size = min(page_size, MAX_PAGE_SIZE)

        rows = audit_services.build_audit_feed(
            from_date=from_date, to_date=to_date, user_id=user_id, model=model, action=action,
        )

        total_count = len(rows)
        total_pages = max(1, -(-total_count // page_size)) if total_count else 1
        start = (page - 1) * page_size
        page_rows = rows[start:start + page_size]

        serializer = AuditFeedEntrySerializer(page_rows, many=True)
        return Response({
            "count": total_count,
            "page": page,
            "page_size": page_size,
            "total_pages": total_pages,
            "results": serializer.data,
        })

    @staticmethod
    def _parse_int(value, param_name, default, minimum):
        if value is None or value == "":
            return default
        try:
            parsed = int(value)
        except ValueError:
            raise ValidationError(f"{param_name} must be an integer.")
        return max(parsed, minimum)
