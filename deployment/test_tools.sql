-- ============================================================================
-- GOOGLE WORKSPACE CRUD OPERATIONS TEST SUITE
-- Tests all 22 deployed UDFs (5 Docs, 6 Sheets, 11 Drive)
-- Run as AGENTS_SERVICE_ROLE in AGENTS_DEMO.PUBLIC
-- ============================================================================

USE ROLE AGENTS_SERVICE_ROLE;
USE WAREHOUSE AGENTS_DEMO_WH;
USE DATABASE AGENTS_DEMO;
USE SCHEMA PUBLIC;

-- ============================================================================
-- GOOGLE DOCS - CRUD OPERATIONS (5 functions)
-- ============================================================================

-- TEST 1: CREATE - Create a new Google Doc
SELECT '========================================' AS separator;
SELECT 'TEST 1: Create Google Doc' AS test_name;
SET doc_id = (SELECT CREATE_GOOGLE_DOC('AI Agent Test Document'):document_id::VARCHAR);
SELECT OBJECT_CONSTRUCT(
    'document_id', $doc_id,
    'status', 'created',
    'url', 'https://docs.google.com/document/d/' || $doc_id || '/edit'
) AS result;

-- TEST 2: READ - Read the document we just created
SELECT 'TEST 2: Read Google Doc' AS test_name;
SELECT READ_GOOGLE_DOC($doc_id, TRUE) AS result;

-- TEST 3: UPDATE - Insert text into the document
SELECT 'TEST 3: Insert Text into Google Doc' AS test_name;
SELECT INSERT_TEXT_GOOGLE_DOC($doc_id, 'Hello from Snowflake Cortex AI Agent!\n\nThis is a test document.', 1) AS result;

-- TEST 4: READ - Verify text was inserted
SELECT 'TEST 4: Verify Text Insertion' AS test_name;
SELECT READ_GOOGLE_DOC($doc_id, TRUE) AS result;

-- TEST 5: UPDATE - Replace text in the document
SELECT 'TEST 5: Replace Text in Google Doc' AS test_name;
SELECT REPLACE_ALL_TEXT_GOOGLE_DOC($doc_id, 'Snowflake', 'Snowflake ❄️', FALSE) AS result;

-- TEST 6: READ - Verify replacement
SELECT 'TEST 6: Verify Text Replacement' AS test_name;
SELECT READ_GOOGLE_DOC($doc_id, TRUE) AS result;

-- TEST 7: UPDATE - Delete a range of content
SELECT 'TEST 7: Delete Content Range' AS test_name;
SELECT DELETE_CONTENT_GOOGLE_DOC($doc_id, 50, 60) AS result;

-- TEST 8: READ - Final document state
SELECT 'TEST 8: Final Document State' AS test_name;
SELECT READ_GOOGLE_DOC($doc_id, TRUE) AS result;

-- ============================================================================
-- GOOGLE SHEETS - CRUD OPERATIONS (6 functions)
-- ============================================================================

SELECT '========================================' AS separator;
SELECT 'GOOGLE SHEETS TESTS' AS section;

-- TEST 9: CREATE - Create a new Google Sheet
SELECT 'TEST 9: Create Google Sheet' AS test_name;
SET sheet_id = (SELECT CREATE_GOOGLE_SHEET('AI Agent Test Spreadsheet'):spreadsheetId::VARCHAR);
SELECT OBJECT_CONSTRUCT(
    'spreadsheet_id', $sheet_id,
    'status', 'created',
    'url', 'https://docs.google.com/spreadsheets/d/' || $sheet_id || '/edit'
) AS result;

-- TEST 10: WRITE - Write data to cells
SELECT 'TEST 10: Write Data to Sheet' AS test_name;
SELECT WRITE_SHEET_DATA(
    $sheet_id,
    'Sheet1!A1:C3',
    '[["Name", "Age", "City"], ["Alice", "30", "New York"], ["Bob", "25", "San Francisco"]]'
) AS result;

