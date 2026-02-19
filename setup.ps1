# setup.ps1 - Windows PowerShell Script for Complete Agent Fabric Setup
# Right-click PowerShell → "Run as Administrator" → Navigate to folder → ./setup.ps1

#Requires -RunAsAdministrator

# Colors
$GREEN = "Green"
$RED = "Red"
$YELLOW = "Yellow"
$BLUE = "Blue"
$CYAN = "Cyan"

function Write-Log { param([string]$Message, [string]$Color="White") Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Color }
function Write-Success { Write-Log "✅ $_" "Green" }
function Write-Error { Write-Log "❌ $_" "Red"; exit 1 }
function Write-Warn { Write-Log "⚠️  $_" "Yellow" }

Write-Log "🚀 Windows Employee Onboarding Agent - COMPLETE SETUP" "Cyan"

# =============================================================================
# 1. PREREQUISITES CHECK (Windows)
# =============================================================================

Write-Log "🔍 Checking Windows Prerequisites..."

# Docker Desktop
try { docker --version | Out-Null; Write-Success "Docker OK" } 
catch { 
    Write-Error "Docker Desktop not running. Install from: https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    Write-Host "1. Install Docker Desktop"
    Write-Host "2. Restart computer"
    Write-Host "3. Enable WSL2 in Windows Features"
    exit 1 
}

# Docker Compose
try { docker-compose --version | Out-Null; Write-Success "Docker Compose OK" } 
catch { Write-Error "Docker Compose not found. Restart Docker Desktop." }

# Git
try { git --version | Out-Null; Write-Success "Git OK" } catch { Write-Warn "Git recommended: https://git-scm.com/download/win" }

Write-Success "Windows Prerequisites OK!"

# =============================================================================
# 2. USER INPUT (Windows)
# =============================================================================

Write-Log "📝 Enter your credentials:" "Yellow"
$ANYPOINT_USER = Read-Host "Anypoint Platform Username"
$ANYPOINT_PASS = Read-Host "Anypoint Platform Password" -AsSecureString
$SECURE_PASS = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ANYPOINT_PASS))
$ANYPOINT_ORG = Read-Host "Anypoint Organization ID"
$GROQ_KEY = Read-Host "Groq API Key (console.groq.com/keys)" -AsSecureString
$SECURE_GROQ = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($GROQ_KEY))
$ANYPOINT_ENV = Read-Host "Environment (Sandbox/Production)" 

# =============================================================================
# 3. CREATE PROJECT STRUCTURE
# =============================================================================

$PROJECT_NAME = "employee-onboarding-agent"
New-Item -ItemType Directory -Force -Path "$PROJECT_NAME" | Out-Null
Set-Location "$PROJECT_NAME"

Write-Log "📁 Creating Windows project structure..." "Blue"

# Create directories (Windows paths)
$dirs = @(
    "postgres",
    "postgres-mcp\src\main\mule",
    "postgres-mcp\src\main\resources",
    "agent-network",
    "flex-gateway",
    "logs"
)
foreach ($dir in $dirs) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

# =============================================================================
# 4. DOCKER COMPOSE (Windows)
# =============================================================================

@"
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: hrdb
      POSTGRES_USER: hruser
      POSTGRES_PASSWORD: hrpass123
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./postgres/init.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U hruser hrdb"]
      interval: 10s
      timeout: 5s
      retries: 5

  mule-mcp:
    build: ./postgres-mcp
    ports:
      - "8081:8081"
    environment:
      POSTGRES_HOST: postgres
      POSTGRES_PORT: 5432
      POSTGRES_DB: hrdb
      POSTGRES_USER: hruser
      POSTGRES_PASSWORD: hrpass123
    depends_on:
      postgres:
        condition: service_healthy
    volumes:
      - ./logs:/opt/mule/logs

  agent-broker:
    image: mulesoft/agent-broker:latest
    ports:
      - "8082:8080"
    environment:
      AGENT_NETWORK_CONFIG: /config/agent-network.yaml
      POSTGRES_MCP_URL: http://mule-mcp:8081/mcp
      GROQ_API_KEY: "$SECURE_GROQ"
    volumes:
      - ./agent-network:/config
      - ./logs:/logs
    depends_on:
      - mule-mcp

  flex-gateway:
    image: mulesoft/flex-gateway:latest
    ports:
      - "8080:8080"
    environment:
      FLEX_GATEWAY_ANYPPOINT_TOKEN: "GENERATED_TOKEN"
    volumes:
      - ./flex-gateway:/usr/local/share/flex-gateway/conf
      - ./agent-network:/agents
    command: >
      flex-gateway start
      --config /usr/local/share/flex-gateway/conf/config.yml
      --proxies-dir /agents

