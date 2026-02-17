# Complete Guide: Publish, Deploy & Run Agent Fabric
## Employee Onboarding Agent Network on Anypoint Platform

This guide provides step-by-step instructions to publish APIs to Exchange, deploy MCP servers to CloudHub, and run the Agent Fabric.

## 📋 Prerequisites

### 1. Required Software
```bash
# Anypoint CLI
npm install -g @mulesoft/anypoint-cli

# Verify installation
anypoint-cli-v4 --version
```

### 2. Anypoint Platform Access
- Valid Anypoint Platform account
- Organization admin permissions
- CloudHub 2.0 access
- Exchange contributor permissions

### 3. Environment Variables
Create `.env` file in project root:
```bash
# Anypoint Platform
ANYPOINT_ORG_ID=your-organization-id
ANYPOINT_ENV=Sandbox
ANYPOINT_CLIENT_ID=your-connected-app-client-id
ANYPOINT_CLIENT_SECRET=your-connected-app-secret

# CloudHub
CLOUDHUB_REGION=us-east-1
CLOUDHUB_DOMAIN=your-unique-domain

# Database (for PostgreSQL MCP)
POSTGRES_HOST=your-postgres-host.amazonaws.com
POSTGRES_PASSWORD=your-secure-password

# External Services
OPENAI_API_KEY=your-openai-api-key
EMAIL_HOST=smtp.gmail.com
EMAIL_PASSWORD=your-email-app-password
```

## 🚀 Step 1: Build All MCP Servers

### Build PostgreSQL MCP Server
```bash
cd postgres-mcp-onboarding
mvn clean package -DskipTests
cd ..
```

### Build Assets MCP Server  
```bash
cd assets-mcp-server
mvn clean package -DskipTests
cd ..
```

### Build Notification MCP Server
```bash
cd notification-mcp-server
mvn clean package -DskipTests
cd ..
```

**Expected Output:** JAR files in each `target/` directory:
- `postgres-mcp-onboarding-1.0.0-mule-application.jar`
- `assets-mcp-server-1.0.0-mule-application.jar`  
- `notification-mcp-server-1.0.0-mule-application.jar`

## 📦 Step 2: Publish APIs to Anypoint Exchange

### Authenticate with Anypoint Platform
```bash
anypoint-cli-v4 auth login
# Enter your credentials when prompted
```

### Publish Employee Onboarding API Specification
```bash
anypoint-cli-v4 exchange asset upload \
  --organization=$ANYPOINT_ORG_ID \
  --name="Employee Onboarding API" \
  --description="Complete employee onboarding API with MCP integration" \
  --type=raml \
  --files employee-onboarding-api/employee-onboarding-api.raml \
  --properties employee-onboarding-api/exchange.json
```

### Publish PostgreSQL MCP Server
```bash
anypoint-cli-v4 exchange asset upload \
  --organization=$ANYPOINT_ORG_ID \
  --name="PostgreSQL MCP Server" \
  --description="Employee database MCP server with RAML-first API design" \
  --type=mule-application \
  --classifier=mule-application \
  --files postgres-mcp-onboarding/target/postgres-mcp-onboarding-1.0.0-mule-application.jar \
  --main-file postgres-mcp-onboarding/src/main/resources/api/postgres-mcp-api.raml
```

### Publish Assets MCP Server
```bash
anypoint-cli-v4 exchange asset upload \
  --organization=$ANYPOINT_ORG_ID \
  --name="Assets MCP Server" \
  --description="Equipment allocation MCP server with inventory management" \
  --type=mule-application \
  --classifier=mule-application \
  --files assets-mcp-server/target/assets-mcp-server-1.0.0-mule-application.jar \
  --main-file assets-mcp-server/src/main/resources/api/assets-mcp-api.raml
```

### Publish Notification MCP Server
```bash
anypoint-cli-v4 exchange asset upload \
  --organization=$ANYPOINT_ORG_ID \
  --name="Notification MCP Server" \
  --description="Multi-channel notification MCP server (email, SMS)" \
  --type=mule-application \
  --classifier=mule-application \
  --files notification-mcp-server/target/notification-mcp-server-1.0.0-mule-application.jar \
  --main-file notification-mcp-server/src/main/resources/api/notification-mcp-api.raml
```

