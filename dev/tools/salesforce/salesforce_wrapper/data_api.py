"""
Data API module for Salesforce CRUD operations.
Uses simple-salesforce library for REST API interactions.
"""

from typing import Dict, List, Any, Optional
from simple_salesforce import Salesforce
from .exceptions import (
    QueryError, RecordNotFoundError, ValidationError,
    InsufficientAccessError
)
from .utils import build_soql_query, build_where_clause, parse_error_response
from .constants import DEFAULT_QUERY_LIMIT


class DataAPI:
    """
    Handles Salesforce Data API operations (CRUD).
    
    This class provides methods for querying, creating, updating, and deleting
    Salesforce records using the REST API.
    """
    
    def __init__(self, sf_client: Salesforce):
        """
        Initialize Data API with a Salesforce client.
        
        Args:
            sf_client: Authenticated simple-salesforce client
        """
        self.sf = sf_client
    
    def query(self, soql: str) -> List[Dict[str, Any]]:
        """
        Execute a SOQL query.
        
        Args:
            soql: SOQL query string
            
        Returns:
            list: List of records matching the query
            
        Raises:
            QueryError: If query execution fails
        """
        try:
            result = self.sf.query(soql)
            records = result.get('records', [])
            
            # Remove attributes metadata from each record
            for record in records:
                if 'attributes' in record:
                    del record['attributes']
            
            return records
            
        except Exception as e:
            raise QueryError(f"Query failed: {str(e)}")
    
    def query_all(self, soql: str) -> List[Dict[str, Any]]:
        """
        Execute a SOQL query including deleted and archived records.
        
        Args:
            soql: SOQL query string
            
        Returns:
            list: List of all records including deleted/archived
            
        Raises:
            QueryError: If query execution fails
        """
        try:
            result = self.sf.query_all(soql)
            records = result.get('records', [])
            
            for record in records:
                if 'attributes' in record:
                    del record['attributes']
            
            return records
            
        except Exception as e:
            raise QueryError(f"Query all failed: {str(e)}")
    
    def get_record(self, object_name: str, record_id: str, fields: Optional[List[str]] = None) -> Dict[str, Any]:
        """
        Get a single record by ID.
        
        Args:
            object_name: Salesforce object name
            record_id: Record ID
            fields: Optional list of fields to retrieve (default: all)
            
        Returns:
            dict: Record data
            
        Raises:
            RecordNotFoundError: If record doesn't exist
        """
        try:
            obj = getattr(self.sf, object_name)
            
            if fields:
                # Build SOQL query with specific fields
                soql = build_soql_query(object_name, fields, f"Id = '{record_id}'")
                records = self.query(soql)
                if not records:
                    raise RecordNotFoundError(f"Record {record_id} not found in {object_name}")
                return records[0]
            else:
                # Get all fields
                record = obj.get(record_id)
                if 'attributes' in record:
                    del record['attributes']
                return record
                
        except RecordNotFoundError:
            raise
        except Exception as e:
            raise RecordNotFoundError(f"Failed to get record: {str(e)}")
    
    def create(self, object_name: str, data: Dict[str, Any]) -> str:
        """
        Create a new record.
        
        Args:
            object_name: Salesforce object name
            data: Record data as dictionary
            
        Returns:
            str: ID of created record
            
        Raises:
            ValidationError: If data validation fails
        """
        try:
            obj = getattr(self.sf, object_name)
            result = obj.create(data)
            
            if not result.get('success'):
                errors = result.get('errors', [])
                error_msg = parse_error_response(errors)
                raise ValidationError(f"Create failed: {error_msg}")
            
            return result['id']
            
        except ValidationError:
            raise
        except Exception as e:
            raise ValidationError(f"Failed to create record: {str(e)}")
    
    def update(self, object_name: str, record_id: str, data: Dict[str, Any]) -> bool:
        """
        Update an existing record.
        
        Args:
            object_name: Salesforce object name
            record_id: Record ID to update
            data: Updated field values
            
        Returns:
            bool: True if successful
            
        Raises:
            ValidationError: If update fails
        """
        try:
            obj = getattr(self.sf, object_name)
            result = obj.update(record_id, data)
            
            # simple-salesforce returns 204 for successful updates (no content)
            # If we get here without exception, it succeeded
            return True
            
        except Exception as e:
            raise ValidationError(f"Failed to update record: {str(e)}")
    
    def delete(self, object_name: str, record_id: str) -> bool:
        """
        Delete a record.

        Args:
            object_name: Salesforce object name
            record_id: Record ID to delete

        Returns:
            bool: True if successful

        Raises:
            RecordNotFoundError: If record doesn't exist
        """
        try:
            obj = getattr(self.sf, object_name)
            result = obj.delete(record_id)
            return True

        except Exception as e:
            raise RecordNotFoundError(f"Failed to delete record: {str(e)}")

    def get_all_records(
        self,
        object_name: str,
        fields: List[str],
        limit: Optional[int] = DEFAULT_QUERY_LIMIT,
        where_clause: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Get all records from an object.

        Args:
            object_name: Salesforce object name
            fields: List of fields to retrieve
            limit: Maximum number of records to return
            where_clause: Optional WHERE clause filter

        Returns:
            list: List of records
        """
        soql = build_soql_query(object_name, fields, where_clause, limit=limit)
        return self.query(soql)

    def search_records(
        self,
        object_name: str,
        field: str,
        value: Any,
        operator: str = 'equals',
        fields: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """
        Search for records matching criteria.

        Args:
            object_name: Salesforce object name
            field: Field name to search
            value: Value to search for
            operator: Comparison operator (equals, like, greater_than, etc.)
            fields: Optional list of fields to return (default: all)

        Returns:
            list: Matching records
        """
        if not fields:
            fields = ['Id', 'Name']

        where_clause = build_where_clause(field, value, operator)
        soql = build_soql_query(object_name, fields, where_clause)
        return self.query(soql)

    def count_records(self, object_name: str, where_clause: Optional[str] = None) -> int:
        """
        Count records in an object.

        Args:
            object_name: Salesforce object name
            where_clause: Optional WHERE clause filter

        Returns:
            int: Number of records
        """
        soql = f"SELECT COUNT() FROM {object_name}"
        if where_clause:
            soql += f" WHERE {where_clause}"

        try:
            result = self.sf.query(soql)
            return result.get('totalSize', 0)
        except Exception as e:
            raise QueryError(f"Count query failed: {str(e)}")

    def upsert(
        self,
        object_name: str,
        external_id_field: str,
        external_id_value: str,
        data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Upsert a record (update if exists, create if not).

        Args:
            object_name: Salesforce object name
            external_id_field: External ID field name
            external_id_value: External ID value
            data: Record data

        Returns:
            dict: Result with 'id' and 'created' flag
        """
        try:
            obj = getattr(self.sf, object_name)
            result = obj.upsert(f"{external_id_field}/{external_id_value}", data)

            return {
                'id': result.get('id'),
                'created': result.get('created', False),
                'success': result.get('success', True)
            }

        except Exception as e:
            raise ValidationError(f"Upsert failed: {str(e)}")

    def bulk_create(self, object_name: str, records: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Create multiple records in bulk.

        Args:
            object_name: Salesforce object name
            records: List of record data dictionaries

        Returns:
            list: List of results with IDs and success status
        """
        try:
            obj = getattr(self.sf, object_name)
            results = []

            # Process in batches to avoid limits
            batch_size = 200
            for i in range(0, len(records), batch_size):
                batch = records[i:i + batch_size]
                for record in batch:
                    try:
                        result = obj.create(record)
                        results.append({
                            'id': result.get('id'),
                            'success': result.get('success', True),
                            'errors': result.get('errors', [])
                        })
                    except Exception as e:
                        results.append({
                            'id': None,
                            'success': False,
                            'errors': [str(e)]
                        })

            return results

        except Exception as e:
            raise ValidationError(f"Bulk create failed: {str(e)}")

