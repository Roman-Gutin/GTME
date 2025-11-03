@echo off
REM ========================================
REM Deploy Google Docs Tools to Snowflake (Windows)
REM ========================================

echo =========================================
echo Google Docs Tools - Snowflake Deployment
echo =========================================
echo.

REM Check if Snow CLI is installed
where snow >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Snow CLI not found. Please install it first:
    echo    pip install snowflake-cli-labs
    exit /b 1
)

echo Snow CLI found
echo.

REM Check if required files exist
echo Checking required files...
if not exist "gsuite_tools\__init__.py" (
    echo ERROR: Required file not found: gsuite_tools\__init__.py
    exit /b 1
)
echo   - gsuite_tools\__init__.py

if not exist "gsuite_tools\gdocs_handler.py" (
    echo ERROR: Required file not found: gsuite_tools\gdocs_handler.py
    exit /b 1
)
echo   - gsuite_tools\gdocs_handler.py

if not exist "snowflake_google_docs_complete_setup.sql" (
    echo ERROR: Required file not found: snowflake_google_docs_complete_setup.sql
    exit /b 1
)
echo   - snowflake_google_docs_complete_setup.sql

echo.
echo =========================================
echo Step 1: Upload Python Files to Stage
echo =========================================
echo.

REM Upload Python files
echo Uploading gsuite_tools\__init__.py...
snow stage copy gsuite_tools\__init__.py @TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/ --overwrite --auto-compress false

echo Uploading gsuite_tools\gdocs_handler.py...
snow stage copy gsuite_tools\gdocs_handler.py @TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/ --overwrite --auto-compress false

echo.
echo Python files uploaded successfully
echo.

REM Verify files are uploaded
echo Verifying uploaded files...
snow stage list @TEST.PUBLIC.GSUITE_STAGE/gsuite_tools/

echo.
echo =========================================
echo Step 2: Execute Setup SQL Script
echo =========================================
echo.

REM Execute the setup script
echo Running snowflake_google_docs_complete_setup.sql...
snow sql -f snowflake_google_docs_complete_setup.sql

echo.
echo Setup script executed successfully
echo.

echo =========================================
echo Step 3: Verify Installation
echo =========================================
echo.

REM Verify functions are created
echo Checking created functions...
snow sql -q "SHOW FUNCTIONS LIKE '%%GOOGLE_DOC%%' IN SCHEMA TEST.PUBLIC;"

echo.
echo =========================================
echo Deployment Complete!
echo =========================================
echo.
echo Next steps:
echo 1. Run tests: snow sql -f test_tools.sql
echo 2. Try reading a document:
echo    snow sql -q "SELECT TEST.PUBLIC.READ_GOOGLE_DOC('your-doc-id', TRUE);"
echo.
echo See SNOWFLAKE_SETUP_GUIDE.md for detailed usage instructions.
echo.

pause

