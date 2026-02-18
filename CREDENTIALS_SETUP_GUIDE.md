# 🔐 Credentials Setup Guide for CloudHub Deployment

## Overview
This guide explains where to configure all necessary credentials for deploying the Employee Onboarding System to CloudHub with Groq AI integration.

---

## 1. 🏢 Anypoint Platform - Connected App Setup

### Where to Configure: Anypoint Platform Web Console

#### Step 1: Create Connected App
1. **Login** to Anypoint Platform: https://anypoint.mulesoft.com
2. **Navigate** to: Access Management → Connected Apps
3. **Click**: "Create Connected App"
4. **Fill Details**:
   ```
   Name: Employee-Onboarding-Deployment-App
   Description: Connected app for employee onboarding system deployment
   Type: App acts on its own behalf (Client Credentials)
   ```

#### Step 2: Grant Required Scopes
Select these scopes:
```
✅ Design Center Developer
✅ Exchange Contributor  
✅ Runtime Manager Deploy
✅ Runtime Manager Read Applications
✅ CloudHub Organization Admin (if available)
✅ CloudHub Network Administrator (if available)
```

#### Step 3: Save Credentials
**IMPORTANT**: Copy and save these immediately:
```
Client ID: <copy-this-value>
Client Secret: <copy-this-value>
```

---

## 2. 🤖 Groq API Key Setup

### Where to Configure: Groq Console

#### Step 1: Create Groq Account
1. **Visit**: https://console.groq.com
2. **Sign Up**: Create free account (no credit card required)
3. **Verify Email**: Complete email verification

#### Step 2: Generate API Key
1. **Navigate** to: API Keys section
2. **Click**: "Create API Key"
3. **Name**: Employee-Onboarding-System
4. **Copy API Key**: Format will be `gsk_...`

#### Example API Key Format:
```
gsk_1234567890abcdef1234567890abcdef1234567890abcdef12
```

---

## 3. 📧 Gmail App Password Setup

### Where to Configure: Google Account Settings

#### Step 1: Enable 2FA (Required)
1. **Go to**: Google Account → Security
2. **Enable**: 2-Step Verification
3. **Complete**: Phone verification

#### Step 2: Generate App Password
1. **Navigate**: Security → App passwords
2. **Select App**: Mail
3. **Generate**: App-specific password
4. **Copy Password**: 16-character password (no spaces)

#### Example App Password Format:
```
abcdEFGHijklMNOP
```

---

## 4. 💻 Local Development Configuration

### Where to Configure: Local Environment Variables

#### Option A: Environment Variables (Recommended)
Create a `.env` file in project root:
```bash
# .env file (DO NOT commit to Git)
ANYPOINT_CLIENT_ID=your-client-id-here
ANYPOINT_CLIENT_SECRET=your-client-secret-here
GROQ_API_KEY=gsk_your-groq-api-key-here
GMAIL_USER=your-email@gmail.com
GMAIL_PASSWORD=your-app-password-here
```

#### Option B: Maven Settings.xml
Add to `~/.m2/settings.xml`:
```xml
<settings>
    <servers>
        <server>
            <id>anypoint-exchange-v3</id>
            <username>${env.ANYPOINT_CLIENT_ID}</username>
            <password>${env.ANYPOINT_CLIENT_SECRET}</password>
        </server>
    </servers>
    <profiles>
        <profile>
            <id>mule-deployment</id>
            <properties>
                <anypoint.client.id>${env.ANYPOINT_CLIENT_ID}</anypoint.client.id>
                <anypoint.client.secret>${env.ANYPOINT_CLIENT_SECRET}</anypoint.client.secret>
                <groq.api.key>${env.GROQ_API_KEY}</groq.api.key>
                <email.smtp.user>${env.GMAIL_USER}</email.smtp.user>
                <email.smtp.password>${env.GMAIL_PASSWORD}</email.smtp.password>
            </properties>
        </profile>
    </profiles>
</settings>
```

---

## 5. ☁️ CloudHub Runtime Manager - Secure Properties

### Where to Configure: CloudHub Runtime Manager Console

#### After Deployment, Configure Secure Properties:

1. **Login** to Anypoint Platform
2. **Navigate**: Runtime Manager → Applications
3. **Select**: employee-onboarding-system
4. **Go to**: Properties tab
5. **Add Secure Properties**:

```properties
# Email Configuration
secure::email.smtp.user=your-email@gmail.com
secure::email.smtp.password=abcdEFGHijklMNOP

# Groq AI Configuration  
secure::groq.apiKey=gsk_1234567890abcdef1234567890abcdef1234567890abcdef12
```

#### Screenshot Guide:
```
Runtime Manager → Applications → [Your App] → Properties
┌─────────────────────────────────────────────┐
│ ✅ Secure Properties                        │
│                                             │
│ Key: secure::email.smtp.user               │
│ Value: your-email@gmail.com                │
│ [Add Property]                             │
│                                             │
│ Key: secure::email.smtp.password           │
│ Value: ••••••••••••••••                   │
│ [Add Property]                             │
│                                             │
│ Key: secure::groq.apiKey                   │
│ Value: ••••••••••••••••••••••••••••       │
│ [Add Property]                             │
└─────────────────────────────────────────────┘
```

---

## 6. 🚀 Deployment Script Configuration

### Where to Configure: Command Line Parameters

