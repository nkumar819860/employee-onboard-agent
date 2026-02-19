@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM Employee Onboarding System - Simple CloudHub Deployment Script
REM ============================================================================
REM This script deploys the consolidated Employee Onboarding System to CloudHub
REM ============================================================================

echo.
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                    🚀 SIMPLE CLOUDHUB DEPLOYMENT SCRIPT                     ║
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

echo ✅ Credentials loaded successfully
echo    Client ID: %ANYPOINT_CLIENT_ID:~0,8%...
echo.

REM ============================================================================
REM CONFIGURATION PARAMETERS
REM ============================================================================
set ENVIRONMENT=%DEPLOYMENT_ENV%
if "%ENVIRONMENT%"=="" set ENVIRONMENT=Sandbox

set APP_NAME=%CLOUDHUB_APP_NAME%
if "%APP_NAME%"=="" set APP_NAME=employee-onboarding-system

set REGION=us-east-2
set WORKER_TYPE=MICRO
set WORKERS=1

echo 🔧 Deployment Configuration:
echo    Environment: %ENVIRONMENT%
echo    App Name: %APP_NAME%
echo    Region: %REGION%
echo    Worker Type: %WORKER_TYPE%
echo    Workers: %WORKERS%
echo.

REM ============================================================================
REM DEPLOY TO CLOUDHUB
REM ============================================================================
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                           🚀 DEPLOYING TO CLOUDHUB                          ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝

echo 🔨 Building and deploying application...

call mvn clean package deploy -DmuleDeploy ^
     -Danypoint.client.id=%ANYPOINT_CLIENT_ID% ^
     -Danypoint.client.secret=%ANYPOINT_CLIENT_SECRET% ^
     -Dcloudhub.application.name=%APP_NAME% ^
     -Dcloudhub.environment=%ENVIRONMENT% ^
     -Dcloudhub.region=%REGION% ^
     -Dcloudhub.workers=%WORKERS% ^
     -Dcloudhub.worker.type=%WORKER_TYPE% ^
     -Dcloudhub.mule.version=4.8.0 ^
     -Dcloudhub.properties="app.port=8080,email.smtp.host=smtp.gmail.com,email.smtp.port=587,groq.api.url=https://api.groq.com/openai/v1"

if errorlevel 1 (
    echo ❌ Deployment failed!
    goto :error_exit
)

echo ✅ Application deployed successfully!
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
echo ✅ Application Name: %APP_NAME%
echo ✅ Environment: %ENVIRONMENT%
echo ✅ Region: %REGION%
echo.
echo 🔗 Application URL: https://%APP_NAME%.%REGION%.cloudhub.io
echo.
echo 🎯 Available Endpoints:
echo    Health Check: https://%APP_NAME%.%REGION%.cloudhub.io/health
echo    Initialize DB: https://%APP_NAME%.%REGION%.cloudhub.io/initializeDatabase
echo    Onboard Employee: https://%APP_NAME%.%REGION%.cloudhub.io/onboardEmployee
echo    NLP Processing: https://%APP_NAME%.%REGION%.cloudhub.io/processOnboardingRequest
echo.
echo 🎯 Next Steps:
echo    1. Configure secure properties in Runtime Manager:
echo       - secure::email.smtp.user=%GMAIL_USER%
echo       - secure::email.smtp.password=[YOUR_GMAIL_PASSWORD]
echo       - secure::groq.apiKey=%GROQ_API_KEY%
echo    2. Test the health endpoint
echo    3. Initialize the database
echo    4. Test employee onboarding
echo.
echo 📖 Runtime Manager: https://anypoint.mulesoft.com/cloudhub/
echo ════════════════════════════════════════════════════════════════════════════════

goto :end

:error_exit
echo.
echo ❌ Deployment failed! Check the error messages above.
echo.
pause
exit /b 1

:end
echo.
echo 🎊 Deployment completed successfully!
echo Press any key to exit...
pause >nul
exit /b 0
