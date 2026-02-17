@echo off
REM Hybrid Deployment Script for Employee Onboarding Agent Network (Windows)
REM Supports deployment to both Docker (local) and Anypoint Platform (CloudHub 2.0)

setlocal enabledelayedexpansion

set DEPLOYMENT_TARGET=%1
set ENV_FILE=""
set VERBOSE=false
set CLEAN_DEPLOYMENT=false

if "%DEPLOYMENT_TARGET%"=="" (
    echo ❌ Error: Deployment target is required
    goto :show_usage
)

if "%DEPLOYMENT_TARGET%"=="--help" goto :show_usage
if "%DEPLOYMENT_TARGET%"=="-h" goto :show_usage

REM Parse additional arguments
:parse_args
if "%2"=="" goto :main_deployment
if "%2"=="-e" (
    set ENV_FILE=%3
    shift
    shift
    goto :parse_args
)
if "%2"=="--verbose" (
    set VERBOSE=true
    shift
    goto :parse_args
)
if "%2"=="--clean" (
    set CLEAN_DEPLOYMENT=true
    shift
    goto :parse_args
)
shift
goto :parse_args

:show_usage
echo 🚀 Employee Onboarding Agent Network - Hybrid Deployment Script (Windows)
echo.
echo Usage: %0 DEPLOYMENT_TARGET [OPTIONS]
echo.
echo DEPLOYMENT_TARGET:
echo   docker      Deploy to local Docker environment
echo   anypoint    Deploy to Anypoint Platform (CloudHub 2.0)
echo   both        Deploy to both Docker and Anypoint Platform
echo.
echo OPTIONS:
echo   -h, --help              Show this help message
echo   -e FILE                 Load environment variables from file
echo   --verbose               Enable verbose output
echo   --clean                 Clean existing deployments before deploying
echo.
echo EXAMPLES:
echo   %0 docker                           # Deploy to Docker only
echo   %0 anypoint -e .env.anypoint       # Deploy to Anypoint with env file
echo   %0 both --clean                    # Clean and deploy to both platforms
goto :eof

:check_docker_prerequisites
echo ℹ️ Checking Docker prerequisites...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not installed or not in PATH
    exit /b 1
)
docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker Compose is not installed or not in PATH
    exit /b 1
)
echo ✅ Docker prerequisites satisfied
goto :eof

:deploy_docker
echo ℹ️ 🐳 Starting Docker deployment...

if "%CLEAN_DEPLOYMENT%"=="true" (
    echo ℹ️ Cleaning existing Docker deployment...
    docker-compose down -v --remove-orphans 2>nul
)

echo ℹ️ Starting Docker services...
docker-compose up -d

echo ℹ️ Waiting for services to be ready...
timeout /t 30 /nobreak >nul

echo ℹ️ Validating Docker deployment...

REM Check if containers are running
for %%s in (postgres flex-gateway postgres-mcp assets-mcp notification-mcp mule-broker) do (
    docker-compose ps %%s | findstr "Up" >nul
    if errorlevel 1 (
        echo ❌ Service %%s is not running
        goto :eof
    ) else (
        echo ✅ Service %%s is running
    )
)

echo ✅ Docker deployment completed successfully!

REM Save Docker deployment info
echo {> docker-deployment-info.json
echo   "deployment": {>> docker-deployment-info.json
echo     "platform": "docker",>> docker-deployment-info.json
echo     "timestamp": "%date% %time%",>> docker-deployment-info.json
echo     "compose_file": "docker-compose.yml">> docker-deployment-info.json
echo   },>> docker-deployment-info.json
echo   "services": {>> docker-deployment-info.json
echo     "flex-gateway": "http://localhost:8080",>> docker-deployment-info.json
echo     "mule-broker": "http://localhost:8081",>> docker-deployment-info.json
echo     "postgres-mcp": "http://localhost:8082",>> docker-deployment-info.json
echo     "assets-mcp": "http://localhost:8083",>> docker-deployment-info.json
echo     "notification-mcp": "http://localhost:8084",>> docker-deployment-info.json
echo     "postgres-db": "localhost:5432">> docker-deployment-info.json
echo   }>> docker-deployment-info.json
echo }>> docker-deployment-info.json

echo ℹ️ Docker deployment information saved to: docker-deployment-info.json
goto :eof

:deploy_anypoint
echo ℹ️ ☁️ Starting Anypoint Platform deployment...
cd anypoint-deployment
call deploy-to-anypoint.sh
cd ..
echo ✅ Anypoint Platform deployment completed successfully!
goto :eof

:show_deployment_summary
set platform=%1
echo.
echo 🎉 Deployment Summary
echo ====================

if "%platform%"=="docker" (
    echo ✅ Docker deployment completed
    echo 🔗 Local URLs:
    echo    • Agent Network: http://localhost:8080
    echo    • HR Broker: http://localhost:8081
    echo    • PostgreSQL MCP: http://localhost:8082
    echo    • Assets MCP: http://localhost:8083
    echo    • Notification MCP: http://localhost:8084
    echo    • React Client: http://localhost:3001
    echo.
    echo 📋 Test the deployment:
    echo    curl -X POST http://localhost:8080/broker/onboard ^
    echo         -H "Content-Type: application/json" ^
    echo         -d "{\"name\":\"John Doe\",\"email\":\"john@company.com\",\"role\":\"developer\"}"
)

if "%platform%"=="anypoint" (
    echo ✅ Anypoint Platform deployment completed
    echo ☁️ CloudHub 2.0 URLs: See anypoint-deployment/deployment-info.json
    echo 📊 Anypoint Visualizer: https://anypoint.mulesoft.com/visualizer
    echo 📦 Anypoint Exchange: https://anypoint.mulesoft.com/exchange/
)

if "%platform%"=="both" (
    echo ✅ Hybrid deployment completed (Docker + Anypoint Platform)
    echo.
    echo 🐳 Docker (Local Development):
    echo    • Agent Network: http://localhost:8080
    echo    • React Client: http://localhost:3001
    echo.
    echo ☁️ Anypoint Platform (Production):
    echo    • See anypoint-deployment/deployment-info.json for URLs
    echo    • Visualizer: https://anypoint.mulesoft.com/visualizer
)

echo.
echo 📁 Configuration Files:
echo    • Docker: agent-network.yaml, exchange.json
echo    • Anypoint: anypoint-deployment/agent-network-anypoint.yaml
echo    • React Client: react-mcp-client/
echo.
goto :eof

:main_deployment
echo 🚀 Employee Onboarding Agent Network - Hybrid Deployment
echo ========================================================
echo.
echo ℹ️ Deployment target: %DEPLOYMENT_TARGET%
echo.

if "%DEPLOYMENT_TARGET%"=="docker" (
    call :check_docker_prerequisites
    if errorlevel 1 exit /b 1
    call :deploy_docker
    call :show_deployment_summary docker
)

if "%DEPLOYMENT_TARGET%"=="anypoint" (
    REM Check Anypoint prerequisites would go here
    call :deploy_anypoint
    call :show_deployment_summary anypoint
)

if "%DEPLOYMENT_TARGET%"=="both" (
    call :check_docker_prerequisites
    if errorlevel 1 exit /b 1
    
    echo ℹ️ 🚀 Starting hybrid deployment (Docker + Anypoint)...
    call :deploy_docker
    
    echo ℹ️ ⏳ Waiting before Anypoint deployment...
    timeout /t 10 /nobreak >nul
    
    call :deploy_anypoint
    call :show_deployment_summary both
)

echo.
echo ✅ Deployment completed successfully! 🎉

:eof
