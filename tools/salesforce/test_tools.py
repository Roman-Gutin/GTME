#!/usr/bin/env python3
"""
Test Salesforce Tools - Prove Everything Works
Similar to test_gsuite_tools.py
"""

import sys
import os

# Add salesforce_tools to path
sys.path.insert(0, os.path.dirname(__file__))

from salesforce_tools import (
    SalesforceTools,
    AccountOperations,
    OpportunityOperations,
    ContactOperations,
    DiscoveryOperations
)

# Credentials
USERNAME = "romangutin860@agentforce.com"
PASSWORD = "FuckSFDC1!"
SECURITY_TOKEN = "iLARVeZyoXUeJm4a5aPwvBZ9"

# DirectConsumerCo Account ID
ACCOUNT_ID = "001g5000002OccTAAS"


def print_test_header(test_num, test_name):
    """Print test header"""
    print("\n" + "="*80)
    print(f"TEST {test_num}: {test_name}")
    print("="*80)


def print_test_result(passed, message=""):
    """Print test result"""
    if passed:
        print(f"✅ PASSED {message}")
    else:
        print(f"❌ FAILED {message}")
    return passed


def test_1_query_accounts():
    """Test 1: Query Accounts"""
    print_test_header(1, "Query Accounts")
    
    try:
        sf = SalesforceTools(USERNAME, PASSWORD, SECURITY_TOKEN)
        accounts = sf.query_records("SELECT Id, Name, Type, Industry FROM Account LIMIT 5")
        
        print(f"\nFound {len(accounts)} accounts:")
        for acc in accounts:
            print(f"  - {acc['Name']} ({acc.get('Type', 'N/A')}) - {acc.get('Industry', 'N/A')}")
        
        return print_test_result(len(accounts) > 0, f"- Retrieved {len(accounts)} accounts")
    except Exception as e:
        print(f"Error: {str(e)}")
        return print_test_result(False, f"- {str(e)}")


def test_2_get_account():
    """Test 2: Get Account Details"""
    print_test_header(2, "Get Account Details")
    
    try:
        sf = AccountOperations(USERNAME, PASSWORD, SECURITY_TOKEN)
        account = sf.get_account(ACCOUNT_ID)
        
        print(f"\nAccount Details:")
        print(f"  Name: {account['Name']}")
        print(f"  Type: {account.get('Type', 'N/A')}")
        print(f"  Industry: {account.get('Industry', 'N/A')}")
        print(f"  City: {account.get('BillingCity', 'N/A')}")
        print(f"  State: {account.get('BillingState', 'N/A')}")
        
        return print_test_result(account['Name'] == 'DirectConsumerCo', "- Retrieved account details")
    except Exception as e:
        print(f"Error: {str(e)}")
        return print_test_result(False, f"- {str(e)}")


def test_3_get_account_summary():
    """Test 3: Get Account Summary"""
    print_test_header(3, "Get Account Summary (with opportunities and contacts)")
    
    try:
        sf = AccountOperations(USERNAME, PASSWORD, SECURITY_TOKEN)
        summary = sf.get_account_summary(ACCOUNT_ID)
        
        print(f"\nAccount Summary:")
        print(f"  Account: {summary['account']['Name']}")
        print(f"  Opportunities: {summary['opportunities']['total']}")
        print(f"  Open Opportunities: {summary['opportunities']['open']}")
        print(f"  Total Opportunity Value: ${summary['opportunities']['total_value']:,.0f}")
        print(f"  Contacts: {summary['contacts']['total']}")
        
        if summary['opportunities']['records']:
            print(f"\n  Top Opportunities:")
            for opp in summary['opportunities']['records'][:3]:
                amount = opp.get('Amount', 0) or 0
                print(f"    - {opp['Name']}: ${amount:,.0f} ({opp.get('StageName', 'N/A')})")
        
        return print_test_result(summary['opportunities']['total'] > 0, "- Retrieved account summary")
    except Exception as e:
        print(f"Error: {str(e)}")
        return print_test_result(False, f"- {str(e)}")


