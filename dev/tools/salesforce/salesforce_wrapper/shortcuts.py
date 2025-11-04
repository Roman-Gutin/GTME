"""
Shortcut functions for common Salesforce objects (Account, Contact, Opportunity).
"""

from typing import Dict, List, Any, Optional
from .data_api import DataAPI
from .constants import DEFAULT_QUERY_LIMIT


class AccountShortcuts:
    """
    Convenience methods for working with Account objects.
    """
    
    def __init__(self, data_api: DataAPI):
        """
        Initialize Account shortcuts.
        
        Args:
            data_api: DataAPI instance
        """
        self.data_api = data_api
    
    def get_all_accounts(
        self,
        fields: Optional[List[str]] = None,
        limit: int = DEFAULT_QUERY_LIMIT
    ) -> List[Dict[str, Any]]:
        """
        Get all accounts.
        
        Args:
            fields: List of fields to retrieve (default: common fields)
            limit: Maximum number of records
            
        Returns:
            list: Account records
        """
        if not fields:
            fields = ['Id', 'Name', 'Type', 'Industry', 'Phone', 'Website', 'BillingCity', 'BillingState']
        
        return self.data_api.get_all_records('Account', fields, limit)
    
    def create_account(
        self,
        name: str,
        **kwargs
    ) -> str:
        """
        Create a new account.
        
        Args:
            name: Account name (required)
            **kwargs: Additional field values (Type, Industry, Phone, Website, etc.)
            
        Returns:
            str: Account ID
        """
        data = {'Name': name}
        data.update(kwargs)
        
        return self.data_api.create('Account', data)
    
    def search_accounts(
        self,
        name: str,
        fields: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """
        Search accounts by name.
        
        Args:
            name: Account name to search for
            fields: Optional list of fields to return
            
        Returns:
            list: Matching accounts
        """
        if not fields:
            fields = ['Id', 'Name', 'Type', 'Industry', 'Phone', 'Website']
        
        return self.data_api.search_records('Account', 'Name', name, 'like', fields)
    
    def get_account_by_id(
        self,
        account_id: str,
        fields: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """
        Get a single account by ID.
        
        Args:
            account_id: Account ID
            fields: Optional list of fields to retrieve
            
        Returns:
            dict: Account record
        """
        return self.data_api.get_record('Account', account_id, fields)
    
    def update_account(
        self,
        account_id: str,
        **kwargs
    ) -> bool:
        """
        Update an account.
        
        Args:
            account_id: Account ID
            **kwargs: Field values to update
            
        Returns:
            bool: True if successful
        """
        return self.data_api.update('Account', account_id, kwargs)
    
    def delete_account(self, account_id: str) -> bool:
        """
        Delete an account.
        
        Args:
            account_id: Account ID
            
        Returns:
            bool: True if successful
        """
        return self.data_api.delete('Account', account_id)


class ContactShortcuts:
    """
    Convenience methods for working with Contact objects.
    """
    
    def __init__(self, data_api: DataAPI):
        self.data_api = data_api
    
    def get_all_contacts(
        self,
        fields: Optional[List[str]] = None,
        limit: int = DEFAULT_QUERY_LIMIT
    ) -> List[Dict[str, Any]]:
        """Get all contacts."""
        if not fields:
            fields = ['Id', 'FirstName', 'LastName', 'Email', 'Phone', 'AccountId', 'Title']
        return self.data_api.get_all_records('Contact', fields, limit)
    
    def create_contact(
        self,
        first_name: str,
        last_name: str,
        **kwargs
    ) -> str:
        """Create a new contact."""
        data = {'FirstName': first_name, 'LastName': last_name}
        data.update(kwargs)
        return self.data_api.create('Contact', data)
    
    def search_contacts(
        self,
        last_name: str,
        fields: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """Search contacts by last name."""
        if not fields:
            fields = ['Id', 'FirstName', 'LastName', 'Email', 'Phone', 'AccountId']
        return self.data_api.search_records('Contact', 'LastName', last_name, 'like', fields)


class OpportunityShortcuts:
    """
    Convenience methods for working with Opportunity objects.
    """
    
    def __init__(self, data_api: DataAPI):
        self.data_api = data_api
    
    def get_all_opportunities(
        self,
        fields: Optional[List[str]] = None,
        limit: int = DEFAULT_QUERY_LIMIT
    ) -> List[Dict[str, Any]]:
        """Get all opportunities."""
        if not fields:
            fields = ['Id', 'Name', 'StageName', 'Amount', 'CloseDate', 'AccountId', 'Probability']
        return self.data_api.get_all_records('Opportunity', fields, limit)
    
    def create_opportunity(
        self,
        name: str,
        stage_name: str,
        close_date: str,
        **kwargs
    ) -> str:
        """Create a new opportunity."""
        data = {'Name': name, 'StageName': stage_name, 'CloseDate': close_date}
        data.update(kwargs)
        return self.data_api.create('Opportunity', data)

