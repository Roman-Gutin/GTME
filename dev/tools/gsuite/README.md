# GTME - Google Tools for Modern Enterprises

Production-ready Google Workspace integrations for Snowflake, enabling seamless document automation and data workflows.

## 🎯 Overview

GTME provides comprehensive Google Docs API integration for Snowflake through User Defined Functions (UDFs). All operations are available as SQL functions, making it easy to automate document workflows directly from your data warehouse.

## 📦 What's Included

### Google Docs Tools (`dev/tools/gsuite/`)

**25+ SQL Functions** covering all major Google Docs operations:

- **Document Operations**: Create, read documents
- **Text Operations**: Insert, delete, replace text
- **Formatting**: Bold, italic, underline, fonts, colors, headings
- **Lists**: Create and manage bulleted/numbered lists
- **Tables**: Create, modify, insert/delete rows and columns
- **Images**: Insert, replace, delete images
- **Page Breaks**: Insert page breaks
- **Named Ranges**: Create bookmarks and references
- **Headers/Footers**: Manage document headers and footers
- **Sections**: Create and style document sections

## 🚀 Quick Start

### Prerequisites

- Snowflake account with external access enabled
- Google Cloud project with Docs API enabled
- OAuth2 credentials (Client ID, Client Secret, Refresh Token)
- Snow CLI installed: `pip install snowflake-cli-labs`

### Installation

#### Option 1: Automated Deployment (Recommended)

**Windows:**
```bash
deploy_to_snowflake.bat
```

**Linux/Mac:**
```bash
chmod +x deploy_to_snowflake.sh
./deploy_to_snowflake.sh
```

#### Option 2: Manual Deployment

1. **Upload Python files:**
   ```bash
   snow stage copy gsuite_tools/__init__.py @TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/ --overwrite --auto-compress false
   snow stage copy gsuite_tools/gdocs_handler.py @TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/ --overwrite --auto-compress false
   ```

2. **Run setup script:**
   ```bash
   snow sql -f snowflake_google_docs_complete_setup.sql
   ```

3. **Verify installation:**
   ```bash
   snow sql -q "SHOW FUNCTIONS LIKE '%GOOGLE_DOC%' IN SCHEMA TEST.PUBLIC;"
   ```

### First Test

```sql
-- Read a Google Doc
SELECT TEST.PUBLIC.READ_GOOGLE_DOC('your-document-id-here', TRUE);

-- Create a new document
SELECT TEST.PUBLIC.CREATE_GOOGLE_DOC('My First Document');
```

## 📚 Documentation

- **[Setup Guide](SNOWFLAKE_SETUP_GUIDE.md)** - Detailed installation instructions
- **[API Reference](gsuite_tools/README.md)** - Complete function documentation
- **[Test Suite](test_tools.sql)** - Comprehensive edge case tests
- **[Deployment Scripts](deploy_to_snowflake.sh)** - Automated deployment

## 🧪 Testing

Run the comprehensive test suite to verify all edge cases:

```bash
snow sql -f test_tools.sql
```

The test suite covers:
- ✅ Special characters and encoding
- ✅ NULL and empty value handling
- ✅ Invalid parameter validation
- ✅ Boundary conditions (negative indices, large values)
- ✅ AI Agent-specific scenarios (JSON parsing, type conversion)
- ✅ Error handling and graceful failures

## 🏗️ Architecture

### Staged Files Approach

```
Snowflake Stage (GSUITE_STAGE)
└── gsuite_tools/
    ├── __init__.py          # Package initialization
    └── gdocs_handler.py     # Main handler class (1,378 lines)

Snowflake UDFs (25+ functions)
├── Document Operations (2 functions)
├── Text Operations (3 functions)
├── Formatting Operations (2 functions)
├── List Operations (2 functions)
├── Table Operations (5 functions)
├── Image Operations (3 functions)
├── Page Break Operations (1 function)
├── Named Range Operations (2 functions)
├── Header/Footer Operations (4 functions)
└── Section Operations (2 functions)
```

### Key Features

