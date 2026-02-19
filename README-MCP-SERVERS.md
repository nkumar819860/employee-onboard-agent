# MCP Servers for Agent Fabric - Employee Onboarding

This document describes the restructured MCP (Model Context Protocol) servers for the Employee Onboarding Agent Fabric, now properly organized for CloudHub deployment.

## 🏗️ Project Structure

The project has been reorganized into three separate MCP server applications:

```
employee-onboard-agent/
├── mcp-postgres-server/          # Employee database operations
├── mcp-assets-server/             # Asset allocation management
├── mcp-notification-server/       # Welcome notifications & emails
├── agent-network-cloudhub.yaml   # Updated agent network configuration
├── deploy-mcp-servers.bat        # CloudHub deployment script
└── README-MCP-SERVERS.md         # This documentation
```

## 📦 MCP Server Details

### 1. MCP PostgreSQL Server (`mcp-postgres-server`)
**Purpose**: Employee database operations and management

**Endpoints**:
- `POST /mcp/tools/create-employee` - Create new employee records
- `GET /mcp/tools/get-employee` - Retrieve employee information
- `POST /mcp/tools/update-status` - Update employee onboarding status
- `GET /health` - Health check endpoint
- `GET /mcp/info` - Server information

**CloudHub URL**: `https://mcp-postgres-server.us-e1.cloudhub.io`

### 2. MCP Assets Server (`mcp-assets-server`)
**Purpose**: Employee asset allocation and management

**Endpoints**:
- `POST /mcp/tools/allocate-assets` - Allocate assets to employees
- `GET /mcp/tools/get-assets` - Get employee's allocated assets
- `POST /mcp/tools/return-assets` - Mark assets as returned
- `GET /health` - Health check endpoint
- `GET /mcp/info` - Server information

**CloudHub URL**: `https://mcp-assets-server.us-e1.cloudhub.io`

### 3. MCP Notification Server (`mcp-notification-server`)
**Purpose**: Welcome notifications and employee communications

**Endpoints**:
- `POST /mcp/tools/send-welcome` - Send welcome notification
- `POST /mcp/tools/send-email` - Send custom email
- `POST /mcp/tools/send-reminder` - Send onboarding reminders
- `GET /health` - Health check endpoint
- `GET /mcp/info` - Server information

**CloudHub URL**: `https://mcp-notification-server.us-e1.cloudhub.io`

## 🚀 Deployment Instructions

### Prerequisites
1. Anypoint Platform account with CloudHub access
2. Maven 3.6+ installed
3. Java 11+ installed

### Step 1: Set Environment Variables
```batch
set ANYPOINT_USERNAME=your-username
set ANYPOINT_PASSWORD=your-password
set ANYPOINT_ORG_ID=your-organization-id
```

### Step 2: Deploy to CloudHub
Run the deployment script:
```batch
deploy-mcp-servers.bat
```

This script will:
1. Build each MCP server application
2. Deploy to CloudHub Sandbox environment
3. Provide deployment status and URLs

### Step 3: Manual Deployment (Alternative)
If the script fails, deploy manually for each server:

```batch
# PostgreSQL MCP Server
cd mcp-postgres-server
mvn clean package -DskipTests
mvn mule:deploy -Dmule.env=Sandbox -Dmule.username=%ANYPOINT_USERNAME% -Dmule.password=%ANYPOINT_PASSWORD%

# Assets MCP Server
cd ../mcp-assets-server
mvn clean package -DskipTests
mvn mule:deploy -Dmule.env=Sandbox -Dmule.username=%ANYPOINT_USERNAME% -Dmule.password=%ANYPOINT_PASSWORD%

# Notification MCP Server
cd ../mcp-notification-server
mvn clean package -DskipTests
mvn mule:deploy -Dmule.env=Sandbox -Dmule.username=%ANYPOINT_USERNAME% -Dmule.password=%ANYPOINT_PASSWORD%
```

## 🔧 Configuration

### Database Configuration
For PostgreSQL MCP Server, configure these secure properties in CloudHub:
- `secure::db.url` - PostgreSQL connection URL
- `secure::db.username` - Database username
- `secure::db.password` - Database password

### Email Configuration
For Notification MCP Server, configure these secure properties in CloudHub:
- `secure::smtp.host` - SMTP server host
- `secure::smtp.port` - SMTP server port
- `secure::smtp.username` - SMTP username
- `secure::smtp.password` - SMTP password

## 🤖 Agent Network Configuration

The `agent-network-cloudhub.yaml` file has been updated with the new CloudHub URLs and enhanced tool definitions. The agent now has access to:

### Employee Management Tools
- Create, retrieve, and update employee records
- Full employee lifecycle management

### Asset Management Tools  
- Allocate equipment (laptops, phones, access cards)
- Track asset assignments
- Process asset returns

### Notification Tools
- Send welcome emails to new employees
- Custom email notifications
- Onboarding reminders and follow-ups

## 🔍 Testing the Deployment

### Health Checks
Verify each server is running:
```bash
curl https://mcp-postgres-server.us-e1.cloudhub.io/health
curl https://mcp-assets-server.us-e1.cloudhub.io/health
curl https://mcp-notification-server.us-e1.cloudhub.io/health
```

### Server Info
Get server capabilities:
```bash
curl https://mcp-postgres-server.us-e1.cloudhub.io/mcp/info
curl https://mcp-assets-server.us-e1.cloudhub.io/mcp/info
curl https://mcp-notification-server.us-e1.cloudhub.io/mcp/info
```

### Complete Onboarding Test
Test the full workflow:
```bash
# 1. Create Employee
curl -X POST https://mcp-postgres-server.us-e1.cloudhub.io/mcp/tools/create-employee \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john.doe@company.com"}'

# 2. Allocate Assets (use employee ID from step 1)
curl -X POST https://mcp-assets-server.us-e1.cloudhub.io/mcp/tools/allocate-assets \
  -H "Content-Type: application/json" \
  -d '{"empId":"EMP123456","assets":["laptop","phone","access-card"]}'

# 3. Send Welcome (use employee details)
curl -X POST https://mcp-notification-server.us-e1.cloudhub.io/mcp/tools/send-welcome \
  -H "Content-Type: application/json" \
  -d '{"empId":"EMP123456","name":"John Doe","email":"john.doe@company.com"}'
```

## 📝 Key Improvements

1. **Separation of Concerns**: Each MCP server handles a specific domain
2. **CloudHub Compatibility**: Proper Mule project structure with secure properties
3. **Enhanced Error Handling**: Comprehensive error responses and logging
4. **Scalability**: Independent scaling of each service
5. **Maintainability**: Clean code organization and documentation
6. **Health Monitoring**: Health check endpoints for all services

## 🔒 Security Considerations

- Use secure properties for sensitive configuration
- Implement proper authentication for production environments
- Configure HTTPS endpoints for secure communication
- Regular security updates and vulnerability scanning

## 📞 Support

For issues or questions:
- Check CloudHub deployment logs in Anypoint Platform
- Review individual server health endpoints
- Verify agent network YAML configuration
- Ensure all environment variables are properly set

## 🎯 Next Steps

1. Deploy the MCP servers using the provided script
2. Configure secure properties in CloudHub
3. Test the agent network with sample onboarding requests
4. Monitor performance and scale as needed
5. Implement additional security measures for production

---

**Agent Fabric Team** | **MuleSoft** | **2026**
