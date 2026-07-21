from datetime import datetime

from rest_framework.exceptions import ValidationError


def parse_date_param(value, param_name):
    if not value:
        return None
    try:
        return datetime.strptime(value, "%Y-%m-%d").date()
    except ValueError:
        raise ValidationError(f"{param_name} must be in YYYY-MM-DD format.")


def get_date_range(request):
    """Every report accepts optional ?from_date=&to_date= (YYYY-MM-DD);
    both default to unbounded (all-time) when omitted."""
    from_date = parse_date_param(request.query_params.get("from_date"), "from_date")
    to_date = parse_date_param(request.query_params.get("to_date"), "to_date")
    return from_date, to_date
