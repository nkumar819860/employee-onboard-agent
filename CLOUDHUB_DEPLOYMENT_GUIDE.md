# CloudHub Deployment Guide - Employee Onboarding System

## 🌐 CloudHub 2.0 Deployment Configuration

### Prerequisites
1. **Anypoint Platform Account** - Active subscription
2. **Connected App** - For automated deployment
3. **Environment Access** - Sandbox/Production environment

## 🔧 Step 1: Configure Connected App in Anypoint Platform

### Create Connected App
1. Login to **Anypoint Platform** → https://anypoint.mulesoft.com
2. Navigate to **Access Management** → **Connected Apps**
3. Click **Create App** → **App acts on its own behalf**
4. Fill in details:
   ```
   Name: Employee-Onboarding-Deployment-App
   Description: Connected app for automated deployment of employee onboarding system
   ```
5. **Grant Scopes:**
   - `Design Center Developer`
   - `Exchange Contributor`
   - `Runtime Manager Deploy`
   - `Runtime Manager Read Applications`
   - `CloudHub Organization Admin` (if available)

6. **Save and Note Down:**
   - Client ID: `<your-client-id>`
   - Client Secret: `<your-client-secret>`

### Alternative: Username/Password Authentication
If Connected App is not available, you can use:
- **Username**: Your Anypoint Platform username
- **Password**: Your Anypoint Platform password

## 🗄️ Step 2: Remove PostgreSQL Dependencies

I'll update the project to use only H2 in-memory database for CloudHub compatibility.

## 🚀 Step 3: Update Maven Configuration for CloudHub

### Update pom.xml for CloudHub Deployment
The pom.xml needs CloudHub-specific configuration.

## 📝 Step 4: Environment Configuration

### Secure Properties for CloudHub
Configure these in Anypoint Platform Runtime Manager:

#### Required Properties:
```properties
# Email Configuration (REQUIRED)
secure::email.smtp.user=your-email@gmail.com
secure::email.smtp.password=your-app-password

# OpenAI Configuration (for Agent Network)
secure::openai.apiKey=your-openai-api-key

# Application Configuration
app.environment=production
```

## 🔨 Step 5: Deployment Methods

### Method 1: Using Updated Deployment Script
```bash
# Deploy to CloudHub using Connected App
./scripts/deploy.sh \
  --client-id <your-client-id> \
  --client-secret <your-client-secret> \
  --environment Production \
  --app-name employee-onboarding-system

# Or using username/password
./scripts/deploy.sh \
  -u <username> \
  -p <password> \
  -e Production \
  -a employee-onboarding-system
```

### Method 2: Direct Maven Command
```bash
mvn clean package mule:deploy -DmuleDeploy \
  -Dusername=<username> \
  -Dpassword=<password> \
  -DapplicationName=employee-onboarding-system \
  -Denvironment=Production \
  -DworkerType=MICRO \
  -Dworkers=1
```

### Method 3: Anypoint Studio
1. Right-click project → **Anypoint Platform** → **Deploy to CloudHub**
2. Enter credentials and configuration
3. Deploy

## 🌟 Step 6: Publish to Anypoint Exchange (Agent Network Assets)

### Publish Application Asset
```bash
# Publish the application to Exchange
mvn clean package deploy \
  -DrepositoryId=anypoint-exchange-v3 \
  -DaltDeploymentRepository=anypoint-exchange-v3::default::https://maven.anypoint.mulesoft.com/api/v3/maven
```

### Exchange Asset Configuration
The `exchange.json` is already configured:
```json
{
  "main": "agent-network.yaml",
  "name": "EmployeeOnboardingAgentFabric",
  "classifier": "agent-network",
  "organizationId": "47562e5d-bf49-440a-a0f5-a9cea0a89aa9",
  "version": "1.0.0"
}
```

## 🔗 Step 7: Agent Network Integration URLs

After CloudHub deployment, your Agent Network will be accessible at:

