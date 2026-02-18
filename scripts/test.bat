@echo off
setlocal enabledelayedexpansion

REM Employee Onboarding System - Testing Script for Windows
REM This script tests the complete onboarding workflow

REM Colors for output (Windows console labels)
set "GREEN=SUCCESS:"
set "RED=ERROR:"
set "YELLOW=INFO:"
set "BLUE=STEP:"

REM Default configuration
set "BASE_URL=http://localhost:8080"
set "EMPLOYEE_SERVICE_URL=http://localhost:8082"
set "ASSET_SERVICE_URL=http://localhost:8083"
set "EMAIL_SERVICE_URL=http://localhost:8084"
set "TEST_EMAIL=test.employee@company.com"
set "EMPLOYEE_ID="

REM Function to display usage
:usage
echo.
echo Usage: %0 [OPTIONS]
echo.
echo Options:
echo   -u, --base-url        Base URL for the main orchestration service [default: http://localhost:8080]
echo   -e, --email           Test email address [default: test.employee@company.com]
echo   -h, --help            Display this help message
echo.
echo Examples:
echo   %0                                          # Test with default settings
echo   %0 -u https://my-app.cloudhub.io           # Test deployed application
echo   %0 -e john.doe@company.com                 # Test with specific email
echo.
exit /b 0

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :check_services
if "%~1"=="-h" goto :usage
if "%~1"=="--help" goto :usage
if "%~1"=="-u" set "BASE_URL=%~2" & shift & shift & goto :parse_args
if "%~1"=="--base-url" set "BASE_URL=%~2" & shift & shift & goto :parse_args
if "%~1"=="-e" set "TEST_EMAIL=%~2" & shift & shift & goto :parse_args
if "%~1"=="--email" set "TEST_EMAIL=%~2" & shift & shift & goto :parse_args
echo %RED% Unknown option: %~1
call :usage
exit /b 1

REM Update service URLs based on base URL
:update_service_urls
echo %BASE_URL% | findstr /C:"localhost" >nul
if !errorlevel! equ 0 (
    set "EMPLOYEE_SERVICE_URL=http://localhost:8082"
    set "ASSET_SERVICE_URL=http://localhost:8083"
    set "EMAIL_SERVICE_URL=http://localhost:8084"
) else (
    REM For cloud deployment, assume all services are behind the same endpoint
    set "EMPLOYEE_SERVICE_URL=%BASE_URL%"
    set "ASSET_SERVICE_URL=%BASE_URL%"
    set "EMAIL_SERVICE_URL=%BASE_URL%"
)

:check_services
echo.
echo %GREEN% Employee Onboarding System - Test Suite
echo ========================================
echo.
echo %BLUE% Checking if services are running...

REM Check if curl is available
curl --version >nul 2>&1
if !errorlevel! neq 0 (
    echo %RED% curl is required but not installed
    echo Please install curl or use Git Bash which includes curl
    pause
    exit /b 1
)

REM Check main orchestration service
curl -s --connect-timeout 5 "%BASE_URL%/health" >nul 2>&1
if !errorlevel! neq 0 (
    echo %RED% Main orchestration service is not accessible at %BASE_URL%
    echo Please ensure the application is running locally or update the base URL with -u flag
    pause
    exit /b 1
)

echo %GREEN% Services are accessible
echo.

:run_tests
set "PASSED=0"
set "FAILED=0"
set "START_TIME=%TIME%"

echo %BLUE% Starting test execution...
echo.

REM Test 1: Health Check
call :test_health_check
if !errorlevel! equ 0 (
    set /a "PASSED+=1"
) else (
    set /a "FAILED+=1"
)

REM Test 2: Database Initialization
call :test_database_initialization
if !errorlevel! equ 0 (
    set /a "PASSED+=1"
) else (
    set /a "FAILED+=1"
)

REM Test 3: Complete Onboarding Workflow
call :test_complete_onboarding
if !errorlevel! equ 0 (
    set /a "PASSED+=1"
) else (
    set /a "FAILED+=1"
)

REM Test 4: Onboarding Status
call :test_onboarding_status
if !errorlevel! equ 0 (
    set /a "PASSED+=1"
) else (
    set /a "FAILED+=1"
)

REM Test 5: Individual Services
call :test_individual_services
if !errorlevel! equ 0 (
    set /a "PASSED+=1"
) else (
    set /a "FAILED+=1"
)

REM Optional Performance Test
echo.
set /p "response=%YELLOW% Run performance test? (y/N): "
if /i "!response!"=="y" goto :performance_test
if /i "!response!"=="yes" goto :performance_test
goto :test_summary

:performance_test
call :test_performance
if !errorlevel! equ 0 (
    set /a "PASSED+=1"
) else (
    set /a "FAILED+=1"
)

:test_summary
set "END_TIME=%TIME%"
echo.
echo %GREEN% Test Suite Completed
echo ===================
echo Passed: %PASSED%
echo Failed: %FAILED%
echo.

if %FAILED% equ 0 (
    echo %GREEN% All tests passed! 🎉
    exit /b 0
) else (
    echo %RED% Some tests failed 😞
    exit /b 1
)

REM Individual test functions

:test_health_check
echo %BLUE% Testing: Health Check
echo   GET %BASE_URL%/health
curl -s "%BASE_URL%/health" > temp_response.json 2>nul
if !errorlevel! neq 0 (
    echo   %RED% ✗ Failed - Service not responding
    if exist temp_response.json del temp_response.json
    exit /b 1
)
echo   %GREEN% ✓ Success - Health check passed
if exist temp_response.json (
    type temp_response.json
    del temp_response.json
)
echo.
exit /b 0

:test_database_initialization
echo %BLUE% Testing: Database Initialization
echo   POST %BASE_URL%/initializeDatabase
curl -s -X POST "%BASE_URL%/initializeDatabase" > temp_response.json 2>nul
if !errorlevel! neq 0 (
    echo   %RED% ✗ Failed - Database initialization failed
    if exist temp_response.json del temp_response.json
    exit /b 1
)
echo   %GREEN% ✓ Success - Database initialized
if exist temp_response.json (
    type temp_response.json
    del temp_response.json
)
echo.
exit /b 0

:test_complete_onboarding
echo %BLUE% Testing: Complete Employee Onboarding Workflow
echo   POST %BASE_URL%/onboardEmployee

REM Create timestamp for unique employee
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "timestamp=%dt:~0,14%"

REM Create test data
echo {"firstName":"John","lastName":"TestEmployee%timestamp%","email":"%TEST_EMAIL%","department":"Engineering","position":"Software Engineer","startDate":"%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%","requestedAssets":["laptop","id_card","phone"]} > temp_request.json

curl -s -X POST -H "Content-Type: application/json" -d @temp_request.json "%BASE_URL%/onboardEmployee" > temp_response.json 2>nul
if !errorlevel! neq 0 (
    echo   %RED% ✗ Failed - Onboarding workflow failed
    if exist temp_request.json del temp_request.json
    if exist temp_response.json del temp_response.json
    exit /b 1
)

echo   %GREEN% ✓ Success - Employee onboarding completed
if exist temp_response.json (
    type temp_response.json
    REM Try to extract employee ID for status testing (basic parsing)
    findstr /C:"employeeId" temp_response.json > temp_id.txt 2>nul
    if exist temp_id.txt (
        for /f "tokens=2 delims=:" %%a in (temp_id.txt) do set "EMPLOYEE_ID=%%a"
        set "EMPLOYEE_ID=!EMPLOYEE_ID:"=!"
        set "EMPLOYEE_ID=!EMPLOYEE_ID:,=!"
        set "EMPLOYEE_ID=!EMPLOYEE_ID: =!"
        del temp_id.txt
    )
    del temp_response.json
)
if exist temp_request.json del temp_request.json
echo.
exit /b 0

:test_onboarding_status
if "%EMPLOYEE_ID%"=="" (
    echo %YELLOW% Skipping status check - Employee ID not available
    echo.
    exit /b 0
)

echo %BLUE% Testing: Get Onboarding Status
echo   GET %BASE_URL%/getOnboardingStatus/%EMPLOYEE_ID%
curl -s "%BASE_URL%/getOnboardingStatus/%EMPLOYEE_ID%" > temp_response.json 2>nul
if !errorlevel! neq 0 (
    echo   %RED% ✗ Failed - Status check failed
    if exist temp_response.json del temp_response.json
    exit /b 1
)
echo   %GREEN% ✓ Success - Status retrieved
if exist temp_response.json (
    type temp_response.json
    del temp_response.json
)
echo.
exit /b 0

:test_individual_services
echo %BLUE% Testing Individual MCP Services
echo.

REM Test Employee Service
echo %BLUE% Testing Employee Onboarding MCP Server...
echo   GET %EMPLOYEE_SERVICE_URL%/listEmployees
curl -s "%EMPLOYEE_SERVICE_URL%/listEmployees" > temp_response.json 2>nul
if !errorlevel! neq 0 (
    echo   %RED% ✗ Failed - Employee service failed
    if exist temp_response.json del temp_response.json
    exit /b 1
)
echo   %GREEN% ✓ Success - Employee service working
if exist temp_response.json del temp_response.json

REM Test Asset Service
echo %BLUE% Testing Asset Allocation MCP Server...
echo   GET %ASSET_SERVICE_URL%/getInventory
curl -s "%ASSET_SERVICE_URL%/getInventory" > temp_response.json 2>nul
if !errorlevel! neq 0 (
    echo   %RED% ✗ Failed - Asset service failed
    if exist temp_response.json del temp_response.json
    exit /b 1
)
echo   %GREEN% ✓ Success - Asset service working
if exist temp_response.json del temp_response.json

REM Test Email Service
echo %BLUE% Testing Email Notification MCP Server...
echo   GET %EMAIL_SERVICE_URL%/getEmailLogs
curl -s "%EMAIL_SERVICE_URL%/getEmailLogs" > temp_response.json 2>nul
if !errorlevel! neq 0 (
    echo   %RED% ✗ Failed - Email service failed
    if exist temp_response.json del temp_response.json
    exit /b 1
)
echo   %GREEN% ✓ Success - Email service working
if exist temp_response.json del temp_response.json
echo.
exit /b 0

:test_performance
echo %BLUE% Running performance test (5 concurrent requests)...

REM Create test data for performance test
echo {"firstName":"Perf","lastName":"TestUser","email":"perf.test@company.com","department":"Testing","position":"Performance Tester","startDate":"%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%","requestedAssets":["laptop"]} > temp_perf_request.json

REM Run 5 concurrent requests (Windows doesn't have & for background jobs like Unix, so we'll run them sequentially but quickly)
for /L %%i in (1,1,5) do (
    echo Running performance test request %%i...
    curl -s -X POST -H "Content-Type: application/json" -d @temp_perf_request.json "%BASE_URL%/onboardEmployee" > nul 2>&1
    if !errorlevel! neq 0 (
        echo   %RED% ✗ Performance test request %%i failed
        if exist temp_perf_request.json del temp_perf_request.json
        exit /b 1
    )
    echo   %GREEN% Request %%i completed
)

if exist temp_perf_request.json del temp_perf_request.json
echo %GREEN% Performance test completed
echo.
exit /b 0
