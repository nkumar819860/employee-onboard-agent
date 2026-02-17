#!/bin/bash

# Hybrid Deployment Script for Employee Onboarding Agent Network
# Supports deployment to both Docker (local) and Anypoint Platform (CloudHub 2.0)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

# Function to show usage
show_usage() {
    echo "🚀 Employee Onboarding Agent Network - Hybrid Deployment Script"
    echo ""
    echo "Usage: $0 [OPTIONS] DEPLOYMENT_TARGET"
    echo ""
    echo "DEPLOYMENT_TARGET:"
    echo "  docker      Deploy to local Docker environment"
    echo "  anypoint    Deploy to Anypoint Platform (CloudHub 2.0)"
    echo "  both        Deploy to both Docker and Anypoint Platform"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help              Show this help message"
    echo "  -e, --env FILE          Load environment variables from file"
    echo "  -v, --verbose           Enable verbose output"
    echo "  -c, --clean             Clean existing deployments before deploying"
    echo "  --docker-only           Skip Anypoint deployment when using 'both'"
    echo "  --anypoint-only         Skip Docker deployment when using 'both'"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 docker                           # Deploy to Docker only"
    echo "  $0 anypoint -e .env.anypoint       # Deploy to Anypoint with env file"
    echo "  $0 both --clean                    # Clean and deploy to both platforms"
    echo ""
    echo "ENVIRONMENT VARIABLES (for Anypoint deployment):"
    echo "  ANYPOINT_ORG_ID         Anypoint Organization ID"
    echo "  ANYPOINT_CLIENT_ID      Anypoint Client ID"
    echo "  ANYPOINT_CLIENT_SECRET  Anypoint Client Secret"
    echo "  ANYPOINT_USERNAME       Anypoint Username"
    echo "  ANYPOINT_PASSWORD       Anypoint Password"
    echo "  ANYPOINT_ENV            Environment name (default: Sandbox)"
    echo "  CLOUDHUB_REGION         CloudHub region (default: us-east-1)"
    echo ""
}

# Function to check prerequisites
check_prerequisites() {
    local platform=$1
    
    if [[ "$platform" == "docker" || "$platform" == "both" ]]; then
        print_info "Checking Docker prerequisites..."
        if ! command -v docker &> /dev/null; then
            print_error "Docker is not installed or not in PATH"
            return 1
        fi
        
        if ! command -v docker-compose &> /dev/null; then
            print_error "Docker Compose is not installed or not in PATH"
            return 1
        fi
        
        print_status "Docker prerequisites satisfied"
    fi
    
    if [[ "$platform" == "anypoint" || "$platform" == "both" ]]; then
        print_info "Checking Anypoint prerequisites..."
        
        if ! command -v anypoint-cli &> /dev/null; then
            print_error "Anypoint CLI is not installed. Install with: npm install -g anypoint-cli"
            return 1
        fi
        
        if ! command -v mvn &> /dev/null; then
            print_error "Maven is not installed or not in PATH"
            return 1
        fi
        
        # Check required environment variables
        local required_vars=("ANYPOINT_ORG_ID" "ANYPOINT_CLIENT_ID" "ANYPOINT_CLIENT_SECRET" "ANYPOINT_USERNAME" "ANYPOINT_PASSWORD")
        for var in "${required_vars[@]}"; do
            if [[ -z "${!var}" ]]; then
                print_error "Required environment variable $var is not set"
                return 1
            fi
        done
        
        print_status "Anypoint prerequisites satisfied"
    fi
}