def test_4_query_opportunities():
    """Test 4: Query Opportunities"""
    print_test_header(4, "Query Opportunities")
    
    try:
        sf = SalesforceTools(USERNAME, PASSWORD, SECURITY_TOKEN)
        opps = sf.query_records(
            f"SELECT Id, Name, StageName, Amount, CloseDate FROM Opportunity WHERE AccountId = '{ACCOUNT_ID}'"
        )
        
        print(f"\nFound {len(opps)} opportunities for DirectConsumerCo:")
        for opp in opps:
            amount = opp.get('Amount', 0) or 0
            print(f"  - {opp['Name']}: ${amount:,.0f} ({opp.get('StageName', 'N/A')})")
        
        return print_test_result(len(opps) > 0, f"- Retrieved {len(opps)} opportunities")
    except Exception as e:
        print(f"Error: {str(e)}")
        return print_test_result(False, f"- {str(e)}")


def test_5_get_pipeline_summary():
    """Test 5: Get Pipeline Summary"""
    print_test_header(5, "Get Pipeline Summary")
    
    try:
        sf = OpportunityOperations(USERNAME, PASSWORD, SECURITY_TOKEN)
        summary = sf.get_pipeline_summary()
        
        print(f"\nPipeline Summary:")
        print(f"  Total Opportunities: {summary['total_opportunities']}")
        print(f"  Total Value: ${summary['total_value']:,.0f}")
        print(f"  Weighted Value: ${summary['weighted_value']:,.0f}")
        
        print(f"\n  By Stage:")
        for stage, data in summary['by_stage'].items():
            print(f"    {stage}: {data['count']} opps, ${data['value']:,.0f}")
        
        return print_test_result(summary['total_opportunities'] > 0, "- Retrieved pipeline summary")
    except Exception as e:
        print(f"Error: {str(e)}")
        return print_test_result(False, f"- {str(e)}")


def test_6_list_objects():
    """Test 6: List All Objects"""
    print_test_header(6, "List All Objects")
    
    try:
        sf = DiscoveryOperations(USERNAME, PASSWORD, SECURITY_TOKEN)
        objects = sf.list_all_objects()
        
        standard = [obj for obj in objects if not obj['custom']]
        custom = [obj for obj in objects if obj['custom']]
        
        print(f"\nFound {len(objects)} total objects:")
        print(f"  Standard: {len(standard)}")
        print(f"  Custom: {len(custom)}")
        
        if custom:
            print(f"\n  Custom Objects:")
            for obj in custom[:10]:
                print(f"    - {obj['label']} ({obj['name']})")
        
        return print_test_result(len(objects) > 0, f"- Retrieved {len(objects)} objects")
    except Exception as e:
        print(f"Error: {str(e)}")
        return print_test_result(False, f"- {str(e)}")


def test_7_get_object_summary():
    """Test 7: Get Object Summary"""
    print_test_header(7, "Get Object Summary (Opportunity)")
    
    try:
        sf = DiscoveryOperations(USERNAME, PASSWORD, SECURITY_TOKEN)
        summary = sf.get_object_summary('Opportunity')
        
        print(f"\nOpportunity Object Summary:")
        print(f"  Label: {summary['label']}")
        print(f"  API Name: {summary['name']}")
        print(f"  Total Fields: {summary['total_fields']}")
        print(f"  Custom Fields: {summary['custom_fields']}")
        print(f"  Record Count: {summary['record_count']}")
        print(f"  Queryable: {summary['queryable']}")
        print(f"  Createable: {summary['createable']}")
        
        return print_test_result(summary['total_fields'] > 0, "- Retrieved object summary")
    except Exception as e:
        print(f"Error: {str(e)}")
        return print_test_result(False, f"- {str(e)}")