- **OAuth2 Authentication**: Automatic token refresh via Snowflake secrets
- **Structured Responses**: Consistent JSON format with success/error handling
- **Error Handling**: Comprehensive validation and graceful error messages
- **Production Ready**: Tested edge cases and AI agent scenarios
- **Modular Design**: Clean separation of concerns with class-based architecture

## 🔧 Configuration

### Environment Variables

Required in `.env` file:

```bash
GOOGLE_CLIENT_ID=your-client-id
GOOGLE_CLIENT_SECRET=your-client-secret
GOOGLE_REFRESH_TOKEN=your-refresh-token
GOOGLE_SCOPES=https://www.googleapis.com/auth/documents,https://www.googleapis.com/auth/drive
```

### Snowflake Configuration

Update `snowflake_google_docs_complete_setup.sql` with your credentials:

```sql
OAUTH_CLIENT_ID = 'your-client-id'
OAUTH_CLIENT_SECRET = 'your-client-secret'
OAUTH_REFRESH_TOKEN = 'your-refresh-token'
```

## 📊 Usage Examples

### Create a Formatted Report

```sql
-- 1. Create document
WITH new_doc AS (
    SELECT TEST.PUBLIC.CREATE_GOOGLE_DOC('Quarterly Report') AS result
)
-- 2. Insert title
, insert_title AS (
    SELECT 
        result:document_id::STRING AS doc_id,
        TEST.PUBLIC.INSERT_TEXT_GOOGLE_DOC(
            result:document_id::STRING, 
            'Q4 2024 Report\n\n', 
            1
        ) AS result
    FROM new_doc
)
-- 3. Format as heading
, format_title AS (
    SELECT 
        doc_id,
        TEST.PUBLIC.UPDATE_PARAGRAPH_STYLE_GOOGLE_DOC(
            doc_id, 
            1, 18, 
            'HEADING_1', 
            NULL, NULL, NULL, NULL
        ) AS result
    FROM insert_title
)
-- 4. Insert table
SELECT 
    doc_id,
    TEST.PUBLIC.INSERT_TABLE_GOOGLE_DOC(doc_id, 5, 3, 20) AS result
FROM format_title;
```

### Batch Update Documents

```sql
-- Update multiple documents from a table
CREATE TEMP TABLE docs_to_update AS
SELECT column1 AS doc_id, column2 AS old_text, column3 AS new_text
FROM VALUES 
    ('doc-id-1', 'Q3', 'Q4'),
    ('doc-id-2', 'Draft', 'Final');

-- Replace text in all documents
SELECT 
    doc_id,
    TEST.PUBLIC.REPLACE_ALL_TEXT_GOOGLE_DOC(doc_id, old_text, new_text, FALSE) AS result
FROM docs_to_update;
```

## 🔗 Git Integration with Snowflake Workspace

See [GIT_INTEGRATION_GUIDE.md](GIT_INTEGRATION_GUIDE.md) for detailed instructions on:
- Setting up Git integration in Snowflake
- Connecting to GitHub repository
- Viewing code in Snowflake Workspace
- Automated deployments via Git

## 🤝 Contributing

This is a production tool for enterprise use. For issues or feature requests, please contact the maintainer.

## 📄 License

Proprietary - All rights reserved

## 🙋 Support

For questions or issues:
1. Check the [Setup Guide](SNOWFLAKE_SETUP_GUIDE.md)
2. Review [Test Suite](test_tools.sql) for examples
3. See [API Reference](gsuite_tools/README.md) for function details

## 🎯 Roadmap

- [ ] Google Sheets integration
- [ ] Google Drive file management
- [ ] Google Calendar integration
- [ ] Batch operations optimization
- [ ] Advanced formatting (styles, themes)
- [ ] Document templates
- [ ] Collaborative editing support

## 📈 Version History

### v1.0.0 (Current)
- ✅ Complete Google Docs API coverage (25+ operations)
- ✅ Staged files architecture with Snowpark
- ✅ Comprehensive test suite with edge cases
- ✅ Production-ready error handling
- ✅ AI Agent compatibility
- ✅ Automated deployment scripts
- ✅ Complete documentation

---

**Built with ❤️ for modern data teams**

