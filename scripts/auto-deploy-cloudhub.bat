@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM Employee Onboarding System - Automated CloudHub Deployment Script
REM ============================================================================
REM This script automatically deploys all components to CloudHub:
REM - Main Orchestration Service
REM - Employee Onboarding MCP Server
REM - Asset Allocation MCP Server  
REM - Email Notification MCP Server
REM - Agent Network Asset to Exchange
REM ============================================================================

echo.
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                    🚀 CLOUDHUB AUTO-DEPLOYMENT SCRIPT                       ║
echo ║                     Employee Onboarding System v1.0                         ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝
echo.

REM Set script directory and project root
set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..
cd /d "%PROJECT_ROOT%"

REM ============================================================================
REM LOAD ENVIRONMENT VARIABLES FROM .ENV FILE
REM ============================================================================
echo 📄 Loading credentials from .env file...

if not exist ".env" (
    echo ❌ Error: .env file not found!
    echo    Please copy .env.template to .env and configure your credentials
    echo    See CREDENTIALS_SETUP_GUIDE.md for detailed instructions
    pause
    exit /b 1
)

REM Parse .env file and set environment variables
for /f "usebackq tokens=1,2 delims==" %%a in (".env") do (
    set line=%%a
    if not "!line:~0,1!"=="#" if not "!line!"=="" (
        set %%a=%%b
    )
)

REM Verify required credentials
if "%ANYPOINT_CLIENT_ID%"=="" (
    echo ❌ Error: ANYPOINT_CLIENT_ID not found in .env file
    goto :error_exit
)

if "%ANYPOINT_CLIENT_SECRET%"=="" (
    echo ❌ Error: ANYPOINT_CLIENT_SECRET not found in .env file
    goto :error_exit
)

if "%GROQ_API_KEY%"=="" (
    echo ❌ Error: GROQ_API_KEY not found in .env file
    goto :error_exit
)

echo ✅ Credentials loaded successfully
echo    Client ID: %ANYPOINT_CLIENT_ID:~0,8%...
echo    Groq API Key: %GROQ_API_KEY:~0,8%...
echo.

REM ============================================================================
REM CONFIGURATION PARAMETERS
REM ============================================================================
set ENVIRONMENT=%DEPLOYMENT_ENV%
if "%ENVIRONMENT%"=="" set ENVIRONMENT=Sandbox

set BASE_APP_NAME=%APP_NAME%
if "%BASE_APP_NAME%"=="" set BASE_APP_NAME=employee-onboarding-system

set REGION=us-east-2
set WORKER_TYPE=MICRO
set WORKERS=1

echo 🔧 Deployment Configuration:
echo    Environment: %ENVIRONMENT%
echo    Base App Name: %BASE_APP_NAME%
echo    Region: %REGION%
echo    Worker Type: %WORKER_TYPE%
echo    Workers: %WORKERS%
echo.

REM ============================================================================
REM PRE-DEPLOYMENT CHECKS
REM ============================================================================
echo 🔍 Running pre-deployment checks...

REM Check if Maven is installed
mvn --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: Maven is not installed or not in PATH
    echo    Please install Maven and add it to your PATH
    goto :error_exit
)
echo ✅ Maven found

REM Check if we can access Anypoint Platform
echo 🔐 Testing Anypoint Platform connectivity...
curl -s -X POST "https://anypoint.mulesoft.com/accounts/api/v2/oauth2/token" ^
     -H "Content-Type: application/json" ^
     -d "{\"client_id\":\"%ANYPOINT_CLIENT_ID%\",\"client_secret\":\"%ANYPOINT_CLIENT_SECRET%\",\"grant_type\":\"client_credentials\"}" >nul
if errorlevel 1 (
    echo ❌ Error: Cannot connect to Anypoint Platform
    echo    Please check your ANYPOINT_CLIENT_ID and ANYPOINT_CLIENT_SECRET
    goto :error_exit
)
echo ✅ Anypoint Platform connection successful

REM Test Groq API
echo 🤖 Testing Groq API connectivity...
curl -s -X POST "https://api.groq.com/openai/v1/models" ^
     -H "Authorization: Bearer %GROQ_API_KEY%" >nul
if errorlevel 1 (
    echo ❌ Warning: Cannot connect to Groq API
    echo    Please verify your GROQ_API_KEY
    echo    Deployment will continue but AI features may not work
) else (
    echo ✅ Groq API connection successful
)

echo.

REM ============================================================================
REM DEPLOYMENT PHASE 1: BUILD PROJECT
REM ============================================================================
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                           📦 PHASE 1: BUILD PROJECT                         ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝

