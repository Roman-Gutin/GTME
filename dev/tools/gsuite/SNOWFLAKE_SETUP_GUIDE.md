# Snowflake Google Docs Integration - Setup Guide

## 📋 Overview

This guide walks you through setting up the complete Google Docs integration for Snowflake using staged Python files.

## 🎯 What You'll Get

After completing this setup, you'll have **25+ SQL functions** available in Snowflake to:
- Create and read Google Docs
- Insert, delete, and replace text
- Format text and paragraphs
- Create and manage tables
- Insert and manage images
- Create bulleted lists
- Manage headers, footers, and sections
- And much more!

## 📁 Files in This Package

```
gsuite_tools/
├── __init__.py              # Package initialization
├── gdocs_handler.py         # Main handler class with all operations
└── README.md                # Detailed API documentation

snowflake_google_docs_complete_setup.sql  # Complete Snowflake setup script
SNOWFLAKE_SETUP_GUIDE.md                  # This file
```

## 🚀 Setup Steps

### Step 1: Upload Python Files to Snowflake

You have two options for uploading the Python files:

#### Option A: Using SnowSQL (Command Line)

```bash
# Navigate to your project directory
cd c:/Users/Owner/alpaca

# Upload the Python files
snowsql -a <your_account> -u <your_username> -d TEST -s PUBLIC -q "
PUT file://gsuite_tools/__init__.py @TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://gsuite_tools/gdocs_handler.py @TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
"
```

#### Option B: Using Snowsight UI (Web Interface)

