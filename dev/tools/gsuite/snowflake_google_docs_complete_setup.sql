-- ========================================
-- GOOGLE DOCS INTEGRATION FOR SNOWFLAKE
-- Complete Setup with Staged Python Files
-- ========================================

USE ROLE ACCOUNTADMIN;
USE DATABASE TEST;
USE SCHEMA PUBLIC;

-- ========================================
-- STEP 1: CREATE STAGE FOR PYTHON FILES
-- ========================================
CREATE OR REPLACE STAGE TEST.PUBLIC.GSUITE_STAGE
  COMMENT = 'Stage for Google Workspace Python modules';

-- Upload Python files using SnowSQL or Snowsight UI:
-- PUT file://c:/Users/Owner/alpaca/gsuite_tools/__init__.py @TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
-- PUT file://c:/Users/Owner/alpaca/gsuite_tools/gdocs_handler.py @TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

-- Verify files are uploaded:
-- LIST @TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/;

-- ========================================
-- STEP 2: CREATE NETWORK RULE FOR GOOGLE APIS
-- ========================================
CREATE OR REPLACE NETWORK RULE GOOGLE_APIS_NETWORK_RULE
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = (
    'oauth2.googleapis.com:443',
    'sheets.googleapis.com:443',
    'docs.googleapis.com:443',
    'www.googleapis.com:443',
    'accounts.google.com:443'
  );

-- ========================================
-- STEP 3: CREATE SECURITY INTEGRATION FOR OAUTH2
-- ========================================
CREATE OR REPLACE SECURITY INTEGRATION google_sheets_oauth
  TYPE = API_AUTHENTICATION
  AUTH_TYPE = OAUTH2
  OAUTH_CLIENT_ID = 'YOUR_GOOGLE_CLIENT_ID_HERE'
  OAUTH_CLIENT_SECRET = 'YOUR_GOOGLE_CLIENT_SECRET_HERE'
  OAUTH_TOKEN_ENDPOINT = 'https://oauth2.googleapis.com/token'
  OAUTH_AUTHORIZATION_ENDPOINT = 'https://accounts.google.com/o/oauth2/auth'
  OAUTH_ALLOWED_SCOPES = (
    'https://www.googleapis.com/auth/spreadsheets',
    'https://www.googleapis.com/auth/drive',
    'https://www.googleapis.com/auth/documents',
    'https://www.googleapis.com/auth/calendar'
  )
  ENABLED = TRUE;

-- ========================================
-- STEP 4: CREATE OAUTH2 SECRET WITH REFRESH TOKEN
-- ========================================
CREATE OR REPLACE SECRET google_oauth_secret
  TYPE = OAUTH2
  API_AUTHENTICATION = google_sheets_oauth
  OAUTH_REFRESH_TOKEN = 'YOUR_GOOGLE_REFRESH_TOKEN_HERE';

-- ========================================
-- STEP 5: CREATE EXTERNAL ACCESS INTEGRATION
-- ========================================
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION GOOGLE_SHEETS_INTEGRATION
  ALLOWED_NETWORK_RULES = (GOOGLE_APIS_NETWORK_RULE)
  ALLOWED_AUTHENTICATION_SECRETS = (google_oauth_secret)
  ENABLED = TRUE;

-- ========================================
-- STEP 6: CREATE UDFs USING STAGED PYTHON FILES
-- ========================================

-- ========================================
-- DOCUMENT OPERATIONS
-- ========================================

-- Create a new Google Doc
CREATE OR REPLACE FUNCTION TEST.PUBLIC.CREATE_GOOGLE_DOC(TITLE VARCHAR DEFAULT 'Untitled Document')
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'create_doc_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def create_doc_handler(title):
    handler = GDocsHandler(_snowflake)
    return handler.create_document(title)
$$;

-- Read a Google Doc
CREATE OR REPLACE FUNCTION TEST.PUBLIC.READ_GOOGLE_DOC(DOCUMENT_ID VARCHAR, EXTRACT_SECTIONS BOOLEAN DEFAULT TRUE)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'read_doc_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def read_doc_handler(document_id, extract_sections):
    handler = GDocsHandler(_snowflake)
    return handler.read_document(document_id, extract_sections)
$$;

-- ========================================
-- TEXT OPERATIONS
-- ========================================

-- Insert text at a specific index
CREATE OR REPLACE FUNCTION TEST.PUBLIC.INSERT_TEXT_GOOGLE_DOC(DOCUMENT_ID VARCHAR, TEXT VARCHAR, INDEX_POS INTEGER DEFAULT 1)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'insert_text_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def insert_text_handler(document_id, text, index_pos):
    handler = GDocsHandler(_snowflake)
    return handler.insert_text(document_id, text, index_pos)