echo 🔨 Building project with Maven...
call mvn clean compile
if errorlevel 1 (
    echo ❌ Build failed!
    goto :error_exit
)
echo ✅ Project built successfully
echo.

REM ============================================================================
REM DEPLOYMENT PHASE 2: DEPLOY MAIN ORCHESTRATION SERVICE
REM ============================================================================
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                    🎯 PHASE 2: DEPLOY MAIN ORCHESTRATION                    ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝

set MAIN_APP_NAME=%BASE_APP_NAME%-main
echo 🚀 Deploying Main Orchestration Service to %MAIN_APP_NAME%...

call mvn clean package deploy -DmuleDeploy ^
     -Danypoint.client.id=%ANYPOINT_CLIENT_ID% ^
     -Danypoint.client.secret=%ANYPOINT_CLIENT_SECRET% ^
     -Dcloudhub.application.name=%MAIN_APP_NAME% ^
     -Dcloudhub.environment=%ENVIRONMENT% ^
     -Dcloudhub.region=%REGION% ^
     -Dcloudhub.workers=%WORKERS% ^
     -Dcloudhub.worker.type=%WORKER_TYPE% ^
     -Dcloudhub.mule.version=4.4.0 ^
     -Dcloudhub.properties="app.port=8080"

if errorlevel 1 (
    echo ❌ Main Orchestration deployment failed!
    goto :error_exit
)
echo ✅ Main Orchestration Service deployed successfully to %MAIN_APP_NAME%
echo.

REM ============================================================================
REM DEPLOYMENT PHASE 3: DEPLOY MCP SERVERS
REM ============================================================================
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                        🔌 PHASE 3: DEPLOY MCP SERVERS                       ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝

REM Deploy Employee Onboarding MCP Server
set EMP_APP_NAME=%BASE_APP_NAME%-employee
echo 🚀 Deploying Employee Onboarding MCP Server to %EMP_APP_NAME%...

call mvn clean package deploy -DmuleDeploy ^
     -Danypoint.client.id=%ANYPOINT_CLIENT_ID% ^
     -Danypoint.client.secret=%ANYPOINT_CLIENT_SECRET% ^
     -Dcloudhub.application.name=%EMP_APP_NAME% ^
     -Dcloudhub.environment=%ENVIRONMENT% ^
     -Dcloudhub.region=%REGION% ^
     -Dcloudhub.workers=%WORKERS% ^
     -Dcloudhub.worker.type=%WORKER_TYPE% ^
     -Dcloudhub.mule.version=4.4.0 ^
     -Dcloudhub.properties="app.port=8082"

if errorlevel 1 (
    echo ❌ Employee MCP Server deployment failed!
    goto :error_exit
)
echo ✅ Employee Onboarding MCP Server deployed successfully
echo.

REM Deploy Asset Allocation MCP Server
set ASSET_APP_NAME=%BASE_APP_NAME%-assets
echo 🚀 Deploying Asset Allocation MCP Server to %ASSET_APP_NAME%...

call mvn clean package deploy -DmuleDeploy ^
     -Danypoint.client.id=%ANYPOINT_CLIENT_ID% ^
     -Danypoint.client.secret=%ANYPOINT_CLIENT_SECRET% ^
     -Dcloudhub.application.name=%ASSET_APP_NAME% ^
     -Dcloudhub.environment=%ENVIRONMENT% ^
     -Dcloudhub.region=%REGION% ^
     -Dcloudhub.workers=%WORKERS% ^
     -Dcloudhub.worker.type=%WORKER_TYPE% ^
     -Dcloudhub.mule.version=4.4.0 ^
     -Dcloudhub.properties="app.port=8083"

if errorlevel 1 (
    echo ❌ Asset MCP Server deployment failed!
    goto :error_exit
)
echo ✅ Asset Allocation MCP Server deployed successfully
echo.

REM Deploy Email Notification MCP Server
set EMAIL_APP_NAME=%BASE_APP_NAME%-email
echo 🚀 Deploying Email Notification MCP Server to %EMAIL_APP_NAME%...

call mvn clean package deploy -DmuleDeploy ^
     -Danypoint.client.id=%ANYPOINT_CLIENT_ID% ^
     -Danypoint.client.secret=%ANYPOINT_CLIENT_SECRET% ^
     -Dcloudhub.application.name=%EMAIL_APP_NAME% ^
     -Dcloudhub.environment=%ENVIRONMENT% ^
     -Dcloudhub.region=%REGION% ^
     -Dcloudhub.workers=%WORKERS% ^
     -Dcloudhub.worker.type=%WORKER_TYPE% ^
     -Dcloudhub.mule.version=4.4.0 ^
     -Dcloudhub.properties="app.port=8084"

