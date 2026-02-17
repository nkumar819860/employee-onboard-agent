# Anypoint Platform Deployment Guide
## Employee Onboarding Agent Network with MCP Servers

This guide provides step-by-step instructions for building, publishing, and deploying the employee onboarding agent network to Anypoint Platform with agentic fabric capabilities.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Project Structure Overview](#project-structure-overview)
3. [Build and Test Locally](#build-and-test-locally)
4. [Publish to Anypoint Exchange](#publish-to-anypoint-exchange)
5. [Deploy to CloudHub 2.0](#deploy-to-cloudhub-20)
6. [Configure Agent Network](#configure-agent-network)
7. [Verification and Testing](#verification-and-testing)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

### 1. Development Environment
- **Anypoint Studio 7.15+** or **Anypoint Code Builder**
- **Maven 3.8+**
- **Java 17** (for Mule 4.6+)
- **Anypoint CLI 4.x**
- **Git**

### 2. Anypoint Platform Access
- Valid Anypoint Platform account
- Organization admin or developer permissions
- CloudHub 2.0 access
- Exchange contributor permissions

### 3. Environment Variables
Create a `.env` file in the project root with the following variables:

```bash
# Anypoint Platform Configuration
ANYPOINT_ORG_ID=your-org-id
ANYPOINT_ENV=Sandbox
ANYPOINT_CLIENT_ID=your-client-id
ANYPOINT_CLIENT_SECRET=your-client-secret
CLOUDHUB_REGION=us-east-1
CLOUDHUB_DOMAIN=your-domain

# Database Configuration
POSTGRES_HOST=your-postgres-host
POSTGRES_PORT=5432
POSTGRES_DB=onboarding
POSTGRES_USER=mule
POSTGRES_PASSWORD=your-password

# External Services
OPENAI_API_KEY=your-openai-key
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email
EMAIL_PASSWORD=your-email-password
```

## Project Structure Overview

```
employee-onboard-agent/
├── agent-network.yaml                 # Main agent network configuration
├── exchange.json                      # Exchange metadata
├── anypoint-deployment/               # Deployment configurations
│   ├── agent-network-anypoint.yaml   # CloudHub-specific config
│   ├── exchange-anypoint.json         # Exchange publication config
│   └── deploy-to-anypoint.sh          # Deployment script
├── postgres-mcp-onboarding/           # PostgreSQL MCP Server
│   ├── pom.xml                        # Maven configuration
│   ├── src/main/mule/
│   │   ├── global.xml                 # Global configurations
│   │   └── postgres-mcp-onboarding.xml # Main flows
│   └── src/main/resources/
│       └── config.properties          # Environment properties
├── assets-mcp-server/                 # Assets MCP Server
│   ├── pom.xml
│   ├── src/main/mule/
│   │   ├── global.xml
│   │   └── assets-mcp-server.xml
│   └── src/main/resources/
│       └── config.properties
└── notification-mcp-server/           # Notification MCP Server
    ├── pom.xml
    ├── src/main/mule/
    │   ├── global.xml
    │   └── notification-mcp-server.xml
    └── src/main/resources/
        └── config.properties
```

## Build and Test Locally

### Step 1: Install Anypoint CLI
```bash
npm install -g @mulesoft/anypoint-cli
anypoint-cli-v4 --version
```

### Step 2: Authenticate with Anypoint Platform
```bash
anypoint-cli-v4 auth login
# Follow prompts to enter credentials
```

### Step 3: Build Each MCP Server

#### PostgreSQL MCP Server
```bash
cd postgres-mcp-onboarding
mvn clean compile
mvn clean package
```

#### Assets MCP Server
```bash
cd assets-mcp-server
mvn clean compile
mvn clean package
```

#### Notification MCP Server
```bash
cd notification-mcp-server
mvn clean compile
mvn clean package
```

### Step 4: Local Testing (Optional)
Use the MuleSoft local runtime to test each application:

```bash
# For each MCP server
cd postgres-mcp-onboarding
mvn mule:run

# Test endpoints
curl -X GET http://localhost:8081/mcp/tools
curl -X POST http://localhost:8081/mcp/tools/create-employee \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@company.com"}'
```

## Publish to Anypoint Exchange

### Step 1: Configure Exchange Assets
Each MCP server will be published as a separate asset. Update the exchange configuration:

```bash
# Navigate to project root
cd employee-onboard-agent
```

### Step 2: Publish PostgreSQL MCP Server
```bash
anypoint-cli-v4 exchange asset upload \
  --organization=$ANYPOINT_ORG_ID \
  --name="PostgreSQL MCP Server" \
  --description="Employee database MCP server for onboarding workflow" \
  --type=mule-application \
  --classifier=mule-application \
  --files postgres-mcp-onboarding/target/postgres-mcp-onboarding-1.0.0-mule-application.jar \
  --properties postgres-mcp-onboarding/exchange.json
```

### Step 3: Publish Assets MCP Server
```bash
anypoint-cli-v4 exchange asset upload \
  --organization=$ANYPOINT_ORG_ID \
  --name="Assets MCP Server" \
  --description="Equipment allocation MCP server for employee onboarding" \
  --type=mule-application \
  --classifier=mule-application \
  --files assets-mcp-server/target/assets-mcp-server-1.0.0-mule-application.jar
```

### Step 4: Publish Notification MCP Server
```bash
anypoint-cli-v4 exchange asset upload \
  --organization=$ANYPOINT_ORG_ID \
  --name="Notification MCP Server" \
  --description="Welcome notification MCP server for employee onboarding" \
  --type=mule-application \
  --classifier=mule-application \
  --files notification-mcp-server/target/notification-mcp-server-1.0.0-mule-application.jar
```

### Step 5: Publish Agent Network Configuration
```bash
anypoint-cli-v4 exchange asset upload \
  --organization=$ANYPOINT_ORG_ID \
  --name="Employee Onboarding Agent Network" \
  --description="Complete agent network for employee onboarding with MCP servers" \
  --type=agent-network \
  --files agent-network.yaml,exchange.json
```

## Deploy to CloudHub 2.0

### Step 1: Deploy PostgreSQL MCP Server
```bash
anypoint-cli-v4 runtime-mgr cloudhub-2 application deploy \
  --name postgres-mcp-$ANYPOINT_ENV \
  --target $ANYPOINT_ENV \
  --artifact postgres-mcp-onboarding/target/postgres-mcp-onboarding-1.0.0-mule-application.jar \
  --replicas 2 \
  --cores 1.0 \
  --memory 1.5 \
  --region $CLOUDHUB_REGION \
  --properties postgres-mcp-onboarding/src/main/resources/config.properties \
  --env POSTGRES_HOST=$POSTGRES_HOST \
  --env POSTGRES_PASSWORD=$POSTGRES_PASSWORD
```

### Step 2: Deploy Assets MCP Server
```bash
anypoint-cli-v4 runtime-mgr cloudhub-2 application deploy \
  --name assets-mcp-$ANYPOINT_ENV \
  --target $ANYPOINT_ENV \
  --artifact assets-mcp-server/target/assets-mcp-server-1.0.0-mule-application.jar \
  --replicas 1 \
  --cores 0.5 \
  --memory 1.0 \
  --region $CLOUDHUB_REGION
```

### Step 3: Deploy Notification MCP Server
```bash
anypoint-cli-v4 runtime-mgr cloudhub-2 application deploy \
  --name notification-mcp-$ANYPOINT_ENV \
  --target $ANYPOINT_ENV \
  --artifact notification-mcp-server/target/notification-mcp-server-1.0.0-mule-application.jar \
  --replicas 1 \
  --cores 0.5 \
  --memory 1.0 \
  --region $CLOUDHUB_REGION \
  --env EMAIL_HOST=$EMAIL_HOST \
  --env EMAIL_PASSWORD=$EMAIL_PASSWORD
```

### Step 4: Automated Deployment Script
Use the provided deployment script for easier deployment:

```bash
# Make script executable
chmod +x anypoint-deployment/deploy-to-anypoint.sh

# Run deployment
./anypoint-deployment/deploy-to-anypoint.sh
```

## Configure Agent Network

### Step 1: Deploy Agent Network
```bash
anypoint-cli-v4 agent-fabric network deploy \
  --name employee-onboarding-network \
  --environment $ANYPOINT_ENV \
  --config agent-network.yaml \
  --region $CLOUDHUB_REGION
```

### Step 2: Configure Connections
Update the agent network configuration with deployed application URLs:

```yaml
# Update agent-network.yaml with actual CloudHub URLs
connections:
  postgres-mcp-cloudhub-connection:
    kind: mcp
    spec:
      url: https://postgres-mcp-sandbox.us-east-1.cloudhub.io/mcp/postgres
      
  assets-mcp-cloudhub-connection:
    kind: mcp
    spec:
      url: https://assets-mcp-sandbox.us-east-1.cloudhub.io/mcp/assets
      
  notification-mcp-cloudhub-connection:
    kind: mcp
    spec:
      url: https://notification-mcp-sandbox.us-east-1.cloudhub.io/mcp/notifications
```

### Step 3: Enable Anypoint Visualizer
```bash
anypoint-cli-v4 visualizer enable \
  --environment $ANYPOINT_ENV \
  --applications postgres-mcp-$ANYPOINT_ENV,assets-mcp-$ANYPOINT_ENV,notification-mcp-$ANYPOINT_ENV
```

## Verification and Testing

### Step 1: Health Checks
Verify each MCP server is running:

```bash
# PostgreSQL MCP Server
curl -X GET https://postgres-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/tools

# Assets MCP Server
curl -X GET https://assets-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/tools

# Notification MCP Server
curl -X GET https://notification-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/tools
```

### Step 2: End-to-End Testing
Test the complete onboarding workflow:

```bash
# Create employee
curl -X POST https://postgres-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/tools/create-employee \
  -H "Content-Type: application/json" \
  -d '{"name":"Jane Smith","email":"jane@company.com"}'

# Allocate assets
curl -X POST https://assets-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/tools/allocate-assets \
  -H "Content-Type: application/json" \
  -d '{"employeeId":"123","assets":["laptop","id-card","bag"]}'

# Send welcome notification
curl -X POST https://notification-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/tools/send-welcome-email \
  -H "Content-Type: application/json" \
  -d '{"employeeId":"123","email":"jane@company.com","name":"Jane Smith"}'
```

### Step 3: Monitor with Anypoint Visualizer
1. Access Anypoint Platform → Visualizer
2. Select your environment
3. View the agent network topology
4. Monitor real-time message flows
5. Check application health and metrics

## Troubleshooting

### Common Issues and Solutions

#### 1. Build Failures
**Issue**: Maven build fails with dependency errors
**Solution**: 
```bash
mvn dependency:tree
mvn clean install -U
```

#### 2. Deployment Failures
**Issue**: CloudHub deployment fails
**Solution**:
- Check application name uniqueness
- Verify environment permissions
- Review deployment logs in Runtime Manager

#### 3. MCP Connection Issues
**Issue**: Agent network can't connect to MCP servers
**Solution**:
- Verify MCP server endpoints are accessible
- Check OAuth2 credentials configuration
- Review security group settings

#### 4. Database Connection Issues
**Issue**: PostgreSQL MCP server can't connect to database
**Solution**:
- Verify database credentials
- Check network connectivity
- Ensure database allows connections from CloudHub IPs

### Monitoring and Logs
- **CloudHub Logs**: Runtime Manager → Applications → Logs
- **Visualizer**: Real-time application topology and metrics
- **Anypoint Monitoring**: Performance metrics and alerts
- **API Analytics**: MCP tool usage statistics

### Support Resources
- [MuleSoft Documentation](https://docs.mulesoft.com)
- [CloudHub 2.0 Guide](https://docs.mulesoft.com/runtime-manager/cloudhub-2)
- [Agent Fabric Documentation](https://docs.mulesoft.com/agent-fabric)
- [MCP Connector Guide](https://docs.mulesoft.com/mcp-connector)

---

## Quick Deployment Checklist

- [ ] Environment variables configured
- [ ] All MCP servers built successfully
- [ ] Assets published to Exchange
- [ ] Applications deployed to CloudHub 2.0
- [ ] Agent network configuration updated
- [ ] Health checks passing
- [ ] End-to-end testing completed
- [ ] Anypoint Visualizer enabled
- [ ] Monitoring alerts configured

**Deployment Time Estimate**: 30-45 minutes for complete setup
**Prerequisites Setup Time**: 15-20 minutes

For additional support, contact your MuleSoft customer success team or visit the MuleSoft Community forums.
