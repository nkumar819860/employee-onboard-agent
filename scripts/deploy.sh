#!/bin/bash

# Employee Onboarding System - Deployment Script
# This script handles deployment to different environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="Sandbox"
WORKER_TYPE="MICRO"
WORKERS="1"
APPLICATION_NAME="employee-onboarding-system"

# Function to display usage
usage() {
    echo -e "${BLUE}Usage: $0 [OPTIONS]${NC}"
    echo ""
    echo "Options:"
    echo "  -e, --environment     Target environment (Sandbox, Production) [default: Sandbox]"
    echo "  -u, --username        Anypoint Platform username"
    echo "  -p, --password        Anypoint Platform password"
    echo "  --client-id           Connected App client ID (preferred for automation)"
    echo "  --client-secret       Connected App client secret"
    echo "  -a, --app-name        Application name [default: employee-onboarding-system]"
    echo "  -w, --worker-type     Worker type (MICRO, SMALL, MEDIUM, LARGE) [default: MICRO]"
    echo "  -n, --workers         Number of workers [default: 1]"
    echo "  -l, --local           Deploy locally using Mule runtime"
    echo "  --publish-exchange    Automatically publish to Anypoint Exchange"
    echo "  -h, --help            Display this help message"
    echo ""
    echo "Authentication Methods:"
    echo "  1. Connected App (Recommended for automation):"
    echo "     $0 --client-id <id> --client-secret <secret> -e Production"
    echo ""
    echo "  2. Username/Password:"
    echo "     $0 -u <username> -p <password> -e Production"
    echo ""
    echo "Examples:"
    echo "  $0 -l                                           # Deploy locally"
    echo "  $0 -u user -p pass -e Production               # Deploy with username/password"
    echo "  $0 --client-id abc --client-secret xyz         # Deploy with Connected App"
    echo "  $0 -u user -p pass -w SMALL -n 2              # Deploy with SMALL workers"
    echo "  $0 -u user -p pass --publish-exchange          # Deploy and publish to Exchange"
    echo ""
    echo "CloudHub Setup Required:"
    echo "  1. Create Connected App in Anypoint Platform → Access Management → Connected Apps"
    echo "  2. Grant scopes: Runtime Manager Deploy, Exchange Contributor"
    echo "  3. Configure secure properties in Runtime Manager:"
    echo "     - secure::email.smtp.user"
    echo "     - secure::email.smtp.password"
    echo "     - secure::openai.apiKey"
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"
    
    # Check Java
    if ! command -v java &> /dev/null; then
        echo -e "${RED}Error: Java is not installed or not in PATH${NC}"
        exit 1
    fi
    
    # Check Maven
    if ! command -v mvn &> /dev/null; then
        echo -e "${RED}Error: Maven is not installed or not in PATH${NC}"
        exit 1
    fi
    
    # Check if pom.xml exists
    if [ ! -f "pom.xml" ]; then
        echo -e "${RED}Error: pom.xml not found. Please run from project root directory${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Prerequisites check passed${NC}"
}

# Function to build the application
build_application() {
    echo -e "${BLUE}Building application...${NC}"
    
    mvn clean package -DskipTests
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Build successful${NC}"
    else
        echo -e "${RED}Build failed${NC}"
        exit 1
    fi
}

# Function to deploy locally
deploy_local() {
    echo -e "${BLUE}Deploying locally...${NC}"
    
    mvn mule:deploy
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Local deployment successful${NC}"
        echo -e "${YELLOW}Application will be available at:${NC}"
        echo -e "  Main Orchestration: http://localhost:8080"
        echo -e "  Employee Service:   http://localhost:8082"
        echo -e "  Asset Service:      http://localhost:8083"
        echo -e "  Email Service:      http://localhost:8084"
    else
        echo -e "${RED}Local deployment failed${NC}"
        exit 1
    fi
}

# Function to deploy to CloudHub
deploy_cloudhub() {
    echo -e "${BLUE}Deploying to CloudHub 2.0...${NC}"
    echo -e "Environment: ${ENVIRONMENT}"
    echo -e "Application: ${APPLICATION_NAME}"
    echo -e "Worker Type: ${WORKER_TYPE}"
    echo -e "Workers: ${WORKERS}"
    
    # Use Connected App credentials if provided, otherwise use username/password
    if [ -n "$CLIENT_ID" ] && [ -n "$CLIENT_SECRET" ]; then
        echo -e "${BLUE}Using Connected App authentication${NC}"
        mvn clean package mule:deploy -DmuleDeploy \
            -DclientId="${CLIENT_ID}" \
            -DclientSecret="${CLIENT_SECRET}" \
            -DapplicationName="${APPLICATION_NAME}" \
            -Denvironment="${ENVIRONMENT}" \
            -DworkerType="${WORKER_TYPE}" \
            -Dworkers="${WORKERS}"
    else
        echo -e "${BLUE}Using username/password authentication${NC}"
        mvn clean package mule:deploy -DmuleDeploy \
            -Dusername="${USERNAME}" \
            -Dpassword="${PASSWORD}" \
            -DapplicationName="${APPLICATION_NAME}" \
            -Denvironment="${ENVIRONMENT}" \
            -DworkerType="${WORKER_TYPE}" \
            -Dworkers="${WORKERS}"
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}CloudHub deployment successful${NC}"
        
        # Determine CloudHub URL based on environment
        local cloudhub_url
        case "${ENVIRONMENT,,}" in
            "sandbox")
                cloudhub_url="https://${APPLICATION_NAME}.us-e2.cloudhub.io"
                ;;
            "production")
                cloudhub_url="https://${APPLICATION_NAME}.us-e1.cloudhub.io"
                ;;
            *)
                cloudhub_url="https://${APPLICATION_NAME}.${ENVIRONMENT,,}.cloudhub.io"
                ;;
        esac
        
        echo -e "${YELLOW}Application will be available at: ${cloudhub_url}${NC}"
        echo -e "${YELLOW}Health Check: ${cloudhub_url}/health${NC}"
        echo -e "${YELLOW}API Endpoints:${NC}"
        echo -e "  Complete Onboarding: ${cloudhub_url}/onboardEmployee"
        echo -e "  Get Status: ${cloudhub_url}/getOnboardingStatus/{employeeId}"
    else
        echo -e "${RED}CloudHub deployment failed${NC}"
        exit 1
    fi
}

