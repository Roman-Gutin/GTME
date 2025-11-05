-- ============================================================================
-- GTME - Snowflake Infrastructure Setup
-- ============================================================================
-- Run this script as ACCOUNTADMIN to set up the Snowflake infrastructure
-- for the GTME Cortex AI Agent
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ----------------------------------------------------------------------------
-- 1. Create Service User
-- ----------------------------------------------------------------------------
CREATE USER IF NOT EXISTS AGENT_SERVICE_USER
  TYPE = SERVICE
  COMMENT = 'Service user for GTME Cortex AI Agent';

-- ----------------------------------------------------------------------------
-- 2. Create Service Role
-- ----------------------------------------------------------------------------
CREATE ROLE IF NOT EXISTS AGENTS_SERVICE_ROLE
  COMMENT = 'Role for managing GTME Cortex AI Agents';

GRANT ROLE AGENTS_SERVICE_ROLE TO USER AGENT_SERVICE_USER;

-- ----------------------------------------------------------------------------
-- 3. Create Network Policy (required for service users to use PAT)
-- ----------------------------------------------------------------------------
CREATE NETWORK RULE IF NOT EXISTS allow_all_ips
  TYPE = IPV4
  VALUE_LIST = ('0.0.0.0/0')
  MODE = INGRESS;

CREATE NETWORK POLICY IF NOT EXISTS agent_service_network_policy
  ALLOWED_NETWORK_RULE_LIST = ('allow_all_ips');

ALTER USER AGENT_SERVICE_USER SET NETWORK_POLICY = agent_service_network_policy;

-- ----------------------------------------------------------------------------
-- 4. Create Personal Access Token
-- ----------------------------------------------------------------------------
-- Note: Copy the token output and add to .env as SNOWFLAKE_PAT
ALTER USER AGENT_SERVICE_USER ADD PROGRAMMATIC ACCESS TOKEN agent_pat;

-- ----------------------------------------------------------------------------
-- 5. Create Database and Warehouse
-- ----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS AGENTS_DEMO
  COMMENT = 'Database for GTME agent functions and tools';

CREATE WAREHOUSE IF NOT EXISTS AGENTS_DEMO_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  COMMENT = 'Warehouse for GTME agent tool execution';

-- ----------------------------------------------------------------------------
-- 6. Grant Privileges to Service Role
-- ----------------------------------------------------------------------------
GRANT USAGE ON DATABASE AGENTS_DEMO TO ROLE AGENTS_SERVICE_ROLE;
GRANT USAGE ON SCHEMA AGENTS_DEMO.PUBLIC TO ROLE AGENTS_SERVICE_ROLE;
GRANT CREATE FUNCTION ON SCHEMA AGENTS_DEMO.PUBLIC TO ROLE AGENTS_SERVICE_ROLE;
GRANT CREATE STAGE ON SCHEMA AGENTS_DEMO.PUBLIC TO ROLE AGENTS_SERVICE_ROLE;
GRANT CREATE SECRET ON SCHEMA AGENTS_DEMO.PUBLIC TO ROLE AGENTS_SERVICE_ROLE;
GRANT USAGE ON WAREHOUSE AGENTS_DEMO_WH TO ROLE AGENTS_SERVICE_ROLE;
GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE AGENTS_SERVICE_ROLE;

-- ----------------------------------------------------------------------------
-- 7. Create snowflake_intelligence Database (for Snowsight visibility)
-- ----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS snowflake_intelligence
  COMMENT = 'Database for Snowflake intelligence features';

CREATE SCHEMA IF NOT EXISTS snowflake_intelligence.agents
  COMMENT = 'Schema for Cortex AI Agents (visible in Snowsight)';

-- Grant to PUBLIC for visibility
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE PUBLIC;

-- Grant to service role for agent creation
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE AGENTS_SERVICE_ROLE;
GRANT USAGE, CREATE AGENT ON SCHEMA snowflake_intelligence.agents TO ROLE AGENTS_SERVICE_ROLE;

-- ----------------------------------------------------------------------------
-- 8. Grant to Your User (replace YOUR_USERNAME with your Snowflake username)
-- ----------------------------------------------------------------------------
-- This allows you to view the agent in Snowsight
GRANT USAGE ON DATABASE snowflake_intelligence TO USER YOUR_USERNAME;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO USER YOUR_USERNAME;

-- ============================================================================
-- Setup Complete!
-- ============================================================================
-- Next Steps:
-- 1. Copy the PAT token from step 4 output to your .env file
-- 2. Replace YOUR_USERNAME in step 8 with your actual Snowflake username
-- 3. Run: snow sql -f deployment/setup_snowflake.sql
-- ============================================================================

