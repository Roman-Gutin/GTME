-- ============================================================================
-- Salesforce Tools for Snowflake - UDF Setup (CATCO Database)
-- ============================================================================

-- USE ROLE ACCOUNTADMIN;  -- Using SERVICE_ROLE instead
USE DATABASE AGENTS_DEMO;
USE SCHEMA PUBLIC;

-- ============================================================================
-- STEP 1: Create External Access Integration for Salesforce API
-- ============================================================================

-- Create network rule for Salesforce API access
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

-- Create secrets for Salesforce credentials
CREATE OR REPLACE SECRET salesforce_username
  TYPE = GENERIC_STRING
  SECRET_STRING = 'romangutin860@agentforce.com';

CREATE OR REPLACE SECRET salesforce_password
  TYPE = GENERIC_STRING
  SECRET_STRING = 'FuckSFDC1!';

CREATE OR REPLACE SECRET salesforce_token
  TYPE = GENERIC_STRING
  SECRET_STRING = 'iLARVeZyoXUeJm4a5aPwvBZ9';

-- Create external access integration
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION salesforce_api_integration
  ALLOWED_NETWORK_RULES = (salesforce_api_network_rule)
  ALLOWED_AUTHENTICATION_SECRETS = (salesforce_username, salesforce_password, salesforce_token)
  ENABLED = TRUE;

-- ============================================================================
-- STEP 2: Create UDFs
-- ============================================================================

-- Query Records
CREATE OR REPLACE FUNCTION salesforce_query_records(soql STRING)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('simple-salesforce==1.12.5', 'requests')
IMPORTS = ('@AGENTS_DEMO.PUBLIC.SALESFORCE_STAGE/salesforce_tools/core.py')
HANDLER = 'query_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (salesforce_api_integration)
SECRETS = ('username' = salesforce_username, 'password' = salesforce_password, 'token' = salesforce_token)
AS
$$
import _snowflake
from core import SalesforceTools

def query_handler(soql):
    try:
        username = _snowflake.get_generic_secret_string('username')
        password = _snowflake.get_generic_secret_string('password')
        token = _snowflake.get_generic_secret_string('token')
        sf = SalesforceTools(username, password, token)
        results = sf.query_records(soql)
        return results
    except Exception as e:
        return {'error': str(e)}
$$;

-- Get Account
CREATE OR REPLACE FUNCTION salesforce_get_account(account_id STRING)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('simple-salesforce==1.12.5')
IMPORTS = ('@AGENTS_DEMO.PUBLIC.SALESFORCE_STAGE/salesforce_tools/core.py', '@AGENTS_DEMO.PUBLIC.SALESFORCE_STAGE/salesforce_tools/accounts.py')
HANDLER = 'get_account_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (salesforce_api_integration)
SECRETS = ('username' = salesforce_username, 'password' = salesforce_password, 'token' = salesforce_token)
AS
$$
import _snowflake
from accounts import AccountOperations

def get_account_handler(account_id):
    try:
        username = _snowflake.get_generic_secret_string('username')
        password = _snowflake.get_generic_secret_string('password')
        token = _snowflake.get_generic_secret_string('token')
        sf = AccountOperations(username, password, token)
        return sf.get_account(account_id)
    except Exception as e:
        return {'error': str(e)}
$$;

-- Get Pipeline Summary
CREATE OR REPLACE FUNCTION salesforce_get_pipeline_summary()
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('simple-salesforce==1.12.5')
IMPORTS = ('@AGENTS_DEMO.PUBLIC.SALESFORCE_STAGE/salesforce_tools/core.py', '@AGENTS_DEMO.PUBLIC.SALESFORCE_STAGE/salesforce_tools/opportunities.py')
HANDLER = 'get_pipeline_summary_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (salesforce_api_integration)
SECRETS = ('username' = salesforce_username, 'password' = salesforce_password, 'token' = salesforce_token)
AS
$$
import _snowflake
from opportunities import OpportunityOperations

def get_pipeline_summary_handler():
    try:
        username = _snowflake.get_generic_secret_string('username')
        password = _snowflake.get_generic_secret_string('password')
        token = _snowflake.get_generic_secret_string('token')
        sf = OpportunityOperations(username, password, token)
        return sf.get_pipeline_summary()
    except Exception as e:
        return {'error': str(e)}
$$;

-- ============================================================================
-- RBAC: Grant Permissions
-- ============================================================================

GRANT USAGE ON INTEGRATION salesforce_api_integration TO ROLE SERVICE_ROLE;
GRANT USAGE ON SCHEMA AGENTS_DEMO.PUBLIC TO ROLE PUBLIC;
GRANT USAGE ON ALL FUNCTIONS IN SCHEMA AGENTS_DEMO.PUBLIC TO ROLE PUBLIC;
GRANT READ ON SECRET salesforce_username TO ROLE SERVICE_ROLE;
GRANT READ ON SECRET salesforce_password TO ROLE SERVICE_ROLE;
GRANT READ ON SECRET salesforce_token TO ROLE SERVICE_ROLE;

-- ============================================================================
-- Verification
-- ============================================================================

SHOW INTEGRATIONS LIKE 'salesforce_api_integration';
SHOW NETWORK RULES LIKE 'salesforce_api_network_rule';
SHOW SECRETS LIKE 'salesforce_%';
SHOW FUNCTIONS IN SCHEMA AGENTS_DEMO.PUBLIC;

SELECT 'Salesforce Tools deployed successfully!' AS status;

