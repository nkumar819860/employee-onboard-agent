# React MCP Client - Employee Onboarding System

A modern React-based MCP (Model Context Protocol) client that replaces Python testing files with an interactive web interface for employee onboarding workflows.

## 🚀 Overview

This React application provides a user-friendly interface for testing and interacting with MCP agents instead of using Python files. It includes:

- **Natural Language Processing**: Extract employee information from conversational input
- **MCP Integration**: Communicate with multiple MCP services (PostgreSQL, Assets, Notifications)
- **Real-time UI**: Interactive workflow visualization with progress indicators
- **Dashboard**: View onboarded employees and allocated assets
- **TypeScript**: Full type safety and modern development experience

## 📁 Project Structure

```
react-mcp-client/
├── public/
│   └── index.html              # HTML template with Bootstrap & FontAwesome
├── src/
│   ├── types/
│   │   └── mcp.ts              # TypeScript type definitions for MCP
│   ├── services/
│   │   └── MCPClient.ts        # MCP client service class
│   ├── App.tsx                 # Main React application component
│   └── index.tsx               # Application entry point
├── package.json                # Project configuration and dependencies
├── webpack.config.js           # Webpack build configuration
├── tsconfig.json              # TypeScript configuration
└── README.md                   # This file
```

## 🛠️ Features

### 1. Natural Language Processing
- Extract employee information from conversational text
- Pattern matching for names, emails, roles, and departments
- Confidence scoring for extraction accuracy

### 2. MCP Workflow Management
- **Step 1**: PostgreSQL MCP - Create employee records
- **Step 2**: Assets MCP - Allocate role-based assets
- **Step 3**: Notifications MCP - Send welcome messages
- Real-time progress tracking and visual indicators

### 3. Interactive UI Components
- **Status Cards**: Health monitoring for MCP services
- **Progress Indicators**: Step-by-step workflow visualization
- **Results Display**: Comprehensive onboarding results
- **Dashboard**: Employee and asset management

### 4. Role-Based Asset Allocation
```typescript
// Example asset templates by role
const assetTemplates = {
  employee: ['laptop', 'ID_card', 'welcome_bag', 'access_card'],
  manager: ['laptop', 'ID_card', 'welcome_bag', 'access_card', 'parking_pass', 'mobile_phone'],
  intern: ['laptop', 'ID_card', 'temporary_badge'],
  executive: ['laptop', 'ID_card', 'welcome_bag', 'access_card', 'parking_pass', 'mobile_phone', 'company_car'],
  developer: ['laptop', 'ID_card', 'welcome_bag', 'access_card', 'development_tools']
};
```

## 🚀 Quick Start

### Prerequisites
- Node.js >= 16.0.0
- npm >= 8.0.0

### Installation

1. **Navigate to the React MCP Client directory:**
   ```bash
   cd react-mcp-client
   ```

2. **Install dependencies:**
   ```bash
   npm run install-deps
   ```

3. **Start the development server:**
   ```bash
   npm start
   ```

4. **Open your browser:**
   The application will automatically open at `http://localhost:3000`

### Alternative Build Commands

```bash
# Development server
npm run dev

# Production build
npm run build
```

## 🎯 Usage Examples

### Basic Employee Onboarding

Enter any of these natural language requests:

```
onboard employee Pradeep Kumar,pradeep.n2019@gmail.com as developer in engineering

create new employee Sarah Johnson,sarah.johnson@company.com for manager role

process onboarding for intern Mike Wilson,mike.wilson@company.com in IT department

add employee Jessica Smith,jessica.smith@company.com as executive in operations
```

### Expected Workflow
1. **NLP Processing**: Extracts name, email, role, and department
2. **Employee Creation**: Creates record in simulated database
3. **Asset Allocation**: Assigns role-appropriate assets with costs
4. **Notifications**: Sends welcome messages via email, SMS, and Slack

## 🏗️ Architecture

### MCP Client Service (`MCPClient.ts`)
```typescript
class MCPClient {
  // NLP-powered employee data extraction
  extractEmployeeDataNLP(text: string): EmployeeData
  
  // MCP tool communication
  async callMCPTool(toolName: string, parameters: any): Promise<MCPResult>
  
  // Complete onboarding workflow
  async onboardEmployeeNLP(input: string, onProgress?: Function): Promise<WorkflowResult>
  
  // Health check for MCP services
  async testMCPToolsIndividually(): Promise<Record<string, any>>
}
```

### Type Safety (`types/mcp.ts`)
- **MCPRequest/MCPResponse**: Protocol-compliant message structures
- **EmployeeData**: Extracted employee information with confidence scoring
- **WorkflowResult**: Complete onboarding workflow results
- **Asset/Notification**: Resource allocation and communication types

