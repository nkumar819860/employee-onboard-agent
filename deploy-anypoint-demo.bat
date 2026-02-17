@echo off
REM 🚀 Anypoint Agent Fabric Demo - Quick Deployment Script (Windows)
REM This script deploys the Employee Onboarding Agent Fabric to Anypoint Platform only

setlocal EnableDelayedExpansion

echo.
echo ╔════════════════════════════════════════════════════════════════╗
echo ║                 🚀 ANYPOINT AGENT FABRIC DEMO                ║
echo ║              Employee Onboarding System Deployment            ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.

REM Check prerequisites
echo ℹ️  Checking prerequisites...

REM Check if Anypoint CLI is installed
anypoint-cli-v4 --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Anypoint CLI v4 not found. Please install:
    echo npm install -g anypoint-cli-v4
    exit /b 1
)

REM Check if Maven is installed
mvn --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Maven not found. Please install Maven 3.6+
    exit /b 1
)

REM Check if Java is installed
java -version >nul 2>&1
if errorlevel 1 (
    echo ❌ Java not found. Please install Java 8 or 11
    exit /b 1
)

echo ✅ Prerequisites check passed

REM Setup environment
echo ℹ️  Setting up Anypoint environment...

if not exist "anypoint-deployment\.env.anypoint" (
    echo ⚠️  Environment file not found. Creating from template...
    copy "anypoint-deployment\.env.anypoint.template" "anypoint-deployment\.env.anypoint"
    echo ❌ Please edit anypoint-deployment\.env.anypoint with your credentials and run again
    echo Required variables:
    echo - ANYPOINT_ORG_ID
    echo - ANYPOINT_CLIENT_ID
    echo - ANYPOINT_CLIENT_SECRET
    echo - ANYPOINT_USERNAME
    echo - ANYPOINT_PASSWORD
    pause
    exit /b 1
)

echo ✅ Environment configured

REM Build MCP servers
echo ℹ️  Building PostgreSQL MCP Server...
cd postgres-mcp-onboarding
call mvn clean package -DskipTests
if errorlevel 1 (
    echo ❌ Failed to build PostgreSQL MCP Server
    exit /b 1
)
cd ..
echo ✅ PostgreSQL MCP Server built

REM Deploy to CloudHub (simplified for demo)
echo ℹ️  Ready to deploy to CloudHub 2.0...
echo.
echo 📋 Manual Steps:
echo 1. Open Anypoint Platform: https://anypoint.mulesoft.com/runtime-manager
echo 2. Click "Deploy Application"
echo 3. Upload: postgres-mcp-onboarding\target\postgres-mcp-onboarding-1.0.0-SNAPSHOT-mule-application.jar
echo 4. Configure:
echo    - Application Name: postgres-mcp-server-demo
echo    - Runtime Version: 4.4.0
echo    - Workers: 1
echo    - Worker Size: 0.1 vCore
echo    - Region: US East (Virginia)
echo 5. Click "Deploy Application"
echo.

echo 🎉 Build Complete!
echo.
echo 📊 Demo URLs:
echo - Anypoint Visualizer: https://anypoint.mulesoft.com/visualizer
echo - Anypoint Exchange:   https://anypoint.mulesoft.com/exchange
echo - Runtime Manager:     https://anypoint.mulesoft.com/runtime-manager
echo - Design Center:       https://anypoint.mulesoft.com/design-center
echo.
echo 📖 Follow the demo guide: ANYPOINT-AGENT-FABRIC-DEMO-GUIDE.md
echo.
pause