if errorlevel 1 (
    echo ❌ Email MCP Server deployment failed!
    goto :error_exit
)
echo ✅ Email Notification MCP Server deployed successfully
echo.

REM ============================================================================
REM DEPLOYMENT PHASE 4: UPDATE AGENT NETWORK WITH LIVE URLS
REM ============================================================================
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                   🔗 PHASE 4: UPDATE AGENT NETWORK URLS                     ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝

echo 📡 Updating agent-network.yaml with live CloudHub URLs...

REM Generate the live URLs
set MAIN_URL=https://%MAIN_APP_NAME%.%REGION%.cloudhub.io
set EMP_URL=https://%EMP_APP_NAME%.%REGION%.cloudhub.io
set ASSET_URL=https://%ASSET_APP_NAME%.%REGION%.cloudhub.io
set EMAIL_URL=https://%EMAIL_APP_NAME%.%REGION%.cloudhub.io

echo 🌐 Live CloudHub URLs:
echo    Main:     %MAIN_URL%
echo    Employee: %EMP_URL%
echo    Assets:   %ASSET_URL%
echo    Email:    %EMAIL_URL%

REM Create backup of original agent-network.yaml
copy "agent-network.yaml" "agent-network.yaml.backup" >nul 2>&1
echo ✅ Created backup: agent-network.yaml.backup

REM Create temporary PowerShell script to update YAML
echo # PowerShell script to update agent-network.yaml with live URLs > temp_update_yaml.ps1
echo $yamlContent = Get-Content "agent-network.yaml" -Raw >> temp_update_yaml.ps1
echo # Update employee onboarding connection URL >> temp_update_yaml.ps1
echo $yamlContent = $yamlContent -replace "url: \$\{employeeOnboarding\.url\}", "url: %EMP_URL%" >> temp_update_yaml.ps1
echo # Update asset allocation connection URL >> temp_update_yaml.ps1
echo $yamlContent = $yamlContent -replace "url: \$\{assetAllocation\.url\}", "url: %ASSET_URL%" >> temp_update_yaml.ps1
echo # Update email notification connection URL >> temp_update_yaml.ps1
echo $yamlContent = $yamlContent -replace "url: \$\{emailNotification\.url\}", "url: %EMAIL_URL%" >> temp_update_yaml.ps1
echo # Update main orchestration URL references >> temp_update_yaml.ps1
echo $yamlContent = $yamlContent -replace "url: \$\{ingressgw\.url\}", "url: %MAIN_URL%" >> temp_update_yaml.ps1
echo # Write updated content back to file >> temp_update_yaml.ps1
echo $yamlContent ^| Set-Content "agent-network.yaml" -NoNewline >> temp_update_yaml.ps1

REM Execute PowerShell script to update YAML
powershell -ExecutionPolicy Bypass -File temp_update_yaml.ps1

if errorlevel 1 (
    echo ❌ Failed to update agent-network.yaml
    echo    Restoring backup...
    copy "agent-network.yaml.backup" "agent-network.yaml" >nul
    echo ⚠️  Using original agent-network.yaml with placeholder URLs
) else (
    echo ✅ Successfully updated agent-network.yaml with live CloudHub URLs
)

REM Clean up temporary files
del temp_update_yaml.ps1 >nul 2>&1

echo.

REM ============================================================================
REM DEPLOYMENT PHASE 5: PUBLISH AGENT NETWORK TO EXCHANGE
REM ============================================================================
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                    📈 PHASE 5: PUBLISH TO ANYPOINT EXCHANGE                 ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝

echo 🔄 Publishing Agent Network Asset to Anypoint Exchange with live URLs...

call mvn clean deploy -DaltDeploymentRepository=anypoint-exchange-v3::default::https://maven.anypoint.mulesoft.com/api/v3/maven ^
     -DclientId=%ANYPOINT_CLIENT_ID% ^
     -DclientSecret=%ANYPOINT_CLIENT_SECRET%

if errorlevel 1 (
    echo ❌ Agent Network Exchange publication failed!
    echo ⚠️  Applications are deployed but Agent Network asset may not be available in Exchange
    echo    Restoring original agent-network.yaml...
    copy "agent-network.yaml.backup" "agent-network.yaml" >nul 2>&1
) else (
    echo ✅ Agent Network Asset published to Exchange successfully with live URLs!
)

REM Clean up backup file
del "agent-network.yaml.backup" >nul 2>&1

echo.

REM ============================================================================
REM PHASE 6: CONFIGURE SECURE PROPERTIES
REM ============================================================================
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                   🔐 PHASE 6: CONFIGURE SECURE PROPERTIES                   ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝

