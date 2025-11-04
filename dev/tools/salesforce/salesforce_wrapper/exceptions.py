"""
Custom exceptions for Salesforce API operations.
"""


class SalesforceException(Exception):
    """Base exception for all Salesforce-related errors."""
    pass


class AuthenticationError(SalesforceException):
    """Raised when authentication fails."""
    pass


class SessionExpiredError(SalesforceException):
    """Raised when the session token has expired."""
    pass


class ObjectNotFoundError(SalesforceException):
    """Raised when a Salesforce object is not found."""
    pass


class FieldNotFoundError(SalesforceException):
    """Raised when a field is not found on an object."""
    pass


class RecordNotFoundError(SalesforceException):
    """Raised when a record is not found."""
    pass


class InvalidFieldTypeError(SalesforceException):
    """Raised when an invalid field type is specified."""
    pass


class DeploymentError(SalesforceException):
    """Raised when a metadata deployment fails."""
    pass


class QueryError(SalesforceException):
    """Raised when a SOQL query fails."""
    pass


class InsufficientAccessError(SalesforceException):
    """Raised when user lacks permissions for an operation."""
    pass


class RateLimitError(SalesforceException):
    """Raised when API rate limit is exceeded."""
    pass


class ValidationError(SalesforceException):
    """Raised when input validation fails."""
    pass


class MetadataAPIError(SalesforceException):
    """Raised when Metadata API operations fail."""
    pass

