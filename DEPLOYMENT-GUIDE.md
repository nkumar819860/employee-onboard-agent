# Anypoint Platform Deployment Guide
## Employee Onboarding Agent Network with MCP Servers

This guide provides step-by-step instructions for building, publishing, and deploying the employee onboarding agent network to Anypoint Platform with agentic fabric capabilities.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Project Structure Overview](#project-structure-overview)
3. [Windows Automated Deployment](#windows-automated-deployment)
4. [Build and Test Locally](#build-and-test-locally)
5. [Publish to Anypoint Exchange](#publish-to-anypoint-exchange)
6. [Deploy to CloudHub 2.0](#deploy-to-cloudhub-20)
7. [Configure Agent Network](#configure-agent-network)
8. [Verification and Testing](#verification-and-testing)
9. [Troubleshooting](#troubleshooting)

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

### 3. Database Setup Options

You have several options for the PostgreSQL database:

#### Option A: Local PostgreSQL on Your Laptop (Recommended for Development)

**Windows Installation:**
```batch
# Download and install PostgreSQL from https://www.postgresql.org/download/windows/
# Or use chocolatey
choco install postgresql

# Start PostgreSQL service
net start postgresql-x64-15

# Connect and create database
psql -U postgres
CREATE DATABASE onboarding;
CREATE USER mule WITH PASSWORD 'mulepassword';
GRANT ALL PRIVILEGES ON DATABASE onboarding TO mule;
\q
```

**macOS Installation:**
```bash
# Using Homebrew
brew install postgresql
brew services start postgresql

# Create database and user
createdb onboarding
psql onboarding
CREATE USER mule WITH PASSWORD 'mulepassword';
GRANT ALL PRIVILEGES ON DATABASE onboarding TO mule;
\q
```

**Linux Installation:**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql postgresql-contrib

# Start service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
sudo -u postgres psql
CREATE DATABASE onboarding;
CREATE USER mule WITH PASSWORD 'mulepassword';
GRANT ALL PRIVILEGES ON DATABASE onboarding TO mule;
\q
```

**Create Database Schema:**
```sql
-- Connect to your local database
psql -h localhost -U mule -d onboarding

-- Create employees table
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    department VARCHAR(100),
    position VARCHAR(100),
    start_date DATE,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create assets table
CREATE TABLE assets (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    asset_type VARCHAR(100) NOT NULL,
    asset_name VARCHAR(255) NOT NULL,
    serial_number VARCHAR(100),
    allocated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'allocated'
);

-- Create notifications table
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    type VARCHAR(50) NOT NULL,
    message TEXT,
    sent_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'sent'
);
```

#### Option B: Cloud PostgreSQL (Production)

**AWS RDS:**
- Create RDS PostgreSQL instance in AWS Console
- Configure security groups to allow CloudHub IP ranges
- Use RDS endpoint as POSTGRES_HOST

**Azure Database for PostgreSQL:**
- Create Azure PostgreSQL instance
- Configure firewall rules for CloudHub access
- Use Azure endpoint as POSTGRES_HOST

**Google Cloud SQL:**
- Create Cloud SQL PostgreSQL instance
- Configure authorized networks for CloudHub
- Use Cloud SQL connection string

### 4. Environment Variables
Create a `.env` file in the project root with the following variables:

```bash
# Anypoint Platform Configuration
ANYPOINT_ORG_ID=your-org-id
ANYPOINT_ENV=Sandbox
ANYPOINT_CLIENT_ID=your-client-id
ANYPOINT_CLIENT_SECRET=your-client-secret
CLOUDHUB_REGION=us-east-1
CLOUDHUB_DOMAIN=your-domain

# Database Configuration (Local PostgreSQL on Laptop)
POSTGRES_HOST=your-laptop-public-ip
POSTGRES_PORT=5432
POSTGRES_DB=onboarding
POSTGRES_USER=mule
POSTGRES_PASSWORD=mulepassword

# Alternative: Use localhost for local testing
# POSTGRES_HOST=localhost (for local Mule runtime testing)

# External Services
GROQ_API_KEY=your-groq-api-key
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email
EMAIL_PASSWORD=your-email-password
```

### 5. Local Database Configuration for CloudHub

When using your laptop as the database server, you need to:

#### Step 1: Configure PostgreSQL for Remote Access
```bash
# Edit postgresql.conf (location varies by OS)
# Windows: C:\Program Files\PostgreSQL\15\data\postgresql.conf
# macOS: /usr/local/var/postgres/postgresql.conf
# Linux: /etc/postgresql/15/main/postgresql.conf

# Change listen_addresses to allow external connections
listen_addresses = '*'
port = 5432
```

#### Step 2: Configure pg_hba.conf for CloudHub Access
```bash
# Edit pg_hba.conf in same directory as postgresql.conf
# Add CloudHub IP ranges (check current ranges in Anypoint Platform documentation)

# Allow connections from your public IP and CloudHub ranges
host    onboarding    mule    0.0.0.0/0    md5
```

#### Step 3: Get Your Public IP Address
```bash
# Check your public IP (this is what CloudHub will use to connect)
curl -s https://api.ipify.org
# or
curl -s https://ifconfig.me

# Use this IP as POSTGRES_HOST in your environment variables
```

#### Step 4: Configure Router/Firewall
```bash
# Forward port 5432 to your laptop in router settings
# Allow port 5432 in Windows Firewall or equivalent

# Windows Firewall rule
netsh advfirewall firewall add rule name="PostgreSQL" dir=in action=allow protocol=TCP localport=5432

# Or use Windows GUI: Windows Defender Firewall → Advanced Settings → New Rule
```

#### Step 5: Restart PostgreSQL Service
```batch
# Windows
net stop postgresql-x64-15
net start postgresql-x64-15

# macOS
brew services restart postgresql

# Linux
sudo systemctl restart postgresql
```

### 6. Testing Local Database Connection

#### From Your Laptop:
```bash
# Test local connection
psql -h localhost -U mule -d onboarding -c "SELECT version();"
```

#### From External (Simulate CloudHub):
```bash
# Test external connection using your public IP
psql -h YOUR_PUBLIC_IP -U mule -d onboarding -c "SELECT version();"
```

#### Connection String for MCP Server:
```bash
# Update postgres-mcp-onboarding/src/main/resources/config.properties
database.host=YOUR_PUBLIC_IP
database.port=5432
database.name=onboarding
database.user=mule
database.password=mulepassword
database.driver=org.postgresql.Driver
database.url=jdbc:postgresql://YOUR_PUBLIC_IP:5432/onboarding
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

## Windows Automated Deployment

For Windows users, we provide automated batch scripts that handle the complete build, publish, and deployment process with minimal manual intervention.

### Quick Start with Windows Scripts

#### Option 1: Complete Automated Deployment (`deploy-all.bat`)

This script performs the full deployment pipeline: build → publish → deploy → test.

```batch
# Set required environment variables (Windows Command Prompt)
set ANYPOINT_ORG_ID=your-org-id
set ANYPOINT_ENV=Sandbox
set CLOUDHUB_REGION=us-east-1
set POSTGRES_HOST=your-postgres-host
set POSTGRES_PASSWORD=your-password
set EMAIL_HOST=smtp.gmail.com
set EMAIL_PASSWORD=your-email-password

# Run complete deployment
deploy-all.bat
```

**What the script does:**
1. ✅ **Validates prerequisites** (Maven, Java, Anypoint CLI)
2. 🔨 **Builds all MCP servers** with error handling
3. 📦 **Publishes APIs and applications to Anypoint Exchange**
4. ☁️ **Deploys to CloudHub 2.0** with optimal configurations
5. ⏳ **Waits for deployments** to complete
6. 🧪 **Tests endpoints** and provides health status
7. 📊 **Displays deployment summary** with URLs and next steps

#### Option 2: Demo Deployment (`deploy-anypoint-demo.bat`)

This simplified script is perfect for demos and quick testing:

```batch
# Run demo deployment
deploy-anypoint-demo.bat
```

**What the demo script does:**
1. ✅ **Prerequisites check** (CLI, Maven, Java)
2. 🔨 **Builds PostgreSQL MCP Server**
3. 📋 **Provides manual deployment steps** for CloudHub
4. 🎯 **Focuses on core demo functionality**

### Windows Script Features

#### Environment Variable Validation
Both scripts validate required environment variables and provide clear error messages:

```batch
if "%ANYPOINT_ORG_ID%"=="" (
    echo ❌ Error: Required environment variables not set
    echo Please set: ANYPOINT_ORG_ID, ANYPOINT_ENV
    echo Example:
    echo   set ANYPOINT_ORG_ID=your-org-id
    echo   set ANYPOINT_ENV=Sandbox
    pause
    exit /b 1
)
```

#### Prerequisite Checking
Automatic validation of required tools:
- ✅ Anypoint CLI v4
- ✅ Maven 3.6+
- ✅ Java 8/11/17
- ✅ Environment configuration files

#### Error Handling and Recovery
- **Build failures**: Clear error messages with suggested fixes
- **Authentication issues**: Automatic login prompts
- **Deployment conflicts**: Graceful handling of existing applications
- **Network timeouts**: Retry logic and status checks

#### Progress Tracking
Real-time progress with emoji indicators:
```
🚀 Starting Employee Onboarding Agent Network Deployment...
📋 Environment: Sandbox
🏢 Organization: your-org-id
🔨 Step 1: Building all MCP servers...
  ✅ PostgreSQL MCP Server built successfully
  ✅ Assets MCP Server built successfully  
  ✅ Notification MCP Server built successfully
📦 Step 2: Publishing to Anypoint Exchange...
☁️ Step 3: Deploying to CloudHub 2.0...
```

### Windows Environment Setup

#### Step 1: Install Prerequisites
```batch
# Install Node.js and Anypoint CLI
# Download from: https://nodejs.org/
npm install -g anypoint-cli-v4

# Verify installation
anypoint-cli-v4 --version
```

#### Step 2: Set Environment Variables (Windows)

**Option A: Command Prompt (Session-based)**
```batch
set ANYPOINT_ORG_ID=your-org-id
set ANYPOINT_ENV=Sandbox
set ANYPOINT_CLIENT_ID=your-client-id
set ANYPOINT_CLIENT_SECRET=your-client-secret
set CLOUDHUB_REGION=us-east-1
set POSTGRES_HOST=your-postgres-host
set POSTGRES_PASSWORD=your-password
set EMAIL_HOST=smtp.gmail.com
set EMAIL_PASSWORD=your-email-password
```

**Option B: PowerShell (Session-based)**
```powershell
$env:ANYPOINT_ORG_ID="your-org-id"
$env:ANYPOINT_ENV="Sandbox"
$env:ANYPOINT_CLIENT_ID="your-client-id"
$env:ANYPOINT_CLIENT_SECRET="your-client-secret"
$env:CLOUDHUB_REGION="us-east-1"
$env:POSTGRES_HOST="your-postgres-host"
$env:POSTGRES_PASSWORD="your-password"
$env:EMAIL_HOST="smtp.gmail.com"
$env:EMAIL_PASSWORD="your-email-password"
```

**Option C: System Environment Variables (Persistent)**
1. Open **System Properties** → **Advanced** → **Environment Variables**
2. Add the variables under **User variables** or **System variables**
3. Restart Command Prompt/PowerShell to reload variables

#### Step 3: Authentication Setup
The script will automatically prompt for authentication if needed:

```batch
# Manual authentication (if required)
anypoint-cli-v4 auth login
```

### Windows Deployment Output

After successful deployment, you'll see:

```
🎉 Deployment Complete!

📊 Your Employee Onboarding Agent Network is ready:
   • PostgreSQL MCP Server: https://postgres-mcp-sandbox.us-east-1.cloudhub.io
   • Assets MCP Server: https://assets-mcp-sandbox.us-east-1.cloudhub.io
   • Notification MCP Server: https://notification-mcp-sandbox.us-east-1.cloudhub.io

🔗 Next Steps:
   1. Access Anypoint Platform: https://anypoint.mulesoft.com
   2. Navigate to Visualizer to see your agent network topology
   3. Check Runtime Manager for application status
   4. Review Exchange for published APIs

📖 For detailed testing and agent fabric setup, see:
   👉 PUBLISH-DEPLOY-RUN-GUIDE.md

✨ Happy integrating with Agent Fabric! ✨
```

### Windows-Specific Troubleshooting

#### Common Windows Issues

**Issue**: `'anypoint-cli-v4' is not recognized`
**Solution**:
```batch
# Add Node.js to PATH or reinstall Anypoint CLI
npm install -g anypoint-cli-v4
# Restart Command Prompt
```

**Issue**: Maven not found
**Solution**:
```batch
# Download Maven from: https://maven.apache.org/download.cgi
# Add Maven bin directory to PATH
# Example: C:\apache-maven-3.8.6\bin
```

**Issue**: Java version conflicts
**Solution**:
```batch
# Set JAVA_HOME explicitly
set JAVA_HOME=C:\Program Files\Java\jdk-17.0.1
set PATH=%JAVA_HOME%\bin;%PATH%
```

**Issue**: Permission denied during deployment
**Solution**:
- Run Command Prompt as **Administrator**
- Check Windows Defender/Antivirus settings
- Verify Anypoint Platform permissions

#### Windows Performance Optimization

**For faster builds on Windows:**
```batch
# Disable Windows Defender real-time scanning for project folder
# Use SSD for better Maven performance
# Increase Maven memory
set MAVEN_OPTS=-Xmx2g -XX:MaxPermSize=256m
```

**For concurrent deployments:**
```batch
# Deploy applications in parallel (advanced users)
start /B anypoint-cli-v4 runtime-mgr cloudhub-2 application deploy postgres-mcp...
start /B anypoint-cli-v4 runtime-mgr cloudhub-2 application deploy assets-mcp...
start /B anypoint-cli-v4 runtime-mgr cloudhub-2 application deploy notification-mcp...
```

### Integration with Windows Development Workflow

#### Visual Studio Code Integration
```json
// .vscode/tasks.json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Deploy to Anypoint",
            "type": "shell",
            "command": "deploy-all.bat",
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            }
        }
    ]
}
```

#### Windows Scheduler Integration
For automated nightly deployments:
```batch
# Create scheduled task
schtasks /create /sc daily /st 02:00 /tn "Anypoint Deployment" /tr "C:\path\to\employee-onboard-agent\deploy-all.bat"
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

### Step 4: Automated Deployment Scripts

**Linux/macOS:**
```bash
# Make script executable
chmod +x anypoint-deployment/deploy-to-anypoint.sh

# Run deployment
./anypoint-deployment/deploy-to-anypoint.sh
```

**Windows:**
```batch
# Run complete automated deployment
deploy-all.bat

# Or run demo deployment
deploy-anypoint-demo.bat
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

### Step 3: Natural Language Processing Testing with Groq

Since the agent network uses Groq for natural language processing, test the conversational AI capabilities:

#### Groq API Setup and Testing
```bash
# Set Groq API key (if not already set)
export GROQ_API_KEY=your-groq-api-key

# Test Groq connectivity
curl -X POST "https://api.groq.com/openai/v1/chat/completions" \
  -H "Authorization: Bearer $GROQ_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Hello, test connection"}],
    "model": "llama3-8b-8192"
  }'
```

#### Agent Network Conversational Testing

**Test 1: Employee Onboarding Conversation**
```bash
# Natural language employee creation
curl -X POST https://postgres-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "I need to onboard a new employee named Sarah Johnson, her email is sarah.johnson@company.com, she will be working in the Engineering department starting Monday.",
    "context": "employee-onboarding"
  }'
```

**Test 2: Asset Allocation Conversation**
```bash
# Natural language asset request
curl -X POST https://assets-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Sarah needs a MacBook Pro, wireless mouse, monitor, and desk setup for her workspace. She prefers a standing desk if available.",
    "context": "asset-allocation",
    "employeeId": "sarah.johnson@company.com"
  }'
```

**Test 3: Notification Preferences Conversation**
```bash
# Natural language notification setup
curl -X POST https://notification-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Send Sarah a welcome email with her first day instructions, include building access details and team introduction schedule. Also notify her manager and the IT team.",
    "context": "notification-setup",
    "employeeId": "sarah.johnson@company.com"
  }'
```

#### Advanced NLP Testing Scenarios

**Test 4: Multi-step Workflow via Natural Language**
```bash
# Complete onboarding workflow through conversation
curl -X POST https://postgres-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/workflow \
  -H "Content-Type: application/json" \
  -d '{
    "conversation": [
      "Create employee profile for Michael Chen, email michael.chen@company.com, Software Engineer, starts next Tuesday",
      "Allocate standard developer equipment: laptop, dual monitors, keyboard, mouse, headset",
      "Schedule welcome call with his team lead Jessica Wang for Tuesday 10 AM",
      "Send onboarding checklist email with IT setup instructions and first week schedule"
    ],
    "workflow": "complete-onboarding"
  }'
```

**Test 5: Intent Recognition Testing**
```bash
# Test various natural language intents
for intent in "create employee" "allocate assets" "send notification" "check status" "update information"
do
  curl -X POST https://postgres-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/intent \
    -H "Content-Type: application/json" \
    -d "{
      \"text\": \"I want to $intent for John Doe\",
      \"analyze_intent\": true
    }"
done
```

**Test 6: Groq Model Performance Testing**
```bash
# Test different Groq models for response quality
models=("llama3-8b-8192" "llama3-70b-8192" "mixtral-8x7b-32768" "gemma-7b-it")

for model in "${models[@]}"
do
  echo "Testing model: $model"
  curl -X POST https://postgres-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/test-model \
    -H "Content-Type: application/json" \
    -d "{
      \"model\": \"$model\",
      \"prompt\": \"Create a comprehensive onboarding plan for a new software engineer including timeline, required documents, and key stakeholders.\",
      \"test_scenario\": \"complex_planning\"
    }"
done
```

#### Interactive NLP Testing with Agent Network

**Web-based Testing Interface** (if deployed):
```bash
# Access the conversational interface
open https://postgres-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/chat

# Or use curl for interactive testing
curl -X GET https://postgres-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/health/nlp
```

**Sample Conversational Test Cases:**

1. **Complex Employee Onboarding:**
   ```
   Human: "We have 5 new interns starting next month. They're all computer science students, need basic equipment, and should be set up in the intern workspace. Can you handle the complete setup?"
   
   Expected: Agent should parse multiple employees, understand intern context, allocate appropriate equipment, and coordinate workspace assignment.
   ```

2. **Equipment Upgrade Request:**
   ```
   Human: "Sarah's laptop is running slow and she needs more RAM for her development work. Also, her monitor has dead pixels. Can we upgrade her setup?"
   
   Expected: Agent should identify existing employee, understand performance issues, suggest appropriate upgrades, and track equipment replacement.
   ```

3. **Emergency Notification:**
   ```
   Human: "There's a building evacuation drill tomorrow at 2 PM. Send notifications to all employees in the Engineering and Design departments with meeting point instructions."
   
   Expected: Agent should understand emergency context, identify target departments, craft appropriate urgent notification, and ensure delivery confirmation.
   ```

#### NLP Performance Metrics

**Response Time Testing:**
```bash
# Measure Groq response times
for i in {1..10}
do
  start_time=$(date +%s.%N)
  curl -s -X POST https://postgres-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/chat \
    -H "Content-Type: application/json" \
    -d '{"message": "Quick test message for response time", "context": "test"}'
  end_time=$(date +%s.%N)
  duration=$(echo "$end_time - $start_time" | bc)
  echo "Test $i: ${duration}s"
done
```

**Intent Accuracy Testing:**
```bash
# Test intent classification accuracy
curl -X POST https://postgres-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/test-intents \
  -H "Content-Type: application/json" \
  -d '{
    "test_cases": [
      {"text": "Add new employee", "expected_intent": "create_employee"},
      {"text": "Give laptop to John", "expected_intent": "allocate_asset"},
      {"text": "Email the team about meeting", "expected_intent": "send_notification"},
      {"text": "How is the onboarding going?", "expected_intent": "check_status"}
    ]
  }'
```

#### Troubleshooting NLP Issues

**Issue**: Groq API rate limiting
**Solution**:
```bash
# Check rate limits and usage
curl -X GET https://api.groq.com/openai/v1/models \
  -H "Authorization: Bearer $GROQ_API_KEY" \
  -v 2>&1 | grep -i "x-ratelimit"
```

**Issue**: Poor intent recognition
**Solution**:
```bash
# Test with more specific prompts
curl -X POST https://postgres-mcp-$ANYPOINT_ENV.$CLOUDHUB_REGION.cloudhub.io/mcp/train-intent \
  -H "Content-Type: application/json" \
  -d '{
    "training_examples": [
      {"text": "onboard new hire", "intent": "create_employee"},
      {"text": "provision equipment", "intent": "allocate_asset"}
    ]
  }'
```

**Issue**: Slow NLP responses
**Solution**:
```bash
# Test different Groq models for speed vs accuracy trade-off
# llama3-8b-8192: Fastest, good for simple tasks
# llama3-70b-8192: Slower, better for complex reasoning
# mixtral-8x7b-32768: Balanced performance
```

### Step 4: Monitor with Anypoint Visualizer
1. Access Anypoint Platform → Visualizer
2. Select your environment
3. View the agent network topology
4. Monitor real-time message flows
5. Check application health and metrics
6. **Monitor NLP conversation flows and Groq API usage**
7. **Review intent recognition accuracy and response times**

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

#### 4. Database Connection Issues (Local PostgreSQL)
**Issue**: CloudHub can't connect to PostgreSQL on your laptop
**Solutions**:

**Connection Timeout:**
```bash
# Check if PostgreSQL is running
# Windows
sc query postgresql-x64-15
# macOS/Linux
ps aux | grep postgres

# Check if port 5432 is accessible from internet
telnet YOUR_PUBLIC_IP 5432
```

**Firewall Blocking:**
```bash
# Windows - Allow PostgreSQL through firewall
netsh advfirewall firewall add rule name="PostgreSQL" dir=in action=allow protocol=TCP localport=5432

# Check Windows Firewall settings
netsh advfirewall firewall show rule name="PostgreSQL"
```

**Router Configuration:**
```bash
# Port forwarding setup (varies by router)
# Forward external port 5432 to internal IP:5432
# Example: 203.0.113.1:5432 -> 192.168.1.100:5432

# Test port forwarding
nmap -p 5432 YOUR_PUBLIC_IP
```

**Dynamic IP Issues:**
```bash
# Your public IP might change - use Dynamic DNS
# Services: No-IP, DuckDNS, Dynu
# Update POSTGRES_HOST when IP changes

# Check current public IP
curl -s https://api.ipify.org

# Set up IP monitoring (Windows batch)
echo @echo off > check_ip.bat
echo curl -s https://api.ipify.org > current_ip.txt >> check_ip.bat
echo fc current_ip.txt last_ip.txt >> check_ip.bat
echo if errorlevel 1 echo IP changed - update CloudHub apps >> check_ip.bat
```

**PostgreSQL Configuration Issues:**
```bash
# Check postgresql.conf
# Windows: C:\Program Files\PostgreSQL\15\data\postgresql.conf
# Ensure these settings:
listen_addresses = '*'
port = 5432
max_connections = 100

# Check pg_hba.conf authentication
# Add this line for CloudHub access:
host    onboarding    mule    0.0.0.0/0    md5

# Restart PostgreSQL after config changes
# Windows
net stop postgresql-x64-15 && net start postgresql-x64-15
```

**Testing Local Database from CloudHub:**
```bash
# Test connection from external IP (simulate CloudHub)
psql -h YOUR_PUBLIC_IP -U mule -d onboarding -c "SELECT 1;"

# Check PostgreSQL logs for connection attempts
# Windows: C:\Program Files\PostgreSQL\15\data\log\
# Look for failed connection attempts
```

**Alternative: Use ngrok for Secure Tunneling:**
```bash
# Download ngrok from https://ngrok.com/
# Install and authenticate with your account

# Create tunnel to PostgreSQL
ngrok tcp 5432

# Use the ngrok URL as POSTGRES_HOST
# Example: 0.tcp.ngrok.io:12345
# Update environment variables:
set POSTGRES_HOST=0.tcp.ngrok.io
set POSTGRES_PORT=12345
```

#### 5. Cloud Database Connection Issues
**Issue**: Can't connect to remote PostgreSQL (AWS RDS, Azure, etc.)
**Solution**:
- Verify database credentials
- Check network connectivity
- Ensure database security groups allow CloudHub IP ranges
- Check VPC and subnet configurations

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