### Production URLs:
- **Main Application**: `https://employee-onboarding-system.us-e2.cloudhub.io`
- **Employee Service**: `https://employee-onboarding-system.us-e2.cloudhub.io` (Port 8082 routes)
- **Asset Service**: `https://employee-onboarding-system.us-e2.cloudhub.io` (Port 8083 routes)  
- **Email Service**: `https://employee-onboarding-system.us-e2.cloudhub.io` (Port 8084 routes)

### Update agent-network.yaml Variables:
```yaml
connections:
  employeeOnboardingConnection:
    spec:
      url: https://employee-onboarding-system.us-e2.cloudhub.io/employee
  assetAllocationConnection:
    spec:
      url: https://employee-onboarding-system.us-e2.cloudhub.io/assets
  emailNotificationConnection:
    spec:
      url: https://employee-onboarding-system.us-e2.cloudhub.io/email
```

## 📊 Step 8: Monitoring and Management

### CloudHub Management
- **Runtime Manager**: Monitor application health
- **Logs**: View application logs in real-time  
- **Alerts**: Set up monitoring alerts
- **Scaling**: Adjust workers and worker types

### Application Endpoints (Post-Deployment)
```
Health Check: https://employee-onboarding-system.us-e2.cloudhub.io/health
API Documentation: https://employee-onboarding-system.us-e2.cloudhub.io/console
```

## 🧪 Step 9: Test CloudHub Deployment

```bash
# Test deployed application
./scripts/test.sh -u https://employee-onboarding-system.us-e2.cloudhub.io

# Manual test
curl https://employee-onboarding-system.us-e2.cloudhub.io/health
```

## 🔐 Step 10: Security Configuration

### Secure Properties in Runtime Manager:
1. Go to **Runtime Manager** → **Applications** → **Your App** → **Properties**
2. Add secure properties:
   ```
   secure::email.smtp.user
   secure::email.smtp.password  
   secure::openai.apiKey
   ```

### HTTPS Configuration:
CloudHub automatically provides HTTPS endpoints with SSL certificates.

## 📋 Step 11: Agent Network Publishing Checklist

### Pre-Publishing Checklist:
- ✅ Application deployed to CloudHub
- ✅ Health endpoints responding
- ✅ Secure properties configured
- ✅ agent-network.yaml updated with CloudHub URLs
- ✅ Exchange asset metadata configured

### Publishing to Exchange:
1. **Build**: `mvn clean package`
2. **Deploy to Exchange**: `mvn deploy`
3. **Verify in Exchange**: Check Anypoint Exchange for your asset
4. **Agent Network Integration**: Asset available for Agentforce

## 🎯 Expected Results

### Successful Deployment Indicators:
- ✅ Application shows as "Started" in Runtime Manager
- ✅ Health endpoint returns 200 OK
- ✅ All API endpoints accessible via HTTPS
- ✅ Email notifications working (if configured)
- ✅ Agent Network asset available in Exchange

### CloudHub Application URL Structure:
```
https://employee-onboarding-system.us-e2.cloudhub.io/onboardEmployee
https://employee-onboarding-system.us-e2.cloudhub.io/health
https://employee-onboarding-system.us-e2.cloudhub.io/getOnboardingStatus/{id}
```

## 🚨 Troubleshooting

### Common Issues:
1. **Authentication Error**: Verify Connected App credentials
2. **Deployment Timeout**: Increase worker size or check dependencies
3. **Email Not Working**: Verify SMTP credentials in secure properties
4. **Database Errors**: Ensure H2 configuration is correct

### Support Resources:
- **MuleSoft Documentation**: https://docs.mulesoft.com/runtime-manager/
- **CloudHub Status**: https://status.salesforce.com/products/CloudHub
- **Community Forum**: https://help.mulesoft.com/

---

**Next Steps**: I'll now update the project files to remove PostgreSQL dependencies and configure for CloudHub deployment.
