#!/usr/bin/env python3
"""
Test Salesforce Opportunity CRUD operations locally
Run this BEFORE deploying to Snowflake to verify API calls work
"""

import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from salesforce_tools.core import SalesforceTools
from salesforce_tools.opportunities import OpportunityOperations

# Credentials
USERNAME = "romangutin860@agentforce.com"
PASSWORD = "FuckSFDC1!"
SECURITY_TOKEN = "iLARVeZyoXUeJm4a5aPwvBZ9"

# DirectConsumerCo Account ID
ACCOUNT_ID = "001g5000002OccTAAS"


def test_query_opportunities():
    """Test: Query opportunities"""
    print("\n" + "="*80)
    print("TEST 1: Query Opportunities")
    print("="*80)
    
    try:
        sf = SalesforceTools(USERNAME, PASSWORD, SECURITY_TOKEN)
        opps = sf.query_records(
            f"SELECT Id, Name, StageName, Amount, CloseDate, Probability FROM Opportunity WHERE AccountId = '{ACCOUNT_ID}' LIMIT 5"
        )
        
        print(f"\n✅ Found {len(opps)} opportunities:")
        for opp in opps:
            amount = opp.get('Amount', 0) or 0
            print(f"  - {opp['Name']}")
            print(f"    Stage: {opp.get('StageName', 'N/A')}")
            print(f"    Amount: ${amount:,.0f}")
            print(f"    Probability: {opp.get('Probability', 0)}%")
            print(f"    Close Date: {opp.get('CloseDate', 'N/A')}")
            print()
        
        return True
    except Exception as e:
        print(f"❌ FAILED: {str(e)}")
        return False


def test_create_opportunity():
    """Test: Create opportunity"""
    print("\n" + "="*80)
    print("TEST 2: Create Opportunity")
    print("="*80)
    
    try:
        sf = OpportunityOperations(USERNAME, PASSWORD, SECURITY_TOKEN)
        
        opp_data = {
            'Name': 'TEST - Local API Test Opportunity',
            'AccountId': ACCOUNT_ID,
            'Amount': 50000,
            'CloseDate': '2025-12-31',
            'StageName': 'Prospecting',
            'Probability': 10
        }
        
        print(f"\nCreating opportunity: {opp_data['Name']}")
        opp_id = sf.create_opportunity(opp_data)
        
        print(f"✅ Created opportunity: {opp_id}")
        return opp_id
    except Exception as e:
        print(f"❌ FAILED: {str(e)}")
        return None


def test_get_opportunity(opp_id):
    """Test: Get opportunity"""
    print("\n" + "="*80)
    print("TEST 3: Get Opportunity")
    print("="*80)
    
    try:
        sf = OpportunityOperations(USERNAME, PASSWORD, SECURITY_TOKEN)
        
        print(f"\nGetting opportunity: {opp_id}")
        opp = sf.get_opportunity(opp_id)
        
        print(f"\n✅ Retrieved opportunity:")
        print(f"  Name: {opp['Name']}")
        print(f"  Stage: {opp.get('StageName', 'N/A')}")
        print(f"  Amount: ${opp.get('Amount', 0):,.0f}")
        print(f"  Probability: {opp.get('Probability', 0)}%")
        print(f"  Close Date: {opp.get('CloseDate', 'N/A')}")
        
        return True
    except Exception as e:
        print(f"❌ FAILED: {str(e)}")
        return False


def test_update_opportunity(opp_id):
    """Test: Update opportunity (including custom fields)"""
    print("\n" + "="*80)
    print("TEST 4: Update Opportunity")
    print("="*80)
    
    try:
        sf = OpportunityOperations(USERNAME, PASSWORD, SECURITY_TOKEN)
        
        # Update standard and custom fields
        update_data = {
            'StageName': 'Qualification',
            'Amount': 75000,
            'Probability': 25,
            'Description': 'Updated via local API test'
        }
        
        print(f"\nUpdating opportunity: {opp_id}")
        print(f"  New Stage: {update_data['StageName']}")
        print(f"  New Amount: ${update_data['Amount']:,.0f}")
        print(f"  New Probability: {update_data['Probability']}%")
        
        success = sf.update_opportunity(opp_id, update_data)
        
        if success:
            print(f"\n✅ Updated successfully")
            
            # Verify the update
            opp = sf.get_opportunity(opp_id)
            print(f"\nVerified:")
            print(f"  Stage: {opp.get('StageName', 'N/A')}")
            print(f"  Amount: ${opp.get('Amount', 0):,.0f}")
            print(f"  Probability: {opp.get('Probability', 0)}%")
            
            return True
        else:
            print(f"❌ Update returned False")
            return False
            
    except Exception as e:
        print(f"❌ FAILED: {str(e)}")
        return False


