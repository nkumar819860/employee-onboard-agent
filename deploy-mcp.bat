@echo off
REM Load environment variables from .env file
for /f "usebackq tokens=1,2 delims==" %%a in (".env") do (
    set %%a=%%b
)

echo Deploying Employee Onboarding MCP System to CloudHub...

mvn clean package deploy -DmuleDeploy ^
    -Danypoint.client.id=%ANYPOINT_CLIENT_ID% ^
    -Danypoint.client.secret=%ANYPOINT_CLIENT_SECRET% ^
    -Dcloudhub.application.name=employee-onboarding-mcp ^
    -Dcloudhub.environment=Sandbox ^
    -Dcloudhub.region=us-east-2 ^
    -Dcloudhub.workers=1 ^
    -Dcloudhub.worker.type=MICRO

if errorlevel 1 (
    echo Deployment failed!
    pause
    exit /b 1
)

echo.
echo ✅ Deployment successful!
echo 🌐 Application URL: https://employee-onboarding-mcp.us-east-2.cloudhub.io
echo 🔗 Health Check: https://employee-onboarding-mcp.us-east-2.cloudhub.io/health
echo.
pause
