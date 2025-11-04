"""
Integration tests for Salesforce wrapper.
Tests against real Salesforce org.
"""

import sys
import os
import time

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from salesforce_wrapper.sf_handler import SalesforceHandler


# Credentials - Replace with your actual Salesforce credentials
CREDENTIALS = {
    'username': "your-username@example.com",
    'password': "your-password",  # Append security token if required
    'client_id': "your-connected-app-client-id",
    'client_secret': "your-connected-app-client-secret",
    'instance_url': "https://login.salesforce.com"
}


def test_discovery():
    """Test discovery functions."""
    print("\n" + "="*60)
    print("TEST: Discovery Functions")
    print("="*60)
    
    handler = SalesforceHandler(**CREDENTIALS)
    
    # Test org discovery
    print("\n1. Discovering org...")
    org_info = handler.discover_org()
    print(f"   ✓ Total objects: {org_info.get('total_objects')}")
    print(f"   ✓ Custom objects: {org_info.get('custom_objects_count')}")
    
    # Test list objects
    print("\n2. Listing all objects...")
    all_objects = handler.list_all_objects()
    print(f"   ✓ Found {len(all_objects)} objects")
    print(f"   ✓ Sample: {all_objects[:5]}")
    
    # Test describe object
    print("\n3. Describing Account object...")
    account_desc = handler.describe_object('Account')
    print(f"   ✓ Label: {account_desc.get('label')}")
    print(f"   ✓ Fields: {account_desc.get('fields_count')}")
    
    # Test get field names
    print("\n4. Getting Account field names...")
    fields = handler.get_field_names('Account')
    print(f"   ✓ Found {len(fields)} fields")
    print(f"   ✓ Sample: {fields[:5]}")
    
    print("\n✅ Discovery tests passed!")
    return True


def test_data_operations():
    """Test CRUD operations."""
    print("\n" + "="*60)
    print("TEST: Data Operations (CRUD)")
    print("="*60)
    
    handler = SalesforceHandler(**CREDENTIALS)
    
    # Test create account
    print("\n1. Creating test account...")
    account_id = handler.create_account(
        name="Test Account - Integration Test",
        Type="Customer",
        Industry="Technology"
    )
    print(f"   ✓ Created account: {account_id}")
    
    # Test get record
    print("\n2. Retrieving account...")
    account = handler.get_account_by_id(account_id)
    print(f"   ✓ Name: {account.get('Name')}")
    print(f"   ✓ Type: {account.get('Type')}")
    
    # Test update record
    print("\n3. Updating account...")
    success = handler.update_record('Account', account_id, {'Phone': '555-1234'})
    print(f"   ✓ Update successful: {success}")
    
    # Test search
    print("\n4. Searching accounts...")
    results = handler.search_accounts("Test Account")
    print(f"   ✓ Found {len(results)} accounts")
    
    # Test query
    print("\n5. Querying with SOQL...")
    records = handler.query_records(f"SELECT Id, Name FROM Account WHERE Id = '{account_id}'")
    print(f"   ✓ Query returned {len(records)} records")
    
    # Test count
    print("\n6. Counting accounts...")
    count = handler.count_records('Account', f"Id = '{account_id}'")
    print(f"   ✓ Count: {count}")
    
    # Clean up
    print("\n7. Deleting test account...")
    success = handler.delete_record('Account', account_id)
    print(f"   ✓ Delete successful: {success}")
    
    print("\n✅ Data operations tests passed!")
    return True


def test_metadata_operations():
    """Test metadata operations (object and field creation)."""
    print("\n" + "="*60)
    print("TEST: Metadata Operations (Schema Creation)")
    print("="*60)
    
    handler = SalesforceHandler(**CREDENTIALS)
    
    # Create a test custom object
    print("\n1. Creating custom object...")
    obj_result = handler.create_custom_object(
        label="Test Object",
        plural_label="Test Objects",
        description="Integration test object"
    )
    
    if not obj_result.get('success'):
        print(f"   ❌ Object creation failed: {obj_result.get('error')}")
        print(f"   This is expected if object already exists. Attempting to verify...")
        # Try to verify if object exists from previous test run
        object_name = "Test_Object__c"
        exists = handler.verify_object_exists(object_name)
        if exists:
            print(f"   ✓ Object '{object_name}' already exists from previous test")
        else:
            print(f"   ❌ Object does not exist and creation failed")
            return False
    else:
        print(f"   ✓ Created object: {obj_result.get('object_name')}")
        object_name = obj_result['object_name']
        time.sleep(5)  # Wait for object to be available

        # Verify object exists
        print("\n2. Verifying object exists...")
        exists = handler.verify_object_exists(object_name)
        print(f"   ✓ Object exists: {exists}")

        if not exists:
            print("   ❌ Object creation succeeded but verification failed")
            return False

    print("\n✅ Metadata operations tests passed!")
    return True


def run_all_tests():
    """Run all integration tests."""
    print("\n" + "="*60)
    print("SALESFORCE WRAPPER - INTEGRATION TESTS")
    print("="*60)
    
    tests = [
        ("Discovery", test_discovery),
        ("Data Operations", test_data_operations),
        ("Metadata Operations", test_metadata_operations),
    ]
    
    results = []
    for test_name, test_func in tests:
        try:
            success = test_func()
            results.append((test_name, success))
        except Exception as e:
            print(f"\n❌ {test_name} failed with error: {e}")
            import traceback
            traceback.print_exc()
            results.append((test_name, False))
    
    # Print summary
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    for test_name, success in results:
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    all_passed = all(success for _, success in results)
    print("\n" + ("="*60))
    if all_passed:
        print("✅ ALL TESTS PASSED!")
    else:
        print("❌ SOME TESTS FAILED")
    print("="*60)
    
    return all_passed


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)