def test_delete_opportunity(opp_id):
    """Test: Delete opportunity"""
    print("\n" + "="*80)
    print("TEST 5: Delete Opportunity")
    print("="*80)
    
    try:
        sf = SalesforceTools(USERNAME, PASSWORD, SECURITY_TOKEN)
        
        print(f"\nDeleting opportunity: {opp_id}")
        success = sf.delete_record('Opportunity', opp_id)
        
        if success:
            print(f"✅ Deleted successfully")
            return True
        else:
            print(f"❌ Delete returned False")
            return False
            
    except Exception as e:
        print(f"❌ FAILED: {str(e)}")
        return False


def test_query_custom_fields():
    """Test: Query opportunities with custom fields"""
    print("\n" + "="*80)
    print("TEST 6: Query Opportunities with Custom Fields")
    print("="*80)
    
    try:
        sf = SalesforceTools(USERNAME, PASSWORD, SECURITY_TOKEN)
        
        # First, get the Opportunity object metadata to see what custom fields exist
        print("\nGetting Opportunity metadata...")
        metadata = sf.sf.Opportunity.describe()
        
        custom_fields = [f['name'] for f in metadata['fields'] if f['custom']]
        print(f"\nFound {len(custom_fields)} custom fields:")
        for field in custom_fields[:10]:  # Show first 10
            print(f"  - {field}")
        
        # Query with some custom fields if they exist
        if custom_fields:
            fields = ['Id', 'Name', 'StageName', 'Amount'] + custom_fields[:3]
            query = f"SELECT {', '.join(fields)} FROM Opportunity WHERE AccountId = '{ACCOUNT_ID}' LIMIT 3"
            
            print(f"\nQuerying with custom fields:")
            print(f"  {query}")
            
            opps = sf.query_records(query)
            print(f"\n✅ Retrieved {len(opps)} opportunities with custom fields")
            
            for opp in opps:
                print(f"\n  {opp['Name']}:")
                for field in custom_fields[:3]:
                    if field in opp:
                        print(f"    {field}: {opp[field]}")
        else:
            print("\n⚠️  No custom fields found on Opportunity object")
        
        return True
    except Exception as e:
        print(f"❌ FAILED: {str(e)}")
        return False


def main():
    """Run all tests"""
    print("\n" + "="*80)
    print("SALESFORCE OPPORTUNITY CRUD - LOCAL API TEST")
    print("="*80)
    print(f"\nTesting against: DirectConsumerCo ({ACCOUNT_ID})")
    print(f"Username: {USERNAME}")
    
    results = []
    
    # Test 1: Query opportunities
    results.append(test_query_opportunities())
    
    # Test 2: Create opportunity
    opp_id = test_create_opportunity()
    if opp_id:
        results.append(True)
        
        # Test 3: Get opportunity
        results.append(test_get_opportunity(opp_id))
        
        # Test 4: Update opportunity
        results.append(test_update_opportunity(opp_id))
        
        # Test 5: Delete opportunity
        results.append(test_delete_opportunity(opp_id))
    else:
        results.extend([False, False, False])
    
    # Test 6: Query with custom fields
    results.append(test_query_custom_fields())
    
    # Summary
    print("\n" + "="*80)
    print("TEST SUMMARY")
    print("="*80)
    
    passed = sum(results)
    total = len(results)
    
    print(f"\nTests Passed: {passed}/{total}")
    
    if passed == total:
        print("\n🎉 ALL TESTS PASSED!")
        print("✅ Salesforce API calls are working correctly!")
        print("\n👉 Ready to deploy to Snowflake!")
    else:
        print(f"\n⚠️  {total - passed} test(s) failed")
        print("Fix the issues before deploying to Snowflake")
    
    print("\n" + "="*80)
    print()
    
    return passed == total


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

