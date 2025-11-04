"""
Main Salesforce handler that provides all high-level functions for Snowflake integration.
This module ties together all components and provides the complete API.
"""

from typing import Dict, List, Any, Optional
from simple_salesforce import Salesforce
from .auth import SalesforceAuth
from .data_api import DataAPI
from .metadata_api import MetadataAPI
from .discovery import Discovery
from .shortcuts import AccountShortcuts, ContactShortcuts, OpportunityShortcuts
from .field_creators import *
from .exceptions import *
from .constants import SALESFORCE_API_VERSION, DEFAULT_QUERY_LIMIT


class SalesforceHandler:
    """
    Main handler class that provides all Salesforce operations.
    
    This class initializes all components and provides a unified interface
    for both data and metadata operations.
    """
    
    def __init__(
        self,
        username: str,
        password: str,
        client_id: str,
        client_secret: str,
        instance_url: str = "https://login.salesforce.com",
        security_token: Optional[str] = None
    ):
        """
        Initialize Salesforce handler.
        
        Args:
            username: Salesforce username
            password: Salesforce password
            client_id: Connected App Client ID
            client_secret: Connected App Client Secret
            instance_url: Salesforce instance URL
            security_token: Security token (optional)
        """
        # Initialize authentication
        self.auth = SalesforceAuth(
            username=username,
            password=password,
            client_id=client_id,
            client_secret=client_secret,
            instance_url=instance_url,
            security_token=security_token
        )
        
        # Authenticate
        auth_result = self.auth.authenticate()
        
        # Initialize simple-salesforce client
        self.sf = Salesforce(
            instance_url=self.auth.get_instance_url(),
            session_id=self.auth.get_session_id(),
            version=SALESFORCE_API_VERSION
        )
        
        # Initialize API components
        self.data_api = DataAPI(self.sf)
        self.metadata_api = MetadataAPI(
            session_id=self.auth.get_session_id(),
            instance_url=self.auth.get_instance_url()
        )
        self.discovery = Discovery(self.sf)
        
        # Initialize shortcuts
        self.accounts = AccountShortcuts(self.data_api)
        self.contacts = ContactShortcuts(self.data_api)
        self.opportunities = OpportunityShortcuts(self.data_api)
    
    # ========================================
    # DISCOVERY & EXPLORATION FUNCTIONS
    # ========================================
    
    def discover_org(self) -> Dict[str, Any]:
        """Get complete org overview."""
        return self.discovery.discover_org()
    
    def list_all_objects(self) -> List[str]:
        """List all objects in org."""
        return self.discovery.list_all_objects()
    
    def list_custom_objects(self) -> List[str]:
        """List custom objects only."""
        return self.discovery.list_custom_objects()
    
    def describe_object(self, object_name: str) -> Dict[str, Any]:
        """Get object metadata."""
        return self.discovery.describe_object(object_name)
    
    def get_field_names(self, object_name: str) -> List[str]:
        """Get all field names for an object."""
        return self.discovery.get_field_names(object_name)
    
    def search_objects(self, keyword: str) -> List[Dict[str, str]]:
        """Find objects by keyword."""
        return self.discovery.search_objects(keyword)
    
    # ========================================
    # DATA OPERATIONS (CRUD)
    # ========================================
    
    def query_records(self, soql: str) -> List[Dict[str, Any]]:
        """Execute SOQL query."""
        return self.data_api.query(soql)
    
    def get_record(self, object_name: str, record_id: str, fields: Optional[List[str]] = None) -> Dict[str, Any]:
        """Get single record."""
        return self.data_api.get_record(object_name, record_id, fields)
    
    def get_all_records(
        self,
        object_name: str,
        fields: List[str],
        limit: int = DEFAULT_QUERY_LIMIT,
        where_clause: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """Get all records from an object."""
        return self.data_api.get_all_records(object_name, fields, limit, where_clause)
    
    def search_records(
        self,
        object_name: str,
        field: str,
        value: Any,
        operator: str = 'equals',
        fields: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Search records."""
        return self.data_api.search_records(object_name, field, value, operator, fields)
    
    def create_record(self, object_name: str, data: Dict[str, Any]) -> str:
        """Create new record."""
        return self.data_api.create(object_name, data)
    
    def update_record(self, object_name: str, record_id: str, data: Dict[str, Any]) -> bool:
        """Update record."""
        return self.data_api.update(object_name, record_id, data)
    
    def delete_record(self, object_name: str, record_id: str) -> bool:
        """Delete record."""
        return self.data_api.delete(object_name, record_id)
    
    def count_records(self, object_name: str, where_clause: Optional[str] = None) -> int:
        """Count records."""
        return self.data_api.count_records(object_name, where_clause)
    
    # ========================================
    # METADATA OPERATIONS (SCHEMA CREATION)
    # ========================================
    
    def create_custom_object(
        self,
        label: str,
        plural_label: str,
        **kwargs
    ) -> Dict[str, Any]:
        """Create custom object."""
        return self.metadata_api.create_custom_object(label, plural_label, **kwargs)
    
    def create_text_field(self, object_name: str, label: str, length: int = 255, required: bool = False) -> Dict[str, Any]:
        """Create text field."""
        return create_text_field(self.metadata_api, object_name, label, length, required)
    
    def create_picklist_field(self, object_name: str, label: str, values: List[str], required: bool = False) -> Dict[str, Any]:
        """Create picklist field."""
        return create_picklist_field(self.metadata_api, object_name, label, values, required)

    def create_textarea_field(self, object_name: str, label: str, length: int = 32768) -> Dict[str, Any]:
        """Create long text area field."""
        return create_textarea_field(self.metadata_api, object_name, label, length)

    def create_number_field(self, object_name: str, label: str, precision: int = 18, scale: int = 0) -> Dict[str, Any]:
        """Create number field."""
        return create_number_field(self.metadata_api, object_name, label, precision, scale)

    def create_currency_field(self, object_name: str, label: str, precision: int = 18, scale: int = 2) -> Dict[str, Any]:
        """Create currency field."""
        return create_currency_field(self.metadata_api, object_name, label, precision, scale)

    def create_date_field(self, object_name: str, label: str, required: bool = False) -> Dict[str, Any]:
        """Create date field."""
        return create_date_field(self.metadata_api, object_name, label, required)

    def create_lookup_field(
        self,
        object_name: str,
        label: str,
        related_to: str,
        relationship_name: Optional[str] = None
    ) -> Dict[str, Any]:
        """Create lookup relationship field."""
        return create_lookup_field(self.metadata_api, object_name, label, related_to, relationship_name)

    def verify_object_exists(self, object_name: str) -> bool:
        """Check if object exists."""
        try:
            self.describe_object(object_name)
            return True
        except ObjectNotFoundError:
            return False

    def verify_field_exists(self, object_name: str, field_name: str) -> bool:
        """Check if field exists on object."""
        try:
            self.discovery.get_field_details(object_name, field_name)
            return True
        except ObjectNotFoundError:
            return False

    # ========================================
    # HIGH-LEVEL ORCHESTRATION FUNCTIONS
    # ========================================

    def create_complete_custom_object(self, requirements: Dict[str, Any]) -> Dict[str, Any]:
        """
        Create a complete custom object with all fields from requirements.

        Args:
            requirements: Dictionary with object and field specifications
                {
                    'label': 'Use Case',
                    'plural_label': 'Use Cases',
                    'description': 'Optional description',
                    'fields': [
                        {'type': 'Picklist', 'label': 'Status', 'values': ['New', 'In Progress']},
                        {'type': 'Currency', 'label': 'Expected ROI', 'precision': 18, 'scale': 2},
                        ...
                    ],
                    'lookups': [
                        {'label': 'Account', 'related_to': 'Account'},
                        ...
                    ]
                }

        Returns:
            dict: Complete creation results
        """
        results = {
            'success': True,
            'object_created': False,
            'fields_created': [],
            'fields_failed': [],
            'errors': []
        }

        try:
            # Create the custom object
            obj_result = self.create_custom_object(
                label=requirements['label'],
                plural_label=requirements['plural_label'],
                description=requirements.get('description')
            )

            if not obj_result.get('success'):
                results['success'] = False
                results['errors'].append(f"Object creation failed: {obj_result.get('error')}")
                return results

            results['object_created'] = True
            results['object_name'] = obj_result['object_name']

            # Wait a bit for object to be available
            import time
            time.sleep(3)

            # Create fields
            for field_spec in requirements.get('fields', []):
                try:
                    field_type = field_spec['type']
                    label = field_spec['label']

                    if field_type == 'Text':
                        result = self.create_text_field(
                            obj_result['object_name'],
                            label,
                            field_spec.get('length', 255),
                            field_spec.get('required', False)
                        )
                    elif field_type == 'LongTextArea':
                        result = self.create_textarea_field(
                            obj_result['object_name'],
                            label,
                            field_spec.get('length', 32768)
                        )
                    elif field_type == 'Number':
                        result = self.create_number_field(
                            obj_result['object_name'],
                            label,
                            field_spec.get('precision', 18),
                            field_spec.get('scale', 0)
                        )
                    elif field_type == 'Currency':
                        result = self.create_currency_field(
                            obj_result['object_name'],
                            label,
                            field_spec.get('precision', 18),
                            field_spec.get('scale', 2)
                        )
                    elif field_type == 'Date':
                        result = self.create_date_field(
                            obj_result['object_name'],
                            label,
                            field_spec.get('required', False)
                        )
                    elif field_type == 'Picklist':
                        result = self.create_picklist_field(
                            obj_result['object_name'],
                            label,
                            field_spec['values'],
                            field_spec.get('required', False)
                        )
                    else:
                        results['fields_failed'].append({
                            'label': label,
                            'error': f"Unsupported field type: {field_type}"
                        })
                        continue

                    if result.get('success'):
                        results['fields_created'].append(result)
                    else:
                        results['fields_failed'].append({
                            'label': label,
                            'error': result.get('error', 'Unknown error')
                        })

                    # Small delay between field creations
                    time.sleep(1)

                except Exception as e:
                    results['fields_failed'].append({
                        'label': field_spec.get('label', 'Unknown'),
                        'error': str(e)
                    })

            # Create lookup fields
            for lookup_spec in requirements.get('lookups', []):
                try:
                    result = self.create_lookup_field(
                        obj_result['object_name'],
                        lookup_spec['label'],
                        lookup_spec['related_to'],
                        lookup_spec.get('relationship_name')
                    )

                    if result.get('success'):
                        results['fields_created'].append(result)
                    else:
                        results['fields_failed'].append({
                            'label': lookup_spec['label'],
                            'error': result.get('error', 'Unknown error')
                        })

                    time.sleep(1)

                except Exception as e:
                    results['fields_failed'].append({
                        'label': lookup_spec.get('label', 'Unknown'),
                        'error': str(e)
                    })

            # Set overall success based on failures
            if results['fields_failed']:
                results['success'] = False
                results['errors'].append(f"{len(results['fields_failed'])} fields failed to create")

            return results

        except Exception as e:
            results['success'] = False
            results['errors'].append(f"Unexpected error: {str(e)}")
            return results

    def test_object_creation(self, object_name: str, num_test_records: int = 3) -> Dict[str, Any]:
        """
        Verify object works by creating and querying test records.

        Args:
            object_name: Object API name to test
            num_test_records: Number of test records to create

        Returns:
            dict: Test results
        """
        results = {
            'success': True,
            'object_exists': False,
            'records_created': [],
            'records_queried': [],
            'errors': []
        }

        try:
            # Verify object exists
            if not self.verify_object_exists(object_name):
                results['success'] = False
                results['errors'].append(f"Object {object_name} does not exist")
                return results

            results['object_exists'] = True

            # Get object fields
            describe = self.describe_object(object_name)
            fields = describe.get('fields', [])

            # Find Name field
            name_field = None
            for field in fields:
                if field.get('nameField'):
                    name_field = field['name']
                    break

            if not name_field:
                name_field = 'Name'

            # Create test records
            for i in range(num_test_records):
                try:
                    test_data = {name_field: f"Test Record {i+1}"}
                    record_id = self.create_record(object_name, test_data)
                    results['records_created'].append(record_id)
                except Exception as e:
                    results['errors'].append(f"Failed to create test record {i+1}: {str(e)}")

            # Query records back
            if results['records_created']:
                try:
                    soql = f"SELECT Id, {name_field} FROM {object_name} WHERE Id IN ({','.join([f\"'{id}'\" for id in results['records_created']])})"
                    records = self.query_records(soql)
                    results['records_queried'] = records
                except Exception as e:
                    results['errors'].append(f"Failed to query test records: {str(e)}")

            # Clean up test records
            for record_id in results['records_created']:
                try:
                    self.delete_record(object_name, record_id)
                except:
                    pass  # Ignore cleanup errors

            if results['errors']:
                results['success'] = False

            return results

        except Exception as e:
            results['success'] = False
            results['errors'].append(f"Test failed: {str(e)}")
            return results

    # ========================================
    # ACCOUNT-SPECIFIC SHORTCUTS
    # ========================================

    def get_all_accounts(self, fields: Optional[List[str]] = None) -> List[Dict[str, Any]]:
        """Get all accounts."""
        return self.accounts.get_all_accounts(fields)

    def create_account(self, name: str, **kwargs) -> str:
        """Create account."""
        return self.accounts.create_account(name, **kwargs)

    def search_accounts(self, name: str) -> List[Dict[str, Any]]:
        """Search accounts by name."""
        return self.accounts.search_accounts(name)

    def get_account_by_id(self, account_id: str) -> Dict[str, Any]:
        """Get single account."""
        return self.accounts.get_account_by_id(account_id)
