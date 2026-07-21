class InvoiceError(Exception):
    """Domain-level error raised by the invoices service layer
    (apps.invoices.services). Kept framework-agnostic so service functions
    stay unit-testable without DRF; views/serializers catch this and
    translate it into a DRF ValidationError for the API response."""
