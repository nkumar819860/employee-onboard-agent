@echo off
REM Unified Employee Onboarding MCP Server Deployment Script for CloudHub
REM This script deploys the consolidated MCP server with all three tools

setlocal enabledelayedexpansion

set ENV_FILE=.env
set VERBOSE=false
set CLEAN_BUILD=false
set APP_NAME=unified-employee-onboarding-mcp

REM Parse arguments
:parse_args
if "%1"=="" goto :main_deployment
if "%1"=="-e" (
    set ENV_FILE=%2
    shift
    shift
    goto :parse_args
)
if "%1"=="--verbose" (
    set VERBOSE=true
    shift
    goto :parse_args
)
if "%1"=="--clean" (
    set CLEAN_BUILD=true
    shift
    goto :parse_args
)
if "%1"=="--help" goto :show_usage
if "%1"=="-h" goto :show_usage
shift
goto :parse_args

:show_usage
echo 🚀 Unified Employee Onboarding MCP Server - CloudHub Deployment Script
echo.
echo Usage: %0 [OPTIONS]
echo.
echo OPTIONS:
echo   -h, --help              Show this help message
echo   -e FILE                 Load environment variables from file (default: .env)
echo   --verbose               Enable verbose output
echo   --clean                 Clean build before deployment
echo.
echo EXAMPLES:
echo   %0                      # Deploy with default .env file
echo   %0 -e .env.prod         # Deploy with production environment file
echo   %0 --clean --verbose    # Clean build with verbose output
echo.
echo MCP TOOLS INCLUDED:
echo   • create-employee       - Creates new employee records
echo   • allocate-assets       - Allocates assets to employees  
echo   • send-welcome          - Sends welcome notifications
echo.
goto :eof

:load_env_file
if exist "%ENV_FILE%" (
    echo ℹ️ Loading environment variables from: %ENV_FILE%
    for /f "usebackq tokens=1,2 delims==" %%a in ("%ENV_FILE%") do (
        if not "%%a"=="" (
            if not "%%a:~0,1%"=="#" (
                set "%%a=%%b"
                if "%VERBOSE%"=="true" echo   %%a=%%b
            )
        )
    )
    echo ✅ Environment variables loaded
) else (
    echo ⚠️ Environment file not found: %ENV_FILE%
    echo ℹ️ Using default configuration
)
goto :eof

:check_prerequisites
echo ℹ️ Checking deployment prerequisites...

REM Check Maven
mvn --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Maven is not installed or not in PATH
    echo ℹ️ Please install Maven 3.6+ and add to PATH
    exit /b 1
)
echo ✅ Maven found

REM Check Java
java -version >nul 2>&1
if errorlevel 1 (
    echo ❌ Java is not installed or not in PATH
    echo ℹ️ Please install Java 17+ and add to PATH
    exit /b 1
)
echo ✅ Java found

REM Check project structure
if not exist "postgres-mcp-onboarding\pom.xml" (
    echo ❌ Project structure not found
    echo ℹ️ Please run this script from the project root directory
    exit /b 1
)
echo ✅ Project structure verified

goto :eof

:build_project
echo ℹ️ Building unified MCP server project...

cd postgres-mcp-onboarding

if "%CLEAN_BUILD%"=="true" (
    echo ℹ️ Performing clean build...
    mvn clean
)

echo ℹ️ Packaging application...
if "%VERBOSE%"=="true" (
    mvn package -DskipTests
) else (
    mvn package -DskipTests -q
)

if errorlevel 1 (
    echo ❌ Build failed
    cd ..
    exit /b 1
)

echo ✅ Build completed successfully
cd ..
goto :eof

:deploy_to_cloudhub
echo ℹ️ ☁️ Deploying to CloudHub...

cd postgres-mcp-onboarding

REM Set deployment properties
set MAVEN_OPTS=-Xmx1024m

echo ℹ️ Application: %APP_NAME%
echo ℹ️ Environment: %ANYPOINT_ENV%
echo ℹ️ Runtime: %MULE_VERSION%

REM Deploy using Maven plugin with Connected App credentials
if "%VERBOSE%"=="true" (
    mvn clean deploy -DmuleDeploy ^
        -Danypoint.clientId=%ANYPOINT_CLIENT_ID% ^
        -Danypoint.clientSecret=%ANYPOINT_CLIENT_SECRET% ^
        -DapplicationName=%APP_NAME% ^
        -Denvironment=%ANYPOINT_ENV% ^
        -DorganizationId=%ANYPOINT_ORG_ID% ^
        -DbusinessGroupId=%BUSINESS_GROUP_ID% ^
        -DworkerType=%CLOUDHUB_WORKER_TYPE% ^
        -Dworkers=%CLOUDHUB_WORKERS% ^
        -Dregion=%CLOUDHUB_REGION% ^
        -DobjectStoreV2=%CLOUDHUB_OBJECT_STORE_V2% ^
        -Dhttp.port=%HTTP_PORT% ^
        -Ddb.url="%DATABASE_URL%" ^
        -Dmcp.serverName=%MCP_SERVER_NAME% ^
        -Dmcp.serverVersion=%MCP_SERVER_VERSION% ^
        -Dgroq.apiKey=%GROQ_API_KEY% ^
        -Dgmail.user=%GMAIL_USER% ^
        -Dgmail.password="%GMAIL_PASSWORD%"
) else (
    mvn clean deploy -DmuleDeploy -q ^
        -Danypoint.clientId=%ANYPOINT_CLIENT_ID% ^
        -Danypoint.clientSecret=%ANYPOINT_CLIENT_SECRET% ^
        -DapplicationName=%APP_NAME% ^
        -Denvironment=%ANYPOINT_ENV% ^
        -DorganizationId=%ANYPOINT_ORG_ID% ^
        -DbusinessGroupId=%BUSINESS_GROUP_ID% ^
        -DworkerType=%CLOUDHUB_WORKER_TYPE% ^
        -Dworkers=%CLOUDHUB_WORKERS% ^
        -Dregion=%CLOUDHUB_REGION% ^
        -DobjectStoreV2=%CLOUDHUB_OBJECT_STORE_V2% ^
        -Dhttp.port=%HTTP_PORT% ^
        -Ddb.url="%DATABASE_URL%" ^
        -Dmcp.serverName=%MCP_SERVER_NAME% ^
        -Dmcp.serverVersion=%MCP_SERVER_VERSION% ^
        -Dgroq.apiKey=%GROQ_API_KEY% ^
        -Dgmail.user=%GMAIL_USER% ^
        -Dgmail.password="%GMAIL_PASSWORD%"
)

