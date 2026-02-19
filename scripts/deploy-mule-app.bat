@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM Mule Application CloudHub Deployment Script
REM ============================================================================

echo.
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                    🚀 MULE APP CLOUDHUB DEPLOYMENT                          ║
echo ║                     Employee Onboarding System v1.0                         ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝
echo.

REM Load environment variables from .env file
echo 📄 Loading credentials from .env file...

if not exist ".env" (
    echo ❌ Error: .env file not found!
    pause
    exit /b 1
)

for /f "usebackq tokens=1,2 delims==" %%a in (".env") do (
    set line=%%a
    if not "!line:~0,1!"=="#" if not "!line!"=="" (
        set %%a=%%b
    )
)

if "%ANYPOINT_CLIENT_ID%"=="" (
    echo ❌ Error: ANYPOINT_CLIENT_ID not found in .env file
    exit /b 1
)

if "%ANYPOINT_CLIENT_SECRET%"=="" (
    echo ❌ Error: ANYPOINT_CLIENT_SECRET not found in .env file
    exit /b 1
)

echo ✅ Credentials loaded successfully
echo.

REM Configuration
set APP_NAME=%CLOUDHUB_APP_NAME%
if "%APP_NAME%"=="" set APP_NAME=employee-onboarding-system
set ENVIRONMENT=Sandbox
set REGION=us-east-2

echo 🔧 Deployment Configuration:
echo    App Name: %APP_NAME%
echo    Environment: %ENVIRONMENT%
echo    Region: %REGION%
echo.

echo 🚀 Deploying Mule application to CloudHub...

REM Use the Mule Maven plugin to deploy
call mvn clean package deploy -DmuleDeploy ^
    -Danypoint.client.id=%ANYPOINT_CLIENT_ID% ^
    -Danypoint.client.secret=%ANYPOINT_CLIENT_SECRET% ^
    -Dcloudhub.application.name=%APP_NAME% ^
    -Dcloudhub.environment=%ENVIRONMENT% ^
    -Dcloudhub.region=%REGION% ^
    -Dcloudhub.workers=1 ^
    -Dcloudhub.worker.type=MICRO ^
    -Dcloudhub.mule.version=4.8.0 ^
    -Dcloudhub.properties="app.port=8080,email.smtp.host=smtp.gmail.com,email.smtp.port=587"

if errorlevel 1 (
    echo ❌ Deployment failed!
    pause
    exit /b 1
)

echo ✅ Application deployed successfully!
echo.
echo 🌐 Application URL: https://%APP_NAME%.%REGION%.cloudhub.io
echo 🔗 Health Check: https://%APP_NAME%.%REGION%.cloudhub.io/health
echo.
echo 📋 Available Endpoints:
echo    - GET  /health
echo    - POST /initializeDatabase
echo    - POST /onboardEmployee
echo    - POST /processOnboardingRequest
echo    - GET  /getOnboardingStatus/{employeeId}
echo.
echo 🎯 Next: Configure secure properties in Runtime Manager
echo    - secure::email.smtp.user
echo    - secure::email.smtp.password
echo    - secure::groq.apiKey
echo.

pause
