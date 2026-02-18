# 🚀 CloudHub Deployment & Agent Network Integration Instructions

## ⚡ Quick Start Guide

### Step 1: Setup Connected App in Anypoint Platform

1. **Login to Anypoint Platform**: https://anypoint.mulesoft.com
2. **Navigate to Access Management** → **Connected Apps**
3. **Create Connected App**:
   - Name: `Employee-Onboarding-Deployment-App`
   - Description: `Connected app for employee onboarding system deployment`
   - Type: **App acts on its own behalf**

4. **Grant Required Scopes**:
   ```
   ✅ Design Center Developer
   ✅ Exchange Contributor  
   ✅ Runtime Manager Deploy
   ✅ Runtime Manager Read Applications
   ✅ CloudHub Organization Admin (if available)
   ```

5. **Save Credentials**:
   - **Client ID**: `<save-this-value>`
   - **Client Secret**: `<save-this-value>`

### Step 2: Deploy to CloudHub

**For Windows Users (.bat files):**
```batch
# Option 1: Using Connected App (Recommended)
scripts\deploy.bat --client-id <your-client-id> --client-secret <your-client-secret> -e Sandbox -a employee-onboarding-system

# Option 2: Using Username/Password
scripts\deploy.bat -u <username> -p <password> -e Sandbox -a employee-onboarding-system

# Option 3: Deploy and Publish to Exchange in one step
scripts\deploy.bat --client-id <your-client-id> --client-secret <your-client-secret> -e Production --publish-exchange
```

**For Linux/Mac Users (.sh files):**
```bash
# Option 1: Using Connected App (Recommended)
./scripts/deploy.sh \
  --client-id <your-client-id> \
  --client-secret <your-client-secret> \
  -e Sandbox \
  -a employee-onboarding-system

# Option 2: Using Username/Password
./scripts/deploy.sh \
  -u <username> \
  -p <password> \
  -e Sandbox \
  -a employee-onboarding-system

# Option 3: Deploy and Publish to Exchange in one step
./scripts/deploy.sh \
  --client-id <your-client-id> \
  --client-secret <your-client-secret> \
  -e Production \
  --publish-exchange
```

### Step 3: Configure Secure Properties

**In Anypoint Platform Runtime Manager**:
1. Go to **Runtime Manager** → **Applications** → **employee-onboarding-system**
2. Go to **Properties** tab
3. Add these **Secure Properties**:

```properties
secure::email.smtp.user=your-email@gmail.com
secure::email.smtp.password=your-app-password
secure::groq.apiKey=gsk_your-groq-api-key
```

### Step 4: Publish Agent Network Asset to Exchange

```bash
# Publish to Exchange for Agent Network integration
mvn clean deploy \
  -DclientId=<your-client-id> \
  -DclientSecret=<your-client-secret> \
  -DaltDeploymentRepository=anypoint-exchange-v3::default::https://maven.anypoint.mulesoft.com/api/v3/maven
```

## 🌐 CloudHub Application URLs

After deployment, your application will be available at:

### Sandbox Environment:
```
Base URL: https://employee-onboarding-system.us-e2.cloudhub.io

API Endpoints:
├── Health Check: /health
├── Complete Onboarding: /onboardEmployee
├── Get Status: /getOnboardingStatus/{employeeId}
├── Initialize Database: /initializeDatabase
│
├── Employee Service (Port 8082 routes):
│   ├── POST /createEmployee
│   ├── GET /getEmployee/{employeeId}
│   ├── GET /listEmployees
│   └── POST /updateTask
│
├── Asset Service (Port 8083 routes):
│   ├── POST /initializeAssets
│   ├── POST /allocateAssets
│   ├── GET /getInventory
│   ├── GET /getEmployeeAssets/{employeeId}
│   └── POST /returnAsset
│
└── Email Service (Port 8084 routes):
    ├── POST /sendWelcomeEmail
    ├── POST /sendAssetAllocationEmail
    ├── POST /sendCompletionEmail
    └── GET /getEmailLogs
```

### Production Environment:
```
Base URL: https://employee-onboarding-system.us-e1.cloudhub.io
(Same endpoints as Sandbox)
```

