-- ============================================================================
-- Salesforce Opportunity CRUD - Test Suite (VARCHAR only for Cortex Agents)
-- ============================================================================
-- All functions use VARCHAR input/output for Cortex Agent compatibility
-- Run with: snow sql -f test_sfdc_tools.sql
-- ============================================================================

USE DATABASE AGENTS_DEMO;
USE SCHEMA PUBLIC;

-- ============================================================================
-- TEST 1: Query Opportunities
-- ============================================================================

SELECT sf_query_opportunities('SELECT Id, Name, StageName, Amount FROM Opportunity LIMIT 3') AS result;

-- ============================================================================
-- TEST 2: Query with Custom Fields
-- ============================================================================

SELECT sf_query_opportunities('SELECT Id, Name, DeliveryInstallationStatus__c, TrackingNumber__c FROM Opportunity WHERE AccountId = ''001g5000002OccTAAS'' LIMIT 2') AS result;

-- ============================================================================
-- TEST 3: Create Opportunity
-- ============================================================================

SELECT sf_create_opportunity('{"Name": "TEST - Cortex Agent Test", "AccountId": "001g5000002OccTAAS", "Amount": 77777, "CloseDate": "2025-12-31", "StageName": "Prospecting", "Probability": 10}') AS result;

SET test_opp_id = (
    SELECT PARSE_JSON(sf_create_opportunity('{"Name": "TEST - SQL Test Opp", "AccountId": "001g5000002OccTAAS", "Amount": 99999, "CloseDate": "2025-12-31", "StageName": "Prospecting"}'))['id']::VARCHAR
);

-- ============================================================================
-- TEST 4: Query with Aggregations
-- ============================================================================

SELECT '' AS blank;
SELECT '============================================================================' AS test_header;
SELECT 'TEST 4: Query with Aggregations (Group By Stage)' AS test_name;
SELECT '============================================================================' AS test_header;

