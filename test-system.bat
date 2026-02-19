@echo off
REM Employee Onboarding System Test Script for Windows

setlocal EnableDelayedExpansion

REM Test results counters
set TESTS_PASSED=0
set TESTS_FAILED=0

REM Function to log messages with timestamp
:log
echo [%date% %time%] %~1
goto :eof

REM Function to show success
:success
echo ✓ %~1
set /a TESTS_PASSED+=1
goto :eof

REM Function to show error
:error
echo ✗ %~1
set /a TESTS_FAILED+=1
goto :eof

REM Function to show warning
:warn
echo ⚠ %~1
goto :eof

REM Main test execution
call :log "Starting Employee Onboarding System Tests..."
call :log "================================================"

REM Check if Docker Compose is available
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    call :error "Docker Compose is not installed"
    exit /b 1
)

REM Start the system
call :log "Starting Docker Compose services..."
docker-compose up -d

REM Wait for services to start
call :log "Waiting for services to start (30 seconds)..."
timeout /t 30 /nobreak >nul

REM Check Docker Compose status
call :log "Checking Docker Compose service status..."
docker-compose ps | findstr "Up" >nul
if %errorlevel% equ 0 (
    call :success "Docker Compose services are running"
) else (
    call :error "Some Docker Compose services are not running"
    docker-compose ps
)

REM Test individual services
call :log "Testing individual service health..."

REM Test Flex Gateway (Nginx)
curl -f -s "http://localhost:8080" >nul 2>&1
if %errorlevel% equ 0 (
    call :success "Flex Gateway (Nginx) is healthy (port 8080)"
) else (
    call :error "Flex Gateway (Nginx) is not responding (port 8080)"
)

REM Test Mule Broker
curl -f -s "http://localhost:8081/health" >nul 2>&1
if %errorlevel% equ 0 (
    call :success "Mule Broker is healthy (port 8081)"
) else (
    call :error "Mule Broker is not responding (port 8081)"
)

REM Test PostgreSQL MCP
curl -f -s "http://localhost:8082/health" >nul 2>&1
if %errorlevel% equ 0 (
    call :success "PostgreSQL MCP is healthy (port 8082)"
) else (
    call :error "PostgreSQL MCP is not responding (port 8082)"
)

REM Test Assets MCP
curl -f -s "http://localhost:8083/health" >nul 2>&1
if %errorlevel% equ 0 (
    call :success "Assets MCP is healthy (port 8083)"
) else (
    call :error "Assets MCP is not responding (port 8083)"
)

REM Test Notifications MCP
curl -f -s "http://localhost:8084/health" >nul 2>&1
if %errorlevel% equ 0 (
    call :success "Notification MCP is healthy (port 8084)"
) else (
    call :error "Notification MCP is not responding (port 8084)"
)

REM Test database connectivity
call :log "Testing database connectivity..."
for /f %%i in ('docker ps -qf "name=postgres"') do set POSTGRES_CONTAINER=%%i
if defined POSTGRES_CONTAINER (
    docker exec %POSTGRES_CONTAINER% pg_isready -U mule -d onboarding >nul 2>&1
    if %errorlevel% equ 0 (
        call :success "PostgreSQL is ready"
    ) else (
        call :error "PostgreSQL is not ready"
    )
) else (
    call :error "PostgreSQL container not found"
)

REM Test onboarding API
call :log "Testing onboarding API..."
set TEST_EMAIL=test.%random%@company.com
set TEST_NAME=Test User %random%

curl -s -X POST "http://localhost:8080/broker/onboard" -H "Content-Type: application/json" -d "{\"name\": \"%TEST_NAME%\", \"email\": \"%TEST_EMAIL%\"}" > temp_response.txt

findstr /c:"error" temp_response.txt >nul
if %errorlevel% equ 0 (
    call :error "Onboarding flow failed"
    type temp_response.txt
) else (
    call :success "Onboarding API call completed"
)

del temp_response.txt >nul 2>&1

REM Test results summary
call :log "================================================"
call :log "Test Results Summary:"
call :log "Tests Passed: %TESTS_PASSED%"
call :log "Tests Failed: %TESTS_FAILED%"
call :log "================================================"

if %TESTS_FAILED% equ 0 (
    call :log "🎉 All tests passed! System is ready for use."
    exit /b 0
) else (
    call :log "❌ Some tests failed. Please check the system configuration."
    exit /b 1
)
