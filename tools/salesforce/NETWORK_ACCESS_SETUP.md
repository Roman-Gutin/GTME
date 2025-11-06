# Salesforce Tools - External Network Access & RBAC Setup

## 🌐 External Access Integration

The Salesforce Tools require external network access to communicate with Salesforce APIs. This document explains the setup.

## 📋 What's Included in snowflake_setup.sql

### 1. Network Rule
```sql
CREATE OR REPLACE NETWORK RULE salesforce_api_network_rule
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = (
    'login.salesforce.com:443',
    'test.salesforce.com:443',
    '*.salesforce.com:443',
    '*.force.com:443',
    '*.my.salesforce.com:443'
  );
```

**Purpose:** Allows outbound HTTPS connections to Salesforce domains

**Domains Covered:**
- `login.salesforce.com` - Production login
- `test.salesforce.com` - Sandbox login
- `*.salesforce.com` - All Salesforce subdomains
- `*.force.com` - Force.com platform
- `*.my.salesforce.com` - My Salesforce domains

### 2. Secret (Optional)
```sql
CREATE OR REPLACE SECRET salesforce_credentials
  TYPE = GENERIC_STRING
  SECRET_STRING = '{"username":"...","password":"...","security_token":"..."}';
```

**Purpose:** Securely store Salesforce credentials (optional - can pass as parameters instead)

**Note:** Replace placeholder values with actual credentials before deployment

### 3. External Access Integration
```sql
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION salesforce_api_integration
  ALLOWED_NETWORK_RULES = (salesforce_api_network_rule)
  ALLOWED_AUTHENTICATION_SECRETS = (salesforce_credentials)
  ENABLED = TRUE;
```

**Purpose:** Combines network rules and secrets into a single integration

**Used By:** All 11 Salesforce UDFs

### 4. UDF Configuration

Each UDF includes:
```sql
EXTERNAL_ACCESS_INTEGRATIONS = (salesforce_api_integration)
SECRETS = ('cred' = salesforce_credentials)
```

**Example:**
```sql
CREATE OR REPLACE FUNCTION salesforce_query_records(...)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('simple-salesforce==1.12.5', 'requests')
EXTERNAL_ACCESS_INTEGRATIONS = (salesforce_api_integration)  -- ✅ Added
SECRETS = ('cred' = salesforce_credentials)                   -- ✅ Added
HANDLER = 'query_handler'
AS $$...$$;
```

## 🔒 RBAC (Role-Based Access Control)

### Permissions Granted

```sql
-- Integration permissions
GRANT USAGE ON INTEGRATION salesforce_api_integration TO ROLE ACCOUNTADMIN;
GRANT USAGE ON INTEGRATION salesforce_api_integration TO ROLE SYSADMIN;

-- Schema permissions
GRANT USAGE ON SCHEMA salesforce_tools TO ROLE PUBLIC;

-- Function permissions
GRANT USAGE ON ALL FUNCTIONS IN SCHEMA salesforce_tools TO ROLE PUBLIC;

-- Secret permissions
GRANT READ ON SECRET salesforce_credentials TO ROLE ACCOUNTADMIN;
GRANT READ ON SECRET salesforce_credentials TO ROLE SYSADMIN;
```

### Permission Breakdown

| Object | Role | Permission | Purpose |
|--------|------|------------|---------|
| `salesforce_api_integration` | ACCOUNTADMIN | USAGE | Admin access to integration |
| `salesforce_api_integration` | SYSADMIN | USAGE | System admin access |
| `salesforce_tools` schema | PUBLIC | USAGE | Everyone can use schema |
| All UDFs | PUBLIC | USAGE | Everyone can call functions |
| `salesforce_credentials` | ACCOUNTADMIN | READ | Admin can read credentials |
| `salesforce_credentials` | SYSADMIN | READ | Sysadmin can read credentials |

## 🚀 Deployment

### Automatic Deployment

Run the deployment script:
```bash
# Windows
deploy_to_snowflake.bat

# Linux/Mac
./deploy_to_snowflake.sh
```

This automatically:
1. Creates network rule
2. Creates secret (with placeholder - update manually)
3. Creates external access integration
4. Uploads Python files
5. Creates all 11 UDFs with external access
6. Grants permissions

### Manual Deployment

```bash
snowsql -c default -f snowflake_setup.sql
```

## ⚙️ Configuration

