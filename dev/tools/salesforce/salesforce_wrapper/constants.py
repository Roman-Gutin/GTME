"""
Constants and configuration values for Salesforce API interactions.
"""

# API Versions
SALESFORCE_API_VERSION = "60.0"
METADATA_API_VERSION = "60.0"

# API Endpoints
OAUTH_TOKEN_ENDPOINT = "/services/oauth2/token"
REST_API_BASE = f"/services/data/v{SALESFORCE_API_VERSION}"
METADATA_API_ENDPOINT = f"/services/Soap/m/{METADATA_API_VERSION}"

# Field Types Mapping
FIELD_TYPES = {
    'Text': 'Text',
    'LongTextArea': 'LongTextArea',
    'RichTextArea': 'Html',
    'Number': 'Number',
    'Currency': 'Currency',
    'Date': 'Date',
    'DateTime': 'DateTime',
    'Picklist': 'Picklist',
    'MultiselectPicklist': 'MultiselectPicklist',
    'Checkbox': 'Checkbox',
    'Email': 'Email',
    'Phone': 'Phone',
    'Url': 'Url',
    'Percent': 'Percent',
    'Lookup': 'Lookup',
    'MasterDetail': 'MasterDetail',
    'AutoNumber': 'AutoNumber',
}

# Default Field Configurations
DEFAULT_TEXT_LENGTH = 255
DEFAULT_TEXTAREA_LENGTH = 32768
DEFAULT_NUMBER_PRECISION = 18
DEFAULT_NUMBER_SCALE = 0
DEFAULT_CURRENCY_PRECISION = 18
DEFAULT_CURRENCY_SCALE = 2

# Deployment Status Values
DEPLOYMENT_STATUS = {
    'PENDING': 'Pending',
    'IN_PROGRESS': 'InProgress',
    'SUCCEEDED': 'Succeeded',
    'FAILED': 'Failed',
    'CANCELING': 'Canceling',
    'CANCELED': 'Canceled',
}

# Standard Objects (commonly used)
STANDARD_OBJECTS = [
    'Account', 'Contact', 'Lead', 'Opportunity', 'Case',
    'Task', 'Event', 'User', 'Campaign', 'Product2',
]

# SOAP Namespaces
SOAP_NAMESPACES = {
    'soapenv': 'http://schemas.xmlsoap.org/soap/envelope/',
    'met': 'http://soap.sforce.com/2006/04/metadata',
    'xsi': 'http://www.w3.org/2001/XMLSchema-instance',
}

# Retry Configuration
MAX_RETRIES = 3
RETRY_DELAY = 2  # seconds
BACKOFF_MULTIPLIER = 2

# Timeout Configuration
DEFAULT_TIMEOUT = 30  # seconds
METADATA_DEPLOY_TIMEOUT = 300  # 5 minutes for metadata deployments

# Query Limits
DEFAULT_QUERY_LIMIT = 2000
MAX_QUERY_LIMIT = 50000

# Picklist Bullet Presets
BULLET_PRESETS = [
    'BULLET_DISC_CIRCLE_SQUARE',
    'BULLET_DIAMONDX_ARROW3D_SQUARE',
    'BULLET_CHECKBOX',
    'BULLET_ARROW_DIAMOND_DISC',
    'NUMBERED_DECIMAL_ALPHA_ROMAN',
    'NUMBERED_DECIMAL_ALPHA_ROMAN_PARENS',
    'NUMBERED_DECIMAL_NESTED',
    'NUMBERED_UPPERALPHA_ALPHA_ROMAN',
    'NUMBERED_UPPERROMAN_UPPERALPHA_DECIMAL',
]

# Search Operators
SEARCH_OPERATORS = {
    'equals': '=',
    'not_equals': '!=',
    'less_than': '<',
    'less_or_equal': '<=',
    'greater_than': '>',
    'greater_or_equal': '>=',
    'like': 'LIKE',
    'in': 'IN',
    'not_in': 'NOT IN',
}

# Error Messages
ERROR_MESSAGES = {
    'AUTH_FAILED': 'Authentication failed. Please check credentials.',
    'INVALID_SESSION': 'Session expired or invalid. Please re-authenticate.',
    'OBJECT_NOT_FOUND': 'Object not found in Salesforce org.',
    'FIELD_NOT_FOUND': 'Field not found on object.',
    'INVALID_FIELD_TYPE': 'Invalid field type specified.',
    'DEPLOYMENT_FAILED': 'Metadata deployment failed.',
    'QUERY_ERROR': 'SOQL query execution failed.',
    'RECORD_NOT_FOUND': 'Record not found.',
    'INSUFFICIENT_ACCESS': 'Insufficient access rights to perform this operation.',
}

# Success Messages
SUCCESS_MESSAGES = {
    'OBJECT_CREATED': 'Custom object created successfully.',
    'FIELD_CREATED': 'Custom field created successfully.',
    'RECORD_CREATED': 'Record created successfully.',
    'RECORD_UPDATED': 'Record updated successfully.',
    'RECORD_DELETED': 'Record deleted successfully.',
}

