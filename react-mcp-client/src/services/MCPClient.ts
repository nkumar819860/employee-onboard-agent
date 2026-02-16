// import axios, { AxiosResponse } from 'axios';
// import { v4 as uuidv4 } from 'uuid';

// Simple UUID v4 generator for demo purposes
const generateUUID = (): string => {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
};
import {
  MCPRequest,
  MCPResponse,
  MCPClientConfig,
  EmployeeData,
  WorkflowResult,
  MCPServiceStatus,
  NLPPatterns,
  OnboardingResult,
  EmployeeRecord,
  Asset,
  Notification
} from '../types/mcp';

export class MCPClient {
  private config: MCPClientConfig;
  private sessionId: string;
  private conversationHistory: any[] = [];
  private simulatedEmployees: EmployeeRecord[] = [];
  private simulatedAssets: Asset[] = [];

  // NLP patterns for extracting employee information
  private nlpPatterns: NLPPatterns = {
    email: /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/,
    name: /\b([A-Za-z]+(?:\s+[A-Za-z]+)+)(?=,|,\s*[\w._%+-]+@)/,
    single_name: /(?:employee|onboard|add|create|process).*?([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)/,
    role: /\b(?:as|for|role)\s+([a-zA-Z]+)(?:\s|$|,)/,
    department: /\b(?:in|department|dept)\s+([a-zA-Z]+)(?:\s|$|,)/
  };

  constructor(baseUrl: string = 'http://localhost:8080') {
    this.sessionId = generateUUID();
    this.config = {
      baseUrl,
      endpoints: {
        broker: `${baseUrl}/broker/onboard`,
        postgres_mcp: `${baseUrl}/mcp/postgres`,
        assets_mcp: `${baseUrl}/mcp/assets`,
        notifications_mcp: `${baseUrl}/mcp/notifications`
      }
    };
  }

  /**
   * Initialize MCP session
   */
  async createSession(): Promise<MCPRequest> {
    console.log(`🔌 Initializing MCP Client Session: ${this.sessionId}`);
    return {
      jsonrpc: '2.0',
      id: generateUUID(),
      method: 'initialize',
      params: {
        protocolVersion: '2024-11-05',
        capabilities: {
          roots: {
            listChanged: true
          },
          sampling: {}
        },
        clientInfo: {
          name: 'react-employee-onboarding-mcp-client',
          version: '1.0.0'
        }
      }
    };
  }

  /**
   * Extract employee information from natural language using NLP patterns
   */
  extractEmployeeDataNLP(text: string): EmployeeData {
    console.log('🧠 Processing natural language input with NLP extraction...');

    const extracted: EmployeeData = {
      name: null,
      email: null,
      role: 'employee',
      department: 'general',
      confidence: 0.0
    };

    // Extract email
    const emailMatch = text.match(this.nlpPatterns.email);
    if (emailMatch) {
      extracted.email = emailMatch[0];
      extracted.confidence += 0.4;
    }

    // Try enhanced name extraction
    const nameMatch = text.match(this.nlpPatterns.name);
    if (nameMatch) {
      extracted.name = nameMatch[1].trim();
      extracted.confidence += 0.3;
    } else {
      // Fallback to single name extraction
      const singleNameMatch = text.match(this.nlpPatterns.single_name);
      if (singleNameMatch) {
        extracted.name = singleNameMatch[1].trim();
        extracted.confidence += 0.25;
      }
    }

    // Extract role
    const roleMatch = text.match(this.nlpPatterns.role);
    if (roleMatch) {
      const role = roleMatch[1].trim().toLowerCase();
      if (['developer', 'manager', 'intern', 'executive', 'admin'].includes(role)) {
        extracted.role = role;
        extracted.confidence += 0.2;
      }
    }

    // Extract department
    const deptMatch = text.match(this.nlpPatterns.department);
    if (deptMatch) {
      extracted.department = deptMatch[1].trim();
      extracted.confidence += 0.1;
    }

    console.log('   ✅ Enhanced NLP Results:', extracted);
    return extracted;
  }

  /**
   * Make MCP tool call following the protocol specification
   */
  async callMCPTool(toolName: string, parameters: any): Promise<{ success: boolean; result?: any; error?: string; request_id: string }> {
    const requestId = generateUUID();

    const mcpRequest: MCPRequest = {
      jsonrpc: '2.0',
      id: requestId,
      method: 'tools/call',
      params: {
        name: toolName,
        arguments: parameters
      }
    };

    console.log(`🔧 MCP Tool Call: ${toolName}`);
    console.log('   Request:', JSON.stringify(mcpRequest, null, 2));

    try {
      // Determine the appropriate endpoint
      let endpoint = this.config.endpoints.broker;
      if (toolName.toLowerCase().includes('postgres')) {
        endpoint = this.config.endpoints.postgres_mcp;
      } else if (toolName.toLowerCase().includes('asset')) {
        endpoint = this.config.endpoints.assets_mcp;
      } else if (toolName.toLowerCase().includes('notification')) {
        endpoint = this.config.endpoints.notifications_mcp;
      }

      // For demo purposes, simulate MCP responses instead of making actual HTTP calls
      const result = this.simulateMCPResponse(toolName, parameters, requestId);
      
      console.log(`   ✅ MCP Tool Success: ${toolName}`);
      return result;

    } catch (error) {
      console.error(`   ❌ MCP Tool Exception: ${error}`);
      return {
        success: false,
        error: String(error),
        request_id: requestId
      };
    }
  }

  /**
   * Simulate MCP server responses for demo purposes
   */
  private simulateMCPResponse(toolName: string, parameters: any, requestId: string): { success: boolean; result?: any; error?: string; request_id: string } {
    if (toolName.toLowerCase().includes('postgres')) {
      return this.simulatePostgresMCP(parameters, requestId);
    } else if (toolName.toLowerCase().includes('asset')) {
      return this.simulateAssetsMCP(parameters, requestId);
    } else if (toolName.toLowerCase().includes('notification')) {
      return this.simulateNotificationsMCP(parameters, requestId);
    } else {
      return { success: false, error: 'Unknown MCP tool', request_id: requestId };
    }
  }

  /**
   * Simulate PostgreSQL MCP service
   */
  private simulatePostgresMCP(params: any, requestId: string): { success: boolean; result?: any; error?: string; request_id: string } {
    if (JSON.stringify(params).includes('health_check')) {
      return {
        success: true,
        result: {
          jsonrpc: '2.0',
          id: requestId,
          result: {
            content: [
              {
                type: 'text',
                text: 'PostgreSQL MCP Server is healthy. Database connection active.'
              }
            ]
          }
        },
        request_id: requestId
      };
    }

    // Simulate employee creation
    const empId = this.simulatedEmployees.length + 1;
    const employeeRecord: EmployeeRecord = {
      id: empId,
      name: params.name || 'Unknown',
      email: params.email || 'unknown@company.com',
      role: params.role || 'employee',
      department: params.department || 'general',
      status: 'active',
      created_at: new Date().toISOString()
    };
    this.simulatedEmployees.push(employeeRecord);

    return {
      success: true,
      result: {
        jsonrpc: '2.0',
        id: requestId,
        result: {
          content: [
            {
              type: 'text',
              text: `Employee created successfully with ID: ${empId}`
            }
          ],
          isError: false
        }
      },
      request_id: requestId
    };
  }

  /**
   * Simulate Assets MCP service
   */
  private simulateAssetsMCP(params: any, requestId: string): { success: boolean; result?: any; error?: string; request_id: string } {
    if (JSON.stringify(params).includes('health_check')) {
      return {
        success: true,
        result: {
          jsonrpc: '2.0',
          id: requestId,
          result: {
            content: [
              {
                type: 'text',
                text: 'Assets MCP Server is healthy. Asset allocation system ready.'
              }
            ]
          }
        },
        request_id: requestId
      };
    }

    // Role-based asset allocation
    const role = params.role || 'employee';
    const empId = params.employee_id || 1;

    const assetTemplates: Record<string, string[]> = {
      employee: ['laptop', 'ID_card', 'welcome_bag', 'access_card'],
      manager: ['laptop', 'ID_card', 'welcome_bag', 'access_card', 'parking_pass', 'mobile_phone'],
      intern: ['laptop', 'ID_card', 'temporary_badge'],
      executive: ['laptop', 'ID_card', 'welcome_bag', 'access_card', 'parking_pass', 'mobile_phone', 'company_car'],
      developer: ['laptop', 'ID_card', 'welcome_bag', 'access_card', 'development_tools']
    };

    const assets = assetTemplates[role] || assetTemplates.employee;
    const totalCost = assets.reduce((sum, asset) => {
      return sum + (asset.includes('laptop') ? 1200 : asset.includes('bag') ? 50 : 25);
    }, 0);

    const allocatedAssets: Asset[] = [];
    assets.forEach(asset => {
      const assetRecord: Asset = {
        asset_id: generateUUID(),
        emp_id: empId,
        type: asset,
        cost: asset.includes('laptop') ? 1200 : asset.includes('bag') ? 50 : 25,
        status: 'allocated',
        delivery_date: new Date(Date.now() + Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
      };
      allocatedAssets.push(assetRecord);
      this.simulatedAssets.push(assetRecord);
    });

    return {
      success: true,
      result: {
        jsonrpc: '2.0',
        id: requestId,
        result: {
          content: [
            {
              type: 'text',
              text: `Allocated ${assets.length} assets for ${role}. Total cost: $${totalCost}`
            }
          ]
        },
        assets_allocated: allocatedAssets,
        total_cost: totalCost
      },
      request_id: requestId
    };
  }

  /**
   * Simulate Notifications MCP service
   */
  private simulateNotificationsMCP(params: any, requestId: string): { success: boolean; result?: any; error?: string; request_id: string } {
    if (JSON.stringify(params).includes('health_check') || params.action === 'health_check') {
      return {
        success: true,
        result: {
          jsonrpc: '2.0',
          id: requestId,
          result: {
            content: [
              {
                type: 'text',
                text: 'Notifications MCP Server is healthy. Email, SMS, and Slack channels ready.'
              }
            ]
          }
        },
        request_id: requestId
      };
    }

    const name = params.name || 'Employee';
    const email = params.email || 'employee@company.com';
    const role = params.role || 'employee';

    const notificationsSent: Notification[] = [
      { channel: 'email', recipient: email, status: 'sent' },
      { channel: 'sms', recipient: '+1234567890', status: 'sent' },
      { channel: 'slack', recipient: `@${name.toLowerCase().replace(' ', '')}`, status: 'sent' }
    ];

    const welcomeMessage = `Dear ${name},\n\nWelcome to our company! Your onboarding as ${role} has been completed.\n\nYour assets have been allocated and welcome notifications sent via multiple channels.\n\nBest regards,\nHR Team (via React MCP Client)`;

    return {
      success: true,
      result: {
        jsonrpc: '2.0',
        id: requestId,
        result: {
          content: [
            {
              type: 'text',
              text: `Welcome notifications sent via 3 channels to ${name}`
            }
          ]
        },
        notifications: notificationsSent,
        welcome_message: welcomeMessage
      },
      request_id: requestId
    };
  }

  /**
   * Complete employee onboarding using natural language input
   */
  async onboardEmployeeNLP(naturalLanguageInput: string, onProgressUpdate?: (status: string, message: string, data?: any) => void): Promise<WorkflowResult> {
    console.log('🚀 Starting Employee Onboarding via React MCP Client');
    console.log(`📝 Natural Language Input: ${naturalLanguageInput}`);

    // Store conversation
    this.conversationHistory.push({
      timestamp: new Date().toISOString(),
      type: 'user_input',
      content: naturalLanguageInput
    });

    onProgressUpdate?.('processing', 'Processing natural language input...');

    // Step 1: Extract employee data using NLP
    const employeeData = this.extractEmployeeDataNLP(naturalLanguageInput);

    if (!employeeData.name || !employeeData.email) {
      const errorMsg = 'Could not extract required employee information (name and email) from input';
      console.error(`❌ ${errorMsg}`);
      return {
        workflow_id: generateUUID(),
        input: naturalLanguageInput,
        extracted_data: employeeData,
        steps: [],
        overall_success: false,
        error: errorMsg
      };
    }

    onProgressUpdate?.('nlp_complete', 'NLP extraction completed', employeeData);

    const workflowResults: WorkflowResult = {
      workflow_id: generateUUID(),
      input: naturalLanguageInput,
      extracted_data: employeeData,
      steps: [],
      overall_success: true
    };

    try {
      // Step 2: Create employee record via PostgreSQL MCP
      onProgressUpdate?.('step_1', 'Creating employee record via PostgreSQL MCP...');
      console.log('🗄️ Step 1: Creating employee record via PostgreSQL MCP');
      
      const postgresResult = await this.callMCPTool('postgres_create_employee', {
        name: employeeData.name,
        email: employeeData.email,
        role: employeeData.role,
        department: employeeData.department
      });

      workflowResults.steps.push({
        step: 1,
        service: 'postgres-mcp',
        action: 'create_employee',
        result: postgresResult
      });

      if (!postgresResult.success) {
        workflowResults.overall_success = false;
        return workflowResults;
      }

      const empId = this.simulatedEmployees.length;

      // Step 3: Allocate assets via Assets MCP
      onProgressUpdate?.('step_2', 'Allocating assets via Assets MCP...');
      console.log('📦 Step 2: Allocating assets via Assets MCP');
      
      const assetsResult = await this.callMCPTool('assets_allocate', {
        employee_id: empId,
        role: employeeData.role,
        department: employeeData.department
      });

      workflowResults.steps.push({
        step: 2,
        service: 'assets-mcp',
        action: 'allocate_assets',
        result: assetsResult
      });

      // Step 4: Send notifications via Notifications MCP
      onProgressUpdate?.('step_3', 'Sending welcome notifications via Notifications MCP...');
      console.log('📧 Step 3: Sending welcome notifications via Notifications MCP');
      
      const notificationResult = await this.callMCPTool('notification_send_welcome', {
        employee_id: empId,
        name: employeeData.name,
        email: employeeData.email,
        role: employeeData.role
      });

      workflowResults.steps.push({
        step: 3,
        service: 'notifications-mcp',
        action: 'send_welcome',
        result: notificationResult
      });

      // Compile final results
      workflowResults.employee_id = empId;
      workflowResults.completion_time = new Date().toISOString();

      // Store in conversation history
      this.conversationHistory.push({
        timestamp: new Date().toISOString(),
        type: 'workflow_result',
        content: workflowResults
      });

      console.log('🎉 Employee onboarding workflow completed successfully!');
      return workflowResults;

    } catch (error) {
      console.error(`❌ Workflow error: ${error}`);
      workflowResults.overall_success = false;
      workflowResults.error = String(error);
      return workflowResults;
    }
  }

  /**
   * Test individual MCP tools for debugging and validation
   */
  async testMCPToolsIndividually(): Promise<Record<string, any>> {
    console.log('🧪 Testing individual MCP tools...');

    const testResults: Record<string, any> = {
      'postgres_mcp': null,
      'assets_mcp': null,
      'notifications_mcp': null
    };

    // Test PostgreSQL MCP
    console.log('Testing PostgreSQL MCP health check...');
    const postgresTest = await this.callMCPTool('postgres_health_check', { action: 'health_check' });
    testResults['postgres_mcp'] = postgresTest;

    // Test Assets MCP
    console.log('Testing Assets MCP health check...');
    const assetsTest = await this.callMCPTool('assets_health_check', { action: 'health_check' });
    testResults['assets_mcp'] = assetsTest;

    // Test Notifications MCP
    console.log('Testing Notifications MCP health check...');
    const notificationsTest = await this.callMCPTool('notifications_health_check', { action: 'health_check' });
    testResults['notifications_mcp'] = notificationsTest;

    return testResults;
  }

  /**
   * Get conversation history
   */
  getConversationHistory(): any[] {
    return this.conversationHistory;
  }

  /**
   * Get simulated employees for demo
   */
  getSimulatedEmployees(): EmployeeRecord[] {
    return this.simulatedEmployees;
  }

  /**
   * Get simulated assets for demo
   */
  getSimulatedAssets(): Asset[] {
    return this.simulatedAssets;
  }

  /**
   * Clear all simulated data
   */
  clearSimulatedData(): void {
    this.simulatedEmployees = [];
    this.simulatedAssets = [];
    this.conversationHistory = [];
  }
}
