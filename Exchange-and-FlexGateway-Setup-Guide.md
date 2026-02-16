# Exchange Publication and Flex Gateway Policy Setup Guide

## Overview
This guide addresses the questions about why the API and agent network are not published to Anypoint Exchange and where the Flex Gateway policies are applied.

## 🏪 Anypoint Exchange Publication

### Current Status
The Employee Onboarding API and Agent Network are **not yet published** to Anypoint Exchange because:

1. **Missing Organization ID**: Exchange requires a valid UUID organization ID
2. **Authentication Required**: Need valid Anypoint Platform credentials
3. **Asset Preparation**: API specifications need proper formatting and metadata

### 📝 Step-by-Step Exchange Publication

#### 1. Prepare API Specifications
✅ **COMPLETED**: Created OpenAPI 3.0 specification at `api-specs/employee-onboarding-api.yaml`

#### 2. Get Organization Information
You need to obtain from Anypoint Platform:
```bash
# Get Organization ID (UUID format)
ORGANIZATION_ID="980c5346-1838-46a0-a1d9-42a6f8bf34a5"

# Get Authentication Token
ANYPOINT_TOKEN="09f4C0a99F494785be2918F6e0Cd6e9B"
```

#### 3. Publish Employee Onboarding API to Exchange
```bash
# Using MuleSoft MCP Server
curl -X POST http://localhost:8080/mcp/exchange/create \
  -H "Content-Type: application/json" \
  -d '{
    "operation": "Create",
    "groupId": "com.company.hr",
    "assetId": "employee-onboarding-api",
    "version": "1.0.0",
    "organizationId": "'$ORGANIZATION_ID'",
    "classifier": "oas",
    "name": "Employee Onboarding API",
    "description": "NLP-powered employee onboarding with MCP microservices",
    "apiVersion": "v1",
    "main": "employee-onboarding-api.yaml",
    "projectPath": "api-specs",
    "keywords": "[\"employee\", \"onboarding\", \"hr\", \"nlp\", \"mcp\"]",
    "tags": "[\"automation\", \"hr\", \"microservices\"]"
  }'
```

#### 4. Publish Agent Network to Exchange
```bash
# Publish Agent Network Configuration
curl -X POST http://localhost:8080/mcp/exchange/create \
  -H "Content-Type: application/json" \
  -d '{
    "operation": "Create",
    "groupId": "com.company.agents",
    "assetId": "employee-onboarding-agent-network",
    "version": "1.0.0",
    "organizationId": "'$ORGANIZATION_ID'",
    "classifier": "custom",
    "name": "Employee Onboarding Agent Network",
    "description": "Agent network configuration with Groq LLM and MCP servers",
    "projectPath": ".",
    "main": "agent-network.yaml",
    "keywords": "[\"agents\", \"groq\", \"mcp\", \"nlp\"]"
  }'
```

## 🛡️ Flex Gateway Policies

### Current Implementation
✅ **COMPLETED**: Created comprehensive Flex Gateway policies:

1. **Rate Limiting Policy**: `flex-gateway-policies/rate-limiting-policy.yaml`
   - 1000 requests/minute with burst of 5
   - 100 requests/hour quota
   - Client IP-based clustering

2. **HTTP Route Configuration**: `flex-gateway-policies/httproute.yaml`
   - Routes for all MCP services
   - Load balancing configuration
   - Health check endpoints

3. **Authentication Policy**: `flex-gateway-policies/authentication-policy.yaml`
   - Basic HTTP authentication
   - API key validation
   - Custom error responses

### 🚀 Applying Flex Gateway Policies

#### 1. Deploy Flex Gateway
```bash
# Install Flex Gateway
kubectl apply -f https://flex-gateway.mulesoft.com/install

# Create namespace
kubectl create namespace flex-system
```

#### 2. Apply Policy Configurations
```bash
# Apply HTTPRoute first
kubectl apply -f flex-gateway-policies/httproute.yaml

# Apply Rate Limiting Policy
kubectl apply -f flex-gateway-policies/rate-limiting-policy.yaml

# Apply Authentication Policy
kubectl apply -f flex-gateway-policies/authentication-policy.yaml
```

#### 3. Verify Policy Application
```bash
# Check HTTPRoute status
kubectl get httproute employee-onboarding-httproute -o yaml

# Check Policy Bindings
kubectl get policybinding -n default

# Test Rate Limiting
for i in {1..10}; do
  curl -X POST http://localhost:8080/broker/onboard \
    -H "Content-Type: application/json" \
    -d '{"name": "Test'$i'", "email": "test'$i'@company.com"}'
  sleep 1
done
```

## 🔧 Integration with Current Nginx Setup

### Current Nginx Configuration Analysis
The current `nginx.conf` already implements basic policies:
- ✅ Rate limiting: `limit_req_zone $binary_remote_addr zone=rl:10m rate=1000r/m`
- ✅ Load balancing: Upstream configurations for MCP services
- ✅ Request routing: Location blocks for different endpoints

### Migration Path to Flex Gateway
1. **Parallel Deployment**: Run Flex Gateway alongside Nginx
2. **Gradual Migration**: Move endpoints one by one
3. **Policy Enhancement**: Add advanced policies (JWT, OAuth, etc.)
4. **Monitoring**: Enhanced observability with Flex Gateway

## 📊 Policy Features Comparison

| Feature | Current Nginx | Flex Gateway Policies |
|---------|---------------|----------------------|
| Rate Limiting | ✅ Basic | ✅ Advanced with quotas |
| Authentication | ❌ None | ✅ Multiple methods |
| Load Balancing | ✅ Basic | ✅ Advanced algorithms |
| Monitoring | ❌ Limited | ✅ Full observability |
| Policy Flexibility | ❌ Static | ✅ Dynamic, conditional |
| API Management | ❌ None | ✅ Full API lifecycle |

## 🎯 Next Steps

### Immediate Actions Required:
1. **Get Anypoint Platform Credentials**
   - Organization ID
   - Access token
   - Environment details

2. **Deploy Flex Gateway**
   - Install in Kubernetes or standalone mode
   - Configure with Anypoint Platform

3. **Publish to Exchange**
   - Execute publication commands with correct credentials
   - Verify assets in Exchange

4. **Apply Policies**
   - Deploy policy configurations
   - Test and validate functionality

### Testing Commands After Setup:
```bash
# Test with rate limiting
curl -X POST http://localhost:8080/broker/onboard \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{"name": "Pradeep", "email": "pradeep.n2019@gmail.com"}'

# Verify rate limit headers
curl -I -X POST http://localhost:8080/broker/onboard \
  -H "Content-Type: application/json"
# Should return headers: x-ratelimit-limit, x-ratelimit-remaining
```

## 📋 Summary

### Why Not Published Yet:
1. **Organization ID Missing**: Need valid UUID from Anypoint Platform
2. **Authentication Required**: Valid platform credentials needed
3. **Environment Setup**: Flex Gateway deployment required

### Where Policies Are Applied:
1. **Current**: Basic rate limiting in Nginx (`nginx.conf`)
2. **Enhanced**: Comprehensive policies in `flex-gateway-policies/` folder
3. **Target**: Flex Gateway with full Anypoint Platform integration

The system is **ready for publication and policy deployment** once the Anypoint Platform credentials and Flex Gateway are properly configured.
