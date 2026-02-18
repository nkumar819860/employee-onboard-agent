#!/bin/bash

# Employee Onboarding System - Testing Script
# This script tests the complete onboarding workflow

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
BASE_URL="http://localhost:8080"
EMPLOYEE_SERVICE_URL="http://localhost:8082"
ASSET_SERVICE_URL="http://localhost:8083"
EMAIL_SERVICE_URL="http://localhost:8084"

# Test configuration
TEST_EMAIL="test.employee@company.com"
EMPLOYEE_ID=""

# Function to display usage
usage() {
    echo -e "${BLUE}Usage: $0 [OPTIONS]${NC}"
    echo ""
    echo "Options:"
    echo "  -u, --base-url        Base URL for the main orchestration service [default: http://localhost:8080]"
    echo "  -e, --email           Test email address [default: test.employee@company.com]"
    echo "  -h, --help            Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                          # Test with default settings"
    echo "  $0 -u https://my-app.cloudhub.io           # Test deployed application"
    echo "  $0 -e john.doe@company.com                 # Test with specific email"
}

# Function to make HTTP request with error handling
make_request() {
    local method=$1
    local url=$2
    local data=$3
    local description=$4
    
    echo -e "${BLUE}Testing: ${description}${NC}"
    echo -e "  ${method} ${url}"
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
                       -H "Content-Type: application/json" \
                       -d "$data" \
                       "$url")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url")
    fi
    
    # Extract body and status code
    body=$(echo "$response" | head -n -1)
    status_code=$(echo "$response" | tail -n 1)
    
    if [ "$status_code" -ge 200 ] && [ "$status_code" -lt 300 ]; then
        echo -e "${GREEN}  ✓ Success (HTTP $status_code)${NC}"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
        echo ""
        return 0
    else
        echo -e "${RED}  ✗ Failed (HTTP $status_code)${NC}"
        echo "$body"
        echo ""
        return 1
    fi
}

# Function to check if services are running
check_services() {
    echo -e "${BLUE}Checking if services are running...${NC}"
    
    # Check main orchestration service
    if ! curl -s --connect-timeout 5 "${BASE_URL}/health" > /dev/null; then
        echo -e "${RED}Error: Main orchestration service is not accessible at ${BASE_URL}${NC}"
        echo "Please ensure the application is running locally or update the base URL with -u flag"
        exit 1
    fi
    
    echo -e "${GREEN}Services are accessible${NC}"
    echo ""
}

# Function to test health endpoint
test_health() {
    make_request "GET" "${BASE_URL}/health" "" "Health Check"
}

# Function to initialize database
test_database_initialization() {
    make_request "POST" "${BASE_URL}/initializeDatabase" "" "Database Initialization"
}

# Function to test complete onboarding workflow
test_complete_onboarding() {
    local timestamp=$(date +%Y%m%d%H%M%S)
    local test_data='{
        "firstName": "John",
        "lastName": "TestEmployee'${timestamp}'",
        "email": "'${TEST_EMAIL}'",
        "department": "Engineering",
        "position": "Software Engineer",
        "startDate": "'$(date +%Y-%m-%d)'",
        "requestedAssets": ["laptop", "id_card", "phone"]
    }'
    
    echo -e "${YELLOW}Starting complete onboarding workflow test...${NC}"
    
    # Make the request and capture the response
    if make_request "POST" "${BASE_URL}/onboardEmployee" "$test_data" "Complete Employee Onboarding"; then
        # Extract employee ID from the response for status checking
        EMPLOYEE_ID=$(echo "$body" | jq -r '.onboardingDetails.employee.id' 2>/dev/null || echo "")
        if [ -n "$EMPLOYEE_ID" ] && [ "$EMPLOYEE_ID" != "null" ]; then
            echo -e "${GREEN}Employee ID extracted: ${EMPLOYEE_ID}${NC}"
        fi
    else
        echo -e "${RED}Onboarding workflow failed${NC}"
        return 1
    fi
}