# Function to publish to Anypoint Exchange
publish_to_exchange() {
    echo -e "${BLUE}Publishing Agent Network asset to Anypoint Exchange...${NC}"
    
    # Use Connected App credentials if provided, otherwise use username/password
    if [ -n "$CLIENT_ID" ] && [ -n "$CLIENT_SECRET" ]; then
        mvn clean deploy \
            -DclientId="${CLIENT_ID}" \
            -DclientSecret="${CLIENT_SECRET}" \
            -DaltDeploymentRepository=anypoint-exchange-v3::default::https://maven.anypoint.mulesoft.com/api/v3/maven
    elif [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
        mvn clean deploy \
            -Dusername="${USERNAME}" \
            -Dpassword="${PASSWORD}" \
            -DaltDeploymentRepository=anypoint-exchange-v3::default::https://maven.anypoint.mulesoft.com/api/v3/maven
    else
        echo -e "${RED}Error: Credentials required for Exchange publishing${NC}"
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Agent Network asset published to Exchange successfully${NC}"
        echo -e "${YELLOW}Asset will be available in Anypoint Exchange for Agent Network integration${NC}"
    else
        echo -e "${RED}Exchange publishing failed${NC}"
        return 1
    fi
}

# Parse command line arguments
LOCAL_DEPLOY=false
PUBLISH_EXCHANGE=false
USERNAME=""
PASSWORD=""
CLIENT_ID=""
CLIENT_SECRET=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -u|--username)
            USERNAME="$2"
            shift 2
            ;;
        -p|--password)
            PASSWORD="$2"
            shift 2
            ;;
        --client-id)
            CLIENT_ID="$2"
            shift 2
            ;;
        --client-secret)
            CLIENT_SECRET="$2"
            shift 2
            ;;
        -a|--app-name)
            APPLICATION_NAME="$2"
            shift 2
            ;;
        -w|--worker-type)
            WORKER_TYPE="$2"
            shift 2
            ;;
        -n|--workers)
            WORKERS="$2"
            shift 2
            ;;
        -l|--local)
            LOCAL_DEPLOY=true
            shift
            ;;
        --publish-exchange)
            PUBLISH_EXCHANGE=true
            shift
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

# Main execution
echo -e "${GREEN}Employee Onboarding System - Deployment Script${NC}"
echo "================================================="

check_prerequisites
build_application

if [ "$LOCAL_DEPLOY" = true ]; then
    deploy_local
else
    # Validate required parameters for CloudHub deployment
    if [ -z "$CLIENT_ID" ] && [ -z "$USERNAME" ]; then
        echo -e "${RED}Error: Either Connected App credentials (--client-id --client-secret) or username/password (-u -p) are required for CloudHub deployment${NC}"
        echo "Use --client-id <id> --client-secret <secret> for Connected App authentication"
        echo "Or use -u <username> -p <password> for username/password authentication"
        echo "Or deploy locally with -l"
        exit 1
    fi
    
    if [ -n "$CLIENT_ID" ] && [ -z "$CLIENT_SECRET" ]; then
        echo -e "${RED}Error: Client secret is required when using client ID${NC}"
        exit 1
    fi
    
    if [ -n "$USERNAME" ] && [ -z "$PASSWORD" ]; then
        echo -e "${RED}Error: Password is required when using username${NC}"
        exit 1
    fi
    
    deploy_cloudhub
    
    # Ask if user wants to publish to Exchange
    if [ "$PUBLISH_EXCHANGE" = false ]; then
        echo -e "${YELLOW}Do you want to publish the Agent Network asset to Anypoint Exchange? (y/N): ${NC}"
        read -r -n 1 response
        echo ""
        if [[ "$response" =~ ^[Yy]$ ]]; then
            PUBLISH_EXCHANGE=true
        fi
    fi
    
    if [ "$PUBLISH_EXCHANGE" = true ]; then
        publish_to_exchange
    fi
fi

echo -e "${GREEN}Deployment completed successfully!${NC}"
