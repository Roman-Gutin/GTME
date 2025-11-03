-- ========================================
-- GOOGLE DOCS TOOLS - COMPREHENSIVE TEST SUITE
-- Edge Cases for AI Agent Usage
-- ========================================

USE ROLE ACCOUNTADMIN;
USE DATABASE TEST;
USE SCHEMA PUBLIC;

-- ========================================
-- TEST 1: BASIC DOCUMENT OPERATIONS
-- ========================================

-- Test 1.1: Create a document with special characters in title
SELECT 'Test 1.1: Create document with special characters' AS test_name,
       TEST.PUBLIC.CREATE_GOOGLE_DOC('Test Doc: "Quotes" & Symbols! @#$%') AS result;

-- Test 1.2: Create document with empty title (should use default)
SELECT 'Test 1.2: Create document with empty title' AS test_name,
       TEST.PUBLIC.CREATE_GOOGLE_DOC('') AS result;

-- Test 1.3: Create document with NULL title (should use default)
SELECT 'Test 1.3: Create document with NULL title' AS test_name,
       TEST.PUBLIC.CREATE_GOOGLE_DOC(NULL) AS result;

-- Test 1.4: Read non-existent document (error handling)
SELECT 'Test 1.4: Read non-existent document' AS test_name,
       TEST.PUBLIC.READ_GOOGLE_DOC('invalid-doc-id-12345', TRUE) AS result;

-- Test 1.5: Read document with invalid boolean parameter
SELECT 'Test 1.5: Read document with NULL extract_sections' AS test_name,
       TEST.PUBLIC.READ_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', NULL) AS result;

-- ========================================
-- TEST 2: TEXT OPERATIONS - EDGE CASES
-- ========================================

-- Test 2.1: Insert text at index 0 (should fail - index must be >= 1)
SELECT 'Test 2.1: Insert text at index 0' AS test_name,
       TEST.PUBLIC.INSERT_TEXT_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 'Test', 0) AS result;

-- Test 2.2: Insert empty string
SELECT 'Test 2.2: Insert empty string' AS test_name,
       TEST.PUBLIC.INSERT_TEXT_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', '', 1) AS result;

-- Test 2.3: Insert NULL text (should fail gracefully)
SELECT 'Test 2.3: Insert NULL text' AS test_name,
       TEST.PUBLIC.INSERT_TEXT_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', NULL, 1) AS result;

-- Test 2.4: Insert text with special characters and newlines
SELECT 'Test 2.4: Insert text with special characters' AS test_name,
       TEST.PUBLIC.INSERT_TEXT_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                           'Line 1\nLine 2\tTabbed\n"Quoted" & <HTML>', 1) AS result;

-- Test 2.5: Insert very long text (10,000 characters)
SELECT 'Test 2.5: Insert very long text' AS test_name,
       TEST.PUBLIC.INSERT_TEXT_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                           REPEAT('A', 10000), 1) AS result;

-- Test 2.6: Delete content with invalid range (end < start)
SELECT 'Test 2.6: Delete content with invalid range' AS test_name,
       TEST.PUBLIC.DELETE_CONTENT_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 100, 50) AS result;

-- Test 2.7: Delete content with negative indices
SELECT 'Test 2.7: Delete content with negative indices' AS test_name,
       TEST.PUBLIC.DELETE_CONTENT_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', -1, 10) AS result;

-- Test 2.8: Replace text with empty string (delete all occurrences)
SELECT 'Test 2.8: Replace text with empty string' AS test_name,
       TEST.PUBLIC.REPLACE_ALL_TEXT_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                'test', '', FALSE) AS result;

-- Test 2.9: Replace text with NULL values
SELECT 'Test 2.9: Replace text with NULL find_text' AS test_name,
       TEST.PUBLIC.REPLACE_ALL_TEXT_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                NULL, 'replacement', FALSE) AS result;

-- Test 2.10: Replace text with regex special characters
SELECT 'Test 2.10: Replace text with regex characters' AS test_name,
       TEST.PUBLIC.REPLACE_ALL_TEXT_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                '.*[test].*', 'replacement', FALSE) AS result;

-- ========================================
-- TEST 3: FORMATTING - EDGE CASES
-- ========================================

-- Test 3.1: Update text style with all NULL parameters (should fail)
SELECT 'Test 3.1: Update text style with all NULLs' AS test_name,
       TEST.PUBLIC.UPDATE_TEXT_STYLE_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                 1, 10, NULL, NULL, NULL, NULL, NULL) AS result;

-- Test 3.2: Update text style with invalid font size (negative)
SELECT 'Test 3.2: Update text style with negative font size' AS test_name,
       TEST.PUBLIC.UPDATE_TEXT_STYLE_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                 1, 10, NULL, NULL, NULL, -5, NULL) AS result;

