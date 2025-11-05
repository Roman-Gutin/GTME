@echo off
REM ============================================================================
REM GTME - Complete Deployment Script (Windows)
REM ============================================================================
REM This script deploys the complete GTME Snowflake Cortex AI Agent
REM Prerequisites:
REM   - Snowflake CLI installed (pip install snowflake-cli-labs)
REM   - .env file configured with credentials
REM   - ACCOUNTADMIN access to Snowflake
REM ============================================================================

setlocal enabledelayedexpansion

REM ============================================================================
REM Step 1: Check Prerequisites
REM ============================================================================
echo ============================================================================
echo Step 1: Checking Prerequisites
echo ============================================================================

REM Check if .env exists
if not exist .env (
    echo [ERROR] .env file not found!
    echo Please copy .env.example to .env and fill in your credentials
    exit /b 1
)
echo [OK] .env file found

REM Check if snow CLI is installed
where snow >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Snowflake CLI not found!
    echo Install with: pip install snowflake-cli-labs
    exit /b 1
)
echo [OK] Snowflake CLI installed

REM Check if Python is installed
where python >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Python not found!
    exit /b 1
)
echo [OK] Python installed

echo.

REM ============================================================================
REM Step 2: Setup Snowflake Infrastructure
REM ============================================================================
echo ============================================================================
echo Step 2: Setting Up Snowflake Infrastructure
echo ============================================================================

echo [WARNING] This step requires ACCOUNTADMIN role
echo Please update deployment/setup_snowflake.sql with your username (line 93)
pause

REM Run setup SQL
snow sql -f deployment/setup_snowflake.sql

echo [OK] Snowflake infrastructure created
echo.
echo [IMPORTANT] Copy the PAT token from the output above to your .env file as SNOWFLAKE_PAT
pause

echo.

REM ============================================================================
REM Step 3: Setup Google OAuth
REM ============================================================================
echo ============================================================================
echo Step 3: Google OAuth Setup
echo ============================================================================

set /p oauth_done="Have you already created the OAuth secret in Snowflake? (y/n): "

if /i not "%oauth_done%"=="y" (
    echo [INFO] Getting OAuth refresh token...
    echo.
    echo 1. Running get_oauth_url.py to show instructions...
    python tools\gsuite\get_oauth_url.py
    echo.
    set /p refresh_token="2. Enter the refresh token you received: "
    echo.
    echo 3. Creating OAuth secret in Snowflake...
    python tools\gsuite\create_oauth_secret.py %refresh_token%
    echo [OK] OAuth secret created
) else (
    echo [OK] OAuth secret already configured
)

echo.

REM ============================================================================
REM Step 4: Deploy Google Workspace Tools
REM ============================================================================
echo ============================================================================
echo Step 4: Deploying Google Workspace Tools
echo ============================================================================

echo [INFO] Uploading Python handlers to Snowflake stage...
python deployment\deploy_gsuite.py
echo [OK] Handlers uploaded

echo.
echo [INFO] Creating UDFs...
python deployment\create_udfs.py
echo [OK] UDFs created

echo.

REM ============================================================================
REM Step 5: Create Agent
REM ============================================================================
echo ============================================================================
echo Step 5: Creating GTME Cortex AI Agent
echo ============================================================================

python agent\create_agent.py --force

echo [OK] Agent created successfully!

echo.

REM ============================================================================
REM Deployment Complete!
REM ============================================================================
echo ============================================================================
echo DEPLOYMENT COMPLETE!
echo ============================================================================
echo.
echo Your GTME Cortex AI Agent is ready!
echo.
echo Verify deployment (optional):
echo   snow sql -f deployment\test_deployment.sql
echo.
echo Next Steps:
echo   1. Go to Snowsight: https://app.snowflake.com/
echo   2. Navigate to: AI ^& ML -^> Cortex -^> Agents
echo   3. Select: GTM_ENGINEER_AGENT
echo   4. Start chatting!
echo.
echo Try these commands:
echo   - Create a Google Doc called 'Meeting Notes'
echo   - Create a Google Sheet called 'Sales Data' with headers
echo   - Create a folder in Google Drive called 'Q1 Reports'
echo.
echo ============================================================================

pause

