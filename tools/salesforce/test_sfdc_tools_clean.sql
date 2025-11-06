-- ============================================================================
-- Salesforce Opportunity CRUD - Clean Test Suite (VARCHAR only)
-- ============================================================================
-- All functions use VARCHAR for Cortex Agent compatibility
-- Run with: snow sql -f test_sfdc_tools_clean.sql
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
-- TEST 3: Create Opportunity (returns JSON with id and success)
-- ============================================================================

SELECT sf_create_opportunity('{"Name": "TEST - Cortex Agent Test", "AccountId": "001g5000002OccTAAS", "Amount": 77777, "CloseDate": "2025-12-31", "StageName": "Prospecting", "Probability": 10}') AS result;

-- Extract the ID from the result for next tests
SET test_opp_id = (
    SELECT PARSE_JSON(sf_create_opportunity('{"Name": "TEST - SQL Test Opp", "AccountId": "001g5000002OccTAAS", "Amount": 99999, "CloseDate": "2025-12-31", "StageName": "Prospecting"}'))['id']::VARCHAR
);

SELECT 'Created opportunity: ' || $test_opp_id AS info;

-- ============================================================================
-- TEST 4: Get Opportunity by ID (returns JSON)
-- ============================================================================

SELECT sf_get_opportunity($test_opp_id) AS result;

-- ============================================================================
-- TEST 5: Update Opportunity - Standard Fields (returns JSON with success)
-- ============================================================================

SELECT sf_update_opportunity($test_opp_id, '{"StageName": "Qualification", "Amount": 150000, "Probability": 30}') AS result;

-- Verify
SELECT sf_get_opportunity($test_opp_id) AS verify;

-- ============================================================================
-- TEST 6: Update Opportunity - Custom Fields (returns JSON with success)
-- ============================================================================

SELECT sf_update_opportunity($test_opp_id, '{"DeliveryInstallationStatus__c": "In progress", "TrackingNumber__c": "TRACK-99999"}') AS result;

-- Verify
SELECT sf_query_opportunities('SELECT Id, Name, DeliveryInstallationStatus__c, TrackingNumber__c FROM Opportunity WHERE Id = ''' || $test_opp_id || '''') AS verify;

-- ============================================================================
-- TEST 7: Delete Opportunity (returns JSON with success)
-- ============================================================================

SELECT sf_delete_opportunity($test_opp_id) AS result;

SELECT 'Deleted opportunity: ' || $test_opp_id AS cleanup;

-- ============================================================================
-- TEST 8: Query with Aggregations
-- ============================================================================

SELECT sf_query_opportunities('SELECT StageName, COUNT(Id) as Count, SUM(Amount) as Total FROM Opportunity WHERE AccountId = ''001g5000002OccTAAS'' GROUP BY StageName') AS result;

-- ============================================================================
-- TEST 9: Query with Relationships
-- ============================================================================

SELECT sf_query_opportunities('SELECT Id, Name, Account.Name, Account.Industry, Amount FROM Opportunity WHERE AccountId = ''001g5000002OccTAAS'' LIMIT 3') AS result;

-- ============================================================================
-- TEST 10: Query Top Opportunities
-- ============================================================================

SELECT sf_query_opportunities('SELECT Id, Name, StageName, Amount FROM Opportunity WHERE Amount > 0 ORDER BY Amount DESC LIMIT 5') AS result;