if errorlevel 1 (
    echo ❌ CloudHub deployment failed
    cd ..
    exit /b 1
)

echo ✅ CloudHub deployment completed successfully
cd ..
goto :eof

:save_deployment_info
echo ℹ️ Saving deployment information...

echo {> unified-mcp-deployment-info.json
echo   "deployment": {>> unified-mcp-deployment-info.json
echo     "platform": "cloudhub",>> unified-mcp-deployment-info.json
echo     "timestamp": "%date% %time%",>> unified-mcp-deployment-info.json
echo     "application_name": "%APP_NAME%",>> unified-mcp-deployment-info.json
echo     "environment": "%ANYPOINT_ENV%",>> unified-mcp-deployment-info.json
echo     "runtime_version": "%MULE_VERSION%">> unified-mcp-deployment-info.json
echo   },>> unified-mcp-deployment-info.json
echo   "mcp_tools": {>> unified-mcp-deployment-info.json
echo     "create_employee": {>> unified-mcp-deployment-info.json
echo       "endpoint": "/mcp/tools/create-employee",>> unified-mcp-deployment-info.json
echo       "method": "POST",>> unified-mcp-deployment-info.json
echo       "description": "Creates new employee records in PostgreSQL">> unified-mcp-deployment-info.json
echo     },>> unified-mcp-deployment-info.json
echo     "allocate_assets": {>> unified-mcp-deployment-info.json
echo       "endpoint": "/mcp/tools/allocate-assets",>> unified-mcp-deployment-info.json
echo       "method": "POST",>> unified-mcp-deployment-info.json
echo       "description": "Allocates assets to employees">> unified-mcp-deployment-info.json
echo     },>> unified-mcp-deployment-info.json
echo     "send_welcome": {>> unified-mcp-deployment-info.json
echo       "endpoint": "/mcp/tools/send-welcome",>> unified-mcp-deployment-info.json
echo       "method": "POST",>> unified-mcp-deployment-info.json
echo       "description": "Sends welcome notifications to new employees">> unified-mcp-deployment-info.json
echo     }>> unified-mcp-deployment-info.json
echo   },>> unified-mcp-deployment-info.json
echo   "health_check": "/health">> unified-mcp-deployment-info.json
echo }>> unified-mcp-deployment-info.json

echo ✅ Deployment information saved to: unified-mcp-deployment-info.json
goto :eof

:show_deployment_summary
echo.
echo 🎉 Unified MCP Server Deployment Summary
echo ========================================
echo.
echo ✅ Application deployed to CloudHub successfully!
echo.
echo 📋 Application Details:
echo    • Name: %APP_NAME%
echo    • Environment: %ANYPOINT_ENV%
echo    • Runtime: %MULE_VERSION%
echo    • Worker Type: MICRO (0.1 vCores)
echo    • Workers: 1
echo.
echo 🔧 MCP Tools Available:
echo    • POST /mcp/tools/create-employee    - Create employee records
echo    • POST /mcp/tools/allocate-assets    - Allocate assets to employees
echo    • POST /mcp/tools/send-welcome       - Send welcome notifications
echo    • GET  /health                       - Health check endpoint
echo.
echo 🌐 CloudHub URLs:
echo    • Runtime Manager: https://anypoint.mulesoft.com/cloudhub/
echo    • Application URL: https://%APP_NAME%.us-e1.cloudhub.io
echo    • Visualizer: https://anypoint.mulesoft.com/visualizer/
echo.
echo 📊 Test Your Deployment:
echo    curl -X POST https://%APP_NAME%.us-e1.cloudhub.io/mcp/tools/create-employee ^
echo         -H "Content-Type: application/json" ^
echo         -d "{\"name\":\"John Doe\",\"email\":\"john@company.com\"}"
echo.
echo 📁 Deployment Info: unified-mcp-deployment-info.json
goto :eof

:main_deployment
echo 🚀 Unified Employee Onboarding MCP Server - CloudHub Deployment
echo ==============================================================
echo.
echo ℹ️ This script will deploy a unified MCP server with three tools:
echo    • create-employee (PostgreSQL integration)
echo    • allocate-assets (Asset management)  
echo    • send-welcome (Notification system)
echo.

call :load_env_file

call :check_prerequisites
if errorlevel 1 exit /b 1

call :build_project  
if errorlevel 1 exit /b 1

call :deploy_to_cloudhub
if errorlevel 1 exit /b 1

call :save_deployment_info

call :show_deployment_summary

echo.
echo ✅ Unified MCP Server deployment completed successfully! 🎉
echo.

:eof