$$;

-- Delete content from a document
CREATE OR REPLACE FUNCTION TEST.PUBLIC.DELETE_CONTENT_GOOGLE_DOC(DOCUMENT_ID VARCHAR, START_INDEX INTEGER, END_INDEX INTEGER)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'delete_content_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def delete_content_handler(document_id, start_index, end_index):
    handler = GDocsHandler(_snowflake)
    return handler.delete_content(document_id, start_index, end_index)
$$;

-- Replace all occurrences of text
CREATE OR REPLACE FUNCTION TEST.PUBLIC.REPLACE_ALL_TEXT_GOOGLE_DOC(
    DOCUMENT_ID VARCHAR, 
    FIND_TEXT VARCHAR, 
    REPLACE_TEXT VARCHAR, 
    MATCH_CASE BOOLEAN DEFAULT FALSE
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'replace_text_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def replace_text_handler(document_id, find_text, replace_text, match_case):
    handler = GDocsHandler(_snowflake)
    return handler.replace_all_text(document_id, find_text, replace_text, match_case)
$$;

-- ========================================
-- FORMATTING OPERATIONS
-- ========================================

-- Update text style (bold, italic, underline, font size, color)
CREATE OR REPLACE FUNCTION TEST.PUBLIC.UPDATE_TEXT_STYLE_GOOGLE_DOC(
    DOCUMENT_ID VARCHAR,
    START_INDEX INTEGER,
    END_INDEX INTEGER,
    BOLD BOOLEAN DEFAULT NULL,
    ITALIC BOOLEAN DEFAULT NULL,
    UNDERLINE BOOLEAN DEFAULT NULL,
    FONT_SIZE FLOAT DEFAULT NULL,
    FOREGROUND_COLOR VARIANT DEFAULT NULL
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'update_text_style_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def update_text_style_handler(document_id, start_index, end_index, bold, italic, underline, font_size, foreground_color):
    handler = GDocsHandler(_snowflake)
    return handler.update_text_style(document_id, start_index, end_index, bold, italic, underline, font_size, foreground_color)
$$;

-- Update paragraph style (headings, alignment, spacing)
CREATE OR REPLACE FUNCTION TEST.PUBLIC.UPDATE_PARAGRAPH_STYLE_GOOGLE_DOC(
    DOCUMENT_ID VARCHAR,
    START_INDEX INTEGER,
    END_INDEX INTEGER,
    NAMED_STYLE_TYPE VARCHAR DEFAULT NULL,
    ALIGNMENT VARCHAR DEFAULT NULL,
    LINE_SPACING FLOAT DEFAULT NULL,
    SPACE_ABOVE FLOAT DEFAULT NULL,
    SPACE_BELOW FLOAT DEFAULT NULL
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'update_paragraph_style_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def update_paragraph_style_handler(document_id, start_index, end_index, named_style_type, alignment, line_spacing, space_above, space_below):
    handler = GDocsHandler(_snowflake)
    return handler.update_paragraph_style(document_id, start_index, end_index, named_style_type, alignment, line_spacing, space_above, space_below)
$$;

-- ========================================
-- LIST OPERATIONS
-- ========================================

-- Create bulleted list
CREATE OR REPLACE FUNCTION TEST.PUBLIC.CREATE_BULLETS_GOOGLE_DOC(
    DOCUMENT_ID VARCHAR,
    START_INDEX INTEGER,
    END_INDEX INTEGER,
    BULLET_PRESET VARCHAR DEFAULT 'BULLET_DISC_CIRCLE_SQUARE'
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'create_bullets_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def create_bullets_handler(document_id, start_index, end_index, bullet_preset):
    handler = GDocsHandler(_snowflake)
    return handler.create_bullets(document_id, start_index, end_index, bullet_preset)
$$;

-- Delete bullets from paragraphs
CREATE OR REPLACE FUNCTION TEST.PUBLIC.DELETE_BULLETS_GOOGLE_DOC(
    DOCUMENT_ID VARCHAR,
    START_INDEX INTEGER,
    END_INDEX INTEGER
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'delete_bullets_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def delete_bullets_handler(document_id, start_index, end_index):
    handler = GDocsHandler(_snowflake)
    return handler.delete_bullets(document_id, start_index, end_index)
$$;

-- ========================================
-- TABLE OPERATIONS
-- ========================================

-- Insert a table
CREATE OR REPLACE FUNCTION TEST.PUBLIC.INSERT_TABLE_GOOGLE_DOC(
    DOCUMENT_ID VARCHAR,
    ROWS INTEGER,
    COLUMNS INTEGER,
    INDEX_POS INTEGER
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'insert_table_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def insert_table_handler(document_id, rows, columns, index_pos):
    handler = GDocsHandler(_snowflake)
    return handler.insert_table(document_id, rows, columns, index_pos)
$$;

-- Insert table row
CREATE OR REPLACE FUNCTION TEST.PUBLIC.INSERT_TABLE_ROW_GOOGLE_DOC(
    DOCUMENT_ID VARCHAR,
    TABLE_START_INDEX INTEGER,
    ROW_INDEX INTEGER,
    INSERT_BELOW BOOLEAN DEFAULT TRUE
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'insert_table_row_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def insert_table_row_handler(document_id, table_start_index, row_index, insert_below):
    handler = GDocsHandler(_snowflake)
    return handler.insert_table_row(document_id, table_start_index, row_index, insert_below)
$$;

-- Insert table column
CREATE OR REPLACE FUNCTION TEST.PUBLIC.INSERT_TABLE_COLUMN_GOOGLE_DOC(
    DOCUMENT_ID VARCHAR,
    TABLE_START_INDEX INTEGER,
    COLUMN_INDEX INTEGER,
    INSERT_RIGHT BOOLEAN DEFAULT TRUE
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'insert_table_column_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def insert_table_column_handler(document_id, table_start_index, column_index, insert_right):
    handler = GDocsHandler(_snowflake)
    return handler.insert_table_column(document_id, table_start_index, column_index, insert_right)
$$;

-- Delete table row
CREATE OR REPLACE FUNCTION TEST.PUBLIC.DELETE_TABLE_ROW_GOOGLE_DOC(
    DOCUMENT_ID VARCHAR,
    TABLE_START_INDEX INTEGER,
    ROW_INDEX INTEGER
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'delete_table_row_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def delete_table_row_handler(document_id, table_start_index, row_index):
    handler = GDocsHandler(_snowflake)
    return handler.delete_table_row(document_id, table_start_index, row_index)
$$;

-- Delete table column
CREATE OR REPLACE FUNCTION TEST.PUBLIC.DELETE_TABLE_COLUMN_GOOGLE_DOC(
    DOCUMENT_ID VARCHAR,
    TABLE_START_INDEX INTEGER,
    COLUMN_INDEX INTEGER
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'delete_table_column_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def delete_table_column_handler(document_id, table_start_index, column_index):
    handler = GDocsHandler(_snowflake)
    return handler.delete_table_column(document_id, table_start_index, column_index)
$$;

-- ========================================
-- IMAGE OPERATIONS
-- ========================================

-- Insert inline image
CREATE OR REPLACE FUNCTION TEST.PUBLIC.INSERT_INLINE_IMAGE_GOOGLE_DOC(
    DOCUMENT_ID VARCHAR,
    IMAGE_URI VARCHAR,
    INDEX_POS INTEGER
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'insert_inline_image_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def insert_inline_image_handler(document_id, image_uri, index_pos):
    handler = GDocsHandler(_snowflake)
    return handler.insert_inline_image(document_id, image_uri, index_pos)
$$;

-- Replace image
CREATE OR REPLACE FUNCTION TEST.PUBLIC.REPLACE_IMAGE_GOOGLE_DOC(
    DOCUMENT_ID VARCHAR,
    IMAGE_OBJECT_ID VARCHAR,
    NEW_IMAGE_URI VARCHAR
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'replace_image_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def replace_image_handler(document_id, image_object_id, new_image_uri):
    handler = GDocsHandler(_snowflake)
    return handler.replace_image(document_id, image_object_id, new_image_uri)
$$;

-- Delete positioned object
CREATE OR REPLACE FUNCTION TEST.PUBLIC.DELETE_POSITIONED_OBJECT_GOOGLE_DOC(
    DOCUMENT_ID VARCHAR,
    OBJECT_ID VARCHAR
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'delete_positioned_object_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def delete_positioned_object_handler(document_id, object_id):
    handler = GDocsHandler(_snowflake)
    return handler.delete_positioned_object(document_id, object_id)
$$;

-- ========================================
-- PAGE BREAK & NAMED RANGE OPERATIONS
-- ========================================

-- Insert page break
CREATE OR REPLACE FUNCTION TEST.PUBLIC.INSERT_PAGE_BREAK_GOOGLE_DOC(
    DOCUMENT_ID VARCHAR,
    INDEX_POS INTEGER
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'insert_page_break_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def insert_page_break_handler(document_id, index_pos):
    handler = GDocsHandler(_snowflake)
    return handler.insert_page_break(document_id, index_pos)
$$;

-- Create named range
CREATE OR REPLACE FUNCTION TEST.PUBLIC.CREATE_NAMED_RANGE_GOOGLE_DOC(
    DOCUMENT_ID VARCHAR,
    RANGE_NAME VARCHAR,
    START_INDEX INTEGER,
    END_INDEX INTEGER
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'create_named_range_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def create_named_range_handler(document_id, range_name, start_index, end_index):
    handler = GDocsHandler(_snowflake)
    return handler.create_named_range(document_id, range_name, start_index, end_index)
$$;

-- Delete named range
CREATE OR REPLACE FUNCTION TEST.PUBLIC.DELETE_NAMED_RANGE_GOOGLE_DOC(
    DOCUMENT_ID VARCHAR,
    NAMED_RANGE_ID VARCHAR DEFAULT NULL,
    RANGE_NAME VARCHAR DEFAULT NULL
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'delete_named_range_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def delete_named_range_handler(document_id, named_range_id, range_name):
    handler = GDocsHandler(_snowflake)
    return handler.delete_named_range(document_id, named_range_id, range_name)
$$;

-- ========================================
-- HEADER/FOOTER & SECTION OPERATIONS
-- ========================================

-- Create header
CREATE OR REPLACE FUNCTION TEST.PUBLIC.CREATE_HEADER_GOOGLE_DOC(
    DOCUMENT_ID VARCHAR,
    SECTION_INDEX INTEGER DEFAULT 0,
    HEADER_TYPE VARCHAR DEFAULT 'DEFAULT'
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'create_header_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def create_header_handler(document_id, section_index, header_type):
    handler = GDocsHandler(_snowflake)
    return handler.create_header(document_id, section_index, header_type)
$$;

-- Create footer
CREATE OR REPLACE FUNCTION TEST.PUBLIC.CREATE_FOOTER_GOOGLE_DOC(
    DOCUMENT_ID VARCHAR,
    SECTION_INDEX INTEGER DEFAULT 0,
    FOOTER_TYPE VARCHAR DEFAULT 'DEFAULT'
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'create_footer_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def create_footer_handler(document_id, section_index, footer_type):
    handler = GDocsHandler(_snowflake)
    return handler.create_footer(document_id, section_index, footer_type)
$$;

-- Insert section break
CREATE OR REPLACE FUNCTION TEST.PUBLIC.INSERT_SECTION_BREAK_GOOGLE_DOC(
    DOCUMENT_ID VARCHAR,
    INDEX_POS INTEGER,
    SECTION_TYPE VARCHAR DEFAULT 'CONTINUOUS'
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = 'insert_section_break_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_SHEETS_INTEGRATION)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/gdocs_handler.py')
AS $$
import _snowflake
from gdocs_handler import GDocsHandler

def insert_section_break_handler(document_id, index_pos, section_type):
    handler = GDocsHandler(_snowflake)
    return handler.insert_section_break(document_id, index_pos, section_type)
$$;

-- ========================================
-- USAGE EXAMPLES
-- ========================================

-- Example 1: Create a new document
-- SELECT TEST.PUBLIC.CREATE_GOOGLE_DOC('My New Document');

-- Example 2: Read a document with sections
-- SELECT TEST.PUBLIC.READ_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', TRUE);

-- Example 3: Insert text
-- SELECT TEST.PUBLIC.INSERT_TEXT_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 'Hello, World!', 1);

-- Example 4: Replace text
-- SELECT TEST.PUBLIC.REPLACE_ALL_TEXT_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 'old', 'new', FALSE);

-- Example 5: Format text as bold
-- SELECT TEST.PUBLIC.UPDATE_TEXT_STYLE_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 1, 50, TRUE, NULL, NULL, NULL, NULL);

-- Example 6: Create a table
-- SELECT TEST.PUBLIC.INSERT_TABLE_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 3, 4, 1);

-- Example 7: Create bulleted list
-- SELECT TEST.PUBLIC.CREATE_BULLETS_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', 1, 100, 'BULLET_DISC_CIRCLE_SQUARE');

-- ========================================
-- SETUP COMPLETE
-- ========================================
-- All Google Docs operations are now available as Snowflake UDFs!
-- See gsuite_tools/README.md for detailed documentation.
