@echo off
echo ====================================
echo  MCP Servers CloudHub Deployment
echo ====================================
echo.

:: Set environment variables (you'll need to set these with your Anypoint credentials)
if "%ANYPOINT_USERNAME%"=="" (
    echo ERROR: ANYPOINT_USERNAME environment variable not set
    echo Please run: set ANYPOINT_USERNAME=your-username
    goto :error
)

if "%ANYPOINT_PASSWORD%"=="" (
    echo ERROR: ANYPOINT_PASSWORD environment variable not set
    echo Please run: set ANYPOINT_PASSWORD=your-password
    goto :error
)

if "%ANYPOINT_ORG_ID%"=="" (
    echo ERROR: ANYPOINT_ORG_ID environment variable not set
    echo Please run: set ANYPOINT_ORG_ID=your-org-id
    goto :error
)

:: Deploy PostgreSQL MCP Server
echo.
echo [1/3] Deploying PostgreSQL MCP Server...
echo ========================================
cd mcp-postgres-server
call mvn clean package -DskipTests
if %errorlevel% neq 0 (
    echo ERROR: Failed to build mcp-postgres-server
    cd ..
    goto :error
)

call mvn mule:deploy -Dmule.env=Sandbox -Dmule.username=%ANYPOINT_USERNAME% -Dmule.password=%ANYPOINT_PASSWORD% -Dmule.businessGroup=%ANYPOINT_ORG_ID%
if %errorlevel% neq 0 (
    echo ERROR: Failed to deploy mcp-postgres-server
    cd ..
    goto :error
)
cd ..
echo ✅ PostgreSQL MCP Server deployed successfully!

:: Deploy Assets MCP Server
echo.
echo [2/3] Deploying Assets MCP Server...
echo ===================================
cd mcp-assets-server
call mvn clean package -DskipTests
if %errorlevel% neq 0 (
    echo ERROR: Failed to build mcp-assets-server
    cd ..
    goto :error
)

call mvn mule:deploy -Dmule.env=Sandbox -Dmule.username=%ANYPOINT_USERNAME% -Dmule.password=%ANYPOINT_PASSWORD% -Dmule.businessGroup=%ANYPOINT_ORG_ID%
if %errorlevel% neq 0 (
    echo ERROR: Failed to deploy mcp-assets-server
    cd ..
    goto :error
)
cd ..
echo ✅ Assets MCP Server deployed successfully!

:: Deploy Notification MCP Server
echo.
echo [3/3] Deploying Notification MCP Server...
echo ==========================================
cd mcp-notification-server
call mvn clean package -DskipTests
if %errorlevel% neq 0 (
    echo ERROR: Failed to build mcp-notification-server
    cd ..
    goto :error
)

call mvn mule:deploy -Dmule.env=Sandbox -Dmule.username=%ANYPOINT_USERNAME% -Dmule.password=%ANYPOINT_PASSWORD% -Dmule.businessGroup=%ANYPOINT_ORG_ID%
if %errorlevel% neq 0 (
    echo ERROR: Failed to deploy mcp-notification-server
    cd ..
    goto :error
)
cd ..
echo ✅ Notification MCP Server deployed successfully!

echo.
echo ====================================
echo  🎉 ALL MCP SERVERS DEPLOYED! 🎉
echo ====================================
echo.
echo Your MCP servers should be available at:
echo - PostgreSQL: https://mcp-postgres-server.us-e1.cloudhub.io
echo - Assets: https://mcp-assets-server.us-e1.cloudhub.io  
echo - Notifications: https://mcp-notification-server.us-e1.cloudhub.io
echo.
echo You can now update your agent-network-cloudhub.yaml with these URLs.
echo.
goto :end

:error
echo.
echo ❌ Deployment failed! Please check the error messages above.
echo.
exit /b 1

:end
echo Deployment completed successfully!
pause