## 🧪 Test Your Deployment

### 1. Test Health Check
```bash
curl https://employee-onboarding-system.us-e2.cloudhub.io/health
```

### 2. Test Complete Workflow
```bash
curl -X POST https://employee-onboarding-system.us-e2.cloudhub.io/onboardEmployee \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@company.com",
    "department": "Engineering",
    "position": "Software Engineer",
    "startDate": "2024-02-20",
    "requestedAssets": ["laptop", "id_card", "phone"]
  }'
```

### 3. Run Comprehensive Test Suite

**For Windows Users:**
```batch
# Test deployed application
scripts\test.bat -u https://employee-onboarding-system.us-e2.cloudhub.io

# Test with custom email
scripts\test.bat -u https://employee-onboarding-system.us-e2.cloudhub.io -e your-test@email.com
```

**For Linux/Mac Users:**
```bash
# Test deployed application
./scripts/test.sh -u https://employee-onboarding-system.us-e2.cloudhub.io

# Test with custom email
./scripts/test.sh -u https://employee-onboarding-system.us-e2.cloudhub.io -e your-test@email.com
```

## 📋 Agent Network Configuration

Your `agent-network.yaml` is configured for CloudHub deployment. The MCP servers will be accessible at:

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

## 🔐 Security Setup Checklist

### Required Secure Properties:
- ✅ `secure::email.smtp.user` - Gmail account for sending emails
- ✅ `secure::email.smtp.password` - Gmail App Password (not regular password)
- ✅ `secure::groq.apiKey` - Groq API key for Agent Network

### Gmail App Password Setup:
1. Enable 2-Factor Authentication in Gmail
2. Go to **Google Account** → **Security** → **App passwords**
3. Generate app password for "Mail"
4. Use this password in `secure::email.smtp.password`

### Groq API Key Setup:
1. Go to https://console.groq.com
2. Sign up for a free account (free tier includes generous limits)
3. Navigate to **API Keys** section
4. Create new API key
5. Use this key in `secure::groq.apiKey` (format: `gsk_...`)

### Groq Benefits:
- ⚡ **Ultra-fast inference** (10x faster than competitors)
- 💰 **Cost-effective** (significantly cheaper than OpenAI)
- 🔄 **OpenAI-compatible API** (easy migration)
- 🧠 **High-quality models** (Llama 3.1 70B Versatile)

## 📊 Monitoring Your Application

### CloudHub Runtime Manager:
- **Application Status**: Monitor application health
- **Logs**: View real-time application logs
- **Alerts**: Set up monitoring alerts
- **Performance**: Monitor CPU, memory usage

### Application Endpoints:
- **Health Check**: `GET /health` - Returns application status
- **Logs**: Available in Runtime Manager dashboard

## 🔄 Updating Your Application

### Deploy New Version:
```bash
# Build and deploy updated version
./scripts/deploy.sh \
  --client-id <client-id> \
  --client-secret <client-secret> \
  -e Production \
  -a employee-onboarding-system
```

### Update Agent Network Asset:
```bash
# Update version in exchange.json and redeploy
mvn clean deploy \
  -DclientId=<client-id> \
  -DclientSecret=<client-secret>
```

## 🎯 Agent Network Integration in Salesforce

### 1. Access Agent Network Assets
1. Login to **Anypoint Platform**
2. Go to **Anypoint Exchange**
3. Search for "EmployeeOnboardingAgentFabric"
4. Your asset should be available for Agent Network integration

### 2. Import in Salesforce Agentforce
1. Go to **Salesforce Setup** → **Agent Network**
2. **Import Asset** from Anypoint Exchange
3. Configure the HR onboarding broker
4. Test agent capabilities

### 3. Available Skills in Agentforce:
- **Employee Onboarding**: Complete end-to-end onboarding process
- **Asset Management**: Allocate and track company assets
- **Email Notifications**: Send automated communications

## 🚨 Troubleshooting

### Common Issues:

#### 1. Deployment Fails
```bash
# Check credentials
./scripts/deploy.sh --help

# Verify Connected App permissions
# Ensure all required scopes are granted
```

#### 2. Email Not Working
- Verify Gmail App Password is correct
- Check secure properties are set in Runtime Manager
- Ensure 2FA is enabled in Gmail account

