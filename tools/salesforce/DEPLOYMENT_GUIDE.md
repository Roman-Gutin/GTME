# Salesforce Tools - Deployment Guide

## 🚀 Deployment via Snow CLI & Service Account

This guide explains how to deploy Salesforce Tools to Snowflake using the Snow CLI and service account authentication, following the same pattern as the gsuite tools.

## 📋 Prerequisites

### 1. Install Snow CLI
```bash
pip install snowflake-cli-labs
```

### 2. Configure Service Account

Create `~/.snowflake/config.toml`:
```toml
[connections.default]
account = "your-account"
user = "your-service-account"
authenticator = "SNOWFLAKE_JWT"
private_key_path = "~/.snowflake/rsa_key.p8"
database = "TEST"
schema = "PUBLIC"
role = "ACCOUNTADMIN"
warehouse = "COMPUTE_WH"
```

### 3. Set Up Salesforce Secrets

The deployment script will create these secrets. Update them with your credentials:

```sql
-- After deployment, update secrets with your Salesforce credentials
ALTER SECRET salesforce_username SET SECRET_STRING = 'your-username@salesforce.com';
ALTER SECRET salesforce_password SET SECRET_STRING = 'your-password';
ALTER SECRET salesforce_token SET SECRET_STRING = 'your-security-token';
```

## 🔧 Deployment Steps

### Option 1: Automated Deployment (Recommended)

```bash
# Unix/Mac
./deploy_to_snowflake.sh

# Windows
deploy_to_snowflake.bat
```

This script:
1. ✅ Checks Snow CLI is installed
2. ✅ Verifies all required files exist
3. ✅ Uploads Python files to Snowflake stage
4. ✅ Creates external access integration
5. ✅ Creates secrets for credentials
6. ✅ Creates all 11 UDFs
7. ✅ Grants RBAC permissions
8. ✅ Verifies installation

### Option 2: Manual Deployment

```bash
# 1. Upload Python files
snow stage copy salesforce_tools/__init__.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/ --overwrite --auto-compress false
snow stage copy salesforce_tools/core.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/ --overwrite --auto-compress false
snow stage copy salesforce_tools/accounts.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/ --overwrite --auto-compress false
snow stage copy salesforce_tools/opportunities.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/ --overwrite --auto-compress false
snow stage copy salesforce_tools/contacts.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/ --overwrite --auto-compress false
snow stage copy salesforce_tools/discovery.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/ --overwrite --auto-compress false

# 2. Verify upload
snow stage list @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/

# 3. Execute setup script
snow sql -f snowflake_setup.sql

# 4. Fix remaining imports (if needed)
snow sql -f fix_imports.sql

# 5. Verify functions
snow sql -q "SHOW FUNCTIONS LIKE '%salesforce%' IN SCHEMA TEST.PUBLIC;"
```

## 🔐 Architecture

### Stage Structure
```
TEST.PUBLIC.SALESFORCE_STAGE/
└── salesforce_tools/
    ├── __init__.py
    ├── core.py
    ├── accounts.py
    ├── opportunities.py
    ├── contacts.py
    └── discovery.py
```

### Secrets
```
salesforce_username  → Salesforce username
salesforce_password  → Salesforce password
salesforce_token     → Salesforce security token
```

### External Access Integration
```
salesforce_api_integration
├── Network Rule: salesforce_api_network_rule
│   ├── login.salesforce.com:443
│   ├── *.salesforce.com:443
│   └── *.force.com:443
└── Secrets: salesforce_username, salesforce_password, salesforce_token
```

### UDFs (11 total)
All UDFs:
- Read credentials from Snowflake secrets
- Use external access integration for API calls
- Import Python modules from stage
- No credential parameters needed

## 🧪 Testing

### Run Test Suite
```bash
snow sql -f test_sfdc_tools.sql
```

Expected output:
```
✅ TEST 1 PASSED: Query Accounts
✅ TEST 2 PASSED: Get Account Details
✅ TEST 3 PASSED: Get Account Summary
✅ TEST 4 PASSED: Query Opportunities
✅ TEST 5 PASSED: Get Pipeline Summary
✅ TEST 6 PASSED: List All Objects
✅ TEST 7 PASSED: Get Object Summary
✅ TEST 8 PASSED: Create and Update Opportunity (CRUD)
✅ TEST 9 PASSED: Query Custom Objects
✅ TEST 10 PASSED: Complex Query with Relationships

🎉 SALESFORCE TOOLS TEST SUITE COMPLETE!
```

### Quick Test
```bash
# Query accounts
snow sql -q "SELECT salesforce_query_records('SELECT Id, Name FROM Account LIMIT 5');"

# Get account details
snow sql -q "SELECT salesforce_get_account('001g5000002OccTAAS');"

# Get pipeline summary
snow sql -q "SELECT salesforce_get_pipeline_summary();"
```

## 📊 Comparison with gsuite Tools

