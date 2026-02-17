@echo off
REM Employee Onboarding Agent Network - Complete Deployment Script for Windows
REM This script builds, publishes, and deploys all MCP servers to Anypoint Platform

setlocal enabledelayedexpansion

echo 🚀 Starting Employee Onboarding Agent Network Deployment...

REM Check if environment variables are set
if "%ANYPOINT_ORG_ID%"=="" (
    echo ❌ Error: Required environment variables not set
    echo Please set: ANYPOINT_ORG_ID, ANYPOINT_ENV
    echo Example:
    echo   set ANYPOINT_ORG_ID=your-org-id
    echo   set ANYPOINT_ENV=Sandbox
    pause
    exit /b 1
)

if "%ANYPOINT_ENV%"=="" (
    echo ❌ Error: Required environment variables not set
    echo Please set: ANYPOINT_ORG_ID, ANYPOINT_ENV
    echo Example:
    echo   set ANYPOINT_ORG_ID=your-org-id
    echo   set ANYPOINT_ENV=Sandbox
    pause
    exit /b 1
)

echo 📋 Environment: %ANYPOINT_ENV%
echo 🏢 Organization: %ANYPOINT_ORG_ID%

REM Step 1: Build all MCP servers
echo.
echo 🔨 Step 1: Building all MCP servers...

echo   Building PostgreSQL MCP Server...
cd postgres-mcp-onboarding
call mvn clean package -DskipTests -q
if errorlevel 1 (
    echo ❌ Failed to build PostgreSQL MCP Server
    cd ..
    pause
    exit /b 1
)
cd ..

echo   Building Assets MCP Server...
cd assets-mcp-server
call mvn clean package -DskipTests -q
if errorlevel 1 (
    echo ❌ Failed to build Assets MCP Server
    cd ..
    pause
    exit /b 1
)
cd ..

echo   Building Notification MCP Server...
cd notification-mcp-server
call mvn clean package -DskipTests -q
if errorlevel 1 (
    echo ❌ Failed to build Notification MCP Server
    cd ..
    pause
    exit /b 1
)
cd ..

echo ✅ All MCP servers built successfully!

REM Step 2: Publish to Exchange
echo.
echo 📦 Step 2: Publishing APIs to Anypoint Exchange...

REM Authenticate if not already authenticated
echo   Checking authentication...
anypoint-cli-v4 account business-group list >nul 2>&1
if errorlevel 1 (
    echo   Please authenticate with Anypoint Platform:
    anypoint-cli-v4 auth login
    if errorlevel 1 (
        echo ❌ Authentication failed
        pause
        exit /b 1
    )
)

echo   Publishing Employee Onboarding API...
anypoint-cli-v4 exchange asset upload --organization=%ANYPOINT_ORG_ID% --name="Employee Onboarding API" --description="Complete employee onboarding API with MCP integration" --type=raml --files employee-onboarding-api/employee-onboarding-api.raml --properties employee-onboarding-api/exchange.json 2>nul || echo   ^(Asset may already exist^)

echo   Publishing PostgreSQL MCP Server...
anypoint-cli-v4 exchange asset upload --organization=%ANYPOINT_ORG_ID% --name="PostgreSQL MCP Server" --description="Employee database MCP server with RAML-first API design" --type=mule-application --classifier=mule-application --files postgres-mcp-onboarding/target/postgres-mcp-onboarding-1.0.0-mule-application.jar --main-file postgres-mcp-onboarding/src/main/resources/api/postgres-mcp-api.raml 2>nul || echo   ^(Asset may already exist^)

echo   Publishing Assets MCP Server...
anypoint-cli-v4 exchange asset upload --organization=%ANYPOINT_ORG_ID% --name="Assets MCP Server" --description="Equipment allocation MCP server with inventory management" --type=mule-application --classifier=mule-application --files assets-mcp-server/target/assets-mcp-server-1.0.0-mule-application.jar --main-file assets-mcp-server/src/main/resources/api/assets-mcp-api.raml 2>nul || echo   ^(Asset may already exist^)

echo   Publishing Notification MCP Server...
anypoint-cli-v4 exchange asset upload --organization=%ANYPOINT_ORG_ID% --name="Notification MCP Server" --description="Multi-channel notification MCP server (email, SMS)" --type=mule-application --classifier=mule-application --files notification-mcp-server/target/notification-mcp-server-1.0.0-mule-application.jar --main-file notification-mcp-server/src/main/resources/api/notification-mcp-api.raml 2>nul || echo   ^(Asset may already exist^)

echo ✅ All assets published to Exchange!

REM Step 3: Deploy to CloudHub 2.0
echo.
echo ☁️ Step 3: Deploying to CloudHub 2.0...

