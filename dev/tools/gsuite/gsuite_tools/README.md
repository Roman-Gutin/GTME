# Google Workspace Tools for Snowflake

Production-ready Google Docs API integration for Snowflake UDFs using Snowpark staged files.

## Overview

This package provides comprehensive Google Docs API operations as Snowflake User Defined Functions (UDFs). All methods use OAuth2 authentication via Snowflake's `_snowflake.get_oauth_access_token('cred')` and return structured JSON responses.

## Features

### Document Operations
- **create_document**: Create new Google Docs
- **read_document**: Read document content with optional section extraction

### Text Operations
- **insert_text**: Insert text at specific positions
- **delete_content**: Delete content ranges
- **replace_all_text**: Find and replace text throughout document

### Formatting Operations
- **update_text_style**: Apply bold, italic, underline, font size, colors
- **update_paragraph_style**: Set headings, alignment, spacing

### List Operations
- **create_bullets**: Convert paragraphs to bulleted lists
- **delete_bullets**: Remove bullets from paragraphs

### Table Operations
- **insert_table**: Create tables with specified rows/columns
- **insert_table_row**: Add rows to existing tables
- **insert_table_column**: Add columns to existing tables
- **delete_table_row**: Remove rows from tables
- **delete_table_column**: Remove columns from tables

### Image Operations
- **insert_inline_image**: Insert images from URIs
- **replace_image**: Replace existing images
- **delete_positioned_object**: Delete images and other positioned objects

### Page Break Operations
- **insert_page_break**: Insert page breaks

### Named Range Operations
- **create_named_range**: Create named ranges for bookmarking
- **delete_named_range**: Delete named ranges

### Header/Footer Operations
- **create_header**: Create document headers
- **create_footer**: Create document footers
- **delete_header**: Delete headers
- **delete_footer**: Delete footers

### Section Operations
- **insert_section_break**: Insert section breaks
- **update_section_style**: Update section formatting (columns, margins)

## Installation in Snowflake

### 1. Upload Python Files to Snowflake Stage

```sql
-- Create stage for Python files
CREATE OR REPLACE STAGE TEST.PUBLIC.GSUITE_STAGE;

-- Upload files (use SnowSQL or Snowsight UI)
PUT file://c:/Users/Owner/alpaca/gsuite_tools/__init__.py @TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://c:/Users/Owner/alpaca/gsuite_tools/gdocs_handler.py @TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

-- Verify files are uploaded
LIST @TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/;
```

### 2. Create Snowflake UDFs

See `snowflake_google_docs_setup.sql` for complete setup including:
- Network rules
- OAuth security integration
- OAuth secret
- External access integration
- All UDF function definitions

## Usage Examples

### Create a New Document

```sql
SELECT TEST.PUBLIC.CREATE_GOOGLE_DOC('My New Document');
```

### Read a Document

```sql
SELECT TEST.PUBLIC.READ_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', TRUE);
```

### Insert Text

```sql
SELECT TEST.PUBLIC.INSERT_TEXT_GOOGLE_DOC(
    '1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U',
    'Hello, World!',
    1
);
```

### Replace Text

```sql
SELECT TEST.PUBLIC.REPLACE_ALL_TEXT_GOOGLE_DOC(
    '1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U',
    'old text',
    'new text',
    FALSE
);
```

### Format Text

```sql
SELECT TEST.PUBLIC.UPDATE_TEXT_STYLE_GOOGLE_DOC(
    '1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U',
    1,
    50,
    TRUE,   -- bold
    FALSE,  -- italic
    NULL,   -- underline
    14,     -- font size
    NULL    -- color
);
```

### Create a Table

```sql
SELECT TEST.PUBLIC.INSERT_TABLE_GOOGLE_DOC(
    '1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U',
    3,  -- rows
    4,  -- columns
    1   -- index
);
```

### Create Bulleted List

```sql
SELECT TEST.PUBLIC.CREATE_BULLETS_GOOGLE_DOC(
    '1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U',
    1,
    100,
    'BULLET_DISC_CIRCLE_SQUARE'
);
```

## Response Format

All functions return JSON with the following structure:

```json
{
  "success": true,
  "operation": "OPERATION_NAME",
  "document_id": "...",
  ...additional fields specific to operation...
}
```

On error:

```json
{
  "success": false,
  "error": "Error message",
  "operation": "OPERATION_NAME"
}
```

## API Reference

Full Google Docs API documentation: https://developers.google.com/workspace/docs/api/reference/rest/v1/documents

## Requirements

- Snowflake account with external access enabled
- Google Cloud project with Docs API enabled
- OAuth2 credentials (Client ID, Client Secret, Refresh Token)
- Appropriate Google Workspace scopes:
  - `https://www.googleapis.com/auth/documents`
  - `https://www.googleapis.com/auth/drive`

## Security

- All OAuth credentials are stored securely in Snowflake secrets
- Access tokens are automatically refreshed by Snowflake
- Network access is restricted to Google API endpoints only

## Version

1.0.0

## Author

Snowflake Integration Team

