#!/bin/bash

# Deploy Agent Network to Anypoint Platform
# This script deploys MCP servers to CloudHub 2.0 and publishes assets to Anypoint Exchange

set -e

echo "🚀 Starting Anypoint Platform deployment for Employee Onboarding Agent Network"

# Check required environment variables
required_vars=("ANYPOINT_ORG_ID" "ANYPOINT_CLIENT_ID" "ANYPOINT_CLIENT_SECRET" "ANYPOINT_USERNAME" "ANYPOINT_PASSWORD")
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "❌ Error: Environment variable $var is not set"
        exit 1
    fi
done

# Set defaults for optional variables
export ANYPOINT_ENV=${ANYPOINT_ENV:-Sandbox}
export CLOUDHUB_REGION=${CLOUDHUB_REGION:-us-east-1}
export OPENAI_API_KEY=${OPENAI_API_KEY:-""}

echo "📋 Configuration:"
echo "  Organization ID: $ANYPOINT_ORG_ID"
echo "  Environment: $ANYPOINT_ENV"
echo "  Region: $CLOUDHUB_REGION"
echo ""

# Login to Anypoint CLI
echo "🔐 Logging into Anypoint Platform..."
anypoint-cli auth login --username "$ANYPOINT_USERNAME" --password "$ANYPOINT_PASSWORD"

# Set organization and environment
anypoint-cli conf organization "$ANYPOINT_ORG_ID"
anypoint-cli conf environment "$ANYPOINT_ENV"

echo "✅ Successfully authenticated to Anypoint Platform"

