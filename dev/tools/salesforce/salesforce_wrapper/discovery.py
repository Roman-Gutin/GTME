"""
Discovery module for exploring Salesforce org metadata.
"""

from typing import Dict, List, Any, Optional
from simple_salesforce import Salesforce
from .exceptions import ObjectNotFoundError, QueryError
from .constants import STANDARD_OBJECTS


class Discovery:
    """
    Handles Salesforce org discovery and metadata exploration.
    
    This class provides methods for discovering objects, fields, and
    other metadata in a Salesforce org.
    """
    
    def __init__(self, sf_client: Salesforce):
        """
        Initialize Discovery with a Salesforce client.
        
        Args:
            sf_client: Authenticated simple-salesforce client
        """
        self.sf = sf_client
    
    def discover_org(self) -> Dict[str, Any]:
        """
        Get a complete overview of the Salesforce org.
        
        Returns:
            dict: Org information including objects, user info, and limits
        """
        try:
            # Get org limits
            limits = self.sf.limits()
            
            # Get all objects
            all_objects = self.list_all_objects()
            custom_objects = self.list_custom_objects()
            
            # Get user info
            user_info = self._get_user_info()
            
            return {
                'success': True,
                'org_id': user_info.get('organizationId'),
                'user_id': user_info.get('userId'),
                'username': user_info.get('userName'),
                'total_objects': len(all_objects),
                'custom_objects_count': len(custom_objects),
                'standard_objects_count': len(all_objects) - len(custom_objects),
                'api_limits': {
                    'daily_api_requests': limits.get('DailyApiRequests', {}),
                    'data_storage': limits.get('DataStorageMB', {}),
                    'file_storage': limits.get('FileStorageMB', {}),
                },
                'sample_objects': all_objects[:10],
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': f"Failed to discover org: {str(e)}"
            }
    
    def list_all_objects(self) -> List[str]:
        """
        List all objects in the org (standard and custom).
        
        Returns:
            list: List of object API names
        """
        try:
            describe = self.sf.describe()
            objects = describe.get('sobjects', [])
            return sorted([obj['name'] for obj in objects])
            
        except Exception as e:
            raise QueryError(f"Failed to list objects: {str(e)}")
    
    def list_custom_objects(self) -> List[str]:
        """
        List only custom objects (ending with __c).
        
        Returns:
            list: List of custom object API names
        """
        all_objects = self.list_all_objects()
        return [obj for obj in all_objects if obj.endswith('__c')]
    
    def list_standard_objects(self) -> List[str]:
        """
        List standard Salesforce objects.
        
        Returns:
            list: List of standard object API names
        """
        all_objects = self.list_all_objects()
        return [obj for obj in all_objects if not obj.endswith('__c')]
    
    def describe_object(self, object_name: str) -> Dict[str, Any]:
        """
        Get detailed metadata for an object.
        
        Args:
            object_name: Salesforce object API name
            
        Returns:
            dict: Object metadata including fields, relationships, etc.
            
        Raises:
            ObjectNotFoundError: If object doesn't exist
        """
        try:
            obj = getattr(self.sf, object_name)
            describe = obj.describe()
            
            return {
                'success': True,
                'name': describe.get('name'),
                'label': describe.get('label'),
                'labelPlural': describe.get('labelPlural'),
                'custom': describe.get('custom', False),
                'createable': describe.get('createable', False),
                'updateable': describe.get('updateable', False),
                'deletable': describe.get('deletable', False),
                'queryable': describe.get('queryable', False),
                'searchable': describe.get('searchable', False),
                'fields_count': len(describe.get('fields', [])),
                'fields': describe.get('fields', []),
                'recordTypeInfos': describe.get('recordTypeInfos', []),
                'childRelationships': describe.get('childRelationships', []),
            }
            
        except AttributeError:
            raise ObjectNotFoundError(f"Object '{object_name}' not found")
        except Exception as e:
            raise ObjectNotFoundError(f"Failed to describe object: {str(e)}")
    
    def get_field_names(self, object_name: str) -> List[str]:
        """
        Get all field names for an object.
        
        Args:
            object_name: Salesforce object API name
            
        Returns:
            list: List of field API names
        """
        describe = self.describe_object(object_name)
        fields = describe.get('fields', [])
        return sorted([field['name'] for field in fields])
    
    def get_field_details(self, object_name: str, field_name: str) -> Dict[str, Any]:
        """
        Get detailed information about a specific field.
        
        Args:
            object_name: Salesforce object API name
            field_name: Field API name
            
        Returns:
            dict: Field metadata
        """
        describe = self.describe_object(object_name)
        fields = describe.get('fields', [])
        
        for field in fields:
            if field['name'] == field_name:
                return field
        
        raise ObjectNotFoundError(f"Field '{field_name}' not found on {object_name}")
    
    def search_objects(self, keyword: str) -> List[Dict[str, str]]:
        """
        Search for objects by keyword in name or label.
        
        Args:
            keyword: Search keyword
            
        Returns:
            list: Matching objects with name and label
        """
        try:
            describe = self.sf.describe()
            objects = describe.get('sobjects', [])
            keyword_lower = keyword.lower()
            
            matches = []
            for obj in objects:
                name = obj.get('name', '').lower()
                label = obj.get('label', '').lower()
                
                if keyword_lower in name or keyword_lower in label:
                    matches.append({
                        'name': obj['name'],
                        'label': obj['label'],
                        'custom': obj.get('custom', False),
                    })
            
            return sorted(matches, key=lambda x: x['name'])

        except Exception as e:
            raise QueryError(f"Search failed: {str(e)}")

    def _get_user_info(self) -> Dict[str, Any]:
        """
        Get current user information from Salesforce identity endpoint.

        Returns:
            dict: User information including userId, organizationId, and userName
        """
        try:
            # Use the identity endpoint to get user info
            # The identity URL is returned in the OAuth response
            identity_url = f"{self.sf.base_url}id"

            headers = {
                'Authorization': f'Bearer {self.sf.session_id}',
                'Content-Type': 'application/json'
            }

            import requests
            response = requests.get(identity_url, headers=headers, timeout=30)

            if response.status_code == 200:
                identity_data = response.json()
                return {
                    'userId': identity_data.get('user_id'),
                    'organizationId': identity_data.get('organization_id'),
                    'userName': identity_data.get('username')
                }
            else:
                # Fallback: query User object for current user
                query = "SELECT Id, Username, Name, Email FROM User WHERE Id = UserInfo.getUserId()"
                # This won't work in SOQL, so use a different approach
                # Query the Organization object for org info
                org_query = "SELECT Id, Name FROM Organization LIMIT 1"
                org_result = self.sf.query(org_query)

                if org_result and org_result.get('records'):
                    org_id = org_result['records'][0]['Id']
                else:
                    org_id = None

                # Salesforce IDs are 18 characters (standard format)
                return {
                    'userId': self.sf.session_id[:18] if self.sf.session_id else None,
                    'organizationId': org_id,
                    'userName': None
                }

        except Exception as e:
            # If all else fails, query Organization for at least org ID
            try:
                org_query = "SELECT Id, Name FROM Organization LIMIT 1"
                org_result = self.sf.query(org_query)

                if org_result and org_result.get('records'):
                    return {
                        'userId': None,
                        'organizationId': org_result['records'][0]['Id'],
                        'userName': None
                    }
            except:
                pass

            # Last resort: return None values
            return {
                'userId': None,
                'organizationId': None,
                'userName': None
            }

    def get_picklist_values(self, object_name: str, field_name: str) -> List[Dict[str, Any]]:
        """
        Get picklist values for a field.

        Args:
            object_name: Salesforce object API name
            field_name: Picklist field API name

        Returns:
            list: Picklist values with labels and API names
        """
        field_details = self.get_field_details(object_name, field_name)

        if field_details.get('type') not in ['picklist', 'multipicklist']:
            raise ValueError(f"Field '{field_name}' is not a picklist field")

        picklist_values = field_details.get('picklistValues', [])
        return [
            {
                'label': pv.get('label'),
                'value': pv.get('value'),
                'active': pv.get('active', True),
                'defaultValue': pv.get('defaultValue', False),
            }
            for pv in picklist_values
        ]

    def get_object_relationships(self, object_name: str) -> Dict[str, List[Dict[str, Any]]]:
        """
        Get all relationships for an object.

        Args:
            object_name: Salesforce object API name

        Returns:
            dict: Parent and child relationships
        """
        describe = self.describe_object(object_name)

        # Get parent relationships (lookup/master-detail fields)
        parent_relationships = []
        for field in describe.get('fields', []):
            if field.get('type') in ['reference']:
                parent_relationships.append({
                    'field': field.get('name'),
                    'label': field.get('label'),
                    'relationshipName': field.get('relationshipName'),
                    'referenceTo': field.get('referenceTo', []),
                })

        # Get child relationships
        child_relationships = []
        for rel in describe.get('childRelationships', []):
            child_relationships.append({
                'childObject': rel.get('childSObject'),
                'field': rel.get('field'),
                'relationshipName': rel.get('relationshipName'),
            })

        return {
            'parent_relationships': parent_relationships,
            'child_relationships': child_relationships,
        }