-- Test 3.3: Update text style with extremely large font size
SELECT 'Test 3.3: Update text style with large font size' AS test_name,
       TEST.PUBLIC.UPDATE_TEXT_STYLE_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                 1, 10, NULL, NULL, NULL, 999, NULL) AS result;

-- Test 3.4: Update text style with invalid color format
SELECT 'Test 3.4: Update text style with invalid color' AS test_name,
       TEST.PUBLIC.UPDATE_TEXT_STYLE_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                 1, 10, NULL, NULL, NULL, NULL, 
                                                 PARSE_JSON('{"invalid": "color"}')) AS result;

-- Test 3.5: Update paragraph style with invalid named style type
SELECT 'Test 3.5: Update paragraph with invalid style type' AS test_name,
       TEST.PUBLIC.UPDATE_PARAGRAPH_STYLE_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                      1, 10, 'INVALID_STYLE', NULL, NULL, NULL, NULL) AS result;

-- Test 3.6: Update paragraph style with negative spacing
SELECT 'Test 3.6: Update paragraph with negative spacing' AS test_name,
       TEST.PUBLIC.UPDATE_PARAGRAPH_STYLE_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                      1, 10, NULL, NULL, -1.5, NULL, NULL) AS result;

-- ========================================
-- TEST 4: TABLE OPERATIONS - EDGE CASES
-- ========================================

-- Test 4.1: Insert table with 0 rows
SELECT 'Test 4.1: Insert table with 0 rows' AS test_name,
       TEST.PUBLIC.INSERT_TABLE_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 0, 3, 1) AS result;

-- Test 4.2: Insert table with 0 columns
SELECT 'Test 4.2: Insert table with 0 columns' AS test_name,
       TEST.PUBLIC.INSERT_TABLE_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 3, 0, 1) AS result;

-- Test 4.3: Insert table with negative dimensions
SELECT 'Test 4.3: Insert table with negative dimensions' AS test_name,
       TEST.PUBLIC.INSERT_TABLE_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', -1, -1, 1) AS result;

-- Test 4.4: Insert table with extremely large dimensions (20x20 - max allowed)
SELECT 'Test 4.4: Insert large table' AS test_name,
       TEST.PUBLIC.INSERT_TABLE_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 20, 20, 1) AS result;

-- Test 4.5: Insert table row with invalid table index
SELECT 'Test 4.5: Insert table row with invalid index' AS test_name,
       TEST.PUBLIC.INSERT_TABLE_ROW_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                99999, 0, TRUE) AS result;

-- Test 4.6: Delete table row with negative row index
SELECT 'Test 4.6: Delete table row with negative index' AS test_name,
       TEST.PUBLIC.DELETE_TABLE_ROW_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                1, -1) AS result;

-- ========================================
-- TEST 5: IMAGE OPERATIONS - EDGE CASES
-- ========================================

-- Test 5.1: Insert image with invalid URI
SELECT 'Test 5.1: Insert image with invalid URI' AS test_name,
       TEST.PUBLIC.INSERT_INLINE_IMAGE_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                   'not-a-valid-uri', 1) AS result;

-- Test 5.2: Insert image with NULL URI
SELECT 'Test 5.2: Insert image with NULL URI' AS test_name,
       TEST.PUBLIC.INSERT_INLINE_IMAGE_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                   NULL, 1) AS result;

-- Test 5.3: Replace image with non-existent object ID
SELECT 'Test 5.3: Replace non-existent image' AS test_name,
       TEST.PUBLIC.REPLACE_IMAGE_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                             'fake-object-id', 'https://example.com/image.png') AS result;

-- Test 5.4: Delete positioned object with NULL object ID
SELECT 'Test 5.4: Delete object with NULL ID' AS test_name,
       TEST.PUBLIC.DELETE_POSITIONED_OBJECT_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                        NULL) AS result;

-- ========================================
-- TEST 6: LIST OPERATIONS - EDGE CASES
-- ========================================

-- Test 6.1: Create bullets with invalid preset
SELECT 'Test 6.1: Create bullets with invalid preset' AS test_name,
       TEST.PUBLIC.CREATE_BULLETS_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                              1, 100, 'INVALID_PRESET') AS result;

-- Test 6.2: Create bullets with NULL preset (should use default)
SELECT 'Test 6.2: Create bullets with NULL preset' AS test_name,
       TEST.PUBLIC.CREATE_BULLETS_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                              1, 100, NULL) AS result;

