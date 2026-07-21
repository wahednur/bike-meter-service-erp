class ReportError(Exception):
    """Domain-level error raised by the reports service layer
    (apps.reports.services). Views catch this and translate it into a DRF
    ValidationError for the API response."""
