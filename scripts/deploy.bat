@echo off
setlocal enabledelayedexpansion

REM Employee Onboarding System - Deployment Script for Windows
REM This script handles deployment to different environments

REM Colors for output (Windows doesn't support ANSI colors in basic cmd, but we'll use echo for clarity)
set "GREEN=SUCCESS:"
set "RED=ERROR:"
set "YELLOW=INFO:"
set "BLUE=STEP:"

REM Default values
set "ENVIRONMENT=Sandbox"
set "WORKER_TYPE=MICRO"
set "WORKERS=1"
set "APPLICATION_NAME=employee-onboarding-system"
set "LOCAL_DEPLOY=false"
set "PUBLISH_EXCHANGE=false"
set "USERNAME="
set "PASSWORD="
set "CLIENT_ID="
set "CLIENT_SECRET="

REM Function to display usage
:usage
echo.
echo Usage: %0 [OPTIONS]
echo.
echo Options:
echo   -e, --environment     Target environment (Sandbox, Production) [default: Sandbox]
echo   -u, --username        Anypoint Platform username
echo   -p, --password        Anypoint Platform password
echo   --client-id           Connected App client ID (preferred for automation)
echo   --client-secret       Connected App client secret
echo   -a, --app-name        Application name [default: employee-onboarding-system]
echo   -w, --worker-type     Worker type (MICRO, SMALL, MEDIUM, LARGE) [default: MICRO]
echo   -n, --workers         Number of workers [default: 1]
echo   -l, --local           Deploy locally using Mule runtime
echo   --publish-exchange    Automatically publish to Anypoint Exchange
echo   -h, --help            Display this help message
echo.
echo Authentication Methods:
echo   1. Connected App (Recommended for automation):
echo      %0 --client-id ^<id^> --client-secret ^<secret^> -e Production
echo.
echo   2. Username/Password:
echo      %0 -u ^<username^> -p ^<password^> -e Production
echo.
echo Examples:
echo   %0 -l                                           # Deploy locally
echo   %0 -u user -p pass -e Production               # Deploy with username/password
echo   %0 --client-id abc --client-secret xyz         # Deploy with Connected App
echo   %0 -u user -p pass -w SMALL -n 2               # Deploy with SMALL workers
echo   %0 -u user -p pass --publish-exchange          # Deploy and publish to Exchange
echo.
echo CloudHub Setup Required:
echo   1. Create Connected App in Anypoint Platform → Access Management → Connected Apps
echo   2. Grant scopes: Runtime Manager Deploy, Exchange Contributor
echo   3. Configure secure properties in Runtime Manager:
echo      - secure::email.smtp.user
echo      - secure::email.smtp.password
echo      - secure::openai.apiKey
exit /b 0

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :check_prerequisites
if "%~1"=="-h" goto :usage
if "%~1"=="--help" goto :usage
if "%~1"=="-l" set "LOCAL_DEPLOY=true" & shift & goto :parse_args
if "%~1"=="--local" set "LOCAL_DEPLOY=true" & shift & goto :parse_args
if "%~1"=="--publish-exchange" set "PUBLISH_EXCHANGE=true" & shift & goto :parse_args
if "%~1"=="-e" set "ENVIRONMENT=%~2" & shift & shift & goto :parse_args
if "%~1"=="--environment" set "ENVIRONMENT=%~2" & shift & shift & goto :parse_args
if "%~1"=="-u" set "USERNAME=%~2" & shift & shift & goto :parse_args
if "%~1"=="--username" set "USERNAME=%~2" & shift & shift & goto :parse_args
if "%~1"=="-p" set "PASSWORD=%~2" & shift & shift & goto :parse_args
if "%~1"=="--password" set "PASSWORD=%~2" & shift & shift & goto :parse_args
if "%~1"=="--client-id" set "CLIENT_ID=%~2" & shift & shift & goto :parse_args
if "%~1"=="--client-secret" set "CLIENT_SECRET=%~2" & shift & shift & goto :parse_args
if "%~1"=="-a" set "APPLICATION_NAME=%~2" & shift & shift & goto :parse_args
if "%~1"=="--app-name" set "APPLICATION_NAME=%~2" & shift & shift & goto :parse_args
if "%~1"=="-w" set "WORKER_TYPE=%~2" & shift & shift & goto :parse_args
if "%~1"=="--worker-type" set "WORKER_TYPE=%~2" & shift & shift & goto :parse_args
if "%~1"=="-n" set "WORKERS=%~2" & shift & shift & goto :parse_args
if "%~1"=="--workers" set "WORKERS=%~2" & shift & shift & goto :parse_args
echo %RED% Unknown option: %~1
call :usage
exit /b 1

:check_prerequisites
echo.
echo %GREEN% Employee Onboarding System - Deployment Script
echo =================================================
echo.
echo %BLUE% Checking prerequisites...

REM Check Java
java -version >nul 2>&1
if !errorlevel! neq 0 (
    echo %RED% Java is not installed or not in PATH
    exit /b 1
)

REM Check Maven
mvn -version >nul 2>&1
if !errorlevel! neq 0 (
    echo %RED% Maven is not installed or not in PATH
    exit /b 1
)

REM Check if pom.xml exists
if not exist "pom.xml" (
    echo %RED% pom.xml not found. Please run from project root directory
    exit /b 1
)

echo %GREEN% Prerequisites check passed
echo.

:build_application
echo %BLUE% Building application...
call mvn clean package -DskipTests

if !errorlevel! neq 0 (
    echo %RED% Build failed
    exit /b 1
)

echo %GREEN% Build successful
echo.