-- Test 6.3: Delete bullets from range with no bullets
SELECT 'Test 6.3: Delete bullets from non-bulleted range' AS test_name,
       TEST.PUBLIC.DELETE_BULLETS_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                              1, 10) AS result;

-- ========================================
-- TEST 7: NAMED RANGE OPERATIONS - EDGE CASES
-- ========================================

-- Test 7.1: Create named range with empty name
SELECT 'Test 7.1: Create named range with empty name' AS test_name,
       TEST.PUBLIC.CREATE_NAMED_RANGE_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                  '', 1, 10) AS result;

-- Test 7.2: Create named range with NULL name
SELECT 'Test 7.2: Create named range with NULL name' AS test_name,
       TEST.PUBLIC.CREATE_NAMED_RANGE_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                  NULL, 1, 10) AS result;

-- Test 7.3: Delete named range with both ID and name NULL
SELECT 'Test 7.3: Delete named range with both NULL' AS test_name,
       TEST.PUBLIC.DELETE_NAMED_RANGE_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                  NULL, NULL) AS result;

-- Test 7.4: Delete non-existent named range
SELECT 'Test 7.4: Delete non-existent named range' AS test_name,
       TEST.PUBLIC.DELETE_NAMED_RANGE_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                  'fake-id-12345', NULL) AS result;

-- ========================================
-- TEST 8: HEADER/FOOTER - EDGE CASES
-- ========================================

-- Test 8.1: Create header with invalid type
SELECT 'Test 8.1: Create header with invalid type' AS test_name,
       TEST.PUBLIC.CREATE_HEADER_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                             0, 'INVALID_TYPE') AS result;

-- Test 8.2: Create header with negative section index
SELECT 'Test 8.2: Create header with negative section index' AS test_name,
       TEST.PUBLIC.CREATE_HEADER_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                             -1, 'DEFAULT') AS result;

-- Test 8.3: Delete header with NULL ID
SELECT 'Test 8.3: Delete header with NULL ID' AS test_name,
       TEST.PUBLIC.DELETE_HEADER_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                             NULL) AS result;

-- ========================================
-- TEST 9: SECTION OPERATIONS - EDGE CASES
-- ========================================

-- Test 9.1: Insert section break with invalid type
SELECT 'Test 9.1: Insert section break with invalid type' AS test_name,
       TEST.PUBLIC.INSERT_SECTION_BREAK_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                    1, 'INVALID_TYPE') AS result;

-- Test 9.2: Insert section break at index 0
SELECT 'Test 9.2: Insert section break at index 0' AS test_name,
       TEST.PUBLIC.INSERT_SECTION_BREAK_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                    0, 'CONTINUOUS') AS result;

-- ========================================
-- TEST 10: AI AGENT SPECIFIC SCENARIOS
-- ========================================

-- Test 10.1: Agent passes JSON string instead of parsed JSON for color
SELECT 'Test 10.1: Agent passes JSON string for color' AS test_name,
       TEST.PUBLIC.UPDATE_TEXT_STYLE_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                                 1, 10, TRUE, NULL, NULL, NULL, 
                                                 '{"red": 1.0, "green": 0.0, "blue": 0.0}') AS result;

-- Test 10.2: Agent passes string 'true' instead of boolean
-- Note: Snowflake will auto-convert, but test the behavior
SELECT 'Test 10.2: Agent passes string boolean' AS test_name,
       TEST.PUBLIC.CREATE_BULLETS_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 
                                              1, 100, 'BULLET_DISC_CIRCLE_SQUARE') AS result;

-- Test 10.3: Agent concatenates multiple operations (batch test)
WITH new_doc AS (
    SELECT TEST.PUBLIC.CREATE_GOOGLE_DOC('Agent Test Document') AS result
)
SELECT 
    'Test 10.3: Agent batch operations' AS test_name,
    result:document_id::STRING AS doc_id,
    TEST.PUBLIC.INSERT_TEXT_GOOGLE_DOC(result:document_id::STRING, 'Hello World\n', 1) AS insert_result
FROM new_doc;

-- ========================================
-- TEST SUMMARY QUERY
-- ========================================

-- Run this to see all test results in a summary format
SELECT 
    'Total Tests' AS metric,
    COUNT(*) AS value
FROM (
    SELECT 'Test completed' AS status
    -- Add UNION ALL for each test result if needed
);

-- ========================================
-- CLEANUP (OPTIONAL)
-- ========================================

-- Uncomment to drop all functions for cleanup
-- DROP FUNCTION IF EXISTS TEST.PUBLIC.CREATE_GOOGLE_DOC(VARCHAR);
-- DROP FUNCTION IF EXISTS TEST.PUBLIC.READ_GOOGLE_DOC(VARCHAR, BOOLEAN);
-- ... (add all other functions)

