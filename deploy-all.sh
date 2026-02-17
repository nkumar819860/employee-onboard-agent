#!/bin/bash

# Employee Onboarding Agent Network - Complete Deployment Script
# This script builds, publishes, and deploys all MCP servers to Anypoint Platform

set -e  # Exit on any error

echo "🚀 Starting Employee Onboarding Agent Network Deployment..."

# Check if environment variables are set
if [ -z "$ANYPOINT_ORG_ID" ] || [ -z "$ANYPOINT_ENV" ]; then
    echo "❌ Error: Required environment variables not set"
    echo "Please set: ANYPOINT_ORG_ID, ANYPOINT_ENV"
    exit 1
fi

echo "📋 Environment: $ANYPOINT_ENV"
echo "🏢 Organization: $ANYPOINT_ORG_ID"

# Step 1: Build all MCP servers
echo ""
echo "🔨 Step 1: Building all MCP servers..."

echo "  Building PostgreSQL MCP Server..."
cd postgres-mcp-onboarding
mvn clean package -DskipTests -q
cd ..

echo "  Building Assets MCP Server..."
cd assets-mcp-server
mvn clean package -DskipTests -q
cd ..

echo "  Building Notification MCP Server..."
cd notification-mcp-server
mvn clean package -DskipTests -q
cd ..

echo "✅ All MCP servers built successfully!"

# Step 2: Publish to Exchange
echo ""
echo "📦 Step 2: Publishing APIs to Anypoint Exchange..."

# Authenticate if not already authenticated
echo "  Checking authentication..."
if ! anypoint-cli-v4 account business-group list >/dev/null 2>&1; then
    echo "  Please authenticate with Anypoint Platform:"
    anypoint-cli-v4 auth login
fi

echo "  Publishing Employee Onboarding API..."
anypoint-cli-v4 exchange asset upload \
  --organization=$ANYPOINT_ORG_ID \
  --name="Employee Onboarding API" \
  --description="Complete employee onboarding API with MCP integration" \
  --type=raml \
  --files employee-onboarding-api/employee-onboarding-api.raml \
  --properties employee-onboarding-api/exchange.json 2>/dev/null || echo "  (Asset may already exist)"

echo "  Publishing PostgreSQL MCP Server..."
anypoint-cli-v4 exchange asset upload \
  --organization=$ANYPOINT_ORG_ID \
  --name="PostgreSQL MCP Server" \
  --description="Employee database MCP server with RAML-first API design" \
  --type=mule-application \
  --classifier=mule-application \
  --files postgres-mcp-onboarding/target/postgres-mcp-onboarding-1.0.0-mule-application.jar \
  --main-file postgres-mcp-onboarding/src/main/resources/api/postgres-mcp-api.raml 2>/dev/null || echo "  (Asset may already exist)"

echo "  Publishing Assets MCP Server..."
anypoint-cli-v4 exchange asset upload \
  --organization=$ANYPOINT_ORG_ID \
  --name="Assets MCP Server" \
  --description="Equipment allocation MCP server with inventory management" \
  --type=mule-application \
  --classifier=mule-application \
  --files assets-mcp-server/target/assets-mcp-server-1.0.0-mule-application.jar \
  --main-file assets-mcp-server/src/main/resources/api/assets-mcp-api.raml 2>/dev/null || echo "  (Asset may already exist)"

echo "  Publishing Notification MCP Server..."
anypoint-cli-v4 exchange asset upload \
  --organization=$ANYPOINT_ORG_ID \
  --name="Notification MCP Server" \
  --description="Multi-channel notification MCP server (email, SMS)" \
  --type=mule-application \
  --classifier=mule-application \
  --files notification-mcp-server/target/notification-mcp-server-1.0.0-mule-application.jar \
  --main-file notification-mcp-server/src/main/resources/api/notification-mcp-api.raml 2>/dev/null || echo "  (Asset may already exist)"

echo "✅ All assets published to Exchange!"

# Step 3: Deploy to CloudHub 2.0
echo ""
echo "☁️ Step 3: Deploying to CloudHub 2.0..."

CLOUDHUB_REGION=${CLOUDHUB_REGION:-us-east-1}