def test_8_create_update_opportunity():
    """Test 8: Create and Update Opportunity (CRUD Test)"""
    print_test_header(8, "Create and Update Opportunity (CRUD Test)")
    
    try:
        sf = OpportunityOperations(USERNAME, PASSWORD, SECURITY_TOKEN)
        
        # Create
        print("\n  Creating test opportunity...")
        opp_data = {
            'Name': 'TEST - Automated Test Opportunity',
            'AccountId': ACCOUNT_ID,
            'Amount': 99999,
            'CloseDate': '2025-12-31',
            'StageName': 'Prospecting'
        }
        opp_id = sf.create_opportunity(opp_data)
        print(f"  ✅ Created: {opp_id}")
        
        # Update
        print("\n  Updating opportunity...")
        sf.update_opportunity(opp_id, {
            'StageName': 'Qualification',
            'Amount': 150000
        })
        print(f"  ✅ Updated stage and amount")
        
        # Verify
        print("\n  Verifying update...")
        updated_opp = sf.get_opportunity(opp_id)
        print(f"  Stage: {updated_opp['StageName']}")
        print(f"  Amount: ${updated_opp['Amount']:,.0f}")
        
        # Cleanup
        print("\n  Cleaning up (deleting test opportunity)...")
        sf.delete_record('Opportunity', opp_id)
        print(f"  ✅ Deleted test opportunity")
        
        return print_test_result(
            updated_opp['StageName'] == 'Qualification' and updated_opp['Amount'] == 150000,
            "- CRUD operations successful"
        )
    except Exception as e:
        print(f"Error: {str(e)}")
        return print_test_result(False, f"- {str(e)}")


def test_9_query_custom_objects():
    """Test 9: Query Custom Objects"""
    print_test_header(9, "Query Custom Objects")
    
    try:
        sf = SalesforceTools(USERNAME, PASSWORD, SECURITY_TOKEN)
        
        # Try to query Use_Case__c if it exists
        try:
            use_cases = sf.query_records(
                "SELECT Id, Name, Stage__c, Workload_Name__c FROM Use_Case__c LIMIT 5"
            )
            print(f"\nFound {len(use_cases)} use cases:")
            for uc in use_cases:
                print(f"  - {uc['Name']} ({uc.get('Stage__c', 'N/A')})")
            
            return print_test_result(True, f"- Retrieved {len(use_cases)} custom object records")
        except Exception as e:
            if 'sObject type' in str(e) or 'does not exist' in str(e):
                print("\n  Use_Case__c object doesn't exist (expected if not set up)")
                return print_test_result(True, "- Custom object query tested (object doesn't exist)")
            else:
                raise
    except Exception as e:
        print(f"Error: {str(e)}")
        return print_test_result(False, f"- {str(e)}")


def test_10_complex_query():
    """Test 10: Complex Query with Relationships"""
    print_test_header(10, "Complex Query with Relationships")
    
    try:
        sf = SalesforceTools(USERNAME, PASSWORD, SECURITY_TOKEN)
        opps = sf.query_records(
            """SELECT Id, Name, Account.Name, Account.Industry, Amount, StageName, CloseDate 
               FROM Opportunity 
               WHERE Amount > 50000 
               ORDER BY Amount DESC 
               LIMIT 10"""
        )
        
        print(f"\nFound {len(opps)} opportunities > $50K:")
        for opp in opps:
            amount = opp.get('Amount', 0) or 0
            account_name = opp.get('Account', {}).get('Name', 'N/A') if opp.get('Account') else 'N/A'
            print(f"  - {opp['Name']}: ${amount:,.0f} ({account_name})")
        
        return print_test_result(len(opps) > 0, f"- Retrieved {len(opps)} opportunities with relationships")
    except Exception as e:
        print(f"Error: {str(e)}")
        return print_test_result(False, f"- {str(e)}")


def main():
    """Run all tests"""
    print("\n" + "="*80)
    print("SALESFORCE TOOLS TEST SUITE")
    print("="*80)
    print(f"\nTesting against: DirectConsumerCo ({ACCOUNT_ID})")
    
    # Run all tests
    results = []
    results.append(test_1_query_accounts())
    results.append(test_2_get_account())
    results.append(test_3_get_account_summary())
    results.append(test_4_query_opportunities())
    results.append(test_5_get_pipeline_summary())
    results.append(test_6_list_objects())
    results.append(test_7_get_object_summary())
    results.append(test_8_create_update_opportunity())
    results.append(test_9_query_custom_objects())
    results.append(test_10_complex_query())
    
    # Summary
    print("\n" + "="*80)
    print("TEST SUITE SUMMARY")
    print("="*80)
    
    passed = sum(results)
    total = len(results)
    
    print(f"\nTests Passed: {passed}/{total}")
    
    if passed == total:
        print("\n🎉 ALL TESTS PASSED!")
        print("✅ Salesforce Tools are working correctly!")
    else:
        print(f"\n⚠️  {total - passed} test(s) failed")
    
    print("\n" + "="*80)
    print()
    
    return passed == total


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