# Function to deploy to Docker
deploy_docker() {
    print_info "🐳 Starting Docker deployment..."
    
    if [[ "$CLEAN_DEPLOYMENT" == "true" ]]; then
        print_info "Cleaning existing Docker deployment..."
        docker-compose down -v --remove-orphans 2>/dev/null || true
    fi
    
    # Start Docker services
    print_info "Starting Docker services..."
    docker-compose up -d
    
    # Wait for services to be ready
    print_info "Waiting for services to be ready..."
    sleep 30
    
    # Validate Docker deployment
    print_info "Validating Docker deployment..."
    
    # Check if containers are running
    local services=("postgres" "flex-gateway" "postgres-mcp" "assets-mcp" "notification-mcp" "mule-broker")
    for service in "${services[@]}"; do
        if docker-compose ps "$service" | grep -q "Up"; then
            print_status "Service $service is running"
        else
            print_error "Service $service is not running"
            return 1
        fi
    done
    
    # Test endpoints
    local endpoints=(
        "http://localhost:8080/health:Flex Gateway"
        "http://localhost:8081/api/health:Mule Broker"
        "http://localhost:8082/api/health:PostgreSQL MCP"
        "http://localhost:8083/api/health:Assets MCP"
        "http://localhost:8084/api/health:Notification MCP"
    )
    
    for endpoint_info in "${endpoints[@]}"; do
        IFS=':' read -r url name <<< "$endpoint_info"
        if curl -s -f "$url" >/dev/null 2>&1; then
            print_status "$name endpoint is responsive"
        else
            print_warning "$name endpoint is not responding (this may be normal during startup)"
        fi
    done
    
    print_status "Docker deployment completed successfully!"
    
    # Save Docker deployment info
    cat << EOF > docker-deployment-info.json
{
  "deployment": {
    "platform": "docker",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "compose_file": "docker-compose.yml"
  },
  "services": {
    "flex-gateway": "http://localhost:8080",
    "mule-broker": "http://localhost:8081",
    "postgres-mcp": "http://localhost:8082", 
    "assets-mcp": "http://localhost:8083",
    "notification-mcp": "http://localhost:8084",
    "postgres-db": "localhost:5432"
  },
  "agent_network": {
    "config_file": "agent-network.yaml",
    "exchange_file": "exchange.json",
    "test_endpoint": "http://localhost:8080/broker/onboard"
  }
}
EOF
    
    print_info "Docker deployment information saved to: docker-deployment-info.json"
}

# Function to deploy to Anypoint Platform
deploy_anypoint() {
    print_info "☁️ Starting Anypoint Platform deployment..."
    
    cd anypoint-deployment
    
    # Make deployment script executable
    chmod +x deploy-to-anypoint.sh
    
    # Run Anypoint deployment
    if [[ "$VERBOSE" == "true" ]]; then
        ./deploy-to-anypoint.sh
    else
        ./deploy-to-anypoint.sh 2>/dev/null
    fi
    
    cd - > /dev/null
    
    print_status "Anypoint Platform deployment completed successfully!"
}

# Function to show deployment summary
show_deployment_summary() {
    local platform=$1
    
    echo ""
    echo "🎉 Deployment Summary"
    echo "===================="
    
    case $platform in
        "docker")
            echo "✅ Docker deployment completed"
            echo "🔗 Local URLs:"
            echo "   • Agent Network: http://localhost:8080"
            echo "   • HR Broker: http://localhost:8081"
            echo "   • PostgreSQL MCP: http://localhost:8082"
            echo "   • Assets MCP: http://localhost:8083"
            echo "   • Notification MCP: http://localhost:8084"
            echo "   • React Client: http://localhost:3001"
            echo ""
            echo "📋 Test the deployment:"
            echo "   curl -X POST http://localhost:8080/broker/onboard \\"
            echo "        -H 'Content-Type: application/json' \\"
            echo "        -d '{\"name\":\"John Doe\",\"email\":\"john@company.com\",\"role\":\"developer\"}'"
            ;;
        "anypoint")
            if [[ -f "anypoint-deployment/deployment-info.json" ]]; then
                local env=${ANYPOINT_ENV:-Sandbox}
                local region=${CLOUDHUB_REGION:-us-east-1}
                echo "✅ Anypoint Platform deployment completed"
                echo "☁️ CloudHub 2.0 URLs:"
                echo "   • HR Agent: https://hr-agent-$env.$region.cloudhub.io"
                echo "   • PostgreSQL MCP: https://postgres-mcp-$env.$region.cloudhub.io"
                echo "   • Assets MCP: https://assets-mcp-$env.$region.cloudhub.io"
                echo "   • Notification MCP: https://notification-mcp-$env.$region.cloudhub.io"
                echo ""
                echo "📊 Anypoint Visualizer: https://anypoint.mulesoft.com/visualizer"
                echo "📦 Anypoint Exchange: https://anypoint.mulesoft.com/exchange/${ANYPOINT_ORG_ID}"
            fi
            ;;
        "both")
            echo "✅ Hybrid deployment completed (Docker + Anypoint Platform)"
            echo ""
            echo "🐳 Docker (Local Development):"
            echo "   • Agent Network: http://localhost:8080"
            echo "   • React Client: http://localhost:3001"
            echo ""
            echo "☁️ Anypoint Platform (Production):"
            if [[ -f "anypoint-deployment/deployment-info.json" ]]; then
                local env=${ANYPOINT_ENV:-Sandbox}
                local region=${CLOUDHUB_REGION:-us-east-1}
                echo "   • HR Agent: https://hr-agent-$env.$region.cloudhub.io"
                echo "   • Visualizer: https://anypoint.mulesoft.com/visualizer"
                echo "   • Exchange: https://anypoint.mulesoft.com/exchange/${ANYPOINT_ORG_ID}"
            fi
            ;;
    esac
    
    echo ""
    echo "📁 Configuration Files:"
    echo "   • Docker: agent-network.yaml, exchange.json"
    echo "   • Anypoint: anypoint-deployment/agent-network-anypoint.yaml"
    echo "   • React Client: react-mcp-client/"
    echo ""
}