| Aspect | gsuite Tools | Salesforce Tools |
|--------|-------------|------------------|
| **Deployment** | Snow CLI | Snow CLI ✅ |
| **Service Account** | JWT Auth | JWT Auth ✅ |
| **Secrets** | Google credentials | Salesforce credentials ✅ |
| **Stage** | GOOGLE_DOCS_STAGE | SALESFORCE_STAGE ✅ |
| **Database** | TEST | TEST ✅ |
| **Schema** | PUBLIC | PUBLIC ✅ |
| **External Access** | Google APIs | Salesforce APIs ✅ |
| **RBAC** | ACCOUNTADMIN | ACCOUNTADMIN ✅ |

## 🔒 Security Best Practices

### ✅ Credentials Management
- Stored in Snowflake secrets (encrypted at rest)
- Never exposed in SQL queries
- Only ACCOUNTADMIN/SYSADMIN can read
- Regular users call UDFs without seeing credentials

### ✅ Network Access
- Explicit allow-list of Salesforce domains
- HTTPS only (port 443)
- External access integration required

### ✅ RBAC
```sql
-- Integration access (admins only)
GRANT USAGE ON INTEGRATION salesforce_api_integration TO ROLE ACCOUNTADMIN;
GRANT USAGE ON INTEGRATION salesforce_api_integration TO ROLE SYSADMIN;

-- Secret access (admins only)
GRANT READ ON SECRET salesforce_username TO ROLE ACCOUNTADMIN;
GRANT READ ON SECRET salesforce_password TO ROLE ACCOUNTADMIN;
GRANT READ ON SECRET salesforce_token TO ROLE ACCOUNTADMIN;

-- Function access (everyone)
GRANT USAGE ON ALL FUNCTIONS IN SCHEMA TEST.PUBLIC TO ROLE PUBLIC;
```

## 🔄 Updating

### Update Python Code
```bash
# 1. Modify Python files locally
# 2. Re-upload to stage
snow stage copy salesforce_tools/core.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/ --overwrite --auto-compress false

# 3. Recreate affected UDFs
snow sql -f snowflake_setup.sql
```

### Update Credentials
```sql
ALTER SECRET salesforce_username SET SECRET_STRING = 'new-username@salesforce.com';
ALTER SECRET salesforce_password SET SECRET_STRING = 'new-password';
ALTER SECRET salesforce_token SET SECRET_STRING = 'new-token';

-- No UDF changes needed - they automatically use new credentials
```

### Update UDFs
```bash
# Re-run setup script
snow sql -f snowflake_setup.sql
```

## ❌ Troubleshooting

### Error: "Snow CLI not found"
```bash
pip install snowflake-cli-labs
```

### Error: "Connection failed"
Check `~/.snowflake/config.toml`:
- Account name correct?
- Service account exists?
- Private key path correct?
- Role has permissions?

### Error: "External network access not allowed"
```sql
-- Verify integration exists
SHOW INTEGRATIONS LIKE 'salesforce_api_integration';

-- Verify network rule
SHOW NETWORK RULES LIKE 'salesforce_api_network_rule';

-- Grant usage
GRANT USAGE ON INTEGRATION salesforce_api_integration TO ROLE ACCOUNTADMIN;
```

### Error: "Secret not found"
```sql
-- Verify secrets exist
SHOW SECRETS LIKE 'salesforce_%';

-- Create if missing
CREATE SECRET salesforce_username TYPE = GENERIC_STRING SECRET_STRING = 'your-username';
CREATE SECRET salesforce_password TYPE = GENERIC_STRING SECRET_STRING = 'your-password';
CREATE SECRET salesforce_token TYPE = GENERIC_STRING SECRET_STRING = 'your-token';
```

### Error: "Import failed"
```sql
-- Verify files are uploaded
snow stage list @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/

-- Re-upload if needed
snow stage copy salesforce_tools/core.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/ --overwrite --auto-compress false
```

## 📚 References

- [Snow CLI Documentation](https://docs.snowflake.com/en/developer-guide/snowflake-cli/index)
- [External Access Integration](https://docs.snowflake.com/en/developer-guide/external-network-access/external-network-access-overview)
- [Snowflake Secrets](https://docs.snowflake.com/en/sql-reference/sql/create-secret)
- [Service Account Authentication](https://docs.snowflake.com/en/user-guide/key-pair-auth)

## ✅ Summary

**Deployment Method:**
- ✅ Snow CLI (not SnowSQL)
- ✅ Service account with JWT auth
- ✅ Secrets for credentials
- ✅ External access integration
- ✅ Stage for Python modules
- ✅ RBAC for security

**Same Pattern as gsuite Tools:**
- ✅ Consistent deployment process
- ✅ Same security model
- ✅ Same directory structure
- ✅ Same testing approach

**Production Ready:**
- ✅ Secure credential management
- ✅ Proper RBAC
- ✅ External network access
- ✅ Comprehensive testing
- ✅ Easy to update

---

**The Salesforce Tools now follow the exact same deployment pattern as gsuite tools!** 🎉

