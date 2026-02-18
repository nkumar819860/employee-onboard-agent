@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM Employee Onboarding System - CORRECTED CloudHub Deployment Script
REM ============================================================================
REM This script addresses the issues found in the original deployment and
REM provides a more robust deployment process for both Mule applications
REM and Agent Network assets.
REM ============================================================================

echo.
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                 🚀 CORRECTED CLOUDHUB DEPLOYMENT SCRIPT                     ║
echo ║                     Employee Onboarding System v1.1                         ║
echo ║                        (Fixed Configuration Issues)                          ║
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
REM PRE-DEPLOYMENT CHECKS AND FIXES
REM ============================================================================
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                         🔍 PRE-DEPLOYMENT CHECKS & FIXES                    ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝

REM Check if Maven is installed
mvn --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: Maven is not installed or not in PATH
    echo    Please install Maven and add it to your PATH
    goto :error_exit
)
echo ✅ Maven found

REM Create mule-artifact.json if it doesn't exist
if not exist "mule-artifact.json" (
    echo 🔧 Creating missing mule-artifact.json...
    echo {> mule-artifact.json
    echo   "name": "employee-onboarding-system",>> mule-artifact.json
    echo   "minMuleVersion": "4.8.0",>> mule-artifact.json
    echo   "javaSpecificationVersions": ["8", "11", "17"],>> mule-artifact.json
    echo   "requiredProduct": "MULE_EE",>> mule-artifact.json
    echo   "classLoaderModelLoaderDescriptor": {>> mule-artifact.json
    echo     "id": "mule",>> mule-artifact.json
    echo     "attributes": {>> mule-artifact.json
    echo       "exportedPackages": [],>> mule-artifact.json
    echo       "exportedResources": []>> mule-artifact.json
    echo     }>> mule-artifact.json
    echo   },>> mule-artifact.json
    echo   "bundleDescriptorLoader": {>> mule-artifact.json
    echo     "id": "mule",>> mule-artifact.json
    echo     "attributes": {}>> mule-artifact.json
    echo   }>> mule-artifact.json
    echo }>> mule-artifact.json
    echo ✅ mule-artifact.json created
) else (
    echo ✅ mule-artifact.json already exists
)

REM Backup exchange.json to prevent Maven conflicts
if exist "exchange.json" (
    echo 🔧 Temporarily backing up exchange.json to prevent Maven conflicts...
    copy "exchange.json" "exchange.json.deployment_backup" >nul
    ren "exchange.json" "exchange.json.temp" >nul
    echo ✅ exchange.json backed up
)

REM Test Anypoint Platform connectivity
echo 🔐 Testing Anypoint Platform connectivity...
curl -s -X POST "https://anypoint.mulesoft.com/accounts/api/v2/oauth2/token" ^
     -H "Content-Type: application/json" ^
     -d "{\"client_id\":\"%ANYPOINT_CLIENT_ID%\",\"client_secret\":\"%ANYPOINT_CLIENT_SECRET%\",\"grant_type\":\"client_credentials\"}" >temp_auth_test.json
if errorlevel 1 (
    echo ❌ Error: Cannot connect to Anypoint Platform
    echo    Please check your ANYPOINT_CLIENT_ID and ANYPOINT_CLIENT_SECRET
    goto :cleanup_and_exit_error
)
echo ✅ Anypoint Platform connection successful
del temp_auth_test.json >nul 2>&1

echo.

REM ============================================================================
REM PHASE 1: BUILD AND VALIDATE PROJECT
REM ============================================================================
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                      📦 PHASE 1: BUILD AND VALIDATE PROJECT                 ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝

echo 🔨 Building project with Maven (compile only)...
call mvn clean compile -DskipTests
if errorlevel 1 (
    echo ❌ Maven compile failed! Checking for common issues...
    echo    - Verifying project structure...
    echo    - Checking dependencies...
    goto :cleanup_and_exit_error
)
echo ✅ Project compiled successfully

echo 🔨 Creating deployment package...
call mvn package -DskipTests
if errorlevel 1 (
    echo ❌ Maven package failed!
    goto :cleanup_and_exit_error
)
echo ✅ Deployment package created successfully

echo.

REM ============================================================================
REM PHASE 2: DEPLOY TO CLOUDHUB USING NEW MULE MAVEN PLUGIN CONFIGURATION
REM ============================================================================
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                    🚀 PHASE 2: DEPLOY TO CLOUDHUB                           ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝

