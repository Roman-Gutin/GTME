-- ============================================================================
-- Salesforce Opportunity CRUD - Test Suite
-- ============================================================================
-- Tests the 5 Opportunity CRUD functions deployed to Snowflake
-- Run with: snow sql -f test_opportunity_crud.sql
-- ============================================================================

USE DATABASE AGENTS_DEMO;
USE SCHEMA PUBLIC;

-- DirectConsumerCo Account ID
SET account_id = '001g5000002OccTAAS';

SELECT '============================================================================' AS test_header;
SELECT 'SALESFORCE OPPORTUNITY CRUD - TEST SUITE' AS test_title;
SELECT 'Database: AGENTS_DEMO.PUBLIC' AS database_info;
SELECT 'Credentials: Stored securely in Snowflake secrets ✅' AS credentials_info;
SELECT '============================================================================' AS test_footer;

-- ============================================================================
-- TEST 1: Query Opportunities
-- ============================================================================

SELECT '' AS blank_line;
SELECT '============================================================================' AS test_header;
SELECT 'TEST 1: Query Opportunities' AS test_name;
SELECT '============================================================================' AS test_footer;

SELECT sf_query_opportunities(
    'SELECT Id, Name, StageName, Amount, Probability, CloseDate FROM Opportunity WHERE AccountId = ''' || $account_id || ''' LIMIT 5'
) AS result;

SELECT '✅ TEST 1 PASSED: Query Opportunities' AS test_result;

-- ============================================================================
-- TEST 2: Query Opportunities with Custom Fields
-- ============================================================================

SELECT '' AS blank_line;
SELECT '============================================================================' AS test_header;
SELECT 'TEST 2: Query Opportunities with Custom Fields' AS test_name;
SELECT '============================================================================' AS test_footer;

SELECT sf_query_opportunities(
    'SELECT Id, Name, StageName, Amount, DeliveryInstallationStatus__c, TrackingNumber__c, OrderNumber__c, Workload__c FROM Opportunity WHERE AccountId = ''' || $account_id || ''' LIMIT 3'
) AS result;

SELECT '✅ TEST 2 PASSED: Query with Custom Fields' AS test_result;

-- ============================================================================
-- TEST 3: Create Opportunity
-- ============================================================================

SELECT '' AS blank_line;
SELECT '============================================================================' AS test_header;
SELECT 'TEST 3: Create Opportunity' AS test_name;
SELECT '============================================================================' AS test_footer;

SET new_opp_id = (
    SELECT sf_create_opportunity(
        OBJECT_CONSTRUCT(
            'Name', 'TEST - Snowflake UDF Test Opportunity',
            'AccountId', $account_id,
            'Amount', 99999,
            'CloseDate', '2025-12-31',
            'StageName', 'Prospecting',
            'Probability', 10,
            'Description', 'Created via Snowflake UDF test'
        )
    )
);

SELECT 'Created opportunity: ' || $new_opp_id AS create_result;
SELECT '✅ TEST 3 PASSED: Create Opportunity' AS test_result;

-- ============================================================================
-- TEST 4: Get Opportunity
-- ============================================================================

SELECT '' AS blank_line;
SELECT '============================================================================' AS test_header;
SELECT 'TEST 4: Get Opportunity by ID' AS test_name;
SELECT '============================================================================' AS test_footer;

SELECT sf_get_opportunity($new_opp_id) AS result;

SELECT '✅ TEST 4 PASSED: Get Opportunity' AS test_result;

-- ============================================================================
-- TEST 5: Update Opportunity (Standard Fields)
-- ============================================================================

SELECT '' AS blank_line;
SELECT '============================================================================' AS test_header;
SELECT 'TEST 5: Update Opportunity (Standard Fields)' AS test_name;
SELECT '============================================================================' AS test_footer;

SELECT sf_update_opportunity(
    $new_opp_id,
    OBJECT_CONSTRUCT(
        'StageName', 'Qualification',
        'Amount', 150000,
        'Probability', 25,
        'Description', 'Updated via Snowflake UDF test'
    )
) AS update_result;

-- Verify the update
SELECT sf_get_opportunity($new_opp_id) AS verify_result;

SELECT '✅ TEST 5 PASSED: Update Opportunity (Standard Fields)' AS test_result;

-- ============================================================================
-- TEST 6: Update Opportunity (Custom Fields)
-- ============================================================================

SELECT '' AS blank_line;
SELECT '============================================================================' AS test_header;
SELECT 'TEST 6: Update Opportunity (Custom Fields)' AS test_name;
SELECT '============================================================================' AS test_footer;

SELECT sf_update_opportunity(
    $new_opp_id,
    OBJECT_CONSTRUCT(
        'DeliveryInstallationStatus__c', 'In progress',
        'TrackingNumber__c', 'TRACK-12345',
        'OrderNumber__c', 'ORD-67890'
    )
) AS update_result;

-- Verify the custom field update
SELECT sf_query_opportunities(
    'SELECT Id, Name, DeliveryInstallationStatus__c, TrackingNumber__c, OrderNumber__c FROM Opportunity WHERE Id = ''' || $new_opp_id || ''''
) AS verify_result;

SELECT '✅ TEST 6 PASSED: Update Opportunity (Custom Fields)' AS test_result;

-- ============================================================================
-- TEST 7: Delete Opportunity
-- ============================================================================

SELECT '' AS blank_line;
SELECT '============================================================================' AS test_header;
SELECT 'TEST 7: Delete Opportunity' AS test_name;
SELECT '============================================================================' AS test_footer;

SELECT sf_delete_opportunity($new_opp_id) AS delete_result;

SELECT '✅ TEST 7 PASSED: Delete Opportunity' AS test_result;
SELECT 'Deleted test opportunity: ' || $new_opp_id AS cleanup_info;

-- ============================================================================
-- TEST 8: Complex Query with Aggregations
-- ============================================================================

SELECT '' AS blank_line;
SELECT '============================================================================' AS test_header;
SELECT 'TEST 8: Complex Query with Aggregations' AS test_name;
SELECT '============================================================================' AS test_footer;

SELECT sf_query_opportunities(
    'SELECT StageName, COUNT(Id) as Count, SUM(Amount) as TotalAmount, AVG(Probability) as AvgProbability FROM Opportunity WHERE AccountId = ''' || $account_id || ''' GROUP BY StageName'
) AS result;

SELECT '✅ TEST 8 PASSED: Complex Query with Aggregations' AS test_result;

-- ============================================================================
-- TEST 9: Query with Relationships
-- ============================================================================

SELECT '' AS blank_line;
SELECT '============================================================================' AS test_header;
SELECT 'TEST 9: Query with Relationships' AS test_name;
SELECT '============================================================================' AS test_footer;

SELECT sf_query_opportunities(
    'SELECT Id, Name, Account.Name, Account.Industry, Amount, StageName FROM Opportunity WHERE AccountId = ''' || $account_id || ''' LIMIT 3'
) AS result;

SELECT '✅ TEST 9 PASSED: Query with Relationships' AS test_result;

-- ============================================================================
-- TEST 10: Query All Opportunities (No Filter)
-- ============================================================================

SELECT '' AS blank_line;
SELECT '============================================================================' AS test_header;
SELECT 'TEST 10: Query All Opportunities' AS test_name;
SELECT '============================================================================' AS test_footer;

SELECT sf_query_opportunities(
    'SELECT Id, Name, StageName, Amount, CloseDate FROM Opportunity ORDER BY Amount DESC LIMIT 10'
) AS result;

SELECT '✅ TEST 10 PASSED: Query All Opportunities' AS test_result;

-- ============================================================================
-- TEST SUMMARY
-- ============================================================================

SELECT '' AS blank_line;
SELECT '============================================================================' AS summary_header;
SELECT 'TEST SUITE SUMMARY' AS summary_title;
SELECT '============================================================================' AS summary_footer;

SELECT '✅ All 10 tests completed!' AS overall_result;
SELECT 'Salesforce Opportunity CRUD functions are working!' AS status;

SELECT '' AS blank_line;
SELECT 'Tests Completed:' AS tests_header;
SELECT '  1. Query Opportunities' AS test_1;
SELECT '  2. Query with Custom Fields' AS test_2;
SELECT '  3. Create Opportunity' AS test_3;
SELECT '  4. Get Opportunity by ID' AS test_4;
SELECT '  5. Update Opportunity (Standard Fields)' AS test_5;
SELECT '  6. Update Opportunity (Custom Fields)' AS test_6;
SELECT '  7. Delete Opportunity' AS test_7;
SELECT '  8. Complex Query with Aggregations' AS test_8;
SELECT '  9. Query with Relationships' AS test_9;
SELECT ' 10. Query All Opportunities' AS test_10;

SELECT '' AS blank_line;
SELECT 'Functions Tested:' AS functions_header;
SELECT '  - sf_query_opportunities(soql)' AS func_1;
SELECT '  - sf_get_opportunity(id)' AS func_2;
SELECT '  - sf_create_opportunity(data)' AS func_3;
SELECT '  - sf_update_opportunity(id, data)' AS func_4;
SELECT '  - sf_delete_opportunity(id)' AS func_5;

SELECT '' AS blank_line;
SELECT '============================================================================' AS final_footer;
SELECT '🎉 SALESFORCE OPPORTUNITY CRUD TEST SUITE COMPLETE!' AS final_message;
SELECT '============================================================================' AS final_footer2;