#### 3. Application Not Starting
- Check application logs in Runtime Manager
- Verify H2 database configuration
- Check for dependency conflicts

#### 4. Agent Network Not Working
- Verify asset is published to Exchange
- Check Groq API key is valid and has sufficient credits
- Ensure agent-network.yaml URLs are correct
- Verify Groq API endpoint is accessible

#### 5. Groq API Issues
- Check API key format (should start with `gsk_`)
- Verify account has sufficient credits
- Check rate limits (Groq has generous free tier)
- Ensure model name is correct: `llama-3.1-70b-versatile`

## 🤖 NLP Testing Guide with Groq

### Natural Language Processing Testing

Once your application is deployed, you can test the NLP capabilities powered by Groq's Llama 3.1 70B model through various natural language interactions:

#### 1. Employee Onboarding NLP Tests

**Test with natural language requests:**

```bash
# Test 1: Simple onboarding request
curl -X POST https://employee-onboarding-system.us-e2.cloudhub.io/nlp/onboard \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Please onboard Sarah Johnson as a Software Engineer in the Engineering department starting March 1st, 2024. She needs a laptop, ID card, and phone."
  }'

# Test 2: Complex onboarding with specific requirements
curl -X POST https://employee-onboarding-system.us-e2.cloudhub.io/nlp/onboard \
  -H "Content-Type: application/json" \
  -d '{
    "message": "I need to onboard a new Marketing Specialist named Michael Chen. He starts on February 25th and will report to Sarah Wilson (EMP002). Please allocate him a MacBook, wireless mouse, external monitor, and access card."
  }'

# Test 3: Casual conversational request
curl -X POST https://employee-onboarding-system.us-e2.cloudhub.io/nlp/onboard \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hey, can you help me set up Lisa Rodriguez? She is joining our Finance team next week as an analyst. Get her the standard equipment package please."
  }'
```

#### 2. Asset Management NLP Tests

```bash
# Test 1: Check asset availability
curl -X POST https://employee-onboarding-system.us-e2.cloudhub.io/nlp/assets \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What laptops do we have available? I need to see the inventory."
  }'

# Test 2: Specific asset allocation
curl -X POST https://employee-onboarding-system.us-e2.cloudhub.io/nlp/assets \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Assign a Dell laptop and Samsung monitor to employee EMP003. Also give them a wireless keyboard."
  }'

# Test 3: Asset return request
curl -X POST https://employee-onboarding-system.us-e2.cloudhub.io/nlp/assets \
  -H "Content-Type: application/json" \
  -d '{
    "message": "John Doe from Engineering is leaving the company. We need to collect all his equipment including laptop LAP002 and phone PHN001."
  }'
```

#### 3. Email Notification NLP Tests

```bash
# Test 1: Send welcome email with natural language
curl -X POST https://employee-onboarding-system.us-e2.cloudhub.io/nlp/email \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Send a warm welcome email to alice.smith@company.com. She is joining the HR department as an HR Coordinator."
  }'

# Test 2: Asset allocation notification
curl -X POST https://employee-onboarding-system.us-e2.cloudhub.io/nlp/email \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Notify bob.wilson@company.com that his laptop, phone, and ID card are ready for pickup. Include the asset details."
  }'
```

#### 4. Status and Query NLP Tests

```bash
# Test 1: Check employee status with natural language
curl -X POST https://employee-onboarding-system.us-e2.cloudhub.io/nlp/status \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What is the onboarding status of John Smith? Has he completed all his tasks?"
  }'

# Test 2: Complex status inquiry
curl -X POST https://employee-onboarding-system.us-e2.cloudhub.io/nlp/status \
  -H "Content-Type: application/json" \
  -d '{
    "message": "I need a report on all new employees who started this month. Show me their onboarding progress and any pending items."
  }'

# Test 3: Department-wide inquiry
curl -X POST https://employee-onboarding-system.us-e2.cloudhub.io/nlp/status \
  -H "Content-Type: application/json" \
  -d '{
    "message": "How many people are currently being onboarded in the Engineering department? Are there any bottlenecks?"
  }'
```