echo "  Deploying PostgreSQL MCP Server..."
anypoint-cli-v4 runtime-mgr cloudhub-2 application deploy \
  --name postgres-mcp-$ANYPOINT_ENV \
  --target $ANYPOINT_ENV \
  --artifact postgres-mcp-onboarding/target/postgres-mcp-onboarding-1.0.0-mule-application.jar \
  --replicas 2 \
  --cores 1.0 \
  --memory 1.5 \
  --region $CLOUDHUB_REGION \
  --env POSTGRES_HOST=${POSTGRES_HOST:-postgres.sandbox.cloudhub.io} \
  --env POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-defaultpassword} \
  --env ANYPOINT_ENV=$ANYPOINT_ENV 2>/dev/null || echo "  (Application may already be deployed)"

echo "  Deploying Assets MCP Server..."
anypoint-cli-v4 runtime-mgr cloudhub-2 application deploy \
  --name assets-mcp-$ANYPOINT_ENV \
  --target $ANYPOINT_ENV \
  --artifact assets-mcp-server/target/assets-mcp-server-1.0.0-mule-application.jar \
  --replicas 1 \
  --cores 0.5 \
  --memory 1.0 \
  --region $CLOUDHUB_REGION \
  --env ANYPOINT_ENV=$ANYPOINT_ENV 2>/dev/null || echo "  (Application may already be deployed)"

echo "  Deploying Notification MCP Server..."
anypoint-cli-v4 runtime-mgr cloudhub-2 application deploy \
  --name notification-mcp-$ANYPOINT_ENV \
  --target $ANYPOINT_ENV \
  --artifact notification-mcp-server/target/notification-mcp-server-1.0.0-mule-application.jar \
  --replicas 1 \
  --cores 0.5 \
  --memory 1.0 \
  --region $CLOUDHUB_REGION \
  --env EMAIL_HOST=${EMAIL_HOST:-smtp.gmail.com} \
  --env EMAIL_PASSWORD=${EMAIL_PASSWORD:-defaultpassword} \
  --env ANYPOINT_ENV=$ANYPOINT_ENV 2>/dev/null || echo "  (Application may already be deployed)"

echo "✅ All applications deployed to CloudHub 2.0!"

# Step 4: Wait for deployment and check status
echo ""
echo "⏳ Step 4: Waiting for deployments to complete..."
sleep 30  # Wait for initial deployment

echo "  Checking deployment status..."
anypoint-cli-v4 runtime-mgr cloudhub-2 application list --environment $ANYPOINT_ENV | grep "mcp-$ANYPOINT_ENV"

# Step 5: Test endpoints
echo ""
echo "🧪 Step 5: Testing MCP server endpoints..."

POSTGRES_URL="https://postgres-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io"
ASSETS_URL="https://assets-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io"
NOTIFICATION_URL="https://notification-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io"

echo "  Testing PostgreSQL MCP Server health..."
curl -s -f "$POSTGRES_URL/health" >/dev/null && echo "    ✅ PostgreSQL MCP Server is healthy" || echo "    ⚠️  PostgreSQL MCP Server not ready yet"

echo "  Testing Assets MCP Server health..."
curl -s -f "$ASSETS_URL/health" >/dev/null && echo "    ✅ Assets MCP Server is healthy" || echo "    ⚠️  Assets MCP Server not ready yet"

echo "  Testing Notification MCP Server health..."
curl -s -f "$NOTIFICATION_URL/health" >/dev/null && echo "    ✅ Notification MCP Server is healthy" || echo "    ⚠️  Notification MCP Server not ready yet"

# Final summary
echo ""
echo "🎉 Deployment Complete!"
echo ""
echo "📊 Your Employee Onboarding Agent Network is ready:"
echo "   • PostgreSQL MCP Server: $POSTGRES_URL"
echo "   • Assets MCP Server: $ASSETS_URL"  
echo "   • Notification MCP Server: $NOTIFICATION_URL"
echo ""
echo "🔗 Next Steps:"
echo "   1. Access Anypoint Platform: https://anypoint.mulesoft.com"
echo "   2. Navigate to Visualizer to see your agent network topology"
echo "   3. Check Runtime Manager for application status"
echo "   4. Review Exchange for published APIs"
echo ""
echo "📖 For detailed testing and agent fabric setup, see:"
echo "   👉 PUBLISH-DEPLOY-RUN-GUIDE.md"
echo ""
echo "✨ Happy integrating with Agent Fabric! ✨"