#### Windows Deployment:
```batch
# Method 1: Direct parameters
scripts\deploy.bat --client-id your-client-id --client-secret your-client-secret -e Sandbox -a employee-onboarding-system

# Method 2: Using environment variables
set ANYPOINT_CLIENT_ID=your-client-id
set ANYPOINT_CLIENT_SECRET=your-client-secret
scripts\deploy.bat -e Production -a employee-onboarding-system
```

#### Linux/Mac Deployment:
```bash
# Method 1: Direct parameters
./scripts/deploy.sh \
  --client-id your-client-id \
  --client-secret your-client-secret \
  -e Sandbox \
  -a employee-onboarding-system

# Method 2: Using environment variables
export ANYPOINT_CLIENT_ID="your-client-id"
export ANYPOINT_CLIENT_SECRET="your-client-secret"
./scripts/deploy.sh -e Production -a employee-onboarding-system
```

---

## 7. 📄 Configuration Files Reference

### Project Configuration Files:

#### A. `src/main/resources/application.properties` (Development)
```properties
# Development Environment Configuration
app.environment=dev

# Groq Configuration (Development)
groq.apiKey=${secure::groq.apiKey}
groq.model=llama-3.1-70b-versatile
groq.timeout=60000

# Email Configuration (Development)
email.smtp.user=${secure::email.smtp.user}
email.smtp.password=${secure::email.smtp.password}
```

#### B. `src/main/resources/cloudhub.properties` (Production)
```properties
# CloudHub Environment Configuration
app.environment=cloudhub

# Groq Configuration (CloudHub)
groq.apiKey=${secure::groq.apiKey}
groq.model=llama-3.1-70b-versatile
groq.timeout=60000

# Email Configuration (CloudHub)
email.smtp.user=${secure::email.smtp.user}
email.smtp.password=${secure::email.smtp.password}
```

#### C. `agent-network.yaml` (Agent Network Configuration)
```yaml
llmProviders:
  groq:
    label: Groq
    description: Groq LLM Provider for Agent Network
    metadata:
      platform: OpenAI

connections:
  groq-connection:
    kind: llm
    ref:
      name: groq
    spec:
      url: https://api.groq.com/openai/v1/
      configuration:
        apiKey: ${groq.apiKey}  # References secure property
        timeout: 600000
```

---

## 8. 🔒 Security Best Practices

### DO's:
- ✅ Use secure properties in CloudHub Runtime Manager
- ✅ Store credentials in environment variables locally
- ✅ Use Connected Apps instead of username/password
- ✅ Enable 2FA on all accounts
- ✅ Rotate API keys regularly
- ✅ Use different credentials for dev/prod environments

### DON'Ts:
- ❌ Never commit credentials to Git
- ❌ Don't store credentials in plain text files
- ❌ Don't share API keys in documentation
- ❌ Don't use production credentials in development
- ❌ Don't reuse passwords across systems

---

## 9. 🧪 Testing Credentials

### Test Anypoint Platform Connection:
```bash
# Test with curl
curl -X POST "https://anypoint.mulesoft.com/accounts/api/v2/oauth2/token" \
  -H "Content-Type: application/json" \
  -d '{
    "client_id": "your-client-id",
    "client_secret": "your-client-secret", 
    "grant_type": "client_credentials"
  }'
```

### Test Groq API Connection:
```bash
# Test with curl
curl -X POST "https://api.groq.com/openai/v1/chat/completions" \
  -H "Authorization: Bearer gsk_your-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Hello"}],
    "model": "llama-3.1-70b-versatile",
    "max_tokens": 100
  }'
```

### Test Email Configuration:
After deployment, test via:
```bash
curl -X POST "https://your-app.cloudhub.io/health"
```

---

## 10. 🆘 Troubleshooting

### Common Issues:

#### Invalid Client Credentials
**Error**: `401 Unauthorized`
**Solution**: 
1. Verify Client ID and Secret are correct
2. Check Connected App scopes
3. Ensure app is not disabled

#### Invalid Groq API Key
**Error**: `Authentication failed`
**Solution**:
1. Verify API key format starts with `gsk_`
2. Check account has sufficient credits
3. Regenerate API key if needed

#### Email Authentication Failed
**Error**: `Authentication failed`
**Solution**:
1. Verify 2FA is enabled
2. Generate new App Password
3. Check email address is correct

#### Secure Properties Not Loading
**Error**: Property not resolved
**Solution**:
1. Ensure secure properties are set in Runtime Manager
2. Verify property names match exactly
3. Restart application after adding properties

---

## 📋 Quick Reference Checklist

### Before Deployment:
- [ ] Connected App created with proper scopes
- [ ] Client ID and Secret saved securely
- [ ] Groq API key generated and tested
- [ ] Gmail App Password generated
- [ ] Environment variables configured locally
- [ ] Deployment script parameters ready

### After Deployment:
- [ ] Secure properties configured in Runtime Manager
- [ ] Application started successfully
- [ ] Health endpoint responding
- [ ] Email functionality tested
- [ ] Groq AI integration tested
- [ ] All APIs accessible

---

## 📞 Support Resources

### Documentation:
- **Anypoint Platform**: https://docs.mulesoft.com/access-management/connected-apps
- **CloudHub Deployment**: https://docs.mulesoft.com/runtime-manager/deploying-to-cloudhub
- **Groq API**: https://console.groq.com/docs
- **Gmail App Passwords**: https://support.google.com/accounts/answer/185833

### Contact Support:
- **MuleSoft Support**: https://help.mulesoft.com/
- **Groq Support**: https://groq.com/contact/
- **Project Support**: Check README.md for project-specific contact info

---

**⚠️ IMPORTANT**: Keep all credentials secure and never commit them to version control!