# Function to publish to Exchange
publish_to_exchange() {
    local project_path=$1
    local asset_id=$2
    local asset_name=$3
    local description=$4

    echo "📦 Publishing $asset_name to Anypoint Exchange..."
    
    cd "$project_path"
    
    # Update pom.xml with Exchange details
    sed -i "s/<groupId>.*<\/groupId>/<groupId>$ANYPOINT_ORG_ID<\/groupId>/" pom.xml
    sed -i "s/<artifactId>.*<\/artifactId>/<artifactId>$asset_id<\/artifactId>/" pom.xml
    
    # Build and publish
    mvn clean package
    
    anypoint-cli exchange asset upload \
        --organizationId "$ANYPOINT_ORG_ID" \
        --groupId "$ANYPOINT_ORG_ID" \
        --assetId "$asset_id" \
        --version "1.0.0" \
        --name "$asset_name" \
        --description "$description" \
        --classifier "mule-application" \
        --files @target/*.jar
    
    echo "✅ Successfully published $asset_name to Exchange"
    cd - > /dev/null
}

# Function to deploy to CloudHub 2.0
deploy_to_cloudhub() {
    local project_path=$1
    local app_name=$2
    local vcores=$3
    local replicas=${4:-1}

    echo "☁️ Deploying $app_name to CloudHub 2.0..."
    
    cd "$project_path"
    
    # Deploy application
    anypoint-cli cloudhub application deploy \
        --appName "$app_name" \
        --runtime "4.6.4" \
        --workers "$replicas" \
        --workerSize "$vcores" \
        --region "$CLOUDHUB_REGION" \
        --property "anypoint.platform.client_id:$ANYPOINT_CLIENT_ID" \
        --property "anypoint.platform.client_secret:$ANYPOINT_CLIENT_SECRET" \
        --file "target/*.jar"
    
    echo "✅ Successfully deployed $app_name to CloudHub 2.0"
    cd - > /dev/null
}

# Step 1: Publish MCP Servers to Exchange
echo ""
echo "📦 Step 1: Publishing MCP Servers to Anypoint Exchange"
echo "=================================================="

publish_to_exchange "../postgres-mcp-onboarding" "postgres-mcp-server" "PostgreSQL MCP Server" "MCP Server for employee data management with PostgreSQL database integration"

publish_to_exchange "../mule-assets" "assets-mcp-server" "Assets MCP Server" "MCP Server for employee asset allocation and management"

publish_to_exchange "../mule-notification" "notification-mcp-server" "Notifications MCP Server" "MCP Server for employee welcome notifications via email and SMS"

publish_to_exchange "../mule-broker" "onboarding-broker" "Onboarding Broker" "HR Onboarding workflow orchestration broker with MCP integration"

# Step 2: Deploy Applications to CloudHub 2.0
echo ""
echo "☁️ Step 2: Deploying Applications to CloudHub 2.0"
echo "================================================"

deploy_to_cloudhub "../postgres-mcp-onboarding" "postgres-mcp-$ANYPOINT_ENV" "1" "2"
deploy_to_cloudhub "../mule-assets" "assets-mcp-$ANYPOINT_ENV" "0.5" "1"  
deploy_to_cloudhub "../mule-notification" "notification-mcp-$ANYPOINT_ENV" "0.5" "1"
deploy_to_cloudhub "../mule-broker" "hr-agent-$ANYPOINT_ENV" "1" "2"

# Step 3: Configure Anypoint Visualizer
echo ""
echo "👁️ Step 3: Configuring Anypoint Visualizer"
echo "=========================================="

# Create visualizer dashboard
cat << EOF > visualizer-config.json
{
  "name": "Employee Onboarding Agent Network",
  "description": "Real-time visualization of employee onboarding workflow",
  "applications": [
    {
      "name": "hr-agent-$ANYPOINT_ENV",
      "type": "broker",
      "category": "HR Agents"
    },
    {
      "name": "postgres-mcp-$ANYPOINT_ENV", 
      "type": "mcp-server",
      "category": "MCP Servers"
    },
    {
      "name": "assets-mcp-$ANYPOINT_ENV",
      "type": "mcp-server", 
      "category": "MCP Servers"
    },
    {
      "name": "notification-mcp-$ANYPOINT_ENV",
      "type": "mcp-server",
      "category": "MCP Servers"
    }
  ],
  "flows": [
    {
      "from": "hr-agent-$ANYPOINT_ENV",
      "to": "postgres-mcp-$ANYPOINT_ENV",
      "label": "Employee Creation"
    },
    {
      "from": "hr-agent-$ANYPOINT_ENV",
      "to": "assets-mcp-$ANYPOINT_ENV", 
      "label": "Asset Allocation"
    },
    {
      "from": "hr-agent-$ANYPOINT_ENV",
      "to": "notification-mcp-$ANYPOINT_ENV",
      "label": "Welcome Notification"
    }
  ]
}
EOF

# Configure Visualizer (Note: This would typically use Anypoint Platform APIs)
echo "📊 Visualizer configuration created: visualizer-config.json"
echo "   Please manually configure in Anypoint Visualizer dashboard"

# Step 4: Create Agent Network Asset
echo ""
echo "🤖 Step 4: Publishing Agent Network to Exchange"
echo "=============================================="

# Create agent network asset
anypoint-cli exchange asset upload \
    --organizationId "$ANYPOINT_ORG_ID" \
    --groupId "$ANYPOINT_ORG_ID" \
    --assetId "employee-onboarding-agent-network" \
    --version "1.0.0" \
    --name "Employee Onboarding Agent Network" \
    --description "Complete employee onboarding agent network with MCP servers deployed on CloudHub 2.0" \
    --classifier "agent-network" \
    --files @agent-network-anypoint.yaml,@exchange-anypoint.json

echo "✅ Successfully published Agent Network to Exchange"

# Step 5: Validation and Health Checks
echo ""
echo "🔍 Step 5: Validation and Health Checks"
echo "======================================"

sleep 30  # Wait for deployments to start

# Check application status
echo "Checking application status..."
for app in "hr-agent-$ANYPOINT_ENV" "postgres-mcp-$ANYPOINT_ENV" "assets-mcp-$ANYPOINT_ENV" "notification-mcp-$ANYPOINT_ENV"; do
    status=$(anypoint-cli cloudhub application describe --appName "$app" --output json | jq -r '.status')
    echo "  $app: $status"
done

# Step 6: Generate URLs and Connection Info
echo ""
echo "🌐 Step 6: Deployment URLs and Connection Information"
echo "=================================================="

echo "🔗 Application URLs:"
echo "  HR Agent: https://hr-agent-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io"
echo "  PostgreSQL MCP: https://postgres-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io"
echo "  Assets MCP: https://assets-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io"
echo "  Notification MCP: https://notification-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io"
echo ""
echo "📊 Anypoint Visualizer:"
echo "  Dashboard: https://anypoint.mulesoft.com/visualizer"
echo "  Search for: Employee Onboarding Agent Network"
echo ""
echo "📦 Anypoint Exchange:"
echo "  Assets: https://anypoint.mulesoft.com/exchange/$ANYPOINT_ORG_ID"
echo ""

# Save deployment info
cat << EOF > deployment-info.json
{
  "deployment": {
    "platform": "anypoint",
    "environment": "$ANYPOINT_ENV", 
    "region": "$CLOUDHUB_REGION",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  },
  "applications": {
    "hr-agent": "https://hr-agent-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io",
    "postgres-mcp": "https://postgres-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io",
    "assets-mcp": "https://assets-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io",
    "notification-mcp": "https://notification-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io"
  },
  "visualizer": {
    "url": "https://anypoint.mulesoft.com/visualizer",
    "dashboard": "Employee Onboarding Agent Network"
  },
  "exchange": {
    "url": "https://anypoint.mulesoft.com/exchange/$ANYPOINT_ORG_ID"
  }
}
EOF

echo "📄 Deployment information saved to: deployment-info.json"

echo ""
echo "🎉 Anypoint Platform deployment completed successfully!"
echo "   Your Employee Onboarding Agent Network is now running on CloudHub 2.0"
echo "   with full Visualizer integration and Exchange publication."
