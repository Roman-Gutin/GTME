"""
Utility functions for Salesforce API operations.
"""

import time
import re
from typing import Dict, List, Any, Optional
from .constants import (
    MAX_RETRIES, RETRY_DELAY, BACKOFF_MULTIPLIER,
    SEARCH_OPERATORS
)


def retry_on_error(func, max_retries: int = MAX_RETRIES, delay: int = RETRY_DELAY):
    """
    Decorator to retry a function on failure with exponential backoff.
    
    Args:
        func: Function to retry
        max_retries: Maximum number of retry attempts
        delay: Initial delay between retries in seconds
        
    Returns:
        Wrapped function with retry logic
    """
    def wrapper(*args, **kwargs):
        current_delay = delay
        for attempt in range(max_retries):
            try:
                return func(*args, **kwargs)
            except Exception as e:
                if attempt == max_retries - 1:
                    raise
                time.sleep(current_delay)
                current_delay *= BACKOFF_MULTIPLIER
        return func(*args, **kwargs)
    return wrapper


def sanitize_api_name(label: str) -> str:
    """
    Convert a label to a valid Salesforce API name.
    
    Args:
        label: Human-readable label
        
    Returns:
        str: Valid API name (e.g., "My Field" -> "My_Field")
    """
    # Replace spaces and special characters with underscores
    api_name = re.sub(r'[^a-zA-Z0-9_]', '_', label)
    # Remove consecutive underscores
    api_name = re.sub(r'_+', '_', api_name)
    # Remove leading/trailing underscores
    api_name = api_name.strip('_')
    # Ensure it starts with a letter
    if api_name and not api_name[0].isalpha():
        api_name = 'X' + api_name
    return api_name


def build_custom_object_api_name(label: str) -> str:
    """
    Build a custom object API name from a label.
    
    Args:
        label: Object label
        
    Returns:
        str: Custom object API name with __c suffix
    """
    api_name = sanitize_api_name(label)
    if not api_name.endswith('__c'):
        api_name += '__c'
    return api_name


def build_custom_field_api_name(label: str, object_name: str) -> str:
    """
    Build a custom field API name from a label.
    
    Args:
        label: Field label
        object_name: Parent object API name
        
    Returns:
        str: Custom field API name with __c suffix
    """
    api_name = sanitize_api_name(label)
    if not api_name.endswith('__c'):
        api_name += '__c'
    return api_name


def build_soql_query(
    object_name: str,
    fields: List[str],
    where_clause: Optional[str] = None,
    order_by: Optional[str] = None,
    limit: Optional[int] = None
) -> str:
    """
    Build a SOQL query string.
    
    Args:
        object_name: Salesforce object name
        fields: List of field names to select
        where_clause: Optional WHERE clause (without 'WHERE' keyword)
        order_by: Optional ORDER BY clause (without 'ORDER BY' keyword)
        limit: Optional LIMIT value
        
    Returns:
        str: Complete SOQL query
    """
    query_parts = [f"SELECT {', '.join(fields)} FROM {object_name}"]
    
    if where_clause:
        query_parts.append(f"WHERE {where_clause}")
    
    if order_by:
        query_parts.append(f"ORDER BY {order_by}")
    
    if limit:
        query_parts.append(f"LIMIT {limit}")
    
    return ' '.join(query_parts)


def build_where_clause(field: str, value: Any, operator: str = 'equals') -> str:
    """
    Build a WHERE clause for SOQL queries.
    
    Args:
        field: Field name
        value: Value to compare
        operator: Comparison operator (equals, not_equals, less_than, etc.)
        
    Returns:
        str: WHERE clause fragment
    """
    op = SEARCH_OPERATORS.get(operator, '=')
    
    # Handle string values (need quotes)
    if isinstance(value, str):
        value = f"'{value}'"
    elif value is None:
        return f"{field} = NULL"
    elif isinstance(value, bool):
        value = str(value).lower()
    
    return f"{field} {op} {value}"


def parse_error_response(response_data: Dict) -> str:
    """
    Parse Salesforce error response and extract meaningful error message.
    
    Args:
        response_data: Error response from Salesforce API
        
    Returns:
        str: Formatted error message
    """
    if isinstance(response_data, list) and len(response_data) > 0:
        error = response_data[0]
        return error.get('message', str(error))
    elif isinstance(response_data, dict):
        if 'message' in response_data:
            return response_data['message']
        elif 'error_description' in response_data:
            return response_data['error_description']
        elif 'error' in response_data:
            return str(response_data['error'])
    return str(response_data)


def validate_object_name(object_name: str) -> bool:
    """
    Validate Salesforce object name format.
    
    Args:
        object_name: Object API name
        
    Returns:
        bool: True if valid, False otherwise
    """
    if not object_name:
        return False
    # Must start with letter, contain only alphanumeric and underscores
    pattern = r'^[a-zA-Z][a-zA-Z0-9_]*(__c)?$'
    return bool(re.match(pattern, object_name))


def validate_field_name(field_name: str) -> bool:
    """
    Validate Salesforce field name format.
    
    Args:
        field_name: Field API name
        
    Returns:
        bool: True if valid, False otherwise
    """
    return validate_object_name(field_name)

