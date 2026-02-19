# Employee Onboarding System - Project Structure

## 📁 Clean Project Structure

```
employee-onboard-agent/
├── 🔧 Configuration Files
│   ├── agent-network.yaml              # Agent network configuration with Groq LLM
│   ├── exchange.json                   # Anypoint Exchange configuration
│   ├── .env                           # Environment variables (development)
│   └── .env.prod                      # Environment variables (production)
│
├── 🐳 Docker & Infrastructure
│   ├── docker-compose.yml             # Main Docker Compose configuration
│   ├── docker-compose.prod.yml        # Production Docker setup
│   ├── nginx.conf                     # Nginx gateway configuration
│   ├── nginx-prod.conf                # Production Nginx configuration
│   └── init-db.sql                    # PostgreSQL database initialization
│
├── 🔗 API Specifications
│   └── api-specs/
│       └── employee-onboarding-api.yaml   # OpenAPI 3.0 specification
│
├── 🛡️ Flex Gateway Policies
│   └── flex-gateway-policies/
│       ├── httproute.yaml             # HTTP routing configuration
│       ├── rate-limiting-policy.yaml  # Rate limiting policy
│       └── authentication-policy.yaml # Authentication policy
│
├── 🔧 Mule Applications
│   ├── mule-broker/
│   │   └── broker.xml                 # Main orchestration broker
│   ├── mule-postgres/
│   │   └── mcp-server.xml            # PostgreSQL MCP service
│   ├── mule-assets/
│   │   └── mcp-server.xml            # Assets MCP service
│   └── mule-notification/
│       └── mcp-server.xml            # Notification MCP service
│
├── 🏗️ Full Mule Project
│   └── postgres-mcp-onboarding/       # Complete Mule project structure
│       ├── pom.xml                   # Maven configuration
│       ├── mule-artifact.json        # Mule artifact configuration
│       └── src/                      # Source code directory
│
├── 📊 Monitoring & Security
│   ├── monitoring/
│   │   └── prometheus.yml            # Prometheus monitoring config
│   └── ssl/
│       ├── server.crt               # SSL certificate
│       └── server.key               # SSL private key
│
├── 🧪 Testing & Deployment
│   ├── test-system.sh               # Linux/Mac test script
│   ├── test-system.bat              # Windows test script
│   └── Exchange-and-FlexGateway-Setup-Guide.md  # Deployment guide
│
└── 📚 Documentation
    └── README.md                     # Main project documentation
```

## 🎯 Key Components

### Core Services
- **Mule Broker**: Orchestrates the complete onboarding workflow
- **PostgreSQL MCP**: Handles employee database operations
- **Assets MCP**: Manages asset allocation (laptop, ID card, bag)
- **Notification MCP**: Sends welcome emails and notifications

### API Gateway
- **Nginx**: Current reverse proxy with basic rate limiting
- **Flex Gateway**: Advanced policy-based gateway (ready for deployment)

### Agent Network
- **Groq LLM Integration**: Natural language processing for onboarding requests
- **MCP Protocol**: Model Context Protocol for microservice communication

### Testing & Deployment
- **Docker Compose**: Complete containerized deployment
- **Test Scripts**: Automated testing for all components
- **Policy Configurations**: Security and performance policies

## 🚀 Quick Start

1. **Start the system**: `docker-compose up -d`
2. **Run tests**: `./test-system.sh` (Linux/Mac) or `test-system.bat` (Windows)
3. **Test onboarding**: 
   ```bash
   curl -X POST http://localhost:8080/broker/onboard \
     -H "Content-Type: application/json" \
     -d '{"name": "Pradeep", "email": "pradeep.n2019@gmail.com"}'
   ```

## 📋 Removed Files

The following unnecessary files have been cleaned up:
- ❌ `data/` directory (PostgreSQL runtime files)
- ❌ `logs/` directory (Runtime logs)
- ❌ `postgresql.conf/` directory (Duplicate config)
- ❌ Test artifacts (test scripts, results)
- ❌ Duplicate configuration files

## 🎉 Result

Clean, organized project structure with only essential files for:
- ✅ Employee onboarding workflow
- ✅ Microservices architecture
- ✅ API gateway and policies
- ✅ NLP agent integration
- ✅ Docker deployment
- ✅ Testing and documentation
