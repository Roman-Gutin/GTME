# Snowflake Cortex Agent Integration Guide

This guide explains how to deploy Salesforce wrapper functions as Snowflake Cortex Agent tools.

## 📋 Prerequisites

1. Snowflake account with Cortex AI enabled
2. Salesforce Developer Edition org with Connected App
3. Snow CLI installed: `pip install snowflake-cli-labs`
4. Network access from Snowflake to Salesforce APIs

## 🚀 Deployment Steps

### Step 1: Create Snowflake Stage

```sql
-- Create stage for Python files
CREATE OR REPLACE STAGE TEST.PUBLIC.SALESFORCE_STAGE
    COMMENT = 'Stage for Salesforce Python wrapper modules';

-- Verify stage
LIST @TEST.PUBLIC.SALESFORCE_STAGE;
```

### Step 2: Upload Python Files

```bash
# Navigate to salesforce directory
cd dev/tools/salesforce

# Upload all Python modules
snow stage copy salesforce_wrapper/__init__.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false
snow stage copy salesforce_wrapper/auth.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false
snow stage copy salesforce_wrapper/data_api.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false
snow stage copy salesforce_wrapper/metadata_api.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false
snow stage copy salesforce_wrapper/discovery.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false
snow stage copy salesforce_wrapper/shortcuts.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false
snow stage copy salesforce_wrapper/field_creators.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false
snow stage copy salesforce_wrapper/sf_handler.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false
snow stage copy salesforce_wrapper/utils.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false
snow stage copy salesforce_wrapper/constants.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false
snow stage copy salesforce_wrapper/exceptions.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false

# Verify upload
snow stage list @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/
```

### Step 3: Create Network Rules and External Access Integration

```sql
-- Create network rule for Salesforce
-- IMPORTANT: Add your specific Salesforce instance URL to VALUE_LIST
CREATE OR REPLACE NETWORK RULE salesforce_network_rule
    MODE = EGRESS
    TYPE = HOST_PORT
    VALUE_LIST = (
        'login.salesforce.com:443',
        'your-instance.salesforce.com:443'  -- Replace with your instance
    )
    COMMENT = 'Allow access to Salesforce APIs';

-- Create external access integration
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION salesforce_integration
    ALLOWED_NETWORK_RULES = (salesforce_network_rule)
    ENABLED = TRUE
    COMMENT = 'External access for Salesforce API calls';

-- Grant usage
GRANT USAGE ON INTEGRATION salesforce_integration TO ROLE ACCOUNTADMIN;
```

### Step 4: Create Secret for Salesforce Credentials

```sql
-- Create secret with Salesforce credentials
-- IMPORTANT: Replace with your actual Salesforce credentials
CREATE OR REPLACE SECRET TEST.PUBLIC.salesforce_secret
    TYPE = GENERIC_STRING
    SECRET_STRING = '{
        "username": "your-username@example.com",
        "password": "your-password-with-security-token",
        "client_id": "your-connected-app-client-id",
        "client_secret": "your-connected-app-client-secret",
        "instance_url": "https://login.salesforce.com"
    }'
    COMMENT = 'Salesforce OAuth credentials';
```

### Step 5: Create UDF Functions

#### Example 1: Discover Org

```sql
CREATE OR REPLACE FUNCTION TEST.PUBLIC.SALESFORCE_DISCOVER_ORG()
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('simple-salesforce==1.12.5', 'requests')
HANDLER = 'discover_org_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (salesforce_integration)
SECRETS = ('cred' = salesforce_secret)
IMPORTS = (
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/__init__.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/auth.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/data_api.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/metadata_api.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/discovery.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/shortcuts.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/field_creators.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/sf_handler.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/utils.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/constants.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/exceptions.py'
)
AS $$
import _snowflake
import json
from sf_handler import SalesforceHandler

def discover_org_handler():
    # Get credentials from secret
    cred_json = _snowflake.get_generic_secret_string('cred')
    cred = json.loads(cred_json)
    
    # Initialize handler
    handler = SalesforceHandler(
        username=cred['username'],
        password=cred['password'],
        client_id=cred['client_id'],
        client_secret=cred['client_secret'],
        instance_url=cred['instance_url']
    )
    
    # Discover org
    return handler.discover_org()
$$;
```

#### Example 2: List All Objects

```sql
CREATE OR REPLACE FUNCTION TEST.PUBLIC.SALESFORCE_LIST_OBJECTS()
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('simple-salesforce==1.12.5', 'requests')
HANDLER = 'list_objects_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (salesforce_integration)
SECRETS = ('cred' = salesforce_secret)
IMPORTS = (
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/__init__.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/auth.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/data_api.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/metadata_api.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/discovery.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/shortcuts.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/field_creators.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/sf_handler.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/utils.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/constants.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/exceptions.py'
)
AS $$
import _snowflake
import json
from sf_handler import SalesforceHandler

def list_objects_handler():
    cred_json = _snowflake.get_generic_secret_string('cred')
    cred = json.loads(cred_json)
    
    handler = SalesforceHandler(
        username=cred['username'],
        password=cred['password'],
        client_id=cred['client_id'],
        client_secret=cred['client_secret'],
        instance_url=cred['instance_url']
    )
    
    return handler.list_all_objects()
$$;
```

## 📝 Function Template

Use this template to create additional functions:

```sql
CREATE OR REPLACE FUNCTION TEST.PUBLIC.SALESFORCE_<FUNCTION_NAME>(<PARAMETERS>)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('simple-salesforce==1.12.5', 'requests')
HANDLER = '<handler_name>'
EXTERNAL_ACCESS_INTEGRATIONS = (salesforce_integration)
SECRETS = ('cred' = salesforce_secret)
IMPORTS = (
    -- All salesforce_wrapper modules
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/__init__.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/auth.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/data_api.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/metadata_api.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/discovery.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/shortcuts.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/field_creators.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/sf_handler.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/utils.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/constants.py',
    '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/exceptions.py'
)
AS $$
import _snowflake
import json
from sf_handler import SalesforceHandler

def <handler_name>(<parameters>):
    cred_json = _snowflake.get_generic_secret_string('cred')
    cred = json.loads(cred_json)
    
    handler = SalesforceHandler(**cred)
    
    # Call appropriate handler method
    return handler.<method_name>(<arguments>)
$$;
```

## 🧪 Testing Functions

```sql
-- Test discover org
SELECT TEST.PUBLIC.SALESFORCE_DISCOVER_ORG();

-- Test list objects
SELECT TEST.PUBLIC.SALESFORCE_LIST_OBJECTS();
```

## 📚 Next Steps

See `snowflake_functions_complete.sql` for all 40+ function definitions ready to deploy.

