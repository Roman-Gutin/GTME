# Salesforce Opportunity CRUD - Snowflake UDFs

## ✅ What's Deployed

5 Snowflake UDFs for Opportunity CRUD operations in **AGENTS_DEMO.PUBLIC**:

1. **sf_query_opportunities(soql)** - Query opportunities with SOQL
2. **sf_get_opportunity(id)** - Get opportunity by ID
3. **sf_create_opportunity(data)** - Create new opportunity
4. **sf_update_opportunity(id, data)** - Update opportunity (including custom fields)
5. **sf_delete_opportunity(id)** - Delete opportunity

## 🧪 Testing

### Local Testing (Verified ✅)
```bash
python test_local_opportunities.py
```

All 6 local tests passed:
- ✅ Query opportunities
- ✅ Create opportunity
- ✅ Get opportunity
- ✅ Update opportunity (standard + custom fields)
- ✅ Delete opportunity
- ✅ Query with custom fields

### Snowflake Testing
```bash
snow sql -f test_opportunity_crud.sql
```

## 📊 Custom Fields Supported

The following custom fields are available on Opportunity:
- `DeliveryInstallationStatus__c`
- `TrackingNumber__c`
- `OrderNumber__c`
- `CurrentGenerators__c`
- `MainCompetitors__c`
- `Technical_Win__c`
- `SE_Comments__c`
- `Workload__c`

## 🚀 Usage Examples

### Query Opportunities
```sql
SELECT sf_query_opportunities(
    'SELECT Id, Name, StageName, Amount FROM Opportunity WHERE AccountId = ''001g5000002OccTAAS'' LIMIT 5'
);
```

### Query with Custom Fields
```sql
SELECT sf_query_opportunities(
    'SELECT Id, Name, DeliveryInstallationStatus__c, TrackingNumber__c FROM Opportunity LIMIT 5'
);
```

### Create Opportunity
```sql
SELECT sf_create_opportunity(
    OBJECT_CONSTRUCT(
        'Name', 'Q4 2025 Deal',
        'AccountId', '001g5000002OccTAAS',
        'Amount', 100000,
        'CloseDate', '2025-12-31',
        'StageName', 'Prospecting',
        'Probability', 10
    )
);
```

### Get Opportunity
```sql
SELECT sf_get_opportunity('006g5000000MgfRAAS');
```

### Update Opportunity (Standard Fields)
```sql
SELECT sf_update_opportunity(
    '006g5000000MgfRAAS',
    OBJECT_CONSTRUCT(
        'StageName', 'Qualification',
        'Amount', 150000,
        'Probability', 25
    )
);
```

### Update Opportunity (Custom Fields)
```sql
SELECT sf_update_opportunity(
    '006g5000000MgfRAAS',
    OBJECT_CONSTRUCT(
        'DeliveryInstallationStatus__c', 'In progress',
        'TrackingNumber__c', 'TRACK-12345',
        'OrderNumber__c', 'ORD-67890'
    )
);
```

### Delete Opportunity
```sql
SELECT sf_delete_opportunity('006g5000000MgfRAAS');
```

### Complex Query with Aggregations
```sql
SELECT sf_query_opportunities(
    'SELECT StageName, COUNT(Id) as Count, SUM(Amount) as Total FROM Opportunity GROUP BY StageName'
);
```

### Query with Relationships
```sql
SELECT sf_query_opportunities(
    'SELECT Id, Name, Account.Name, Account.Industry, Amount FROM Opportunity LIMIT 10'
);
```

## 🔐 Security

- ✅ Credentials stored in Snowflake secrets
- ✅ External access integration configured
- ✅ No credentials exposed in queries
- ✅ RBAC permissions granted to PUBLIC role

## 📁 Files

- **test_local_opportunities.py** - Local Python tests (all passed ✅)
- **deploy_opportunity_crud.sql** - Deployment script
- **test_opportunity_crud.sql** - Snowflake test suite
- **salesforce_tools/opportunities.py** - Python implementation

## 🎯 What Works

✅ **Query** - Any SOQL query on Opportunity  
✅ **Create** - Create opportunities with standard and custom fields  
✅ **Read** - Get opportunity by ID  
✅ **Update** - Update standard and custom fields  
✅ **Delete** - Delete opportunities  
✅ **Custom Fields** - Full support for all custom fields  
✅ **Relationships** - Query related objects (Account, etc.)  
✅ **Aggregations** - COUNT, SUM, AVG, etc.  

## 🚀 Deployment

Already deployed to:
- **Database:** AGENTS_DEMO
- **Schema:** PUBLIC
- **Stage:** SALESFORCE_STAGE

To redeploy:
```bash
snow sql -f deploy_opportunity_crud.sql
```

## ✅ Summary

**Status:** Deployed and tested ✅  
**Local Tests:** 6/6 passed ✅  
**Functions:** 5 UDFs deployed ✅  
**Custom Fields:** Fully supported ✅  
**Ready to Use:** Yes! 🎉