# Parse command line arguments
DEPLOYMENT_TARGET=""
ENV_FILE=""
VERBOSE="false"
CLEAN_DEPLOYMENT="false"
DOCKER_ONLY="false"
ANYPOINT_ONLY="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -e|--env)
            ENV_FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE="true"
            shift
            ;;
        -c|--clean)
            CLEAN_DEPLOYMENT="true"
            shift
            ;;
        --docker-only)
            DOCKER_ONLY="true"
            shift
            ;;
        --anypoint-only)
            ANYPOINT_ONLY="true"
            shift
            ;;
        docker|anypoint|both)
            DEPLOYMENT_TARGET="$1"
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate arguments
if [[ -z "$DEPLOYMENT_TARGET" ]]; then
    print_error "Deployment target is required"
    show_usage
    exit 1
fi

# Load environment file if specified
if [[ -n "$ENV_FILE" ]]; then
    if [[ -f "$ENV_FILE" ]]; then
        print_info "Loading environment variables from $ENV_FILE"
        # shellcheck disable=SC1090
        source "$ENV_FILE"
    else
        print_error "Environment file not found: $ENV_FILE"
        exit 1
    fi
fi

# Main deployment logic
echo "🚀 Employee Onboarding Agent Network - Hybrid Deployment"
echo "========================================================"
echo ""
print_info "Deployment target: $DEPLOYMENT_TARGET"
echo ""

case $DEPLOYMENT_TARGET in
    "docker")
        check_prerequisites "docker" || exit 1
        deploy_docker
        show_deployment_summary "docker"
        ;;
    "anypoint")
        check_prerequisites "anypoint" || exit 1
        deploy_anypoint
        show_deployment_summary "anypoint"
        ;;
    "both")
        if [[ "$ANYPOINT_ONLY" == "true" ]]; then
            check_prerequisites "anypoint" || exit 1
            deploy_anypoint
        elif [[ "$DOCKER_ONLY" == "true" ]]; then
            check_prerequisites "docker" || exit 1
            deploy_docker
        else
            check_prerequisites "both" || exit 1
            
            # Deploy to Docker first
            print_info "🚀 Starting hybrid deployment (Docker + Anypoint)..."
            deploy_docker
            
            print_info "⏳ Waiting before Anypoint deployment..."
            sleep 10
            
            # Deploy to Anypoint
            deploy_anypoint
        fi
        show_deployment_summary "both"
        ;;
    *)
        print_error "Invalid deployment target: $DEPLOYMENT_TARGET"
        show_usage
        exit 1
        ;;
esac

echo ""
print_status "Deployment completed successfully! 🎉"
