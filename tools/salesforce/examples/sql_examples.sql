-- ============================================================================
-- Salesforce Tools - SQL Usage Examples
-- ============================================================================
-- Run with: snowsql -c default -f sql_examples.sql
-- ============================================================================

USE SCHEMA salesforce_tools;

-- Set credentials (replace with your actual credentials)
SET sf_username = 'your-username@salesforce.com';
SET sf_password = 'your-password';
SET sf_token = 'your-security-token';

-- ============================================================================
-- EXAMPLE 1: Query Accounts
-- ============================================================================

SELECT 'EXAMPLE 1: Query Accounts' AS example;

SELECT salesforce_query_records(
    'SELECT Id, Name, Industry, BillingCity FROM Account LIMIT 10',
    $sf_username,
    $sf_password,
    $sf_token
) AS accounts;

-- ============================================================================
-- EXAMPLE 2: Get Account Details
-- ============================================================================

SELECT 'EXAMPLE 2: Get Account Details' AS example;

-- Replace with actual account ID
SET account_id = '001g5000002OccTAAS';

SELECT salesforce_get_account(
    $account_id,
    $sf_username,
    $sf_password,
    $sf_token
) AS account_details;

-- ============================================================================
-- EXAMPLE 3: Get Account Summary (with opportunities and contacts)
-- ============================================================================

SELECT 'EXAMPLE 3: Get Account Summary' AS example;

SELECT salesforce_get_account_summary(
    $account_id,
    $sf_username,
    $sf_password,
    $sf_token
) AS account_summary;

-- ============================================================================
-- EXAMPLE 4: Create Opportunity
-- ============================================================================

SELECT 'EXAMPLE 4: Create Opportunity' AS example;

SELECT salesforce_create_opportunity(
    OBJECT_CONSTRUCT(
        'Name', 'Q4 2025 - Test Deal',
        'AccountId', $account_id,
        'Amount', 100000,
        'CloseDate', '2025-12-31',
        'StageName', 'Prospecting'
    ),
    $sf_username,
    $sf_password,
    $sf_token
) AS new_opportunity_id;

-- ============================================================================
-- EXAMPLE 5: Update Opportunity
-- ============================================================================

SELECT 'EXAMPLE 5: Update Opportunity' AS example;

-- Replace with actual opportunity ID
SET opportunity_id = '006xxx';

SELECT salesforce_update_opportunity(
    $opportunity_id,
    OBJECT_CONSTRUCT(
        'StageName', 'Qualification',
        'Amount', 150000
    ),
    $sf_username,
    $sf_password,
    $sf_token
) AS update_success;

-- ============================================================================
-- EXAMPLE 6: Get Pipeline Summary
-- ============================================================================

SELECT 'EXAMPLE 6: Get Pipeline Summary' AS example;

SELECT salesforce_get_pipeline_summary(
    $sf_username,
    $sf_password,
    $sf_token
) AS pipeline_summary;

-- ============================================================================
-- EXAMPLE 7: List All Objects
-- ============================================================================

SELECT 'EXAMPLE 7: List All Objects' AS example;

SELECT salesforce_list_objects(
    $sf_username,
    $sf_password,
    $sf_token
) AS all_objects;

-- ============================================================================
-- EXAMPLE 8: Get Object Summary
-- ============================================================================

SELECT 'EXAMPLE 8: Get Object Summary' AS example;

SELECT salesforce_get_object_summary(
    'Opportunity',
    $sf_username,
    $sf_password,
    $sf_token
) AS opportunity_metadata;

-- ============================================================================
-- EXAMPLE 9: Sync Salesforce Data to Snowflake Table
-- ============================================================================

SELECT 'EXAMPLE 9: Sync Salesforce Data to Snowflake' AS example;

-- Create table from Salesforce query
CREATE OR REPLACE TABLE salesforce_accounts AS
SELECT 
    value:Id::STRING AS account_id,
    value:Name::STRING AS account_name,
    value:Industry::STRING AS industry,
    value:BillingCity::STRING AS city,
    value:BillingState::STRING AS state
FROM TABLE(FLATTEN(
    salesforce_query_records(
        'SELECT Id, Name, Industry, BillingCity, BillingState FROM Account WHERE Type = ''Customer''',
        $sf_username,
        $sf_password,
        $sf_token
    )
));

SELECT * FROM salesforce_accounts LIMIT 10;

-- ============================================================================
-- EXAMPLE 10: Join Snowflake Data with Salesforce
-- ============================================================================

SELECT 'EXAMPLE 10: Join Snowflake Data with Salesforce' AS example;

-- Enrich Snowflake data with live Salesforce data
SELECT 
    sa.account_name,
    sa.industry,
    sf_live.value:AnnualRevenue::NUMBER AS annual_revenue,
    sf_live.value:NumberOfEmployees::NUMBER AS employees
FROM salesforce_accounts sa
CROSS JOIN LATERAL (
    SELECT salesforce_get_account(
        sa.account_id,
        $sf_username,
        $sf_password,
        $sf_token
    ) AS value
) sf_live
LIMIT 5;

-- ============================================================================
-- Done!
-- ============================================================================

SELECT '✅ All examples completed!' AS status;

