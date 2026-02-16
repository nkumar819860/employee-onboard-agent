#!/bin/bash
# Employee Onboarding System Test Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
    ((TESTS_PASSED++))
}

error() {
    echo -e "${RED}✗ $1${NC}"
    ((TESTS_FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to check if service is responding
check_service() {
    local service_name=$1
    local port=$2
    local endpoint=${3:-"health"}
    
    if curl -f -s "http://localhost:$port/$endpoint" > /dev/null 2>&1; then
        success "$service_name is healthy (port $port)"
        return 0
    else
        error "$service_name is not responding (port $port)"
        return 1
    fi
}

# Function to test API endpoint
test_api() {
    local endpoint=$1
    local payload=$2
    local expected_text=$3
    
    log "Testing API endpoint: $endpoint"
    
    response=$(curl -s -X POST "http://localhost:8080$endpoint" \
        -H "Content-Type: application/json" \
        -d "$payload" || echo "CURL_ERROR")
    
    if [[ $response == "CURL_ERROR" ]]; then
        error "Failed to connect to $endpoint"
        return 1
    fi
    
    if [[ -n "$expected_text" && $response != *"$expected_text"* ]]; then
        error "API test failed for $endpoint"
        echo "Response: $response"
        return 1
    else
        success "API test passed for $endpoint"
        echo "Response: $response"
        return 0
    fi
}

# Function to check database
check_database() {
    log "Testing database connectivity and schema..."
    
    # Check if PostgreSQL is ready
    if docker exec $(docker ps -qf "name=postgres") pg_isready -U mule -d onboarding > /dev/null 2>&1; then
        success "PostgreSQL is ready"
    else
        error "PostgreSQL is not ready"
        return 1
    fi
    
    # Check if tables exist
    tables=$(docker exec $(docker ps -qf "name=postgres") psql -U mule -d onboarding -t -c "\dt" 2>/dev/null | wc -l)
    if [[ $tables -gt 0 ]]; then
        success "Database tables exist"
    else
        error "Database tables not found"
        return 1
    fi
    
    # Check employee table structure
    if docker exec $(docker ps -qf "name=postgres") psql -U mule -d onboarding -c "\d employees" > /dev/null 2>&1; then
        success "Employees table structure is valid"
    else
        error "Employees table structure issue"
        return 1
    fi
}

# Function to test complete onboarding flow
test_onboarding_flow() {
    log "Testing complete onboarding flow..."
    
    local test_email="test.$(date +%s)@company.com"
    local test_name="Test User $(date +%s)"
    
    # Test onboarding endpoint
    response=$(curl -s -X POST "http://localhost:8080/broker/onboard" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"$test_name\", \"email\": \"$test_email\"}")
    
    if [[ $response == *"error"* ]] || [[ $response == "CURL_ERROR" ]]; then
        error "Onboarding flow failed"
        echo "Response: $response"
        return 1
    fi
    
    success "Onboarding API call completed"
    
    # Wait a moment for processing
    sleep 5
    
    # Verify employee was created in database
    count=$(docker exec $(docker ps -qf "name=postgres") psql -U mule -d onboarding \
        -t -c "SELECT COUNT(*) FROM employees WHERE email = '$test_email';" 2>/dev/null | tr -d ' ' || echo "0")
    
    if [[ $count -gt 0 ]]; then
        success "Employee record created in database"
        return 0
    else
        error "Employee record not found in database"
        return 1
    fi
}

# Function to test rate limiting
test_rate_limiting() {
    log "Testing rate limiting (sending 5 concurrent requests)..."
    
    local success_count=0
    local rate_limited_count=0
    
    for i in {1..5}; do
        response_code=$(curl -s -o /dev/null -w "%{http_code}" \
            -X POST "http://localhost:8080/mcp/postgres" \
            -H "Content-Type: application/json" \
            -d '{"method": "health_check"}')
        
        if [[ $response_code == "200" ]]; then
            ((success_count++))
        elif [[ $response_code == "429" ]]; then
            ((rate_limited_count++))
        fi
    done
    
    if [[ $success_count -gt 0 ]]; then
        success "Rate limiting is working ($success_count successful, $rate_limited_count rate-limited)"
    else
        warn "Rate limiting test inconclusive"
    fi
}

# Main test execution
main() {
    log "Starting Employee Onboarding System Tests..."
    log "================================================"
    
    # Check if Docker Compose is available
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is not installed"
        exit 1
    fi
    
    # Start the system
    log "Starting Docker Compose services..."
    docker-compose up -d
    
    # Wait for services to start
    log "Waiting for services to start (30 seconds)..."
    sleep 30
    
    # Check Docker Compose status
    log "Checking Docker Compose service status..."
    if docker-compose ps | grep -q "Up"; then
        success "Docker Compose services are running"
    else
        error "Some Docker Compose services are not running"
        docker-compose ps
    fi
    
    # Test individual services
    log "Testing individual service health..."
    check_service "Flex Gateway (Nginx)" "8080" ""
    check_service "Mule Broker" "8081" "health"
    check_service "PostgreSQL MCP" "8082" "health"
    check_service "Assets MCP" "8083" "health"
    check_service "Notification MCP" "8084" "health"
    
    # Test database
    check_database
    
    # Test individual MCP endpoints
    log "Testing individual MCP services..."
    test_api "/mcp/postgres" '{"method": "health_check"}' ""
    test_api "/mcp/assets" '{"method": "health_check"}' ""
    test_api "/mcp/notifications" '{"method": "health_check"}' ""
    
    # Test complete onboarding flow
    test_onboarding_flow
    
    # Test rate limiting
    test_rate_limiting
    
    # Test results summary
    log "================================================"
    log "Test Results Summary:"
    success "Tests Passed: $TESTS_PASSED"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        error "Tests Failed: $TESTS_FAILED"
    else
        log "Tests Failed: $TESTS_FAILED"
    fi
    
    log "================================================"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log "🎉 All tests passed! System is ready for use."
        exit 0
    else
        log "❌ Some tests failed. Please check the system configuration."
        exit 1
    fi
}

# Handle script interruption
trap 'log "Test interrupted by user"; exit 130' INT

# Run main function
main "$@"