### Publish Agent Network Configuration
```bash
anypoint-cli-v4 exchange asset upload \
  --organization=$ANYPOINT_ORG_ID \
  --name="Employee Onboarding Agent Network" \
  --description="Complete agent fabric network configuration" \
  --type=other \
  --files agent-network.yaml,exchange.json
```

## ☁️ Step 3: Deploy to CloudHub 2.0

### Deploy PostgreSQL MCP Server
```bash
anypoint-cli-v4 runtime-mgr cloudhub-2 application deploy \
  --name postgres-mcp-$ANYPOINT_ENV \
  --target $ANYPOINT_ENV \
  --artifact postgres-mcp-onboarding/target/postgres-mcp-onboarding-1.0.0-mule-application.jar \
  --replicas 2 \
  --cores 1.0 \
  --memory 1.5 \
  --region $CLOUDHUB_REGION \
  --env POSTGRES_HOST=$POSTGRES_HOST \
  --env POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  --env ANYPOINT_ENV=$ANYPOINT_ENV
```

### Deploy Assets MCP Server
```bash
anypoint-cli-v4 runtime-mgr cloudhub-2 application deploy \
  --name assets-mcp-$ANYPOINT_ENV \
  --target $ANYPOINT_ENV \
  --artifact assets-mcp-server/target/assets-mcp-server-1.0.0-mule-application.jar \
  --replicas 1 \
  --cores 0.5 \
  --memory 1.0 \
  --region $CLOUDHUB_REGION \
  --env ANYPOINT_ENV=$ANYPOINT_ENV
```

### Deploy Notification MCP Server
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
  --env EMAIL_PASSWORD=$EMAIL_PASSWORD \
  --env ANYPOINT_ENV=$ANYPOINT_ENV
```

**Wait for Deployment:** Each deployment takes 3-5 minutes. Check status:
```bash
anypoint-cli-v4 runtime-mgr cloudhub-2 application list --environment $ANYPOINT_ENV
```

## 🤖 Step 4: Deploy Agent Fabric Network

### Verify MCP Server URLs
After deployment, your MCP servers will be available at:
```bash
# PostgreSQL MCP Server
https://postgres-mcp-sandbox.us-east-1.cloudhub.io

# Assets MCP Server  
https://assets-mcp-sandbox.us-east-1.cloudhub.io

# Notification MCP Server
https://notification-mcp-sandbox.us-east-1.cloudhub.io
```

### Update Agent Network Configuration
Update `agent-network.yaml` with actual CloudHub URLs:
```yaml
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

### Deploy Agent Network
```bash
anypoint-cli-v4 agent-fabric network deploy \
  --name employee-onboarding-network \
  --environment $ANYPOINT_ENV \
  --config agent-network.yaml \
  --region $CLOUDHUB_REGION
```

### Enable Anypoint Visualizer
```bash
anypoint-cli-v4 visualizer enable \
  --environment $ANYPOINT_ENV \
  --applications postgres-mcp-$ANYPOINT_ENV,assets-mcp-$ANYPOINT_ENV,notification-mcp-$ANYPOINT_ENV
```

## 🧪 Step 5: Test & Verify Deployment

### Health Checks
```bash
# Test PostgreSQL MCP Server
curl -X GET https://postgres-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/health

# Test Assets MCP Server
curl -X GET https://assets-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/health

# Test Notification MCP Server  
curl -X GET https://notification-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/health
```

### Test MCP Tool Discovery
```bash
# List available MCP tools for each server
curl -X GET https://postgres-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/tools \
  -H "Authorization: Bearer $ACCESS_TOKEN"

curl -X GET https://assets-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/tools \
  -H "Authorization: Bearer $ACCESS_TOKEN"

curl -X GET https://notification-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/tools \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

### End-to-End Onboarding Workflow Test
```bash
# 1. Create Employee
curl -X POST https://postgres-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/tools/create-employee \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{"name":"Jane Smith","email":"jane@company.com"}'