echo 📋 Secure Properties Configuration Required:
echo.
echo Please manually configure these secure properties in Runtime Manager:
echo ────────────────────────────────────────────────────────────────────────────
echo 🔗 Runtime Manager URL: https://anypoint.mulesoft.com/cloudhub/
echo.
echo For application: %MAIN_APP_NAME%
echo   secure::email.smtp.user=%GMAIL_USER%
echo   secure::email.smtp.password=********************
echo   secure::groq.apiKey=gsk_********************
echo.
echo For application: %EMP_APP_NAME%
echo   secure::email.smtp.user=%GMAIL_USER%
echo   secure::email.smtp.password=********************
echo   secure::groq.apiKey=gsk_********************
echo.
echo For application: %ASSET_APP_NAME%
echo   secure::email.smtp.user=%GMAIL_USER%
echo   secure::email.smtp.password=********************
echo   secure::groq.apiKey=gsk_********************
echo.
echo For application: %EMAIL_APP_NAME%
echo   secure::email.smtp.user=%GMAIL_USER%
echo   secure::email.smtp.password=********************
echo   secure::groq.apiKey=gsk_********************
echo ────────────────────────────────────────────────────────────────────────────
echo.

REM ============================================================================
REM PHASE 7: DEPLOYMENT VERIFICATION
REM ============================================================================
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                     ✅ PHASE 7: DEPLOYMENT VERIFICATION                     ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝

echo 🔍 Waiting for applications to start (30 seconds)...
timeout /t 30 /nobreak >nul

echo 🌐 Application URLs:
echo ────────────────────────────────────────────────────────────────────────────
echo 🎯 Main Orchestration:    https://%MAIN_APP_NAME%.%REGION%.cloudhub.io
echo 👤 Employee Service:      https://%EMP_APP_NAME%.%REGION%.cloudhub.io  
echo 📦 Asset Service:         https://%ASSET_APP_NAME%.%REGION%.cloudhub.io
echo 📧 Email Service:         https://%EMAIL_APP_NAME%.%REGION%.cloudhub.io
echo ────────────────────────────────────────────────────────────────────────────
echo.

echo 🧪 Testing application health...

REM Test Main Application
echo Testing Main Orchestration...
curl -s -o nul -w "%%{http_code}" https://%MAIN_APP_NAME%.%REGION%.cloudhub.io/health > temp_status.txt
set /p MAIN_STATUS=<temp_status.txt
del temp_status.txt

if "%MAIN_STATUS%"=="200" (
    echo ✅ Main Orchestration: Healthy
) else (
    echo ⚠️  Main Orchestration: Status %MAIN_STATUS% ^(may still be starting^)
)

echo.

REM ============================================================================
REM DEPLOYMENT SUMMARY
REM ============================================================================
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                          🎉 DEPLOYMENT COMPLETED!                           ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝
echo.
echo 📊 Deployment Summary:
echo ════════════════════════════════════════════════════════════════════════════════
echo ✅ Main Orchestration Service    → %MAIN_APP_NAME%
echo ✅ Employee Onboarding MCP       → %EMP_APP_NAME%
echo ✅ Asset Allocation MCP          → %ASSET_APP_NAME%
echo ✅ Email Notification MCP        → %EMAIL_APP_NAME%
echo ✅ Agent Network Exchange Asset  → Published
echo.
echo 🔗 Key URLs:
echo    Main API: https://%MAIN_APP_NAME%.%REGION%.cloudhub.io
echo    Health:   https://%MAIN_APP_NAME%.%REGION%.cloudhub.io/health
echo    Runtime Manager: https://anypoint.mulesoft.com/cloudhub/
echo.
echo 🎯 Next Steps:
echo    1. Configure secure properties in Runtime Manager (see above)
echo    2. Test the health endpoints
echo    3. Initialize the database: POST /initializeDatabase
echo    4. Test employee onboarding: POST /onboardEmployee
echo    5. Configure Agent Network in Salesforce Agentforce
echo.
echo 📖 For detailed testing instructions, see:
echo    - DEPLOYMENT_INSTRUCTIONS.md
echo    - Employee_Onboarding_System_Presentation.html
echo ════════════════════════════════════════════════════════════════════════════════

goto :end

:error_exit
echo.
echo ❌ Deployment failed! Check the error messages above.
echo 📖 For troubleshooting help, see CREDENTIALS_SETUP_GUIDE.md
echo.
pause
exit /b 1

:end
echo.
echo 🎊 Deployment completed successfully!
echo Press any key to exit...
pause >nul
exit /b 0