:main_deployment
if "%LOCAL_DEPLOY%"=="true" goto :deploy_local

REM Validate CloudHub deployment parameters
if "%CLIENT_ID%"=="" if "%USERNAME%"=="" (
    echo %RED% Either Connected App credentials (--client-id --client-secret) or username/password (-u -p) are required for CloudHub deployment
    echo Use --client-id ^<id^> --client-secret ^<secret^> for Connected App authentication
    echo Or use -u ^<username^> -p ^<password^> for username/password authentication
    echo Or deploy locally with -l
    exit /b 1
)

if not "%CLIENT_ID%"=="" if "%CLIENT_SECRET%"=="" (
    echo %RED% Client secret is required when using client ID
    exit /b 1
)

if not "%USERNAME%"=="" if "%PASSWORD%"=="" (
    echo %RED% Password is required when using username
    exit /b 1
)

goto :deploy_cloudhub

:deploy_local
echo %BLUE% Deploying locally...
call mvn mule:deploy

if !errorlevel! neq 0 (
    echo %RED% Local deployment failed
    exit /b 1
)

echo %GREEN% Local deployment successful
echo %YELLOW% Application will be available at:
echo   Main Orchestration: http://localhost:8080
echo   Employee Service:   http://localhost:8082
echo   Asset Service:      http://localhost:8083
echo   Email Service:      http://localhost:8084
goto :deployment_complete

:deploy_cloudhub
echo %BLUE% Deploying to CloudHub 2.0...
echo Environment: %ENVIRONMENT%
echo Application: %APPLICATION_NAME%
echo Worker Type: %WORKER_TYPE%
echo Workers: %WORKERS%
echo.

REM Use Connected App credentials if provided, otherwise use username/password
if not "%CLIENT_ID%"=="" if not "%CLIENT_SECRET%"=="" (
    echo %BLUE% Using Connected App authentication
    call mvn clean package mule:deploy -DmuleDeploy -DclientId="%CLIENT_ID%" -DclientSecret="%CLIENT_SECRET%" -DapplicationName="%APPLICATION_NAME%" -Denvironment="%ENVIRONMENT%" -DworkerType="%WORKER_TYPE%" -Dworkers="%WORKERS%"
) else (
    echo %BLUE% Using username/password authentication
    call mvn clean package mule:deploy -DmuleDeploy -Dusername="%USERNAME%" -Dpassword="%PASSWORD%" -DapplicationName="%APPLICATION_NAME%" -Denvironment="%ENVIRONMENT%" -DworkerType="%WORKER_TYPE%" -Dworkers="%WORKERS%"
)

if !errorlevel! neq 0 (
    echo %RED% CloudHub deployment failed
    exit /b 1
)

echo %GREEN% CloudHub deployment successful

REM Determine CloudHub URL based on environment
set "CLOUDHUB_URL="
if /i "%ENVIRONMENT%"=="Sandbox" set "CLOUDHUB_URL=https://%APPLICATION_NAME%.us-e2.cloudhub.io"
if /i "%ENVIRONMENT%"=="Production" set "CLOUDHUB_URL=https://%APPLICATION_NAME%.us-e1.cloudhub.io"
if "%CLOUDHUB_URL%"=="" set "CLOUDHUB_URL=https://%APPLICATION_NAME%.%ENVIRONMENT%.cloudhub.io"

echo.
echo %YELLOW% Application will be available at: %CLOUDHUB_URL%
echo %YELLOW% Health Check: %CLOUDHUB_URL%/health
echo %YELLOW% API Endpoints:
echo   Complete Onboarding: %CLOUDHUB_URL%/onboardEmployee
echo   Get Status: %CLOUDHUB_URL%/getOnboardingStatus/{employeeId}
echo.

REM Ask if user wants to publish to Exchange
if "%PUBLISH_EXCHANGE%"=="false" (
    set /p "response=%YELLOW% Do you want to publish the Agent Network asset to Anypoint Exchange? (y/N): "
    if /i "!response!"=="y" set "PUBLISH_EXCHANGE=true"
    if /i "!response!"=="yes" set "PUBLISH_EXCHANGE=true"
)

if "%PUBLISH_EXCHANGE%"=="true" goto :publish_exchange
goto :deployment_complete

:publish_exchange
echo.
echo %BLUE% Publishing Agent Network asset to Anypoint Exchange...

REM Use Connected App credentials if provided, otherwise use username/password
if not "%CLIENT_ID%"=="" if not "%CLIENT_SECRET%"=="" (
    call mvn clean deploy -DclientId="%CLIENT_ID%" -DclientSecret="%CLIENT_SECRET%" -DaltDeploymentRepository=anypoint-exchange-v3::default::https://maven.anypoint.mulesoft.com/api/v3/maven
) else if not "%USERNAME%"=="" if not "%PASSWORD%"=="" (
    call mvn clean deploy -Dusername="%USERNAME%" -Dpassword="%PASSWORD%" -DaltDeploymentRepository=anypoint-exchange-v3::default::https://maven.anypoint.mulesoft.com/api/v3/maven
) else (
    echo %RED% Credentials required for Exchange publishing
    goto :deployment_complete
)

if !errorlevel! neq 0 (
    echo %RED% Exchange publishing failed
    goto :deployment_complete
)

echo %GREEN% Agent Network asset published to Exchange successfully
echo %YELLOW% Asset will be available in Anypoint Exchange for Agent Network integration

:deployment_complete
echo.
echo %GREEN% Deployment completed successfully!
echo.
pause
exit /b 0

REM Helper function to shift arguments (Windows batch doesn't have shift in functions)
:shift
shift
goto :eof
