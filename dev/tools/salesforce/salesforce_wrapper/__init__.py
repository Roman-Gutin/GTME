"""
Salesforce Python Wrapper Library for Snowflake Cortex Agent Integration

A comprehensive library for interacting with Salesforce Data API and Metadata API
through pure Python implementations suitable for Snowflake UDF deployment.

Author: GTME Project
Version: 1.0.0
"""

__version__ = "1.0.0"
__author__ = "GTME Project"

# Import main classes for easy access
from .auth import SalesforceAuth
from .data_api import DataAPI
from .metadata_api import MetadataAPI
from .discovery import Discovery
from .shortcuts import AccountShortcuts

__all__ = [
    'SalesforceAuth',
    'DataAPI',
    'MetadataAPI',
    'Discovery',
    'AccountShortcuts',
]