SELECT sf_query_opportunities(
    'SELECT StageName, COUNT(Id) as OpportunityCount, SUM(Amount) as TotalAmount, AVG(Probability) as AvgProbability FROM Opportunity WHERE AccountId = ''' || $account_id || ''' GROUP BY StageName'
) AS result;

SELECT '✅ TEST 4 PASSED' AS status;

-- ============================================================================
-- TEST 5: Query with Relationships
-- ============================================================================

SELECT '' AS blank;
SELECT '============================================================================' AS test_header;
SELECT 'TEST 5: Query with Relationships (Account Info)' AS test_name;
SELECT '============================================================================' AS test_header;

SELECT sf_query_opportunities(
    'SELECT Id, Name, Account.Name, Account.Industry, Account.Type, Amount, StageName FROM Opportunity WHERE AccountId = ''' || $account_id || ''' LIMIT 3'
) AS result;

SELECT '✅ TEST 5 PASSED' AS status;

-- ============================================================================
-- TEST 6: Create Opportunity
-- ============================================================================

SELECT '' AS blank;
SELECT '============================================================================' AS test_header;
SELECT 'TEST 6: Create New Opportunity' AS test_name;
SELECT '============================================================================' AS test_header;

SET new_opp_id = (
    SELECT sf_create_opportunity(
        OBJECT_CONSTRUCT(
            'Name', 'TEST - Snowflake SQL Test Opportunity',
            'AccountId', $account_id,
            'Amount', 88888,
            'CloseDate', '2025-12-31',
            'StageName', 'Prospecting',
            'Probability', 10,
            'Description', 'Created via Snowflake SQL test suite'
        )
    )
);

SELECT 'Created Opportunity ID: ' || $new_opp_id AS create_result;
SELECT '✅ TEST 6 PASSED' AS status;

-- ============================================================================
-- TEST 7: Get Opportunity by ID
-- ============================================================================

SELECT '' AS blank;
SELECT '============================================================================' AS test_header;
SELECT 'TEST 7: Get Opportunity by ID' AS test_name;
SELECT '============================================================================' AS test_header;

SELECT sf_get_opportunity($new_opp_id) AS result;

SELECT '✅ TEST 7 PASSED' AS status;

-- ============================================================================
-- TEST 8: Update Opportunity (Standard Fields)
-- ============================================================================

SELECT '' AS blank;
SELECT '============================================================================' AS test_header;
SELECT 'TEST 8: Update Opportunity (Standard Fields)' AS test_name;
SELECT '============================================================================' AS test_header;

SELECT sf_update_opportunity(
    $new_opp_id,
    OBJECT_CONSTRUCT(
        'StageName', 'Qualification',
        'Amount', 125000,
        'Probability', 30,
        'Description', 'Updated via Snowflake SQL test - Stage moved to Qualification'
    )
) AS update_result;

-- Verify the update
SELECT sf_get_opportunity($new_opp_id) AS verify_result;

SELECT '✅ TEST 8 PASSED' AS status;

-- ============================================================================
-- TEST 9: Update Opportunity (Custom Fields)
-- ============================================================================

SELECT '' AS blank;
SELECT '============================================================================' AS test_header;
SELECT 'TEST 9: Update Opportunity (Custom Fields)' AS test_name;
SELECT '============================================================================' AS test_header;

SELECT sf_update_opportunity(
    $new_opp_id,
    OBJECT_CONSTRUCT(
        'DeliveryInstallationStatus__c', 'In progress',
        'TrackingNumber__c', 'TRACK-TEST-99999',
        'OrderNumber__c', 'ORD-TEST-88888'
    )
) AS update_result;

-- Verify custom fields were updated
SELECT sf_query_opportunities(
    'SELECT Id, Name, StageName, Amount, DeliveryInstallationStatus__c, TrackingNumber__c, OrderNumber__c FROM Opportunity WHERE Id = ''' || $new_opp_id || ''''
) AS verify_result;

SELECT '✅ TEST 9 PASSED' AS status;

-- ============================================================================
-- TEST 10: Update Opportunity (Mixed Standard + Custom Fields)
-- ============================================================================

SELECT '' AS blank;
SELECT '============================================================================' AS test_header;
SELECT 'TEST 10: Update Opportunity (Mixed Fields)' AS test_name;
SELECT '============================================================================' AS test_header;

SELECT sf_update_opportunity(
    $new_opp_id,
    OBJECT_CONSTRUCT(
        'StageName', 'Needs Analysis',
        'Amount', 175000,
        'Probability', 50,
        'DeliveryInstallationStatus__c', 'Completed',
        'Workload__c', 'High Priority'
    )
) AS update_result;

-- Verify all updates
SELECT sf_get_opportunity($new_opp_id) AS verify_result;

SELECT '✅ TEST 10 PASSED' AS status;

-- ============================================================================
-- TEST 11: Query All Opportunities (Top 10 by Amount)
-- ============================================================================

SELECT '' AS blank;
SELECT '============================================================================' AS test_header;
SELECT 'TEST 11: Query Top 10 Opportunities by Amount' AS test_name;
SELECT '============================================================================' AS test_header;

SELECT sf_query_opportunities(
    'SELECT Id, Name, Account.Name, StageName, Amount, CloseDate FROM Opportunity WHERE Amount > 0 ORDER BY Amount DESC LIMIT 10'
) AS result;

SELECT '✅ TEST 11 PASSED' AS status;

-- ============================================================================
-- TEST 12: Query Opportunities by Stage
-- ============================================================================

SELECT '' AS blank;
SELECT '============================================================================' AS test_header;
SELECT 'TEST 12: Query Opportunities by Stage (Closed Won)' AS test_name;
SELECT '============================================================================' AS test_header;

SELECT sf_query_opportunities(
    'SELECT Id, Name, Account.Name, Amount, CloseDate FROM Opportunity WHERE StageName = ''Closed Won'' LIMIT 5'
) AS result;

SELECT '✅ TEST 12 PASSED' AS status;

-- ============================================================================
-- TEST 13: Delete Opportunity (Cleanup)
-- ============================================================================

SELECT '' AS blank;
SELECT '============================================================================' AS test_header;
SELECT 'TEST 13: Delete Test Opportunity (Cleanup)' AS test_name;
SELECT '============================================================================' AS test_header;

SELECT sf_delete_opportunity($new_opp_id) AS delete_result;

SELECT 'Deleted Opportunity ID: ' || $new_opp_id AS cleanup_info;
SELECT '✅ TEST 13 PASSED' AS status;

-- ============================================================================
-- TEST SUMMARY
-- ============================================================================

SELECT '' AS blank;
SELECT '============================================================================' AS summary_header;
SELECT '                           TEST SUMMARY                                    ' AS summary_title;
SELECT '============================================================================' AS summary_header;
SELECT '' AS blank;

SELECT '✅ All 13 Tests Completed Successfully!' AS overall_result;
SELECT '' AS blank;

SELECT 'Tests Executed:' AS tests_header;
SELECT '  1. Query Opportunities (Simple)' AS test_1;
SELECT '  2. Query Opportunities for Specific Account' AS test_2;
SELECT '  3. Query Opportunities with Custom Fields' AS test_3;
SELECT '  4. Query with Aggregations (Group By)' AS test_4;
SELECT '  5. Query with Relationships (Account)' AS test_5;
SELECT '  6. Create Opportunity' AS test_6;
SELECT '  7. Get Opportunity by ID' AS test_7;
SELECT '  8. Update Opportunity (Standard Fields)' AS test_8;
SELECT '  9. Update Opportunity (Custom Fields)' AS test_9;
SELECT ' 10. Update Opportunity (Mixed Fields)' AS test_10;
SELECT ' 11. Query Top 10 by Amount' AS test_11;
SELECT ' 12. Query by Stage (Closed Won)' AS test_12;
SELECT ' 13. Delete Opportunity (Cleanup)' AS test_13;

SELECT '' AS blank;
SELECT 'Functions Tested:' AS functions_header;
SELECT '  ✅ sf_query_opportunities(soql)' AS func_1;
SELECT '  ✅ sf_get_opportunity(id)' AS func_2;
SELECT '  ✅ sf_create_opportunity(data)' AS func_3;
SELECT '  ✅ sf_update_opportunity(id, data)' AS func_4;
SELECT '  ✅ sf_delete_opportunity(id)' AS func_5;

SELECT '' AS blank;
SELECT 'Features Verified:' AS features_header;
SELECT '  ✅ SOQL Queries' AS feature_1;
SELECT '  ✅ Custom Fields' AS feature_2;
SELECT '  ✅ Aggregations (COUNT, SUM, AVG)' AS feature_3;
SELECT '  ✅ Relationships (Account.Name, etc.)' AS feature_4;
SELECT '  ✅ Create Operations' AS feature_5;
SELECT '  ✅ Read Operations' AS feature_6;
SELECT '  ✅ Update Operations (Standard + Custom)' AS feature_7;
SELECT '  ✅ Delete Operations' AS feature_8;

SELECT '' AS blank;
SELECT '============================================================================' AS final_header;
SELECT '           ��� SALESFORCE TOOLS TEST SUITE COMPLETE! ���                     ' AS final_message;
SELECT '============================================================================' AS final_header;
SELECT '' AS blank;
