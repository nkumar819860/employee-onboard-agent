# NLP Testing Guide for Employee Onboarding Agent Fabric

## 🧠 Natural Language Processing Testing

Your Employee Onboarding Agent Fabric has been successfully published to Anypoint Exchange and is ready for NLP testing in Agentforce. This guide provides comprehensive testing scenarios and queries.

## 📋 Prerequisites

1. ✅ Agent Network published to Exchange: `EmployeeOnboardingAgentFabric v1.0.0`
2. ✅ Exchange.json configured with proper variables
3. 🔄 Mule applications (may need manual deployment via Runtime Manager)
4. 🎯 Salesforce org with Agentforce enabled

## 🎯 Setup for Testing

### Step 1: Import Agent Network to Salesforce
1. Go to Salesforce Setup → Agentforce → Agent Networks
2. Import from Anypoint Exchange:
   - **Group ID**: `47562e5d-bf49-440a-a0f5-a9cea0a89aa9`
   - **Asset ID**: `employeeonboardingagentfabric`
   - **Version**: `1.0.0`

### Step 2: Configure Variables
Set these variables in your Agent Network configuration:
```yaml
hrAgent.url: https://employee-onboarding-system-main.us-east-2.cloudhub.io
employeeOnboarding.url: https://employee-onboarding-system-employee.us-east-2.cloudhub.io
assetAllocation.url: https://employee-onboarding-system-assets.us-east-2.cloudhub.io
emailNotification.url: https://employee-onboarding-system-email.us-east-2.cloudhub.io
groq.apiKey: [YOUR_GROQ_API_KEY]
```

## 🗣️ NLP Test Queries

### Basic Employee Onboarding Tests

#### Test 1: Complete Employee Onboarding
```
"Please onboard a new employee named John Smith in the Engineering department. He needs a laptop, phone, and ID card. Send him a welcome email with onboarding details."
```

**Expected Response**: The agent should:
- Create employee profile for John Smith
- Allocate requested assets (laptop, phone, ID card)
- Send welcome email
- Provide onboarding completion status

#### Test 2: Department-Specific Onboarding
```
"We have a new Marketing Manager, Sarah Johnson, starting next Monday. She'll need marketing materials, a company phone, and access to our creative software. Please set up her onboarding process."
```

#### Test 3: Remote Employee Onboarding
```
"Onboard Michael Chen as a remote Software Developer. He needs a laptop to be shipped to his home address, VPN access setup, and welcome documentation emailed to him."
```

### Asset Management Tests

#### Test 4: Asset Inquiry
```
"What assets are available for allocation? Show me the current inventory status."
```

#### Test 5: Specific Asset Request
```
"Allocate a MacBook Pro and iPhone 15 to employee ID EMP12345. Update their asset assignment record."
```

#### Test 6: Asset Return Processing
```
"Process asset return for departing employee Lisa Wang. She's returning a laptop, monitor, and access card."
```

### Email Notification Tests

#### Test 7: Welcome Email
```
"Send a personalized welcome email to our new hire David Rodriguez in the Sales team. Include his start date, reporting manager, and first-day instructions."
```

#### Test 8: Asset Notification
```
"Notify employee about their allocated equipment: laptop serial ABC123, phone number +1-555-0199, and ID card number ID789."
```

### Complex Workflow Tests

#### Test 9: Bulk Onboarding
```
"We're onboarding 5 new interns for the summer program. They all need basic equipment packages and orientation emails. Their names are: Alex Kim, Maria Santos, James Wilson, Emma Thompson, and Ryan Lee."
```

#### Test 10: Role-Specific Onboarding
```
"Onboard a new Security Specialist, Rachel Moore. She needs enhanced security clearance, specialized security tools, encrypted laptop, and security protocol documentation."
```

### Error Handling Tests

#### Test 11: Insufficient Information
```
"Onboard a new employee in the IT department."
```
**Expected**: Agent should ask for missing required information (name, specific role, etc.)

#### Test 12: Invalid Asset Request
```
"Allocate a helicopter to John Smith."
```
**Expected**: Agent should respond with available asset options

## 🔍 Validation Points

For each test, verify:

### ✅ Response Quality
- [ ] Natural language understanding is accurate
- [ ] Response is contextually appropriate
- [ ] Professional and helpful tone
- [ ] Complete information provided

### ✅ Workflow Execution
- [ ] Correct services are invoked
- [ ] Data flows properly between services
- [ ] Error handling is graceful
- [ ] Status updates are provided

### ✅ Integration Points
- [ ] Employee profile creation works
- [ ] Asset allocation functions properly
- [ ] Email notifications are sent
- [ ] Database updates are successful

## 📊 Performance Metrics

Monitor these metrics during testing:

### Response Time
- **Target**: < 5 seconds for simple queries
- **Target**: < 15 seconds for complex workflows

### Success Rate
- **Target**: > 90% successful query resolution
- **Target**: < 5% error rate

### User Experience
- **Clarity**: Responses are clear and actionable
- **Completeness**: All requested actions are addressed
- **Accuracy**: Information provided is correct

## 🐛 Troubleshooting Common Issues

### Issue 1: Agent Not Responding
**Cause**: Agent Network not properly imported
**Solution**: Re-import from Exchange, verify all URLs

### Issue 2: Partial Workflow Execution
**Cause**: One or more MCP servers unavailable
**Solution**: Check CloudHub application status in Runtime Manager

### Issue 3: No Email Notifications
**Cause**: Email service configuration issues
**Solution**: Verify SMTP settings and credentials

### Issue 4: Asset Allocation Failures
**Cause**: Database connectivity issues
**Solution**: Check H2 database configuration and initialization

## 🎯 Advanced Testing Scenarios

### Scenario A: Peak Load Testing
Test with multiple simultaneous onboarding requests:
```
"Process urgent onboarding for 3 new hires starting tomorrow: 
- Tech Lead: Innovation Department
- Project Manager: Operations  
- Business Analyst: Finance"
```

### Scenario B: Multi-Language Testing
```
"Por favor, incorpora a un nuevo empleado llamado Carlos García en el departamento de Ventas."
```

### Scenario C: Integration Testing
```
"Create a complete onboarding workflow for Senior Developer Anna Kowalski, including Salesforce user setup, Slack channel addition, and calendar scheduling for her first week."
```

## 📝 Test Results Template

Use this template to document your testing results:

```
Test ID: [Test Number]
Query: [NLP Query Used]
Expected Result: [What should happen]
Actual Result: [What actually happened]
Status: [PASS/FAIL/PARTIAL]
Notes: [Additional observations]
Timestamp: [When tested]
```

## 🚀 Next Steps After Testing

1. **Document Issues**: Report any failures or unexpected behavior
2. **Performance Tuning**: Optimize based on response times
3. **User Training**: Create user guides based on successful patterns
4. **Production Deployment**: Move to production environment after validation
5. **Monitoring Setup**: Implement ongoing monitoring and alerts

## 🎉 Success Indicators

Your Agent Fabric is working correctly when:
- ✅ All basic onboarding queries work smoothly
- ✅ Asset management integrates properly
- ✅ Email notifications are sent reliably
- ✅ Complex multi-step workflows complete successfully
- ✅ Error handling provides helpful guidance
- ✅ Response times meet performance targets

Happy testing! 🚀
