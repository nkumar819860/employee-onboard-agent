# Employee Onboarding System - MuleSoft MCP Implementation

A comprehensive employee onboarding system built with MuleSoft that demonstrates the power of Model Context Protocol (MCP) servers for orchestrating complex business processes.

## 🚀 Overview

This system provides end-to-end employee onboarding automation through three dedicated MCP servers:

1. **Employee Onboarding MCP Server** (Port 8082) - Manages employee profiles and onboarding tasks
2. **Asset Allocation MCP Server** (Port 8083) - Handles company asset inventory and allocation
3. **Email Notification MCP Server** (Port 8084) - Sends automated email communications
4. **Main Orchestration Service** (Port 8080) - Coordinates all services for complete workflow

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                Agent Network (Port 8080)                │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │  Employee   │  │   Asset     │  │   Email     │     │
│  │ Onboarding  │  │ Allocation  │  │Notification │     │
│  │    MCP      │  │    MCP      │  │    MCP      │     │
│  │  (8082)     │  │  (8083)     │  │  (8084)     │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              H2 Database                        │   │
│  │        (In-Memory Storage)                      │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## 🛠️ Technology Stack

- **MuleSoft Runtime**: 4.8.0
- **MCP Connector**: 1.3.0
- **Database**: H2 In-Memory Database
- **Email**: SMTP Integration
- **Agent Network**: Configured for Agentforce integration

## 📋 Features

### Employee Onboarding MCP Server
- ✅ Create employee profiles
- ✅ Get employee information
- ✅ Update onboarding tasks
- ✅ List employees by department/status
- ✅ Track onboarding progress

### Asset Allocation MCP Server
- ✅ Initialize asset inventory
- ✅ Allocate assets to employees
- ✅ Track asset status and availability
- ✅ Return assets to inventory
- ✅ Generate allocation reports

### Email Notification MCP Server
- ✅ Send welcome emails
- ✅ Asset allocation notifications
- ✅ Onboarding completion emails
- ✅ Email logging and tracking

### Main Orchestration
- ✅ Complete end-to-end onboarding workflow
- ✅ Database initialization
- ✅ Health monitoring
- ✅ Status tracking

## 🚀 Quick Start

### Prerequisites

- MuleSoft Anypoint Studio or Mule Runtime 4.8.0+
- Java 8 or 11
- Maven 3.6+

### 1. Clone and Setup

```bash
git clone <repository-url>
cd employeeonboardingagentfabric
```

### 2. Configure Properties

Update `src/main/resources/application.properties`:

```properties
# Email Configuration (Required for email notifications)
email.smtp.host=smtp.gmail.com
email.smtp.port=587
email.smtp.user=your-email@gmail.com
email.smtp.password=your-app-password
```

### 3. Build the Application

```bash
mvn clean package
```

### 4. Deploy

**Local Deployment:**
```bash
mvn mule:deploy
```

**CloudHub 2.0 Deployment:**
```bash
mvn clean package mule:deploy -DmuleDeploy \
  -Dusername=<anypoint-username> \
  -Dpassword=<anypoint-password> \
  -DapplicationName=employee-onboarding-system \
  -Denvironment=Sandbox \
  -DworkerType=MICRO \
  -Dworkers=1
```

## 📖 API Documentation

### Main Orchestration Endpoints (Port 8080)

#### Complete Employee Onboarding
```http
POST http://localhost:8080/onboardEmployee
Content-Type: application/json

{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@company.com",
  "department": "Engineering",
  "position": "Software Engineer",
  "startDate": "2024-02-20",
  "requestedAssets": ["laptop", "id_card", "phone"]
}
```

#### Get Onboarding Status
```http
GET http://localhost:8080/getOnboardingStatus/{employeeId}
```

#### Initialize Database
```http
POST http://localhost:8080/initializeDatabase
```

#### Health Check
```http
GET http://localhost:8080/health
```

### Employee Onboarding MCP Server (Port 8082)

#### Create Employee Profile
```http
POST http://localhost:8082/createEmployee
Content-Type: application/json

{
  "employeeId": "EMP12345",
  "firstName": "Jane",
  "lastName": "Smith",
  "email": "jane.smith@company.com",
  "department": "HR",
  "position": "HR Manager",
  "startDate": "2024-02-20"
}
```

#### Get Employee
```http
GET http://localhost:8082/getEmployee/{employeeId}
```

#### List Employees
```http
GET http://localhost:8082/listEmployees
```

### Asset Allocation MCP Server (Port 8083)

#### Initialize Assets
```http
POST http://localhost:8083/initializeAssets
```

#### Allocate Assets
```http
POST http://localhost:8083/allocateAssets
Content-Type: application/json

{
  "employeeId": "EMP12345",
  "assetTypes": ["laptop", "id_card", "phone"]
}
```

#### Get Inventory
```http
GET http://localhost:8083/getInventory
```

### Email Notification MCP Server (Port 8084)

#### Send Welcome Email
```http
POST http://localhost:8084/sendWelcomeEmail
Content-Type: application/json

{
  "employeeId": "EMP12345",
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@company.com",
  "department": "Engineering"
}
```

## 🧪 Testing the Complete Workflow

### 1. Initialize the System
```bash
curl -X POST http://localhost:8080/initializeDatabase
```

### 2. Onboard a New Employee
```bash
curl -X POST http://localhost:8080/onboardEmployee \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Alice",
    "lastName": "Johnson",
    "email": "alice.johnson@company.com",
    "department": "Marketing",
    "position": "Marketing Manager",
    "startDate": "2024-02-20",
    "requestedAssets": ["laptop", "id_card", "phone"]
  }'
```

### 3. Check Status
```bash
curl http://localhost:8080/getOnboardingStatus/{employeeId}
```

## 🌐 Cloud Deployment

### Anypoint Platform Deployment

1. **Create Application in Anypoint Platform**
   - Login to Anypoint Platform
   - Navigate to Runtime Manager
   - Create new application

2. **Deploy using Maven**
   ```bash
   mvn clean package mule:deploy -DmuleDeploy \
     -Dusername=<username> \
     -Dpassword=<password> \
     -DapplicationName=employee-onboarding \
     -Denvironment=Production \
     -DworkerType=SMALL \
     -Dworkers=1
   ```

3. **Configure Properties**
   - Set email SMTP credentials in secure properties
   - Configure database connection if using external DB

### Agent Network Integration

The system is configured for integration with MuleSoft's Agent Network:

```yaml
# agent-network.yaml configuration is included
# Provides HR onboarding capabilities through MCP servers
```

## 🔒 Security Considerations

- Email credentials should be stored as secure properties
- Database connections should use encrypted passwords
- API endpoints should be secured with appropriate authentication
- Consider implementing rate limiting for production use

## 📊 Monitoring and Logging

### Health Checks
- Main orchestration health: `GET /health`
- Database connectivity monitoring
- Email service status tracking

### Logging
- All operations are logged with correlation IDs
- Email sending activities are tracked in database
- Asset allocation history is maintained

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Check the MuleSoft documentation
- Review the MCP connector documentation

## 🎯 Future Enhancements

- [ ] Integration with Salesforce for employee data sync
- [ ] Advanced workflow automation
- [ ] Mobile app integration
- [ ] Analytics and reporting dashboard
- [ ] Multi-language support for email templates
- [ ] Advanced asset tracking with IoT integration

---

**Built with ❤️ using MuleSoft and MCP**