volumes:
  postgres_data:
"@ | Out-File -FilePath "docker-compose.yml" -Encoding UTF8

# =============================================================================
# 5. POSTGRES SCHEMA
# =============================================================================

$init_sql = @"
-- HR Tables
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    employee_id VARCHAR(50) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    department VARCHAR(100),
    role VARCHAR(100),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE it_provisioning (
    id SERIAL PRIMARY KEY,
    employee_id VARCHAR(50) REFERENCES employees(employee_id),
    okta_user_id VARCHAR(100),
    laptop_assigned BOOLEAN DEFAULT FALSE,
    office365_setup BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- MCP Functions
CREATE OR REPLACE FUNCTION onboard_employee(p_employee_id VARCHAR, p_first_name VARCHAR, p_last_name VARCHAR, p_email VARCHAR, p_dept VARCHAR, p_role VARCHAR) RETURNS JSON AS `$$
DECLARE result JSON;
BEGIN
    INSERT INTO employees (employee_id, first_name, last_name, email, department, role) VALUES (p_employee_id, p_first_name, p_last_name, p_email, p_dept, p_role);
    INSERT INTO it_provisioning (employee_id) VALUES (p_employee_id);
    SELECT json_build_object('status', 'success', 'employee_id', p_employee_id, 'message', 'Employee onboarded successfully') INTO result;
    RETURN result;
END;
$$` LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_employee(p_employee_id VARCHAR) RETURNS JSON AS `$$
BEGIN
    RETURN (SELECT json_build_object('employee_id', e.employee_id, 'name', e.first_name || ' ' || e.last_name, 'email', e.email, 'department', e.department, 'it_provisioned', i.id IS NOT NULL)
        FROM employees e LEFT JOIN it_provisioning i ON e.employee_id = i.employee_id WHERE e.employee_id = p_employee_id);
END;
$$` LANGUAGE plpgsql;
"@
$init_sql | Out-File -FilePath "postgres\init.sql" -Encoding UTF8

# =============================================================================
# 6. MULE MCP FILES (pom.xml, mule config, properties)
# =============================================================================

# pom.xml
$pom_content = @"
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>postgres-mcp-server</artifactId>
    <version>1.0.0</version>
    <packaging>mule-application</packaging>
    <properties>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <mule.maven.plugin.version>4.1.3</mule.maven.plugin.version>
        <mule.version>4.6.0</mule.version>
    </properties>
    <build>
        <plugins>
            <plugin>
                <groupId>org.mule.tools.maven</groupId>
                <artifactId>mule-maven-plugin</artifactId>
                <version>$${mule.maven.plugin.version}</version>
                <extensions>true</extensions>
                <configuration><classifier>worker</classifier></configuration>
            </plugin>
        </plugins>
    </build>
    <dependencies>
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <version>42.7.3</version>
        </dependency>
        <dependency>
            <groupId>com.mulesoft.muleesb</groupId>
            <artifactId>mule-ee-distribution-standalone</artifactId>
            <version>$${mule.version}</version>
            <classifier>worker</classifier>
            <type>mule-application</type>
            <scope>provided</scope>
        </dependency>
    </dependencies>
</project>
"@
$pom_content | Out-File -FilePath "postgres-mcp\pom.xml" -Encoding UTF8

# Config.yml
@"
postgres:
  host: `${env:POSTGRES_HOST:postgres}
  port: `${env:POSTGRES_PORT:5432}
  database: `${env:POSTGRES_DB:hrdb}
  username: `${env:POSTGRES_USER:hruser}
  password: `${env:POSTGRES_PASSWORD:hrpass123}
"@ | Out-File -FilePath "postgres-mcp\src\main\resources\config.yml" -Encoding UTF8

# Flex Gateway Config
@"
env:
  http: 
    port: 8080
  anypoint:
    platform:
      organization: "$ANYPOINT_ORG"
      environment: "$ANYPOINT_ENV"
proxies:
  onboarding-broker:
    pathPrefix: /onboarding-broker
    upstreamUrl: http://agent-broker:8080
    policies:
      - rate-limit:
          interval: 1m
          requestsPermitted: 100
      - cors:
          allowedOrigins: ["*"]
"@ | Out-File -FilePath "flex-gateway\config.yml" -Encoding UTF8

# Agent Network (Groq)
@"
apiVersion: a2a.mulesoft.com/v1alpha1
kind: AgentNetwork
metadata:
  name: employee-onboarding-postgres
spec:
  brokers:
    onboarding-broker:
      card:
        protocolVersion: "0.3.0"
        name: "Employee Onboarding Agent (Windows)"
        description: "AI-powered employee onboarding with PostgreSQL + Groq"
        url: "http://localhost:8080/onboarding-broker"
        provider: { organization: "LocalDev" }
        defaultInputModes: ["application/json", "text/plain"]
        skills: [{ id: "employee-onboarding", description: "Onboards new employees", tags: ["hr", "ai", "postgres"] }]
      spec:
        llm: 
          provider: "groq"
          model: "llama-3.3-70b-versatile"
        instructions: |
          You are Employee Onboarding Agent for Windows. Process natural language requests:
          "Onboard John Doe, john@company.com, Software Engineer, Engineering"
          
          Steps:
          1. Extract: employee_id (EMP001 format), first_name, last_name, email, department, role
          2. Validate email format and required fields
          3. Call postgres-mcp.onboard_employee tool
          4. Return JSON: {{"status": "success", "employee_id": "EMP001"}}
        links: [{ mcp: { ref: "postgres-mcp" } }]
        maxNumberOfLoops: 10
        maxTokens: 2000
  mcpServers:
    postgres-mcp:
      servers: [{ name: "postgres-hr-mcp", url: "http://mule-mcp:8081/mcp", transport: "streamableHttp" }]
"@ | Out-File -FilePath "agent-network\agent-network.yaml" -Encoding UTF8

New-Item -ItemType File -Path "agent-network\exchange.json" -Force | Out-Null

# .env file (Windows format)
@"
GROQ_API_KEY=$SECURE_GROQ
ANYPOINT_ORG_ID=$ANYPOINT_ORG
ANYPOINT_ENV=$ANYPOINT_ENV
"@ | Out-File -FilePath ".env" -Encoding UTF8

Write-Success "✅ Windows project structure created!"

# =============================================================================
# 7. BUILD & START (Windows Docker)
# =============================================================================

Write-Log "🚀 Building and starting Agent Fabric on Windows..." "Cyan"

# Build Mule MCP
docker-compose build mule-mcp
if ($LASTEXITCODE -ne 0) { Write-Error "Mule MCP build failed" }

# Start services
docker-compose up -d
Start-Sleep -Seconds 30

Write-Log "⏳ Waiting for Windows services (90 seconds)..." "Yellow"
Start-Sleep -Seconds 90

# Health check
docker-compose ps

Write-Success "🎉 Windows Agent Fabric LIVE at http://localhost:8080/onboarding-broker"

# =============================================================================
# 8. FINAL TEST
# =============================================================================

Write-Log "🧪 Testing Windows Agent..." "Blue"

$test_payload = @{
    messages = @(
        @{
            role = "user"
            content = "Onboard Jane Smith, jane@company.com, DevOps Engineer, Engineering"
        }
    )
} | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod -Uri "http://localhost:8080/onboarding-broker/v1/chat" -Method Post -Body $test_payload -ContentType "application/json"
Write-Host "Agent Response: $response`n"

Write-Success "🎉 WINDOWS SETUP COMPLETE!"
Write-Log "🌐 URLs:" "Cyan"
Write-Host "  Flex Gateway: http://localhost:8080/onboarding-broker"
Write-Host "  Agent Broker: http://localhost:8082"
Write-Host "  Mule MCP:     http://localhost:8081/mcp"
Write-Host "  Postgres:     localhost:5432"
Write-Host "`n📱 PowerShell Test Command:"
Write-Host "  `$body = @{messages=@{role='user';content='Onboard John Doe, john@company.com, Engineer, IT'}} | ConvertTo-Json"
Write-Host "  Invoke-RestMethod -Uri 'http://localhost:8080/onboarding-broker/v1/chat' -Method Post -Body `$body -ContentType 'application/json'"
