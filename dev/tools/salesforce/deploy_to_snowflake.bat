@echo off
REM Salesforce Wrapper - Snowflake Deployment Script (Windows)
REM This script uploads Python files to Snowflake stage

echo ==========================================
echo Salesforce Wrapper - Snowflake Deployment
echo ==========================================
echo.
echo This script will:
echo   1. Upload Python files to Snowflake stage
echo   2. Verify uploaded files
echo.
echo Prerequisites:
echo   - Snow CLI installed (pip install snowflake-cli-labs)
echo   - Snowflake connection configured
echo   - Stage TEST.PUBLIC.SALESFORCE_STAGE created
echo.

REM Check if snow CLI is installed
where snow >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Snow CLI not found. Install with: pip install snowflake-cli-labs
    exit /b 1
)

echo =========================================
echo Step 1: Upload Python Files to Stage
echo =========================================
echo.

REM Upload Python files
echo Uploading salesforce_wrapper\__init__.py...
snow stage copy salesforce_wrapper\__init__.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false

echo Uploading salesforce_wrapper\auth.py...
snow stage copy salesforce_wrapper\auth.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false

echo Uploading salesforce_wrapper\data_api.py...
snow stage copy salesforce_wrapper\data_api.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false

echo Uploading salesforce_wrapper\metadata_api.py...
snow stage copy salesforce_wrapper\metadata_api.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false

echo Uploading salesforce_wrapper\discovery.py...
snow stage copy salesforce_wrapper\discovery.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false

echo Uploading salesforce_wrapper\shortcuts.py...
snow stage copy salesforce_wrapper\shortcuts.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false

echo Uploading salesforce_wrapper\field_creators.py...
snow stage copy salesforce_wrapper\field_creators.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false

echo Uploading salesforce_wrapper\sf_handler.py...
snow stage copy salesforce_wrapper\sf_handler.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false

echo Uploading salesforce_wrapper\utils.py...
snow stage copy salesforce_wrapper\utils.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false

echo Uploading salesforce_wrapper\constants.py...
snow stage copy salesforce_wrapper\constants.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false

echo Uploading salesforce_wrapper\exceptions.py...
snow stage copy salesforce_wrapper\exceptions.py @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ --overwrite --auto-compress false

echo.
echo Python files uploaded successfully
echo.

REM Verify files are uploaded
echo Verifying uploaded files...
snow stage list @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/

echo.
echo =========================================
echo Deployment Complete!
echo =========================================
echo.
echo Next steps:
echo   1. Review SNOWFLAKE_INTEGRATION.md for setup instructions
echo   2. Create network rules and external access integration
echo   3. Create secret with Salesforce credentials
echo   4. Deploy UDF functions using provided SQL scripts
echo.
echo Test with:
echo   SELECT TEST.PUBLIC.SALESFORCE_DISCOVER_ORG();
echo.

pause

