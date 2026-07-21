class EcommerceError(Exception):
    """Domain-level error raised by the ecommerce service layer
    (apps.ecommerce.services). Views catch this and translate it into a
    DRF ValidationError for the API response."""