# 2. Allocate Assets (use employee ID from step 1)
curl -X POST https://assets-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/tools/allocate-assets \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{"employeeId":"123","assets":["laptop","id-card","bag"]}'

# 3. Send Welcome Email
curl -X POST https://notification-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/tools/send-welcome-email \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{"employeeId":"123","email":"jane@company.com","name":"Jane Smith"}'
```

## 🎯 Step 6: Run Agent Fabric

### Access Anypoint Visualizer
1. Login to [Anypoint Platform](https://anypoint.mulesoft.com)
2. Navigate to **Visualizer** → **Agent Networks**
3. Select your environment: `$ANYPOINT_ENV`
4. View **Employee Onboarding Agent Network** topology

### Agent Fabric Operations

#### Start Agent Network
```bash
anypoint-cli-v4 agent-fabric network start \
  --name employee-onboarding-network \
  --environment $ANYPOINT_ENV
```

#### Monitor Agent Activity
```bash
# View agent network status
anypoint-cli-v4 agent-fabric network describe \
  --name employee-onboarding-network \
  --environment $ANYPOINT_ENV

# View agent logs  
anypoint-cli-v4 agent-fabric network logs \
  --name employee-onboarding-network \
  --environment $ANYPOINT_ENV \
  --tail 100
```

#### Test Agent Interactions
```bash
# Invoke agent workflow through broker
curl -X POST https://onboarding-broker-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/broker/onboard \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{
    "name": "John Doe",
    "email": "john@company.com",
    "position": "Software Engineer"
  }'
```

## 📊 Step 7: Monitor & Manage

### Anypoint Visualizer Dashboards
- **Real-time Topology**: View agent network components and connections
- **Message Flows**: Track agent-to-agent communications
- **Performance Metrics**: Monitor response times and throughput
- **Health Status**: Check component availability

### CloudHub Monitoring
```bash
# Application status
anypoint-cli-v4 runtime-mgr cloudhub-2 application describe \
  --name postgres-mcp-$ANYPOINT_ENV \
  --environment $ANYPOINT_ENV

# Application logs
anypoint-cli-v4 runtime-mgr cloudhub-2 application logs \
  --name postgres-mcp-$ANYPOINT_ENV \
  --environment $ANYPOINT_ENV \
  --tail 100
```

### Scaling Operations
```bash
# Scale up Assets MCP Server
anypoint-cli-v4 runtime-mgr cloudhub-2 application modify \
  --name assets-mcp-$ANYPOINT_ENV \
  --environment $ANYPOINT_ENV \
  --replicas 2 \
  --cores 1.0
```

## 🔧 Troubleshooting

### Common Issues

1. **Deployment Failures**
   ```bash
   # Check deployment status
   anypoint-cli-v4 runtime-mgr cloudhub-2 application describe \
     --name postgres-mcp-$ANYPOINT_ENV \
     --environment $ANYPOINT_ENV
   ```

2. **MCP Connection Issues**
   ```bash
   # Test MCP endpoints directly
   curl -X GET https://postgres-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/tools
   ```

3. **Agent Network Issues**
   ```bash
   # Restart agent network
   anypoint-cli-v4 agent-fabric network restart \
     --name employee-onboarding-network \
     --environment $ANYPOINT_ENV
   ```

## ✅ Success Indicators

- [ ] All 3 MCP servers deployed successfully to CloudHub 2.0
- [ ] Health check endpoints responding (HTTP 200)
- [ ] MCP tools discoverable (`/mcp/tools` returns tool list)
- [ ] Agent network visible in Anypoint Visualizer
- [ ] End-to-end onboarding workflow completes successfully
- [ ] Real-time monitoring data available in Visualizer

## 🎉 You're Ready!

Your Employee Onboarding Agent Network with agentic fabric capabilities is now:
- **Published** to Anypoint Exchange with full API documentation
- **Deployed** to CloudHub 2.0 with auto-scaling and high availability
- **Running** as an intelligent agent fabric network
- **Monitored** through Anypoint Visualizer with real-time insights

The system can now handle employee onboarding requests with intelligent agent orchestration, database operations, asset allocation, and multi-channel notifications!
