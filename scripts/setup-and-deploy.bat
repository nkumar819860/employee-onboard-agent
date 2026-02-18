@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM Employee Onboarding System - Complete Setup and Deployment Script
REM ============================================================================
REM This script helps you set up credentials and deploy everything in one go
REM ============================================================================

echo.
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║              🚀 EMPLOYEE ONBOARDING SYSTEM - COMPLETE SETUP                 ║
echo ║                      Setup + Deploy + Configure                             ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝
echo.

REM Set script directory and project root
set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..
cd /d "%PROJECT_ROOT%"

REM ============================================================================
REM STEP 1: CHECK IF .ENV EXISTS
REM ============================================================================
echo 🔍 Checking environment configuration...

if exist ".env" (
    echo ✅ Found existing .env file
    set /p OVERWRITE="Do you want to reconfigure credentials? (y/N): "
    if /i "!OVERWRITE!"=="y" goto :configure_env
    goto :check_credentials
) else (
    echo ⚠️  No .env file found, creating one...
    goto :configure_env
)

:configure_env
echo.
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                        🔐 CREDENTIAL CONFIGURATION                           ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝

REM Copy template if needed
if not exist ".env" (
    if exist ".env.template" (
        copy ".env.template" ".env" >nul
        echo ✅ Created .env from template
    ) else (
        echo ❌ Error: .env.template not found!
        goto :error_exit
    )
)

echo.
echo 📝 Please provide your credentials:
echo    (Leave blank to keep existing values)
echo.

REM Load existing values if they exist
call :load_existing_env

REM Get Anypoint Platform credentials
echo 🏢 Anypoint Platform Credentials:
echo    Get these from: https://anypoint.mulesoft.com → Access Management → Connected Apps
echo.
set /p NEW_CLIENT_ID="Client ID [%ANYPOINT_CLIENT_ID%]: "
if not "!NEW_CLIENT_ID!"=="" set ANYPOINT_CLIENT_ID=!NEW_CLIENT_ID!

set /p NEW_CLIENT_SECRET="Client Secret [%ANYPOINT_CLIENT_SECRET:~0,8%***]: "
if not "!NEW_CLIENT_SECRET!"=="" set ANYPOINT_CLIENT_SECRET=!NEW_CLIENT_SECRET!

echo.
echo 🤖 Groq AI Credentials:
echo    Get API key from: https://console.groq.com → API Keys
echo.
set /p NEW_GROQ_KEY="Groq API Key [%GROQ_API_KEY:~0,8%***]: "
if not "!NEW_GROQ_KEY!"=="" set GROQ_API_KEY=!NEW_GROQ_KEY!

echo.
echo 📧 Email Configuration:
echo    Generate app password from: Google Account → Security → App passwords
echo.
set /p NEW_GMAIL_USER="Gmail Address [%GMAIL_USER%]: "
if not "!NEW_GMAIL_USER!"=="" set GMAIL_USER=!NEW_GMAIL_USER!

set /p NEW_GMAIL_PASSWORD="Gmail App Password [%GMAIL_PASSWORD:~0,4%***]: "
if not "!NEW_GMAIL_PASSWORD!"=="" set GMAIL_PASSWORD=!NEW_GMAIL_PASSWORD!

echo.
echo 🚀 Deployment Configuration:
set /p NEW_ENV="Target Environment (Sandbox/Production) [%DEPLOYMENT_ENV%]: "
if not "!NEW_ENV!"=="" set DEPLOYMENT_ENV=!NEW_ENV!

set /p NEW_APP_NAME="Application Base Name [%APP_NAME%]: "
if not "!NEW_APP_NAME!"=="" set APP_NAME=!NEW_APP_NAME!

REM Write updated .env file
call :write_env_file

echo ✅ Credentials configured successfully!

:check_credentials
echo.
echo 🔍 Validating credentials...

REM Load current .env values
call :load_existing_env

REM Validate required credentials
if "%ANYPOINT_CLIENT_ID%"=="" (
    echo ❌ Error: Missing Anypoint Client ID
    goto :configure_env
)