### Option 1: Use Secret (Recommended for Production)

1. Update the secret with real credentials:
```sql
ALTER SECRET salesforce_credentials
SET SECRET_STRING = '{
  "username": "your-username@salesforce.com",
  "password": "your-password",
  "security_token": "your-token"
}';
```

2. UDFs can read from secret automatically

### Option 2: Pass Credentials as Parameters (Recommended for Testing)

Pass credentials directly when calling UDFs:
```sql
SELECT salesforce_query_records(
    'SELECT Id, Name FROM Account LIMIT 5',
    'your-username@salesforce.com',  -- username
    'your-password',                  -- password
    'your-security-token'             -- token
);
```

## 🧪 Testing

### Test Network Access

```sql
-- Test basic query
SELECT salesforce_query_records(
    'SELECT Id, Name FROM Account LIMIT 1',
    'username',
    'password',
    'token'
);
```

If you get an error about network access, check:
1. External access integration is created
2. Network rule includes Salesforce domains
3. UDF has `EXTERNAL_ACCESS_INTEGRATIONS` clause

### Test All Functions

Run the test suite:
```sql
-- Copy/paste test_sfdc_tools.sql into Snowsight
```

## 🔍 Verification

### Check Integration
```sql
SHOW INTEGRATIONS LIKE 'salesforce_api_integration';
```

Expected output:
- `name`: salesforce_api_integration
- `type`: EXTERNAL_ACCESS
- `enabled`: true

### Check Network Rule
```sql
SHOW NETWORK RULES LIKE 'salesforce_api_network_rule';
```

Expected output:
- `name`: salesforce_api_network_rule
- `type`: HOST_PORT
- `mode`: EGRESS

### Check Secret
```sql
SHOW SECRETS LIKE 'salesforce_credentials';
```

Expected output:
- `name`: salesforce_credentials
- `secret_type`: GENERIC_STRING

### Check Functions
```sql
SHOW FUNCTIONS IN SCHEMA salesforce_tools;
```

Expected output: 11 functions

## ❌ Troubleshooting

### Error: "External network access not allowed"

**Cause:** UDF missing external access integration

**Fix:** Ensure UDF has:
```sql
EXTERNAL_ACCESS_INTEGRATIONS = (salesforce_api_integration)
```

### Error: "Network rule does not allow access to..."

**Cause:** Salesforce domain not in network rule

**Fix:** Add domain to network rule:
```sql
ALTER NETWORK RULE salesforce_api_network_rule
SET VALUE_LIST = (
    'login.salesforce.com:443',
    'your-custom-domain.salesforce.com:443',
    ...
);
```

### Error: "Integration does not exist"

**Cause:** External access integration not created

**Fix:** Run:
```sql
CREATE EXTERNAL ACCESS INTEGRATION salesforce_api_integration
  ALLOWED_NETWORK_RULES = (salesforce_api_network_rule)
  ALLOWED_AUTHENTICATION_SECRETS = (salesforce_credentials)
  ENABLED = TRUE;
```

### Error: "Insufficient privileges"

**Cause:** Missing RBAC permissions

**Fix:** Grant permissions:
```sql
GRANT USAGE ON INTEGRATION salesforce_api_integration TO ROLE your_role;
GRANT USAGE ON SCHEMA salesforce_tools TO ROLE your_role;
GRANT USAGE ON ALL FUNCTIONS IN SCHEMA salesforce_tools TO ROLE your_role;
```

## 📚 References

- [Snowflake External Access](https://docs.snowflake.com/en/developer-guide/external-network-access/external-network-access-overview)
- [Network Rules](https://docs.snowflake.com/en/sql-reference/sql/create-network-rule)
- [Secrets](https://docs.snowflake.com/en/sql-reference/sql/create-secret)
- [External Access Integrations](https://docs.snowflake.com/en/sql-reference/sql/create-external-access-integration)

## ✅ Summary

**What's Configured:**
- ✅ Network rule for Salesforce domains
- ✅ Secret for credentials (optional)
- ✅ External access integration
- ✅ All 11 UDFs with external access
- ✅ RBAC permissions

**Ready to Use:**
- ✅ Copy/paste `test_sfdc_tools.sql` into Snowsight
- ✅ Update credentials in the SQL variables
- ✅ Run tests
- ✅ All functions should work!

---

**The Salesforce Tools are now configured with proper external network access and RBAC!** 🎉