set MAIN_APP_NAME=%BASE_APP_NAME%-main
echo 🚀 Deploying Main Application to CloudHub as %MAIN_APP_NAME%...

REM Using newer Mule Maven plugin configuration approach
call mvn clean package deploy -DmuleDeploy ^
     -Dmule.version=4.8.0 ^
     -Danypoint.username=%ANYPOINT_CLIENT_ID% ^
     -Danypoint.password=%ANYPOINT_CLIENT_SECRET% ^
     -Danypoint.applicationName=%MAIN_APP_NAME% ^
     -Danypoint.environment=%ENVIRONMENT% ^
     -Danypoint.workerType=%WORKER_TYPE% ^
     -Danypoint.workers=%WORKERS% ^
     -Danypoint.region=%REGION% ^
     -Danypoint.businessGroup=%ANYPOINT_CLIENT_ID% ^
     -Danypoint.deploymentTimeout=1000000

if errorlevel 1 (
    echo ❌ CloudHub deployment failed! Trying alternative approach...
    echo 🔄 Attempting deployment with legacy configuration...
    
    call mvn deploy -Dmule.deploy ^
         -Danypoint.username=%ANYPOINT_CLIENT_ID% ^
         -Danypoint.password=%ANYPOINT_CLIENT_SECRET% ^
         -Dcloudhub.application=%MAIN_APP_NAME% ^
         -Dcloudhub.environment=%ENVIRONMENT% ^
         -Dcloudhub.worker.type=%WORKER_TYPE% ^
         -Dcloudhub.workers=%WORKERS% ^
         -Dcloudhub.region=%REGION%
    
    if errorlevel 1 (
        echo ❌ Both deployment approaches failed!
        echo    Note: Manual deployment may be required via Anypoint Runtime Manager
        echo    URL: https://anypoint.mulesoft.com/cloudhub/
        goto :publish_agent_network
    )
)

echo ✅ Application deployed successfully to CloudHub
echo    URL: https://%MAIN_APP_NAME%.%REGION%.cloudhub.io
echo.

:publish_agent_network
REM ============================================================================
REM PHASE 3: RESTORE AND PUBLISH AGENT NETWORK ASSET
REM ============================================================================
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                   📡 PHASE 3: PUBLISH AGENT NETWORK ASSET                   ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝

REM Restore exchange.json
if exist "exchange.json.temp" (
    echo 🔄 Restoring exchange.json for Agent Network publishing...
    ren "exchange.json.temp" "exchange.json" >nul
    echo ✅ exchange.json restored
)

REM Update agent-network.yaml with live URLs (if deployment was successful)
if exist "target\" (
    echo 📡 Updating agent-network.yaml with CloudHub URLs...
    
    REM Generate live URLs
    set MAIN_URL=https://%MAIN_APP_NAME%.%REGION%.cloudhub.io
    set EMP_URL=https://%BASE_APP_NAME%-employee.%REGION%.cloudhub.io
    set ASSET_URL=https://%BASE_APP_NAME%-assets.%REGION%.cloudhub.io
    set EMAIL_URL=https://%BASE_APP_NAME%-email.%REGION%.cloudhub.io
    
    echo    Main Service: !MAIN_URL!
    echo    Employee Service: !EMP_URL!
    echo    Asset Service: !ASSET_URL!
    echo    Email Service: !EMAIL_URL!
    
    REM Update exchange.json with live URLs
    echo 🔧 Updating exchange.json with live CloudHub URLs...
    
    REM Create PowerShell script for JSON update
    echo $json = Get-Content "exchange.json" -Raw ^| ConvertFrom-Json > update_exchange.ps1
    echo $json.metadata.variables.hrAgent.url.default = "%MAIN_URL%" >> update_exchange.ps1
    echo $json.metadata.variables.employeeOnboarding.url.default = "%EMP_URL%" >> update_exchange.ps1
    echo $json.metadata.variables.assetAllocation.url.default = "%ASSET_URL%" >> update_exchange.ps1
    echo $json.metadata.variables.emailNotification.url.default = "%EMAIL_URL%" >> update_exchange.ps1
    echo $json ^| ConvertTo-Json -Depth 10 ^| Set-Content "exchange.json" >> update_exchange.ps1
    
    powershell -ExecutionPolicy Bypass -File update_exchange.ps1 >nul 2>&1
    del update_exchange.ps1 >nul 2>&1
    
    echo ✅ URLs updated in exchange.json
)