if "%ANYPOINT_CLIENT_SECRET%"=="" (
    echo ❌ Error: Missing Anypoint Client Secret
    goto :configure_env
)

if "%GROQ_API_KEY%"=="" (
    echo ❌ Error: Missing Groq API Key
    goto :configure_env
)

echo ✅ All required credentials found!

echo.
echo 📋 Configuration Summary:
echo ════════════════════════════════════════════════════════════════════════════════
echo    Environment: %DEPLOYMENT_ENV%
echo    App Name: %APP_NAME%
echo    Email: %GMAIL_USER%
echo    Client ID: %ANYPOINT_CLIENT_ID:~0,12%...
echo    Groq Key: %GROQ_API_KEY:~0,12%...
echo ════════════════════════════════════════════════════════════════════════════════

echo.
set /p PROCEED="Proceed with deployment? (Y/n): "
if /i "!PROCEED!"=="n" goto :end

REM ============================================================================
REM STEP 2: RUN AUTOMATED DEPLOYMENT
REM ============================================================================
echo.
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                           🚀 STARTING DEPLOYMENT                            ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝

echo 🔄 Launching automated deployment script...
echo.

call "%SCRIPT_DIR%auto-deploy-cloudhub.bat"

if errorlevel 1 (
    echo ❌ Deployment failed!
    goto :error_exit
)

echo.
echo 🎊 Setup and deployment completed successfully!
goto :end

REM ============================================================================
REM HELPER FUNCTIONS
REM ============================================================================

:load_existing_env
if exist ".env" (
    for /f "usebackq tokens=1,2 delims==" %%a in (".env") do (
        set line=%%a
        if not "!line:~0,1!"=="#" if not "!line!"=="" (
            set %%a=%%b
        )
    )
)
exit /b

:write_env_file
echo # 🔐 Environment Variables for Employee Onboarding System > ".env"
echo # Generated by setup script on %date% %time% >> ".env"
echo. >> ".env"
echo # ============================================================================= >> ".env"
echo # ANYPOINT PLATFORM CREDENTIALS >> ".env"
echo # ============================================================================= >> ".env"
echo ANYPOINT_CLIENT_ID=%ANYPOINT_CLIENT_ID% >> ".env"
echo ANYPOINT_CLIENT_SECRET=%ANYPOINT_CLIENT_SECRET% >> ".env"
echo. >> ".env"
echo # ============================================================================= >> ".env"
echo # GROQ AI CREDENTIALS >> ".env"
echo # ============================================================================= >> ".env"
echo GROQ_API_KEY=%GROQ_API_KEY% >> ".env"
echo. >> ".env"
echo # ============================================================================= >> ".env"
echo # EMAIL CONFIGURATION >> ".env"
echo # ============================================================================= >> ".env"
echo GMAIL_USER=%GMAIL_USER% >> ".env"
echo GMAIL_PASSWORD=%GMAIL_PASSWORD% >> ".env"
echo. >> ".env"
echo # ============================================================================= >> ".env"
echo # DEPLOYMENT CONFIGURATION >> ".env"
echo # ============================================================================= >> ".env"
if "%DEPLOYMENT_ENV%"=="" set DEPLOYMENT_ENV=Sandbox
if "%APP_NAME%"=="" set APP_NAME=employee-onboarding-system
echo DEPLOYMENT_ENV=%DEPLOYMENT_ENV% >> ".env"
echo APP_NAME=%APP_NAME% >> ".env"
exit /b

:error_exit
echo.
echo ❌ Setup failed! Check the error messages above.
echo 📖 For help, see CREDENTIALS_SETUP_GUIDE.md
echo.
pause
exit /b 1

:end
echo.
echo 📖 Next steps:
echo    1. Configure secure properties in Runtime Manager
echo    2. Test your deployed applications
echo    3. Set up Agent Network in Salesforce Agentforce
echo.
echo 📚 Documentation:
echo    - DEPLOYMENT_INSTRUCTIONS.md
echo    - Employee_Onboarding_System_Presentation.html
echo    - CREDENTIALS_SETUP_GUIDE.md
echo.
echo Press any key to exit...
pause >nul
exit /b 0
