# Anypoint Platform & Docker Hybrid Deployment Guide

This guide explains how to deploy the Employee Onboarding Agent Network to both Docker (local development) and Anypoint Platform (production) environments, with Anypoint Visualizer integration and Exchange publication.

## 🏗️ Architecture Overview

The hybrid deployment supports two parallel environments:

### 🐳 Docker Environment (Local Development)
- **Purpose**: Local development, testing, and demos
- **Components**: Mule ESB containers, PostgreSQL, Nginx (Flex Gateway)
- **Networking**: Local ports (8080-8084)
- **Data**: Local PostgreSQL instance

### ☁️ Anypoint Platform (Production)
- **Purpose**: Production deployment with enterprise features
- **Runtime**: CloudHub 2.0
- **Components**: MCP servers deployed as Mule applications
- **Monitoring**: Anypoint Visualizer integration
- **Distribution**: Anypoint Exchange publication

## 📋 Prerequisites

### For Docker Deployment
- Docker Desktop or Docker Engine
- Docker Compose v2.0+
- 8GB+ RAM available for containers

### For Anypoint Platform Deployment
- Anypoint Platform account with appropriate permissions
- Anypoint CLI: `npm install -g anypoint-cli`
- Maven 3.6+
- Java 8 or 11
- Environment variables configured (see [Configuration](#configuration))

## 🚀 Quick Start

### Option 1: Docker Only
```bash
./deploy-hybrid.sh docker
```

### Option 2: Anypoint Platform Only
```bash
# Configure environment first
cp anypoint-deployment/.env.anypoint.template anypoint-deployment/.env.anypoint
# Edit .env.anypoint with your credentials
./deploy-hybrid.sh anypoint -e anypoint-deployment/.env.anypoint
```

### Option 3: Both Platforms (Hybrid)
```bash
# Configure environment first
cp anypoint-deployment/.env.anypoint.template anypoint-deployment/.env.anypoint
# Edit .env.anypoint with your credentials
./deploy-hybrid.sh both -e anypoint-deployment/.env.anypoint
```

## ⚙️ Configuration

### Docker Configuration Files
- `agent-network.yaml` - Agent network definition for Docker
- `exchange.json` - Local environment variables
- `docker-compose.yml` - Container orchestration
- `.env` - Local environment variables (optional)

### Anypoint Platform Configuration Files
- `anypoint-deployment/agent-network-anypoint.yaml` - Agent network for CloudHub
- `anypoint-deployment/exchange-anypoint.json` - Anypoint-specific configuration
- `anypoint-deployment/.env.anypoint` - Anypoint credentials and settings

### Required Environment Variables for Anypoint

Create `anypoint-deployment/.env.anypoint`:

```bash
# Required Anypoint Credentials
ANYPOINT_ORG_ID=your-organization-id
ANYPOINT_CLIENT_ID=your-connected-app-client-id
ANYPOINT_CLIENT_SECRET=your-connected-app-secret
ANYPOINT_USERNAME=your-anypoint-username
ANYPOINT_PASSWORD=your-anypoint-password

# Optional Configuration
ANYPOINT_ENV=Sandbox                    # Environment name
CLOUDHUB_REGION=us-east-1              # CloudHub region
OPENAI_API_KEY=your-openai-key         # For LLM integration
```

## 🔧 Deployment Options

### Full Command Reference

```bash
# Deploy to Docker with cleanup
./deploy-hybrid.sh docker --clean

# Deploy to Anypoint with verbose output
./deploy-hybrid.sh anypoint --verbose -e .env.anypoint

# Deploy to both platforms
./deploy-hybrid.sh both --clean

# Deploy only Docker part of hybrid
./deploy-hybrid.sh both --docker-only

# Deploy only Anypoint part of hybrid
./deploy-hybrid.sh both --anypoint-only

# Show help
./deploy-hybrid.sh --help
```

## 📊 Anypoint Visualizer Integration

The deployment automatically configures Anypoint Visualizer to provide real-time monitoring:

### Features Enabled
- **Application Topology**: Visual representation of MCP server interactions
- **Real-time Metrics**: Request counts, response times, error rates
- **Flow Tracing**: End-to-end transaction tracking
- **Health Monitoring**: Component status and availability
- **Alerting**: Automated alerts for failures or performance issues

### Accessing Visualizer
1. Go to [Anypoint Visualizer](https://anypoint.mulesoft.com/visualizer)
2. Search for "Employee Onboarding Agent Network"
3. View real-time topology and metrics

### Key Visualizer Components
- **HR Agent**: Main orchestration broker
- **PostgreSQL MCP**: Employee data management
- **Assets MCP**: Equipment allocation service
- **Notifications MCP**: Welcome message service

## 📦 Anypoint Exchange Publication

The deployment publishes assets to Anypoint Exchange for reusability:

### Published Assets
1. **Employee Onboarding Agent Network** (agent-network)
2. **PostgreSQL MCP Server** (mule-application)
3. **Assets MCP Server** (mule-application)
4. **Notifications MCP Server** (mule-application)
5. **Onboarding Broker** (mule-application)

### Accessing Exchange Assets
1. Go to [Anypoint Exchange](https://anypoint.mulesoft.com/exchange)
2. Navigate to your organization's private exchange
3. Search for "employee-onboarding" or "mcp-server"

## 🌐 Endpoint URLs

### Docker Environment
```
Agent Network:    http://localhost:8080
HR Broker:        http://localhost:8081
PostgreSQL MCP:   http://localhost:8082
Assets MCP:       http://localhost:8083
Notifications:    http://localhost:8084
React Client:     http://localhost:3001
```

### Anypoint Platform (CloudHub)
```
HR Agent:         https://hr-agent-{env}.{region}.cloudhub.io
PostgreSQL MCP:   https://postgres-mcp-{env}.{region}.cloudhub.io
Assets MCP:       https://assets-mcp-{env}.{region}.cloudhub.io
Notifications:    https://notification-mcp-{env}.{region}.cloudhub.io
```

## 🧪 Testing the Deployment

### Docker Testing
```bash
# Test onboarding workflow
curl -X POST http://localhost:8080/broker/onboard \
  -H 'Content-Type: application/json' \
  -d '{"name":"John Doe","email":"john@company.com","role":"developer"}'

# Check individual MCP servers
curl http://localhost:8082/api/health  # PostgreSQL MCP
curl http://localhost:8083/api/health  # Assets MCP
curl http://localhost:8084/api/health  # Notifications MCP
```

### Anypoint Platform Testing
```bash
# Test CloudHub deployment
curl -X POST https://hr-agent-sandbox.us-east-1.cloudhub.io/broker/onboard \
  -H 'Content-Type: application/json' \
  -H 'x-api-key: your-api-key' \
  -d '{"name":"Jane Smith","email":"jane@company.com","role":"manager"}'
```

### React Client Testing
1. Open http://localhost:3001 in your browser
2. Enter employee details in natural language:
   - "Onboard John Doe, john@company.com as developer"
3. Watch the real-time workflow execution
4. Check Anypoint Visualizer for CloudHub interactions

## 🔍 Monitoring and Troubleshooting

### Docker Monitoring
```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs -f [service-name]

# Check resource usage
docker stats
```

### Anypoint Platform Monitoring
1. **Runtime Manager**: Monitor application status and performance
2. **Visualizer**: Real-time topology and flow visualization
3. **CloudHub Logs**: Application logs and debugging information
4. **API Analytics**: Request metrics and performance data

### Common Issues and Solutions

#### Docker Issues
- **Port conflicts**: Change ports in docker-compose.yml
- **Memory issues**: Increase Docker memory allocation
- **Startup failures**: Check logs with `docker-compose logs`

#### Anypoint Issues
- **Authentication failures**: Verify credentials in .env.anypoint
- **Deployment failures**: Check Maven build with `mvn clean package`
- **Runtime issues**: Check CloudHub logs in Runtime Manager

## 🔄 Development Workflow

### Recommended Development Process
1. **Local Development**: Use Docker environment for development and testing
2. **Integration Testing**: Deploy to Anypoint Sandbox environment
3. **Production Deployment**: Deploy to Anypoint Production environment

### Code Changes Workflow
1. Make changes locally
2. Test with Docker: `./deploy-hybrid.sh docker --clean`
3. Test React client at http://localhost:3001
4. Deploy to Anypoint: `./deploy-hybrid.sh anypoint`
5. Verify in Anypoint Visualizer

### Configuration Updates
1. Update agent-network.yaml (Docker) or agent-network-anypoint.yaml (Anypoint)
2. Update exchange.json or exchange-anypoint.json
3. Redeploy with `./deploy-hybrid.sh both --clean`

## 📈 Scaling and Performance

### Docker Scaling
```bash
# Scale specific services
docker-compose up -d --scale postgres-mcp=2
docker-compose up -d --scale assets-mcp=3
```

### CloudHub Scaling
- **vCores**: Adjust in deployment configuration (0.5-8 vCores)
- **Replicas**: Configure for high availability (1-8 replicas)
- **Auto-scaling**: Enable in CloudHub for dynamic scaling

### Performance Optimization
1. **Database**: Use external PostgreSQL for production
2. **Caching**: Enable object store persistence
3. **Load Balancing**: Use CloudHub's built-in load balancing
4. **CDN**: Configure CloudFront for static assets

## 🔐 Security Considerations

### Docker Security
- Network isolation with Docker networks
- Environment variables for secrets
- Regular image updates

### Anypoint Platform Security
- OAuth 2.0 client credentials
- API key authentication
- VPC and VPN connectivity
- Anypoint Security (additional license)

## 📚 Additional Resources

- [Anypoint Platform Documentation](https://docs.mulesoft.com/general/)
- [CloudHub 2.0 Guide](https://docs.mulesoft.com/cloudhub-2/)
- [Anypoint Visualizer Guide](https://docs.mulesoft.com/visualizer/)
- [Anypoint Exchange Guide](https://docs.mulesoft.com/exchange/)
- [MCP (Model Context Protocol) Specification](https://modelcontextprotocol.io/)

## 🆘 Support and Troubleshooting

### Getting Help
1. Check application logs in Runtime Manager (Anypoint) or Docker logs
2. Use Anypoint Visualizer for real-time debugging
3. Review the troubleshooting section in this guide
4. Check MuleSoft documentation and community forums

### Log Locations
- **Docker**: `docker-compose logs [service-name]`
- **CloudHub**: Runtime Manager → Applications → [App Name] → Logs
- **React Client**: Browser developer console

---

*This guide provides comprehensive instructions for deploying the Employee Onboarding Agent Network to both Docker and Anypoint Platform environments. The hybrid approach enables seamless development-to-production workflows while leveraging enterprise-grade monitoring and management capabilities.*
