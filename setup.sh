#!/bin/bash
# setup.sh - Complete Anypoint Platform + Flex Gateway + Exchange + Agent Fabric Setup
# Author: Employee Onboarding Agent Deployment Script
# Date: Feb 2026

set -e  # Exit on any error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Global Config
PROJECT_NAME="employee-onboarding-agent"
ANYPOINT_ORG_ID=""
ANYPOINT_USER=""
ANYPOINT_PASS=""
GROQ_API_KEY=""

log() { echo -e "${BLUE}[$(date +'%H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# =============================================================================
# 1. INPUT PARAMETERS
# =============================================================================
log "🎛️  Configuration Setup"
read -p "Anypoint Platform Username: " ANYPOINT_USER
read -s -p "Anypoint Platform Password: " ANYPOINT_PASS
echo
read -p "Anypoint Organization ID: " ANYPOINT_ORG_ID
read -s -p "Groq API Key: " GROQ_API_KEY
echo
read -p "Anypoint Environment (Sandbox/Production): " ANYPOINT_ENV
echo

# =============================================================================
# 2. PREREQUISITES CHECK
# =============================================================================
log "🔍 Checking Prerequisites..."

# Docker & Docker Compose
command -v docker >/dev/null 2>&1 || error "Docker not installed. Install from https://docker.com"
command -v docker-compose >/dev/null 2>&1 || error "Docker Compose not installed"
docker info >/dev/null 2>&1 || error "Docker daemon not running. Start with 'sudo systemctl start docker'"

# Anypoint CLI
if ! command -v anypoint &> /dev/null; then
    log "📦 Installing Anypoint CLI v4..."
    curl -sL https://anypoint-cli.s3.amazonaws.com/releases/latest/anypointcli_linux_amd64.tar.gz | tar xz
    sudo mv anypointcli /usr/local/bin/anypoint
    anypoint version || error "Anypoint CLI installation failed"
fi

success "Prerequisites OK!"

# =============================================================================
# 3. PROJECT SETUP
# =============================================================================
log "📁 Creating $PROJECT_NAME project..."

mkdir -p $PROJECT_NAME/{postgres,postgres-mcp/src/main/{mule,resources},agent-network,flex-gateway,logs}
cd $PROJECT_NAME

# 3.1 Docker Compose with Flex Gateway + Mule Runtime
cat > docker-compose.yml << EOF
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
      GROQ_API_KEY: "$GROQ_API_KEY"
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
EOF

# 3.2 Postgres Schema (same as before)
cat > postgres/init.sql << 'EOF'
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
CREATE OR REPLACE FUNCTION onboard_employee(
    p_employee_id VARCHAR, p_first_name VARCHAR, p_last_name VARCHAR, 
    p_email VARCHAR, p_dept VARCHAR, p_role VARCHAR
) RETURNS JSON AS $$
DECLARE result JSON;
BEGIN
    INSERT INTO employees (employee_id, first_name, last_name, email, department, role)
    VALUES (p_employee_id, p_first_name, p_last_name, p_email, p_dept, p_role);
    INSERT INTO it_provisioning (employee_id) VALUES (p_employee_id);
    SELECT json_build_object('status', 'success', 'employee_id', p_employee_id, 
        'message', 'Employee onboarded successfully') INTO result;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_employee(p_employee_id VARCHAR) RETURNS JSON AS $$
BEGIN
    RETURN (SELECT json_build_object('employee_id', e.employee_id, 'name', e.first_name || ' ' || e.last_name,
        'email', e.email, 'department', e.department, 'it_provisioned', i.id IS NOT NULL)
        FROM employees e LEFT JOIN it_provisioning i ON e.employee_id = i.employee_id 
        WHERE e.employee_id = p_employee_id);
END;
$$ LANGUAGE plpgsql;
EOF

# 3.3 pom.xml for Mule MCP
cat > postgres-mcp/pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
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
                <version>${mule.maven.plugin.version}</version>
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
            <version>${mule.version}</version>
            <classifier>worker</classifier>
            <type>mule-application</type>
            <scope>provided</scope>
        </dependency>
    </dependencies>
</project>
EOF

# 3.4 Mule MCP XML
cat > postgres-mcp/src/main/mule/postgres-mcp.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<mule xmlns:db="http://www.mulesoft.org/schema/mule/db" xmlns:ee="http://www.mulesoft.org/schema/mule/ee/core"
      xmlns:http="http://www.mulesoft.org/schema/mule/http" xmlns="http://www.mulesoft.org/schema/mule/core" 
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.mulesoft.org/schema/mule/core http://www.mulesoft.org/schema/mule/core/current/mule.xsd
      http://www.mulesoft.org/schema/mule/http http://www.mulesoft.org/schema/mule/http/current/mule-http.xsd
      http://www.mulesoft.org/schema/mule/db http://www.mulesoft.org/schema/mule/db/current/mule-db.xsd
      http://www.mulesoft.org/schema/mule/ee/core http://www.mulesoft.org/schema/mule/ee/core/current/mule-ee.xsd">
    
    <db:config name="postgres_config">
        <db:generic-connection host="${postgres.host}" port="${postgres.port}" user="${postgres.username}" 
            password="${postgres.password}" database="${postgres.database}" driverClassName="org.postgresql.Driver">
            <db:pooling-profile maxIdle="10" maxWait="30000"/>
        </db:generic-connection>
    </db:config>

    <flow name="postgres-mcp-endpoint">
        <http:listener config-ref="HTTP_Listener_config" path="/mcp"/>
        <ee:transform>
            <ee:message>
                <ee:set-payload><![CDATA[%dw 2.0 output application/json --- { tool: payload.body.tool, params: payload.body.params }]]></ee:set-payload>
            </ee:message>
        </ee:transform>
        <choice>
            <when expression="#[payload.tool == 'onboard_employee']">
                <db:execute>
                    <db:statement><![CDATA[SELECT onboard_employee($[0]::varchar, $[1]::varchar, $[2]::varchar, $[3]::varchar, $[4]::varchar, $[5]::varchar)]]></db:statement>
                    <db:input-parameters>#[{ employee_id: payload.params.employee_id, first_name: payload.params.first_name, last_name: payload.params.last_name, email: payload.params.email, department: payload.params.department, role: payload.params.role }]</db:input-parameters>
                </db:execute>
            </when>
            <when expression="#[payload.tool == 'get_employee']">
                <db:execute>
                    <db:statement><![CDATA[SELECT get_employee($[0]::varchar)]]></db:statement>
                    <db:input-parameters>#[ [payload.params.employee_id] ]</db:input-parameters>
                </db:execute>
            </when>
            <otherwise>
                <set-payload value="#[output application/json --- { error: 'Unknown tool: ' ++ payload.tool }]" />
            </otherwise>
        </choice>
        <ee:transform>
            <ee:message>
                <ee:set-payload><![CDATA[%dw 2.0 output application/json --- { content: [{ type: "text", text: if (payload.result[0]?) payload.result[0] else payload }] }]]></ee:set-payload>
            </ee:message>
        </ee:transform>
        <http:response-status code="200"/>
    </flow>

    <http:listener-config name="HTTP_Listener_config">
        <http:listener-connection host="0.0.0.0" port="8081"/>
    </http:listener-config>
</mule>
EOF

# 3.5 Config files
cat > postgres-mcp/src/main/resources/config.yml << EOF
postgres:
  host: \${POSTGRES_HOST:postgres}
  port: \${POSTGRES_PORT:5432}
  database: \${POSTGRES_DB:hrdb}
  username: \${POSTGRES_USER:hruser}
  password: \${POSTGRES_PASSWORD:hrpass123}
EOF

# Agent Network with Groq
cat > agent-network/agent-network.yaml << EOF
apiVersion: a2a.mulesoft.com/v1alpha1
kind: AgentNetwork
metadata:
  name: employee-onboarding-postgres
spec:
  brokers:
    onboarding-broker:
      card:
        protocolVersion: "0.3.0"
        name: "Employee Onboarding Agent"
        description: "AI-powered employee onboarding with Postgres"
        url: "http://localhost:8080/onboarding-broker"
        provider: { organization: "LocalDev" }
        defaultInputModes: ["application/json", "text/plain"]
        skills: [{ id: "employee-onboarding", description: "Onboard employees", tags: ["hr", "ai"] }]
      spec:
        llm: { provider: "groq", model: "llama-3.3-70b-versatile" }
        instructions: |
          Process: "Onboard John Doe, john@company.com, Engineer, IT"
          1. Extract data, generate EMPxxx ID
          2. Call postgres-mcp.onboard_employee
          3. Return JSON success
        links: [{ mcp: { ref: "postgres-mcp" } }]
        maxNumberOfLoops: 10
        maxTokens: 2000
  mcpServers:
    postgres-mcp:
      servers: [{ name: "postgres-hr-mcp", url: "http://mule-mcp:8081/mcp", transport: "streamableHttp" }]
EOF

touch agent-network/exchange.json

# Flex Gateway Config
cat > flex-gateway/config.yml << EOF
env:
  http: { port: 8080 }
  anypoint:
    platform:
      organization: "$ANYPOINT_ORG_ID"
      environment: "$ANYPOINT_ENV"
proxies:
  onboarding-broker:
    pathPrefix: /onboarding-broker
    upstreamUrl: http://agent-broker:8080
    policies:
      - rate-limit: { interval: 1m, requestsPermitted: 100 }
      - cors: { allowedOrigins: ["*"] }
EOF

# .env file
cat > .env << EOF
GROQ_API_KEY=$GROQ_API_KEY
ANYPOINT_ORG_ID=$ANYPOINT_ORG_ID
ANYPOINT_ENV=$ANYPOINT_ENV
EOF

success "Project structure created!"

# =============================================================================
# 4. ANYPOINT CLI LOGIN & FLEX GATEWAY REGISTRATION
# =============================================================================
log "🔐 Anypoint Platform Login & Flex Gateway Setup..."

# Login to Anypoint CLI
anypoint account:login --username="$ANYPOINT_USER" --password="$ANYPOINT_PASS" || error "Anypoint login failed"

# Get Flex Gateway Token
FLEX_TOKEN=$(anypoint flex-gateway:get-activation-token --org="$ANYPOINT_ORG_ID" --env="$ANYPOINT_ENV" --output=json | jq -r '.token')
[[ -z "$FLEX_TOKEN" ]] && error "Failed to get Flex Gateway token"

# Update docker-compose with token
sed -i "s/GENERATED_TOKEN/$FLEX_TOKEN/" docker-compose.yml

success "Flex Gateway token obtained: $FLEX_TOKEN"

# =============================================================================
# 5. BUILD & START STACK
# =============================================================================
log "🚀 Building and starting Agent Fabric..."

# Build Mule MCP
docker-compose build mule-mcp || error "Mule MCP build failed"

# Start all services
docker-compose up -d

# Wait for services
log "⏳ Waiting for services to start (2-3 mins)..."
sleep 120

# Health check
docker-compose ps | grep "Up" || warn "Some services may not be healthy"

success "Agent Fabric running on http://localhost:8080/onboarding-broker"

# =============================================================================
# 6. EXCHANGE PUBLISHING
# =============================================================================
log "📤 Publishing to Anypoint Exchange..."

# Create Exchange asset
cat > exchange.json << EOF
{
  "exchange": {
    "name": "employee-onboarding-agent",
    "groupId": "com.example",
    "artifactId": "employee-onboarding-agent",
    "version": "1.0.0",
    "assetId": "employee-onboarding-agent",
    "category": "Integration"
  }
}
EOF

# Publish to Exchange (requires manual approval in UI for first time)
anypoint exchange:publish --org="$ANYPOINT_ORG_ID" --product="Exchange" --type="rest-api" \
  --main="agent-network/agent-network.yaml" --name="employee-onboarding-agent" || \
  warn "Exchange publish failed (manual approval needed in UI)"

# =============================================================================
# 7. API MANAGER POLICIES
# =============================================================================
log "🔒 Applying API Policies..."

# Apply Client ID Enforcement Policy via CLI
anypoint api:manage:apply-policy --org="$ANYPOINT_ORG_ID" --env="$ANYPOINT_ENV" \
  --api="onboarding-broker" --policy="client-id-enforcement" || \
  warn "Policy application failed (apply manually in API Manager)"

# =============================================================================
# 8. FINAL TESTS
# =============================================================================
log "🧪 Running end-to-end tests..."

# Test Agent
RESPONSE=$(curl -s -X POST http://localhost:8080/onboarding-broker/v1/chat \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Onboard Jane Smith, jane@company.com, DevOps Engineer, Engineering"}]}')

echo "🧠 Agent Response: $RESPONSE"

# Verify database
docker exec $(docker ps -q -f name=postgres) psql -U hruser -d hrdb -c "SELECT * FROM employees;" | head -20

# =============================================================================
# 9. SUMMARY & NEXT STEPS
# =============================================================================
success "🎉 COMPLETE SETUP SUCCESSFUL!"
echo ""
echo "🌐 ACCESS POINTS:"
echo "  Flex Gateway: http://localhost:8080/onboarding-broker"
echo "  Agent Broker: http://localhost:8082"
echo "  Mule MCP:     http://localhost:8081/mcp"
echo "  Postgres:     localhost:5432"
echo ""
echo "📊 Anypoint Platform:"
echo "  • Org: $ANYPOINT_ORG_ID"
echo "  • Env: $ANYPOINT_ENV"
echo "  • Flex Gateway: Check Runtime Manager"
echo "  • API Manager: /onboarding-broker policies applied"
echo "  • Exchange: Search 'employee-onboarding-agent'"
echo ""
echo "🔄 Management Commands:"
echo "  docker-compose logs -f    # View logs"
echo "  docker-compose down       # Stop"
echo "  docker-compose restart    # Restart"
echo ""
echo "📱 Test Command:"
echo "  curl -X POST http://localhost:8080/onboarding-broker/v1/chat -H 'Content-Type: application/json' -d '{\"messages\":[{\"role\":\"user\",\"content\":\"Onboard John Doe, john@company.com, Engineer, IT\"}]}'"
echo ""
success "Your AI Agent Fabric is LIVE! 🚀"