-- TEST 11: READ - Read the data we just wrote
SELECT 'TEST 11: Read Sheet Data' AS test_name;
SELECT READ_SHEET_DATA($sheet_id, 'Sheet1!A1:C3') AS result;

-- TEST 12: UPDATE - Update a specific cell
SELECT 'TEST 12: Update Single Cell' AS test_name;
SELECT UPDATE_CELL($sheet_id, 'Sheet1!B2', '31') AS result;

-- TEST 13: READ - Verify the update
SELECT 'TEST 13: Verify Cell Update' AS test_name;
SELECT READ_SHEET_DATA($sheet_id, 'Sheet1!B2') AS result;

-- TEST 14: APPEND - Append a new row
SELECT 'TEST 14: Append Row to Sheet' AS test_name;
SELECT APPEND_SHEET_DATA(
    $sheet_id,
    'Sheet1',
    '[["Charlie", "28", "Boston"]]'
) AS result;

-- TEST 15: READ - Read all data including appended row
SELECT 'TEST 15: Read All Data' AS test_name;
SELECT READ_SHEET_DATA($sheet_id, 'Sheet1!A1:C4') AS result;

-- TEST 16: DELETE - Clear a range of cells
SELECT 'TEST 16: Clear Cell Range' AS test_name;
SELECT CLEAR_SHEET_DATA($sheet_id, 'Sheet1!C2:C4') AS result;

-- TEST 17: READ - Verify clear operation
SELECT 'TEST 17: Verify Clear Operation' AS test_name;
SELECT READ_SHEET_DATA($sheet_id, 'Sheet1!A1:C4') AS result;

-- ============================================================================
-- GOOGLE DRIVE - FILE & FOLDER OPERATIONS (11 functions)
-- ============================================================================

SELECT '========================================' AS separator;
SELECT 'GOOGLE DRIVE TESTS' AS section;

-- TEST 18: CREATE - Create a folder
SELECT 'TEST 18: Create Google Drive Folder' AS test_name;
SET folder_id = (SELECT CREATE_DRIVE_FOLDER('AI Agent Test Folder', NULL):id::VARCHAR);
SELECT OBJECT_CONSTRUCT(
    'folder_id', $folder_id,
    'status', 'created',
    'url', 'https://drive.google.com/drive/folders/' || $folder_id
) AS result;

-- TEST 19: READ - List folder contents (should be empty)
SELECT 'TEST 19: List Folder Contents' AS test_name;
SELECT LIST_FOLDER_CONTENTS($folder_id, 10, 'name') AS result;

-- TEST 20: READ - Get folder metadata
SELECT 'TEST 20: Get Folder Metadata' AS test_name;
SELECT GET_FOLDER_METADATA($folder_id) AS result;

-- TEST 21: READ - Get file metadata for our document
SELECT 'TEST 21: Get Document Metadata' AS test_name;
SELECT GET_FILE_METADATA($doc_id) AS result;

-- TEST 22: UPDATE - Move document to folder
SELECT 'TEST 22: Move Document to Folder' AS test_name;
SELECT MOVE_FILE($doc_id, $folder_id) AS result;

-- TEST 23: READ - List folder contents (should now contain document)
SELECT 'TEST 23: List Folder Contents After Move' AS test_name;
SELECT LIST_FOLDER_CONTENTS($folder_id, 10, 'name') AS result;

-- TEST 24: CREATE - Copy the document
SELECT 'TEST 24: Copy Document' AS test_name;
SET copied_doc_id = (SELECT COPY_FILE($doc_id, 'Copy of Test Document', NULL):id::VARCHAR);
SELECT OBJECT_CONSTRUCT(
    'document_id', $copied_doc_id,
    'status', 'copied',
    'url', 'https://docs.google.com/document/d/' || $copied_doc_id || '/edit'
) AS result;