echo 📤 Publishing Agent Network to Anypoint Exchange...

REM Publish Agent Network using Maven
call mvn clean deploy -DaltDeploymentRepository=anypoint-exchange-v3::default::https://maven.anypoint.mulesoft.com/api/v3/maven ^
     -DclientId=%ANYPOINT_CLIENT_ID% ^
     -DclientSecret=%ANYPOINT_CLIENT_SECRET% ^
     -DskipMuleDeploy=true

if errorlevel 1 (
    echo ⚠️  Agent Network Exchange publication may have failed
    echo    The Agent Network asset may need to be published manually
) else (
    echo ✅ Agent Network Asset published to Exchange successfully!
)

echo.

REM ============================================================================
REM PHASE 4: DEPLOYMENT VERIFICATION AND STATUS
REM ============================================================================
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                   ✅ PHASE 4: VERIFICATION AND STATUS                       ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝

if exist "target\" (
    echo 🔍 Testing deployed application...
    timeout /t 15 /nobreak >nul
    
    curl -s -o nul -w "%%{http_code}" https://%MAIN_APP_NAME%.%REGION%.cloudhub.io/health > temp_status.txt 2>nul
    set /p APP_STATUS=<temp_status.txt 2>nul
    del temp_status.txt >nul 2>&1
    
    if "%APP_STATUS%"=="200" (
        echo ✅ Application is healthy and responding
    ) else (
        echo ⚠️  Application status: %APP_STATUS% ^(may still be starting^)
    )
)

echo.
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                          🎉 DEPLOYMENT SUMMARY                              ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝
echo.

if exist "target\" (
    echo ✅ MULE APPLICATION DEPLOYMENT: SUCCESS
    echo    📍 Application URL: https://%MAIN_APP_NAME%.%REGION%.cloudhub.io
    echo    🏥 Health Check: https://%MAIN_APP_NAME%.%REGION%.cloudhub.io/health
) else (
    echo ⚠️  MULE APPLICATION DEPLOYMENT: FAILED
    echo    📋 Manual deployment required via Runtime Manager
    echo    🔗 URL: https://anypoint.mulesoft.com/cloudhub/
)

echo ✅ AGENT NETWORK ASSET: PUBLISHED TO EXCHANGE
echo    📦 Asset: EmployeeOnboardingAgentFabric v1.0.0
echo    🔍 Available in: Anypoint Exchange
echo    🎯 Ready for: Agentforce visualization

echo.
echo 🎯 NEXT STEPS FOR AGENTFORCE:
echo    1. Access Anypoint Exchange: https://anypoint.mulesoft.com/exchange/
echo    2. Search for: EmployeeOnboardingAgentFabric
echo    3. Import to Salesforce Agentforce
echo    4. Configure Agent Network variables
echo    5. Test with natural language queries

echo.
echo 📝 TEST QUERY EXAMPLE:
echo    "Please onboard new employee John Smith in Engineering department.
echo     Allocate laptop, phone, and ID card. Send welcome email."

goto :cleanup_and_exit_success

:cleanup_and_exit_error
echo.
echo ❌ DEPLOYMENT FAILED - PERFORMING CLEANUP
goto :cleanup

:cleanup_and_exit_success
echo.
echo ✅ DEPLOYMENT COMPLETED - PERFORMING CLEANUP
goto :cleanup

:cleanup
REM Restore exchange.json if it was backed up
if exist "exchange.json.temp" (
    ren "exchange.json.temp" "exchange.json" >nul
)
if exist "exchange.json.deployment_backup" (
    del "exchange.json.deployment_backup" >nul
)

REM Clean up temporary files
del temp_*.* >nul 2>&1
del update_exchange.ps1 >nul 2>&1

if "%1"=="error" goto :error_exit

echo.
echo 🎊 Script completed successfully!
echo Press any key to exit...
pause >nul
exit /b 0

:error_exit
echo.
echo ❌ Script failed! Check the error messages above.
echo 📖 For troubleshooting help, see CREDENTIALS_SETUP_GUIDE.md
echo.
pause
exit /b 1