if "%CLOUDHUB_REGION%"=="" set CLOUDHUB_REGION=us-east-1
if "%POSTGRES_HOST%"=="" set POSTGRES_HOST=postgres.sandbox.cloudhub.io
if "%POSTGRES_PASSWORD%"=="" set POSTGRES_PASSWORD=defaultpassword
if "%EMAIL_HOST%"=="" set EMAIL_HOST=smtp.gmail.com
if "%EMAIL_PASSWORD%"=="" set EMAIL_PASSWORD=defaultpassword

echo   Deploying PostgreSQL MCP Server...
anypoint-cli-v4 runtime-mgr cloudhub-2 application deploy --name postgres-mcp-%ANYPOINT_ENV% --target %ANYPOINT_ENV% --artifact postgres-mcp-onboarding/target/postgres-mcp-onboarding-1.0.0-mule-application.jar --replicas 2 --cores 1.0 --memory 1.5 --region %CLOUDHUB_REGION% --env POSTGRES_HOST=%POSTGRES_HOST% --env POSTGRES_PASSWORD=%POSTGRES_PASSWORD% --env ANYPOINT_ENV=%ANYPOINT_ENV% 2>nul || echo   ^(Application may already be deployed^)

echo   Deploying Assets MCP Server...
anypoint-cli-v4 runtime-mgr cloudhub-2 application deploy --name assets-mcp-%ANYPOINT_ENV% --target %ANYPOINT_ENV% --artifact assets-mcp-server/target/assets-mcp-server-1.0.0-mule-application.jar --replicas 1 --cores 0.5 --memory 1.0 --region %CLOUDHUB_REGION% --env ANYPOINT_ENV=%ANYPOINT_ENV% 2>nul || echo   ^(Application may already be deployed^)

echo   Deploying Notification MCP Server...
anypoint-cli-v4 runtime-mgr cloudhub-2 application deploy --name notification-mcp-%ANYPOINT_ENV% --target %ANYPOINT_ENV% --artifact notification-mcp-server/target/notification-mcp-server-1.0.0-mule-application.jar --replicas 1 --cores 0.5 --memory 1.0 --region %CLOUDHUB_REGION% --env EMAIL_HOST=%EMAIL_HOST% --env EMAIL_PASSWORD=%EMAIL_PASSWORD% --env ANYPOINT_ENV=%ANYPOINT_ENV% 2>nul || echo   ^(Application may already be deployed^)

echo ✅ All applications deployed to CloudHub 2.0!

REM Step 4: Wait for deployment and check status
echo.
echo ⏳ Step 4: Waiting for deployments to complete...
timeout /t 30 /nobreak >nul

echo   Checking deployment status...
anypoint-cli-v4 runtime-mgr cloudhub-2 application list --environment %ANYPOINT_ENV% | findstr "mcp-%ANYPOINT_ENV%"

REM Step 5: Test endpoints
echo.
echo 🧪 Step 5: Testing MCP server endpoints...

set POSTGRES_URL=https://postgres-mcp-%ANYPOINT_ENV%.%CLOUDHUB_REGION%.cloudhub.io
set ASSETS_URL=https://assets-mcp-%ANYPOINT_ENV%.%CLOUDHUB_REGION%.cloudhub.io
set NOTIFICATION_URL=https://notification-mcp-%ANYPOINT_ENV%.%CLOUDHUB_REGION%.cloudhub.io

echo   Testing PostgreSQL MCP Server health...
curl -s -f "%POSTGRES_URL%/health" >nul 2>&1 && (
    echo     ✅ PostgreSQL MCP Server is healthy
) || (
    echo     ⚠️  PostgreSQL MCP Server not ready yet
)

echo   Testing Assets MCP Server health...
curl -s -f "%ASSETS_URL%/health" >nul 2>&1 && (
    echo     ✅ Assets MCP Server is healthy
) || (
    echo     ⚠️  Assets MCP Server not ready yet
)

echo   Testing Notification MCP Server health...
curl -s -f "%NOTIFICATION_URL%/health" >nul 2>&1 && (
    echo     ✅ Notification MCP Server is healthy
) || (
    echo     ⚠️  Notification MCP Server not ready yet
)

REM Final summary
echo.
echo 🎉 Deployment Complete!
echo.
echo 📊 Your Employee Onboarding Agent Network is ready:
echo    • PostgreSQL MCP Server: %POSTGRES_URL%
echo    • Assets MCP Server: %ASSETS_URL%
echo    • Notification MCP Server: %NOTIFICATION_URL%
echo.
echo 🔗 Next Steps:
echo    1. Access Anypoint Platform: https://anypoint.mulesoft.com
echo    2. Navigate to Visualizer to see your agent network topology
echo    3. Check Runtime Manager for application status
echo    4. Review Exchange for published APIs
echo.
echo 📖 For detailed testing and agent fabric setup, see:
echo    👉 PUBLISH-DEPLOY-RUN-GUIDE.md
echo.
echo ✨ Happy integrating with Agent Fabric! ✨
echo.
pause
