"""
Python usage examples for Salesforce Tools
"""

import json
from salesforce_tools import SalesforceTools, AccountOperations, OpportunityOperations

# Load credentials
with open('../credentials.json') as f:
    creds = json.load(f)

# Initialize
sf = SalesforceTools(
    username=creds['username'],
    password=creds['password'],
    security_token=creds['security_token']
)

# ============================================================================
# EXAMPLE 1: Query Accounts
# ============================================================================

print("\n" + "="*80)
print("EXAMPLE 1: Query Accounts")
print("="*80)

accounts = sf.query_records("SELECT Id, Name, Industry FROM Account LIMIT 5")
for account in accounts:
    print(f"  {account['Name']} - {account.get('Industry', 'N/A')}")

# ============================================================================
# EXAMPLE 2: Get Account Details
# ============================================================================

print("\n" + "="*80)
print("EXAMPLE 2: Get Account Details")
print("="*80)

account_ops = AccountOperations(
    username=creds['username'],
    password=creds['password'],
    security_token=creds['security_token']
)

# Get first account from previous query
if accounts:
    account_id = accounts[0]['Id']
    account = account_ops.get_account(account_id)
    print(f"  Name: {account['Name']}")
    print(f"  Type: {account.get('Type', 'N/A')}")
    print(f"  Industry: {account.get('Industry', 'N/A')}")

# ============================================================================
# EXAMPLE 3: Create Opportunity
# ============================================================================

print("\n" + "="*80)
print("EXAMPLE 3: Create Opportunity")
print("="*80)

opp_ops = OpportunityOperations(
    username=creds['username'],
    password=creds['password'],
    security_token=creds['security_token']
)

# Create opportunity
opp_data = {
    'Name': 'Test Opportunity - Python Example',
    'AccountId': accounts[0]['Id'],
    'Amount': 50000,
    'CloseDate': '2025-12-31',
    'StageName': 'Prospecting'
}

try:
    opp_id = opp_ops.create_opportunity(opp_data)
    print(f"  ✅ Created opportunity: {opp_id}")
    
    # Update it
    opp_ops.update_opportunity(opp_id, {'StageName': 'Qualification'})
    print(f"  ✅ Updated opportunity stage")
    
    # Delete it (cleanup)
    sf.delete_record('Opportunity', opp_id)
    print(f"  ✅ Deleted test opportunity")
    
except Exception as e:
    print(f"  ❌ Error: {str(e)}")

# ============================================================================
# EXAMPLE 4: Get Pipeline Summary
# ============================================================================

print("\n" + "="*80)
print("EXAMPLE 4: Get Pipeline Summary")
print("="*80)

summary = opp_ops.get_pipeline_summary()
print(f"  Total Opportunities: {summary['total_opportunities']}")
print(f"  Total Value: ${summary['total_value']:,.0f}")
print(f"  Weighted Value: ${summary['weighted_value']:,.0f}")

print("\n  By Stage:")
for stage, data in summary['by_stage'].items():
    print(f"    {stage}: {data['count']} opps, ${data['value']:,.0f}")

# ============================================================================
# EXAMPLE 5: Discovery
# ============================================================================

print("\n" + "="*80)
print("EXAMPLE 5: Discovery")
print("="*80)

# List custom objects
custom_objects = sf.list_custom_objects()
print(f"  Custom Objects: {len(custom_objects)}")
for obj in custom_objects[:5]:
    print(f"    - {obj}")

# Get object summary
if custom_objects:
    obj_name = custom_objects[0]
    fields = sf.get_field_names(obj_name)
    print(f"\n  {obj_name} has {len(fields)} fields")

print("\n✅ All examples completed!")

