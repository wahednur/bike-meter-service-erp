class LoanError(Exception):
    """Domain-level error raised by the loans service layer
    (apps.loans.services). Views/serializers catch this and translate it
    into a DRF ValidationError for the API response."""
