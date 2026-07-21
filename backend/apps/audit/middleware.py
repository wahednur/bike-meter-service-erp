from apps.audit.context import set_current_request


class CurrentRequestMiddleware:
    """Stashes the current request in a contextvar so the audit signal
    handlers (apps.audit.signals), which run deep inside model.save()/
    delete() with no access to the request, can attribute automatic
    AuditLog entries to the right system user. See apps.audit.context for
    why this reads request.user lazily rather than here."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        set_current_request(request)
        try:
            response = self.get_response(request)
        finally:
            set_current_request(None)
        return response
