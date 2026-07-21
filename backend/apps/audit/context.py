import contextvars

_current_request_var = contextvars.ContextVar("audit_current_request", default=None)


def set_current_request(request):
    _current_request_var.set(request)


def get_current_user():
    """Used by the signal handlers, which have no access to the request.

    Deliberately reads request.user lazily, at call time, rather than the
    middleware resolving it once up front: this project authenticates via
    JWT (see REST_FRAMEWORK/DEFAULT_AUTHENTICATION_CLASSES), and DRF only
    resolves request.user lazily inside APIView.dispatch() - AFTER Django's
    own middleware stack has already run. A plain "grab request.user in
    middleware" would always see AnonymousUser for API requests. Holding a
    live reference to the request and reading .user only when a signal
    actually fires (i.e. during view execution, after DRF's authentication
    has completed and synced the resolved user back onto this same
    request object) gets the right value.
    """
    request = _current_request_var.get()
    if request is None:
        return None
    user = getattr(request, "user", None)
    if user is not None and getattr(user, "is_authenticated", False):
        return user
    return None
