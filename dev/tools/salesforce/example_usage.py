"""
Example usage of Salesforce Python Wrapper.
Demonstrates key functionality.
"""

from salesforce_wrapper.sf_handler import SalesforceHandler

# Configuration
CREDENTIALS = {
    'username': 'your-username@example.com',
    'password': 'your-password',  # Append security token if required
    'client_id': 'your-client-id',
    'client_secret': 'your-client-secret',
    'instance_url': 'https://login.salesforce.com'  # Use login.salesforce.com for OAuth
}


def example_discovery():
    """Example: Discover org and explore objects."""
    print("\n" + "="*60)
    print("EXAMPLE 1: Discovery & Exploration")
    print("="*60)
    
    handler = SalesforceHandler(**CREDENTIALS)
    
    # Discover org
    org_info = handler.discover_org()
    print(f"\nOrg Overview:")
    print(f"  Total Objects: {org_info['total_objects']}")
    print(f"  Custom Objects: {org_info['custom_objects_count']}")
    
    # List custom objects
    custom_objects = handler.list_custom_objects()
    print(f"\nCustom Objects: {custom_objects[:5]}")
    
    # Describe Account object
    account_desc = handler.describe_object('Account')
    print(f"\nAccount Object:")
    print(f"  Label: {account_desc['label']}")
    print(f"  Fields: {account_desc['fields_count']}")


def example_data_operations():
    """Example: CRUD operations on Account."""
    print("\n" + "="*60)
    print("EXAMPLE 2: Data Operations (CRUD)")
    print("="*60)
    
    handler = SalesforceHandler(**CREDENTIALS)
    
    # Create account
    print("\n1. Creating account...")
    account_id = handler.create_account(
        name="Example Corp",
        Type="Customer",
        Industry="Technology",
        Phone="555-1234"
    )
    print(f"   Created: {account_id}")
    
    # Get account
    print("\n2. Retrieving account...")
    account = handler.get_account_by_id(account_id)
    print(f"   Name: {account['Name']}")
    print(f"   Type: {account['Type']}")
    
    # Update account
    print("\n3. Updating account...")
    handler.update_record('Account', account_id, {'Website': 'https://example.com'})
    print("   Updated successfully")
    
    # Search accounts
    print("\n4. Searching accounts...")
    results = handler.search_accounts("Example")
    print(f"   Found {len(results)} accounts")
    
    # Delete account
    print("\n5. Deleting account...")
    handler.delete_record('Account', account_id)
    print("   Deleted successfully")


def example_create_custom_object():
    """Example: Create a complete custom object with fields."""
    print("\n" + "="*60)
    print("EXAMPLE 3: Create Custom Object with Fields")
    print("="*60)
    
    handler = SalesforceHandler(**CREDENTIALS)
    
    # Define requirements
    requirements = {
        'label': 'Customer Feedback',
        'plural_label': 'Customer Feedback',
        'description': 'Track customer feedback and feature requests',
        'fields': [
            {
                'type': 'Picklist',
                'label': 'Status',
                'values': ['New', 'Under Review', 'Planned', 'Implemented', 'Rejected'],
                'required': True
            },
            {
                'type': 'Picklist',
                'label': 'Priority',
                'values': ['Critical', 'High', 'Medium', 'Low']
            },
            {
                'type': 'Picklist',
                'label': 'Category',
                'values': ['Bug', 'Feature Request', 'Improvement', 'Question']
            },
            {
                'type': 'LongTextArea',
                'label': 'Description',
                'length': 5000
            },
            {
                'type': 'LongTextArea',
                'label': 'Resolution Notes',
                'length': 5000
            },
            {
                'type': 'Number',
                'label': 'Votes',
                'precision': 10,
                'scale': 0
            },
            {
                'type': 'Date',
                'label': 'Target Date'
            },
            {
                'type': 'Date',
                'label': 'Completed Date'
            }
        ],
        'lookups': [
            {
                'label': 'Account',
                'related_to': 'Account',
                'relationship_name': 'Feedback_Items'
            },
            {
                'label': 'Contact',
                'related_to': 'Contact',
                'relationship_name': 'Submitted_Feedback'
            }
        ]
    }
    
    print("\nCreating custom object with 8 fields and 2 lookups...")
    result = handler.create_complete_custom_object(requirements)
    
    if result['success']:
        print(f"\n✅ Success!")
        print(f"   Object: {result['object_name']}")
        print(f"   Fields Created: {len(result['fields_created'])}")
        if result['fields_failed']:
            print(f"   Fields Failed: {len(result['fields_failed'])}")
            for failed in result['fields_failed']:
                print(f"     - {failed['label']}: {failed['error']}")
    else:
        print(f"\n❌ Failed!")
        print(f"   Errors: {result['errors']}")


def example_query_and_analyze():
    """Example: Query data and analyze."""
    print("\n" + "="*60)
    print("EXAMPLE 4: Query and Analyze Data")
    print("="*60)
    
    handler = SalesforceHandler(**CREDENTIALS)
    
    # Get all accounts
    print("\n1. Getting all accounts...")
    accounts = handler.get_all_accounts(limit=10)
    print(f"   Retrieved {len(accounts)} accounts")
    
    # Count accounts by type
    print("\n2. Counting accounts by type...")
    customer_count = handler.count_records('Account', "Type = 'Customer'")
    partner_count = handler.count_records('Account', "Type = 'Partner'")
    print(f"   Customers: {customer_count}")
    print(f"   Partners: {partner_count}")
    
    # Complex SOQL query
    print("\n3. Running complex SOQL query...")
    soql = """
        SELECT Id, Name, Type, Industry, AnnualRevenue
        FROM Account
        WHERE Type = 'Customer'
        AND Industry = 'Technology'
        ORDER BY AnnualRevenue DESC
        LIMIT 5
    """
    results = handler.query_records(soql)
    print(f"   Found {len(results)} tech customers")
    for account in results:
        print(f"     - {account['Name']}: ${account.get('AnnualRevenue', 0):,.0f}")


if __name__ == "__main__":
    print("\n" + "="*60)
    print("SALESFORCE PYTHON WRAPPER - USAGE EXAMPLES")
    print("="*60)
    print("\nNOTE: Update CREDENTIALS at the top of this file before running")
    print()
    
    # Uncomment the examples you want to run:
    
    # example_discovery()
    # example_data_operations()
    # example_create_custom_object()
    # example_query_and_analyze()
    
    print("\n" + "="*60)
    print("Update credentials and uncomment examples to run")
    print("="*60)

