-- ============================================================================
-- TEST DEPLOYMENT - Verify all Google Workspace tools are registered
-- ============================================================================
-- Run this after deployment to verify everything is set up correctly
-- Expected: 22 UDFs (5 Docs, 6 Sheets, 11 Drive)
-- ============================================================================

USE ROLE AGENTS_SERVICE_ROLE;
USE WAREHOUSE AGENTS_DEMO_WH;
USE DATABASE AGENTS_DEMO;
USE SCHEMA PUBLIC;

-- ============================================================================
-- 1. Check Stage and Files
-- ============================================================================
SELECT '=== STAGE CHECK ===' AS test_section;

SHOW STAGES LIKE 'GSUITE_STAGE';

LIST @AGENTS_DEMO.PUBLIC.GSUITE_STAGE/gsuite_tools/;

-- Expected files:
-- - __init__.py
-- - gdocs_handler.py
-- - gsheets_handler.py
-- - gdrive_handler.py

-- ============================================================================
-- 2. Check External Access Integration
-- ============================================================================
SELECT '=== EXTERNAL ACCESS CHECK ===' AS test_section;

SHOW INTEGRATIONS LIKE 'google_workspace_integration';

SHOW NETWORK RULES LIKE 'google_apis_network_rule';

-- ============================================================================
-- 3. Check OAuth Secret
-- ============================================================================
SELECT '=== OAUTH SECRET CHECK ===' AS test_section;

SHOW SECRETS LIKE 'google_oauth_secret';

SHOW SECURITY INTEGRATIONS LIKE 'google_workspace_oauth';

-- ============================================================================
-- 4. Check All UDFs
-- ============================================================================
SELECT '=== UDF CHECK ===' AS test_section;

-- List all Google Workspace UDFs
SHOW FUNCTIONS LIKE '%GOOGLE%' IN SCHEMA AGENTS_DEMO.PUBLIC;

-- Count UDFs by category
SELECT 
    '=== UDF COUNT BY CATEGORY ===' AS test_section,
    SUM(CASE WHEN "name" LIKE '%_DOC%' THEN 1 ELSE 0 END) AS docs_functions,
    SUM(CASE WHEN "name" LIKE '%_SHEET%' THEN 1 ELSE 0 END) AS sheets_functions,
    SUM(CASE WHEN "name" LIKE '%DRIVE%' OR "name" LIKE '%FILE%' OR "name" LIKE '%FOLDER%' OR "name" LIKE '%PERMISSION%' THEN 1 ELSE 0 END) AS drive_functions,
    COUNT(*) AS total_functions
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- ============================================================================
-- 5. Detailed UDF List
-- ============================================================================
SELECT '=== DETAILED UDF LIST ===' AS test_section;

-- Google Docs Functions (Expected: 5)
SELECT 'GOOGLE DOCS FUNCTIONS' AS category, "name", "arguments" 
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID(-2)))
WHERE "name" LIKE '%_DOC%'
ORDER BY "name";

-- Google Sheets Functions (Expected: 6)
SELECT 'GOOGLE SHEETS FUNCTIONS' AS category, "name", "arguments"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID(-3)))
WHERE "name" LIKE '%_SHEET%'
ORDER BY "name";

-- Google Drive Functions (Expected: 11)
SELECT 'GOOGLE DRIVE FUNCTIONS' AS category, "name", "arguments"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID(-4)))
WHERE "name" LIKE '%DRIVE%' OR "name" LIKE '%FILE%' OR "name" LIKE '%FOLDER%' OR "name" LIKE '%PERMISSION%'
ORDER BY "name";

-- ============================================================================
-- 6. Check Agent
-- ============================================================================
SELECT '=== AGENT CHECK ===' AS test_section;

-- Check if agent exists in snowflake_intelligence schema
USE SCHEMA snowflake_intelligence.agents;
SHOW CORTEX SEARCH SERVICES;  -- This will show agents in Snowsight

-- ============================================================================
-- 7. Test a Simple Function (Optional - requires OAuth to be working)
-- ============================================================================
SELECT '=== FUNCTION TEST (OPTIONAL) ===' AS test_section;

-- Uncomment to test creating a Google Doc
-- This will only work if OAuth is properly configured
-- SELECT AGENTS_DEMO.PUBLIC.CREATE_GOOGLE_DOC('Test Document - Deployment Verification');

-- ============================================================================
-- EXPECTED RESULTS SUMMARY
-- ============================================================================
-- Stage: GSUITE_STAGE with 4 Python files
-- Network Rule: google_apis_network_rule
-- External Access Integration: google_workspace_integration
-- Security Integration: google_workspace_oauth
-- Secret: google_oauth_secret
-- UDFs: 22 total (5 Docs, 6 Sheets, 11 Drive)
-- Agent: GTM_ENGINEER_AGENT in snowflake_intelligence.agents
-- ============================================================================

SELECT '=== TEST COMPLETE ===' AS test_section;
SELECT 'If all checks passed, deployment is successful!' AS status;
SELECT 'Next: Test the agent in Snowsight UI' AS next_step;
SELECT 'Go to: AI & ML → Cortex → Agents → GTM_ENGINEER_AGENT' AS location;

