@echo off
REM ============================================================================
REM GTME - Master Deployment Script (Windows)
REM ============================================================================
REM Deploys Snowflake Cortex AI Agent with Google Workspace and/or Salesforce
REM ============================================================================

setlocal enabledelayedexpansion

echo.
echo ========================================
echo GTME - Deployment Starting
echo ========================================
echo.

REM ============================================================================
REM STEP 0: Prerequisites Check
REM ============================================================================
echo ========================================
echo STEP 0: Checking Prerequisites
echo ========================================
echo.

REM Check if .env exists
if not exist .env (
    echo [ERROR] .env file not found!
    echo Please copy .env.example to .env and fill in your credentials:
    echo   copy .env.example .env
    exit /b 1
)

REM Load environment variables
for /f "tokens=1,2 delims==" %%a in (.env) do (
    set "%%a=%%b"
)

REM Check Snow CLI
where snow >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Snow CLI not found!
    echo Please install: pip install snowflake-cli-labs
    exit /b 1
)
echo [OK] Snow CLI installed

REM Check Python
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python not found!
    exit /b 1
)
echo [OK] Python found

REM Check required environment variables
if "%SNOWFLAKE_ACCOUNT%"=="YOUR_ACCOUNT_ID" (
    echo [ERROR] SNOWFLAKE_ACCOUNT not set in .env
    exit /b 1
)

REM Determine what to deploy
if not defined DEPLOY_GOOGLE_WORKSPACE set DEPLOY_GOOGLE_WORKSPACE=true
if not defined DEPLOY_SALESFORCE set DEPLOY_SALESFORCE=true

echo.
echo Deployment Configuration:
echo   - Google Workspace: %DEPLOY_GOOGLE_WORKSPACE%
echo   - Salesforce: %DEPLOY_SALESFORCE%
echo.

if "%DEPLOY_GOOGLE_WORKSPACE%"=="false" if "%DEPLOY_SALESFORCE%"=="false" (
    echo [ERROR] Both integrations disabled!
    exit /b 1
)

REM ============================================================================
REM STEP 1: Snowflake Infrastructure Setup
REM ============================================================================
echo.
echo ========================================
echo STEP 1: Setting Up Snowflake Infrastructure
echo ========================================
echo.

echo Creating service user, role, database, warehouse...
snow sql -f deployment\setup_snowflake.sql

if %errorlevel% neq 0 (
    echo [ERROR] Snowflake setup failed
    exit /b 1
)

echo [OK] Snowflake infrastructure created
echo.
echo [WARNING] IMPORTANT: Copy the PAT token from above and add to .env as SNOWFLAKE_PAT
echo.
pause

REM Reload .env to get PAT
for /f "tokens=1,2 delims==" %%a in (.env) do (
    set "%%a=%%b"
)

if "%SNOWFLAKE_PAT%"=="YOUR_PERSONAL_ACCESS_TOKEN" (
    echo [ERROR] SNOWFLAKE_PAT not set in .env
    exit /b 1
)

REM ============================================================================
REM STEP 2: Google Workspace Deployment (Optional)
REM ============================================================================
if "%DEPLOY_GOOGLE_WORKSPACE%"=="true" (
    echo.
    echo ========================================
    echo STEP 2: Deploying Google Workspace Tools
    echo ========================================
    echo.
    
    REM Check credentials
    if "%GOOGLE_CLIENT_ID%"=="your-client-id.apps.googleusercontent.com" (
        echo [ERROR] GOOGLE_CLIENT_ID not set in .env
        exit /b 1
    )
    
    REM Get OAuth refresh token
    echo Getting Google OAuth refresh token...
    echo [WARNING] A browser window will open. Please authorize the application.
    python tools\gsuite\get_oauth_url.py
    
    echo.
    set /p REFRESH_TOKEN="Enter the refresh token from the browser: "
    
    if "!REFRESH_TOKEN!"=="" (
        echo [ERROR] No refresh token provided
        exit /b 1
    )
    
    REM Create OAuth secret
    echo Creating OAuth secret in Snowflake...
    python tools\gsuite\create_oauth_secret.py "!REFRESH_TOKEN!"
    
    REM Deploy handlers
    echo Uploading Python handlers to Snowflake stage...
    python deployment\deploy_gsuite.py
    
    REM Create UDFs
    echo Creating Google Workspace UDFs...
    python deployment\create_udfs.py
    
    echo [OK] Google Workspace tools deployed (22 tools)
) else (
    echo.
    echo [WARNING] Skipping Google Workspace deployment (DEPLOY_GOOGLE_WORKSPACE=false)
)