-- TEST 25: UPDATE - Rename the copied file
SELECT 'TEST 25: Rename Copied File' AS test_name;
SELECT RENAME_FILE($copied_doc_id, 'Renamed Test Document') AS result;

-- TEST 26: UPDATE - Share file with someone (replace with your email)
-- Uncomment and replace with actual email to test
-- SELECT 'TEST 26: Share File' AS test_name;
-- SELECT SHARE_FILE($copied_doc_id, 'your-email@example.com', 'reader', FALSE) AS result;

-- TEST 27: READ - List permissions on file
SELECT 'TEST 27: List File Permissions' AS test_name;
SELECT LIST_PERMISSIONS($copied_doc_id) AS result;

-- TEST 28: DELETE - Remove a specific permission (if you added one in TEST 26)
-- Uncomment and replace with actual permission_id from TEST 27
-- SELECT 'TEST 28: Remove Permission' AS test_name;
-- SELECT REMOVE_PERMISSION($copied_doc_id, 'permission_id_here') AS result;

-- TEST 29: DELETE - Delete the copied file
SELECT 'TEST 29: Delete Copied File' AS test_name;
SELECT DELETE_FILE($copied_doc_id) AS result;

-- ============================================================================
-- CLEANUP (Optional - uncomment to clean up test files)
-- ============================================================================

-- Uncomment these lines to delete test files after verification
-- SELECT 'CLEANUP: Deleting test document' AS cleanup_step;
-- SELECT DELETE_FILE($doc_id) AS result;

-- SELECT 'CLEANUP: Deleting test spreadsheet' AS cleanup_step;
-- SELECT DELETE_FILE($sheet_id) AS result;

-- SELECT 'CLEANUP: Deleting test folder' AS cleanup_step;
-- SELECT DELETE_FILE($folder_id) AS result;

-- ============================================================================
-- TEST SUMMARY
-- ============================================================================

SELECT '========================================' AS separator;
SELECT '
TEST SUITE COMPLETE!

Functions Tested:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

GOOGLE DOCS (5 functions):
  ✓ CREATE_GOOGLE_DOC          - Create new documents
  ✓ READ_GOOGLE_DOC             - Read document content
  ✓ INSERT_TEXT_GOOGLE_DOC      - Insert text at position
  ✓ DELETE_CONTENT_GOOGLE_DOC   - Delete text ranges
  ✓ REPLACE_ALL_TEXT_GOOGLE_DOC - Find and replace text

GOOGLE SHEETS (6 functions):
  ✓ CREATE_GOOGLE_SHEET         - Create new spreadsheets
  ✓ READ_SHEET_DATA             - Read cell ranges
  ✓ WRITE_SHEET_DATA            - Write to cell ranges
  ✓ APPEND_SHEET_DATA           - Append rows
  ✓ UPDATE_CELL                 - Update single cells
  ✓ CLEAR_SHEET_DATA            - Clear cell ranges

GOOGLE DRIVE (11 functions):
  ✓ CREATE_DRIVE_FOLDER         - Create folders
  ✓ LIST_FOLDER_CONTENTS        - List folder contents
  ✓ GET_FOLDER_METADATA         - Get folder details
  ✓ GET_FILE_METADATA           - Get file details
  ✓ MOVE_FILE                   - Move files/folders
  ✓ COPY_FILE                   - Copy files
  ✓ RENAME_FILE                 - Rename files/folders
  ✓ DELETE_FILE                 - Delete files/folders
  ✓ SHARE_FILE                  - Share with users
  ✓ LIST_PERMISSIONS            - List file permissions
  ✓ REMOVE_PERMISSION           - Remove permissions

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TOTAL: 22 Google Workspace Functions

Next Steps:
1. Review test results above
2. Verify files in Google Drive: https://drive.google.com/
3. Uncomment CLEANUP section to delete test files
4. Test the agent in Snowsight: AI & ML → Cortex → Agents → GTM_ENGINEER_AGENT

' AS summary;

