"""
High-level field creation functions for common field types.
These wrap the MetadataAPI to provide simple interfaces for creating fields.
"""

from typing import Dict, List, Any, Optional
from .metadata_api import MetadataAPI
from .constants import (
    DEFAULT_TEXT_LENGTH,
    DEFAULT_TEXTAREA_LENGTH,
    DEFAULT_NUMBER_PRECISION,
    DEFAULT_NUMBER_SCALE,
    DEFAULT_CURRENCY_PRECISION,
    DEFAULT_CURRENCY_SCALE
)


def create_text_field(
    metadata_api: MetadataAPI,
    object_name: str,
    label: str,
    length: int = DEFAULT_TEXT_LENGTH,
    required: bool = False,
    unique: bool = False,
    description: Optional[str] = None
) -> Dict[str, Any]:
    """
    Create a text field.

    Args:
        metadata_api: MetadataAPI instance
        object_name: Object API name
        label: Field label
        length: Maximum length (default: DEFAULT_TEXT_LENGTH from constants)
        required: Whether field is required
        unique: Whether field must be unique
        description: Optional description

    Returns:
        dict: Creation result
    """
    field_metadata = {
        'type': 'Text',
        'label': label,
        'length': length,
        'required': required,
        'unique': unique,
        'description': description,
    }
    return metadata_api.create_custom_field(object_name, field_metadata)


def create_textarea_field(
    metadata_api: MetadataAPI,
    object_name: str,
    label: str,
    length: int = DEFAULT_TEXTAREA_LENGTH,
    visible_lines: int = 3,
    description: Optional[str] = None
) -> Dict[str, Any]:
    """
    Create a long text area field.

    Args:
        metadata_api: MetadataAPI instance
        object_name: Object API name
        label: Field label
        length: Maximum length (default: DEFAULT_TEXTAREA_LENGTH from constants)
        visible_lines: Number of visible lines (default: 3)
        description: Optional description

    Returns:
        dict: Creation result
    """
    field_metadata = {
        'type': 'LongTextArea',
        'label': label,
        'length': length,
        'visible_lines': visible_lines,
        'description': description,
    }
    return metadata_api.create_custom_field(object_name, field_metadata)


def create_number_field(
    metadata_api: MetadataAPI,
    object_name: str,
    label: str,
    precision: int = DEFAULT_NUMBER_PRECISION,
    scale: int = DEFAULT_NUMBER_SCALE,
    required: bool = False,
    unique: bool = False,
    description: Optional[str] = None
) -> Dict[str, Any]:
    """
    Create a number field.

    Args:
        metadata_api: MetadataAPI instance
        object_name: Object API name
        label: Field label
        precision: Total digits (default: DEFAULT_NUMBER_PRECISION from constants)
        scale: Decimal places (default: DEFAULT_NUMBER_SCALE from constants)
        required: Whether field is required
        unique: Whether field must be unique
        description: Optional description

    Returns:
        dict: Creation result
    """
    field_metadata = {
        'type': 'Number',
        'label': label,
        'precision': precision,
        'scale': scale,
        'required': required,
        'unique': unique,
        'description': description,
    }
    return metadata_api.create_custom_field(object_name, field_metadata)


def create_currency_field(
    metadata_api: MetadataAPI,
    object_name: str,
    label: str,
    precision: int = DEFAULT_CURRENCY_PRECISION,
    scale: int = DEFAULT_CURRENCY_SCALE,
    required: bool = False,
    description: Optional[str] = None
) -> Dict[str, Any]:
    """
    Create a currency field.

    Args:
        metadata_api: MetadataAPI instance
        object_name: Object API name
        label: Field label
        precision: Total digits (default: DEFAULT_CURRENCY_PRECISION from constants)
        scale: Decimal places (default: DEFAULT_CURRENCY_SCALE from constants)
        required: Whether field is required
        description: Optional description

    Returns:
        dict: Creation result
    """
    field_metadata = {
        'type': 'Currency',
        'label': label,
        'precision': precision,
        'scale': scale,
        'required': required,
        'description': description,
    }
    return metadata_api.create_custom_field(object_name, field_metadata)


def create_date_field(
    metadata_api: MetadataAPI,
    object_name: str,
    label: str,
    required: bool = False,
    description: Optional[str] = None
) -> Dict[str, Any]:
    """
    Create a date field.
    
    Args:
        metadata_api: MetadataAPI instance
        object_name: Object API name
        label: Field label
        required: Whether field is required
        description: Optional description
        
    Returns:
        dict: Creation result
    """
    field_metadata = {
        'type': 'Date',
        'label': label,
        'required': required,
        'description': description,
    }
    return metadata_api.create_custom_field(object_name, field_metadata)