1. Log into Snowsight (https://app.snowflake.com)
2. Navigate to **Data** → **Databases** → **TEST** → **PUBLIC** → **Stages**
3. Click on **GSUITE_STAGE** (it will be created by the setup script)
4. Click **+ Files** button
5. Upload both files:
   - `gsuite_tools/__init__.py`
   - `gsuite_tools/gdocs_handler.py`
6. Make sure they're in a `gsuite_tools/` subdirectory in the stage

### Step 2: Run the Setup Script

1. Open `snowflake_google_docs_complete_setup.sql` in Snowsight or your SQL editor
2. Execute the entire script (it will take 1-2 minutes)
3. The script will:
   - Create the stage for Python files
   - Set up network rules for Google APIs
   - Configure OAuth2 security integration
   - Create the OAuth secret with your refresh token
   - Create external access integration
   - Create all 25+ UDF functions

### Step 3: Verify the Setup

Run this query to verify files are uploaded:

```sql
LIST @TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/;
```

You should see:
- `gsuite_tools/__init__.py`
- `gsuite_tools/gdocs_handler.py`

### Step 4: Test the Integration

Try reading your test document:

```sql
SELECT TEST.PUBLIC.READ_GOOGLE_DOC('1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U', TRUE);
```

Expected result:
```json
{
  "success": true,
  "operation": "READ_DOC",
  "document_id": "1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U",
  "title": "Your Document Title",
  "full_content": "...",
  "content_length": 1234,
  "sections": [...],
  "sections_count": 5,
  "document_url": "https://docs.google.com/document/d/..."
}
```

## 📚 Available Functions

### Document Operations
- `CREATE_GOOGLE_DOC(title)` - Create new document
- `READ_GOOGLE_DOC(document_id, extract_sections)` - Read document

### Text Operations
- `INSERT_TEXT_GOOGLE_DOC(document_id, text, index)` - Insert text
- `DELETE_CONTENT_GOOGLE_DOC(document_id, start_index, end_index)` - Delete content
- `REPLACE_ALL_TEXT_GOOGLE_DOC(document_id, find_text, replace_text, match_case)` - Replace text

### Formatting Operations
- `UPDATE_TEXT_STYLE_GOOGLE_DOC(...)` - Bold, italic, underline, font size, colors
- `UPDATE_PARAGRAPH_STYLE_GOOGLE_DOC(...)` - Headings, alignment, spacing

### List Operations
- `CREATE_BULLETS_GOOGLE_DOC(...)` - Create bulleted lists
- `DELETE_BULLETS_GOOGLE_DOC(...)` - Remove bullets

### Table Operations
- `INSERT_TABLE_GOOGLE_DOC(...)` - Create tables
- `INSERT_TABLE_ROW_GOOGLE_DOC(...)` - Add rows
- `INSERT_TABLE_COLUMN_GOOGLE_DOC(...)` - Add columns
- `DELETE_TABLE_ROW_GOOGLE_DOC(...)` - Delete rows
- `DELETE_TABLE_COLUMN_GOOGLE_DOC(...)` - Delete columns

### Image Operations
- `INSERT_INLINE_IMAGE_GOOGLE_DOC(...)` - Insert images
- `REPLACE_IMAGE_GOOGLE_DOC(...)` - Replace images
- `DELETE_POSITIONED_OBJECT_GOOGLE_DOC(...)` - Delete images

### Other Operations
- `INSERT_PAGE_BREAK_GOOGLE_DOC(...)` - Insert page breaks
- `CREATE_NAMED_RANGE_GOOGLE_DOC(...)` - Create bookmarks
- `DELETE_NAMED_RANGE_GOOGLE_DOC(...)` - Delete bookmarks
- `CREATE_HEADER_GOOGLE_DOC(...)` - Create headers
- `CREATE_FOOTER_GOOGLE_DOC(...)` - Create footers
- `INSERT_SECTION_BREAK_GOOGLE_DOC(...)` - Insert section breaks

## 🧪 Example Workflows

### Create a Formatted Document

```sql
-- 1. Create a new document
SELECT TEST.PUBLIC.CREATE_GOOGLE_DOC('My Report') AS result;
-- Copy the document_id from the result

-- 2. Insert a title
SELECT TEST.PUBLIC.INSERT_TEXT_GOOGLE_DOC('<document_id>', 'Quarterly Report\n\n', 1);

-- 3. Format the title as Heading 1
SELECT TEST.PUBLIC.UPDATE_PARAGRAPH_STYLE_GOOGLE_DOC('<document_id>', 1, 18, 'HEADING_1', NULL, NULL, NULL, NULL);

-- 4. Insert body text
SELECT TEST.PUBLIC.INSERT_TEXT_GOOGLE_DOC('<document_id>', 'This is the introduction.\n\n', 19);

-- 5. Create a table
SELECT TEST.PUBLIC.INSERT_TABLE_GOOGLE_DOC('<document_id>', 3, 4, 50);
```

### Batch Update Multiple Documents

```sql
-- Create a table with document IDs
CREATE TEMP TABLE docs_to_update AS
SELECT '1b87Zc1s6JP7wGRu6ouHm26pMbwXgHvltnv0BJ7qSD5U' AS doc_id
UNION ALL
SELECT 'another-doc-id';

-- Replace text in all documents
SELECT 
    doc_id,
    TEST.PUBLIC.REPLACE_ALL_TEXT_GOOGLE_DOC(doc_id, 'old text', 'new text', FALSE) AS result
FROM docs_to_update;
```

## 🔧 Troubleshooting

### Error: "Stage does not exist"
- Make sure you ran the setup script first
- Verify with: `SHOW STAGES LIKE 'GSUITE_STAGE';`

### Error: "File not found in stage"
- Re-upload the Python files
- Check file paths with: `LIST @TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/;`

### Error: "OAuth token invalid"
- Your refresh token may have expired
- Generate a new refresh token using the OAuth Playground
- Update the secret in the setup script

### Error: "Network rule violation"
- Verify network rules are created
- Check with: `SHOW NETWORK RULES;`

### Error: "Module not found: gdocs_handler"
- The IMPORTS path may be incorrect
- Verify files are in `gsuite_tools/` subdirectory in the stage
- Check the stage path in the function definitions

## 📖 Additional Resources

- **API Documentation**: See `gsuite_tools/README.md` for detailed method documentation
- **Google Docs API**: https://developers.google.com/workspace/docs/api/reference/rest/v1/documents
- **Snowflake UDFs**: https://docs.snowflake.com/en/developer-guide/udf/python/udf-python

## ✅ Success Checklist

- [ ] Python files uploaded to stage
- [ ] Setup script executed successfully
- [ ] Test query returns document data
- [ ] All 25+ functions are available
- [ ] OAuth authentication working

## 🎉 You're Done!

You now have a complete Google Docs integration in Snowflake. All operations are available as SQL functions that you can use in queries, stored procedures, and tasks.

For detailed usage examples and API reference, see `gsuite_tools/README.md`.