### UI Components (`App.tsx`)
- **StatusCard**: Service health monitoring
- **StepIndicator**: Workflow progress visualization  
- **NLPResults**: Extraction results display
- **WorkflowResults**: Complete onboarding summary

## 🔧 Configuration

### MCP Endpoints
```typescript
const endpoints = {
  broker: `${baseUrl}/broker/onboard`,
  postgres_mcp: `${baseUrl}/mcp/postgres`,
  assets_mcp: `${baseUrl}/mcp/assets`,
  notifications_mcp: `${baseUrl}/mcp/notifications`
};
```

### NLP Patterns
```typescript
const nlpPatterns = {
  email: /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/,
  name: /\b([A-Za-z]+(?:\s+[A-Za-z]+)+)(?=,|,\s*[\w._%+-]+@)/,
  role: /\b(?:as|for|role)\s+([a-zA-Z]+)(?:\s|$|,)/,
  department: /\b(?:in|department|dept)\s+([a-zA-Z]+)(?:\s|$|,)/
};
```

## 🎨 UI Features

### Styling
- **Bootstrap 5.3.0**: Responsive layout and components
- **FontAwesome 6.4.0**: Professional icons
- **Custom CSS**: Gradient backgrounds, animations, and transitions
- **Progress Indicators**: Real-time step tracking with animations

### Responsive Design
- Mobile-friendly interface
- Adaptive card layouts
- Accessible form controls
- Interactive dashboard tabs

## 📊 Comparison with Python Implementation

| Feature | Python Files | React MCP Client |
|---------|-------------|------------------|
| **Interface** | Command-line | Web-based GUI |
| **User Experience** | Technical users | All user types |
| **Real-time Feedback** | Console logs | Visual progress |
| **Data Visualization** | Text output | Interactive cards |
| **Accessibility** | Limited | Full web accessibility |
| **Deployment** | Local scripts | Web application |
| **Extensibility** | Script modification | Component-based |

## 🔄 MCP Protocol Implementation

### Session Management
```typescript
async createSession(): Promise<MCPRequest> {
  return {
    jsonrpc: '2.0',
    id: generateUUID(),
    method: 'initialize',
    params: {
      protocolVersion: '2024-11-05',
      capabilities: { roots: { listChanged: true }, sampling: {} },
      clientInfo: { name: 'react-employee-onboarding-mcp-client', version: '1.0.0' }
    }
  };
}
```

### Tool Calls
```typescript
async callMCPTool(toolName: string, parameters: any): Promise<MCPResult> {
  const mcpRequest: MCPRequest = {
    jsonrpc: '2.0',
    id: generateUUID(),
    method: 'tools/call',
    params: { name: toolName, arguments: parameters }
  };
  // Handle routing and response processing...
}
```

## 🚀 Deployment

### Development
```bash
npm run dev
# Serves on http://localhost:3000 with hot reload
```

### Production
```bash
npm run build
# Creates optimized build in dist/ directory
```

### Integration
The React client can be integrated into existing systems by:
1. **Standalone**: Deploy as independent web application
2. **Embedded**: Include as component in larger dashboard
3. **API Integration**: Connect to real MCP servers instead of simulation
4. **Authentication**: Add user management and security layers

## 🤝 Benefits Over Python Testing

1. **Better User Experience**: Intuitive web interface vs command-line
2. **Visual Feedback**: Progress indicators and real-time updates
3. **Accessibility**: Web-based accessibility features
4. **Cross-Platform**: Works on any device with a browser
5. **Scalability**: Easy to extend with new MCP services
6. **Professional UI**: Modern design suitable for production use
7. **Real-time Collaboration**: Multiple users can test simultaneously
8. **Data Persistence**: Dashboard maintains session data

## 📝 Development Notes

### Key Technologies
- **React 18**: Modern React with hooks and concurrent features
- **TypeScript**: Full type safety and developer experience
- **Webpack 5**: Module bundling and development server
- **Bootstrap 5**: UI framework with modern design system
- **Model Context Protocol**: Standardized agent communication

### Future Enhancements
- [ ] Authentication and user management
- [ ] Real MCP server integration (replacing simulation)
- [ ] Advanced analytics and reporting
- [ ] Multi-language support
- [ ] Export functionality (PDF reports, CSV data)
- [ ] WebSocket real-time updates
- [ ] Role-based access control
- [ ] Audit logging and compliance

## 📄 License

MIT License - see package.json for details.

---

**This React MCP Client successfully replaces Python testing files with a modern, interactive web application that provides superior user experience while maintaining full MCP protocol compatibility.**