REM ============================================================================
REM STEP 3: Salesforce Deployment (Optional)
REM ============================================================================
if "%DEPLOY_SALESFORCE%"=="true" (
    echo.
    echo ========================================
    echo STEP 3: Deploying Salesforce Tools
    echo ========================================
    echo.
    
    REM Check credentials
    if "%SALESFORCE_USERNAME%"=="your-username@salesforce.com" (
        echo [ERROR] SALESFORCE_USERNAME not set in .env
        exit /b 1
    )
    
    REM Run Salesforce deployment
    echo Running Salesforce deployment script...
    cd tools\salesforce
    call deploy_to_snowflake.bat
    cd ..\..
    
    REM Update secrets with credentials from .env
    echo Updating Salesforce secrets...
    snow sql -q "ALTER SECRET AGENTS_DEMO.PUBLIC.salesforce_username SET SECRET_STRING = '%SALESFORCE_USERNAME%';"
    snow sql -q "ALTER SECRET AGENTS_DEMO.PUBLIC.salesforce_password SET SECRET_STRING = '%SALESFORCE_PASSWORD%';"
    snow sql -q "ALTER SECRET AGENTS_DEMO.PUBLIC.salesforce_token SET SECRET_STRING = '%SALESFORCE_SECURITY_TOKEN%';"
    
    echo [OK] Salesforce tools deployed (11 tools)
) else (
    echo.
    echo [WARNING] Skipping Salesforce deployment (DEPLOY_SALESFORCE=false)
)

REM ============================================================================
REM STEP 4: Create Agent
REM ============================================================================
echo.
echo ========================================
echo STEP 4: Creating Cortex AI Agent
echo ========================================
echo.

REM Determine agent configuration
set AGENT_CONFIG=gtm_engineer
set TOOL_COUNT=33

if "%DEPLOY_GOOGLE_WORKSPACE%"=="true" if "%DEPLOY_SALESFORCE%"=="false" (
    set AGENT_CONFIG=minimal
    set TOOL_COUNT=22
)

if "%DEPLOY_GOOGLE_WORKSPACE%"=="false" if "%DEPLOY_SALESFORCE%"=="true" (
    set AGENT_CONFIG=salesforce
    set TOOL_COUNT=11
)

echo Creating agent with configuration: %AGENT_CONFIG% (%TOOL_COUNT% tools)
python agent\create_agent.py --config %AGENT_CONFIG%

echo [OK] Agent created: %AGENT_NAME%

REM ============================================================================
REM STEP 5: Verification
REM ============================================================================
echo.
echo ========================================
echo STEP 5: Deployment Verification
echo ========================================
echo.

echo Running verification tests...
snow sql -f deployment\test_deployment.sql

REM ============================================================================
REM DEPLOYMENT COMPLETE
REM ============================================================================
echo.
echo ========================================
echo DEPLOYMENT COMPLETE!
echo ========================================
echo.

echo Your GTME agent is ready!
echo.
echo Deployment Summary:
echo   - Agent Name: %AGENT_NAME%
echo   - Total Tools: %TOOL_COUNT%
if "%DEPLOY_GOOGLE_WORKSPACE%"=="true" echo   - Google Workspace: [OK] 22 tools
if "%DEPLOY_SALESFORCE%"=="true" echo   - Salesforce: [OK] 11 tools

echo.
echo Next Steps:
echo   1. Go to Snowsight: https://app.snowflake.com/
echo   2. Navigate to: AI ^& ML -^> Cortex -^> Agents
echo   3. Select: %AGENT_NAME%
echo   4. Start chatting!

echo.
echo Run Tests (Optional):
if "%DEPLOY_GOOGLE_WORKSPACE%"=="true" echo   Google Workspace: snow sql -f deployment\test_tools.sql
if "%DEPLOY_SALESFORCE%"=="true" echo   Salesforce: snow sql -f tools\salesforce\test_sfdc_tools.sql

echo.
echo [OK] Deployment completed successfully!
pause