#### 5. Advanced NLP Conversation Tests

```bash
# Test 1: Multi-step conversation
curl -X POST https://employee-onboarding-system.us-e2.cloudhub.io/nlp/conversation \
  -H "Content-Type: application/json" \
  -d '{
    "message": "I need help with onboarding. We have 3 new hires starting next week.",
    "conversationId": "conv_001"
  }'

# Follow-up message
curl -X POST https://employee-onboarding-system.us-e2.cloudhub.io/nlp/conversation \
  -H "Content-Type: application/json" \
  -d '{
    "message": "They are all for the Sales department: Tom, Jerry, and Mickey. Tom is a Senior Sales Rep, Jerry is a Sales Coordinator, and Mickey is a Sales Analyst.",
    "conversationId": "conv_001"
  }'

# Test 2: Clarification and context
curl -X POST https://employee-onboarding-system.us-e2.cloudhub.io/nlp/conversation \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Can you handle urgent onboarding? We have someone starting tomorrow.",
    "conversationId": "conv_002"
  }'
```

#### 6. Error Handling and Edge Cases

```bash
# Test 1: Incomplete information
curl -X POST https://employee-onboarding-system.us-e2.cloudhub.io/nlp/onboard \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Please onboard someone new."
  }'

# Test 2: Conflicting requirements
curl -X POST https://employee-onboarding-system.us-e2.cloudhub.io/nlp/assets \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Allocate laptop LAP001 to both John and Mary at the same time."
  }'

# Test 3: Invalid employee reference
curl -X POST https://employee-onboarding-system.us-e2.cloudhub.io/nlp/status \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What is the status of employee EMPXYZ999?"
  }'
```

### Expected NLP Responses

The Groq-powered system should provide:

1. **Intelligent Parsing**: Extract entities like names, departments, dates, and asset types
2. **Context Understanding**: Maintain conversation context across multiple messages
3. **Professional Responses**: Generate appropriate business communication
4. **Error Handling**: Gracefully handle incomplete or conflicting information
5. **Confirmation**: Ask for clarification when needed

### Sample Expected Response:

```json
{
  "success": true,
  "message": "I'll help you onboard Sarah Johnson as a Software Engineer in Engineering, starting March 1st, 2024.",
  "extractedData": {
    "firstName": "Sarah",
    "lastName": "Johnson",
    "position": "Software Engineer",
    "department": "Engineering",
    "startDate": "2024-03-01",
    "requestedAssets": ["laptop", "id_card", "phone"]
  },
  "actions": [
    "Creating employee profile",
    "Allocating requested assets",
    "Sending welcome email",
    "Scheduling orientation"
  ],
  "nextSteps": "Employee profile will be created and welcome email sent. Please provide her email address for notifications.",
  "conversationId": "conv_12345"
}
```

### Performance Metrics to Monitor:

- **Response Time**: Groq typically responds in <1 second
- **Accuracy**: Entity extraction accuracy should be >95%
- **Context Retention**: Multi-turn conversations should maintain context
- **Error Rate**: System should gracefully handle edge cases

### Support Resources:
- **MuleSoft Documentation**: https://docs.mulesoft.com/
- **CloudHub Support**: https://help.mulesoft.com/
- **Agent Network Guide**: https://docs.mulesoft.com/agent-network/
- **Groq Documentation**: https://console.groq.com/docs
- **Groq Community**: https://groq.com/community/

## ✅ Deployment Success Checklist

- ✅ Connected App created with proper scopes
- ✅ Application deployed to CloudHub successfully
- ✅ Health check endpoint responding (200 OK)
- ✅ Secure properties configured in Runtime Manager
- ✅ Email functionality tested
- ✅ Agent Network asset published to Exchange
- ✅ All API endpoints accessible via HTTPS
- ✅ Complete onboarding workflow tested
- ✅ Application logs showing no errors
- ✅ Groq API integration verified
- ✅ NLP endpoints responding correctly
- ✅ Natural language processing tests passing
- ✅ Conversation context maintained properly

---

**🎉 Congratulations! Your Employee Onboarding System with Groq-powered NLP is now live on CloudHub and ready for Agent Network integration with Salesforce Agentforce! 🎉**