# Function to test onboarding status
test_onboarding_status() {
    if [ -n "$EMPLOYEE_ID" ] && [ "$EMPLOYEE_ID" != "null" ]; then
        make_request "GET" "${BASE_URL}/getOnboardingStatus/${EMPLOYEE_ID}" "" "Get Onboarding Status"
    else
        echo -e "${YELLOW}Skipping status check - Employee ID not available${NC}"
    fi
}

# Function to test individual MCP servers
test_individual_services() {
    echo -e "${YELLOW}Testing individual MCP services...${NC}"
    
    # Test Employee Service
    echo -e "${BLUE}Testing Employee Onboarding MCP Server...${NC}"
    make_request "GET" "${EMPLOYEE_SERVICE_URL}/listEmployees" "" "List Employees"
    
    # Test Asset Service
    echo -e "${BLUE}Testing Asset Allocation MCP Server...${NC}"
    make_request "GET" "${ASSET_SERVICE_URL}/getInventory" "" "Get Asset Inventory"
    
    # Test Email Service
    echo -e "${BLUE}Testing Email Notification MCP Server...${NC}"
    make_request "GET" "${EMAIL_SERVICE_URL}/getEmailLogs" "" "Get Email Logs"
}

# Function to run performance test
test_performance() {
    echo -e "${YELLOW}Running performance test (5 concurrent requests)...${NC}"
    
    local test_data='{
        "firstName": "Perf",
        "lastName": "TestUser",
        "email": "perf.test@company.com",
        "department": "Testing",
        "position": "Performance Tester",
        "startDate": "'$(date +%Y-%m-%d)'",
        "requestedAssets": ["laptop"]
    }'
    
    # Run 5 concurrent requests
    for i in {1..5}; do
        {
            curl -s -X POST \
                 -H "Content-Type: application/json" \
                 -d "${test_data/TestUser/TestUser$i}" \
                 "${BASE_URL}/onboardEmployee" > /dev/null
            echo -e "${GREEN}Request $i completed${NC}"
        } &
    done
    
    wait
    echo -e "${GREEN}Performance test completed${NC}"
}

# Function to run all tests
run_all_tests() {
    echo -e "${GREEN}Employee Onboarding System - Test Suite${NC}"
    echo "========================================"
    echo ""
    
    local start_time=$(date +%s)
    local passed=0
    local failed=0
    
    # Array of test functions
    tests=(
        "test_health"
        "test_database_initialization"
        "test_complete_onboarding"
        "test_onboarding_status"
        "test_individual_services"
    )
    
    for test in "${tests[@]}"; do
        echo -e "${BLUE}Running: $test${NC}"
        if $test; then
            ((passed++))
        else
            ((failed++))
        fi
        echo "----------------------------------------"
    done
    
    # Optional performance test
    echo -e "${YELLOW}Run performance test? (y/N): ${NC}"
    read -r -n 1 response
    echo ""
    if [[ "$response" =~ ^[Yy]$ ]]; then
        if test_performance; then
            ((passed++))
        else
            ((failed++))
        fi
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    echo -e "${GREEN}Test Suite Completed${NC}"
    echo "==================="
    echo -e "Passed: ${GREEN}$passed${NC}"
    echo -e "Failed: ${RED}$failed${NC}"
    echo -e "Duration: ${duration}s"
    
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}All tests passed! 🎉${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed 😞${NC}"
        exit 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--base-url)
            BASE_URL="$2"
            # Update other service URLs based on base URL
            if [[ "$BASE_URL" == *"localhost"* ]]; then
                EMPLOYEE_SERVICE_URL="http://localhost:8082"
                ASSET_SERVICE_URL="http://localhost:8083"
                EMAIL_SERVICE_URL="http://localhost:8084"
            else
                # For cloud deployment, assume all services are behind the same endpoint
                EMPLOYEE_SERVICE_URL="$BASE_URL"
                ASSET_SERVICE_URL="$BASE_URL"
                EMAIL_SERVICE_URL="$BASE_URL"
            fi
            shift 2
            ;;
        -e|--email)
            TEST_EMAIL="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Check prerequisites
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required but not installed${NC}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Warning: jq is not installed. JSON responses will not be formatted${NC}"
fi

# Main execution
check_services
run_all_tests