def create_datetime_field(
    metadata_api: MetadataAPI,
    object_name: str,
    label: str,
    required: bool = False,
    description: Optional[str] = None
) -> Dict[str, Any]:
    """
    Create a datetime field.
    """
    field_metadata = {
        'type': 'DateTime',
        'label': label,
        'required': required,
        'description': description,
    }
    return metadata_api.create_custom_field(object_name, field_metadata)


def create_picklist_field(
    metadata_api: MetadataAPI,
    object_name: str,
    label: str,
    values: List[str],
    required: bool = False,
    description: Optional[str] = None
) -> Dict[str, Any]:
    """
    Create a picklist field.

    Args:
        metadata_api: MetadataAPI instance
        object_name: Object API name
        label: Field label
        values: List of picklist values
        required: Whether field is required
        description: Optional description

    Returns:
        dict: Creation result
    """
    if not values:
        raise ValueError("Picklist must have at least one value")

    field_metadata = {
        'type': 'Picklist',
        'label': label,
        'values': values,
        'required': required,
        'description': description,
    }
    return metadata_api.create_custom_field(object_name, field_metadata)


def create_checkbox_field(
    metadata_api: MetadataAPI,
    object_name: str,
    label: str,
    default_value: bool = False,
    description: Optional[str] = None
) -> Dict[str, Any]:
    """
    Create a checkbox field.

    Args:
        metadata_api: MetadataAPI instance
        object_name: Object API name
        label: Field label
        default_value: Default checked state
        description: Optional description

    Returns:
        dict: Creation result
    """
    field_metadata = {
        'type': 'Checkbox',
        'label': label,
        'default_value': default_value,
        'description': description,
    }
    return metadata_api.create_custom_field(object_name, field_metadata)


def create_lookup_field(
    metadata_api: MetadataAPI,
    object_name: str,
    label: str,
    related_to: str,
    relationship_name: Optional[str] = None,
    required: bool = False,
    description: Optional[str] = None
) -> Dict[str, Any]:
    """
    Create a lookup relationship field.

    Args:
        metadata_api: MetadataAPI instance
        object_name: Object API name
        label: Field label
        related_to: Related object API name (e.g., 'Account')
        relationship_name: Optional relationship name
        required: Whether field is required
        description: Optional description

    Returns:
        dict: Creation result
    """
    field_metadata = {
        'type': 'Lookup',
        'label': label,
        'related_to': related_to,
        'relationship_name': relationship_name,
        'required': required,
        'description': description,
    }
    return metadata_api.create_custom_field(object_name, field_metadata)


def create_email_field(
    metadata_api: MetadataAPI,
    object_name: str,
    label: str,
    required: bool = False,
    unique: bool = False,
    description: Optional[str] = None
) -> Dict[str, Any]:
    """
    Create an email field.

    Args:
        metadata_api: MetadataAPI instance
        object_name: Object API name
        label: Field label
        required: Whether field is required
        unique: Whether field must be unique
        description: Optional description

    Returns:
        dict: Creation result
    """
    field_metadata = {
        'type': 'Email',
        'label': label,
        'required': required,
        'unique': unique,
        'description': description,
    }
    return metadata_api.create_custom_field(object_name, field_metadata)


def create_phone_field(
    metadata_api: MetadataAPI,
    object_name: str,
    label: str,
    required: bool = False,
    description: Optional[str] = None
) -> Dict[str, Any]:
    """
    Create a phone field.

    Args:
        metadata_api: MetadataAPI instance
        object_name: Object API name
        label: Field label
        required: Whether field is required
        description: Optional description

    Returns:
        dict: Creation result
    """
    field_metadata = {
        'type': 'Phone',
        'label': label,
        'required': required,
        'description': description,
    }
    return metadata_api.create_custom_field(object_name, field_metadata)


def create_url_field(
    metadata_api: MetadataAPI,
    object_name: str,
    label: str,
    required: bool = False,
    description: Optional[str] = None
) -> Dict[str, Any]:
    """
    Create a URL field.

    Args:
        metadata_api: MetadataAPI instance
        object_name: Object API name
        label: Field label
        required: Whether field is required
        description: Optional description

    Returns:
        dict: Creation result
    """
    field_metadata = {
        'type': 'Url',
        'label': label,
        'required': required,
        'description': description,
    }
    return metadata_api.create_custom_field(object_name, field_metadata)
