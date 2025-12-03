@echo off
REM ============================================================================
REM GTME - GTM Engineer Agent Deployment Script (Windows)
REM ============================================================================
setlocal enabledelayedexpansion

echo.
echo === GTME Deployment ===
echo.

REM Check .env
if not exist .env (
    echo [ERROR] .env not found. Run: copy .env.example .env
    exit /b 1
)

REM Load environment variables
for /f "tokens=1,2 delims==" %%a in (.env) do (
    set "%%a=%%b"
)

REM Check prerequisites
where snow >nul 2>nul || (echo [ERROR] Snow CLI not found. Run: pip install snowflake-cli-labs && exit /b 1)
where python >nul 2>nul || (echo [ERROR] Python not found && exit /b 1)

if "%SNOWFLAKE_ACCOUNT%"=="" (echo [ERROR] SNOWFLAKE_ACCOUNT not set && exit /b 1)
if "%SNOWFLAKE_PAT%"=="" (echo [ERROR] SNOWFLAKE_PAT not set && exit /b 1)

echo [OK] Prerequisites OK
echo.

REM Deploy Salesforce
if not "%DEPLOY_SALESFORCE%"=="false" (
    echo === Deploying Salesforce Tools ===
    snow sql -f tools\salesforce\snowflake_setup.sql
    snow sql -f tools\salesforce\deploy_opportunity_crud.sql
    snow sql -f tools\salesforce\deploy_account_crud.sql
    echo [OK] Salesforce UDFs deployed
    echo.
)

REM Deploy Web Search
if not "%DEPLOY_WEB_SEARCH%"=="false" (
    echo === Deploying Web Search Tools ===
    snow sql -f tools\web_search\perplexity\deploy_perplexity.sql
    snow sql -f tools\web_search\parallel_web_systems\deploy_udfs.sql
    snow sql -f tools\web_search\parallel_web_systems\deploy_udfs2.sql
    snow sql -f tools\web_search\parallel_web_systems\deploy_manage_proc.sql
    echo [OK] Web Search UDFs deployed
    echo.
)

REM Create Agent
echo === Creating Cortex AI Agent ===
python agent\build_agent.py gtm_engineer --delete
echo [OK] Agent created
echo.

REM Done
echo === Deployment Complete! ===
echo.
echo Next Steps:
echo   1. Go to https://app.snowflake.com/
echo   2. Navigate to: AI ^& ML -^> Cortex -^> Agents
echo   3. Select: GTM_ENGINEER_AGENT
echo   4. Start chatting!
echo.
echo [OK] Done!
pause

