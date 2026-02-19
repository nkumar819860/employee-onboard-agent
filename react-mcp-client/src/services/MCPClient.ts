import {
  EmployeeData,
  EmployeeRecord,
  WorkflowResult,
  SystemHealth,
  MCPResponse,
  MCPConfig,
  Asset,
  EmailNotification,
  NotificationResult,
  MCPEndpoints
} from '../types/mcp';

export class MCPClient {
  private config: MCPConfig;

  constructor(baseUrl?: string) {
    this.config = {
      baseUrl: baseUrl || process.env.REACT_APP_MCP_BASE_URL || 'http://localhost:8081',
      endpoints: {
        employee: '/mcp/tools/create-employee',
        asset: '/mcp/tools/allocate-asset',
        email: '/mcp/tools/send-email',
        health: '/health'
      },
      timeout: 30000,
      retryAttempts: 3,
      apiKey: process.env.REACT_APP_MCP_API_KEY
    };
  }

  private async makeRequest<T>(
    endpoint: string,
    method: 'GET' | 'POST' | 'PUT' | 'DELETE' = 'GET',
    data?: any
  ): Promise<MCPResponse<T>> {
    const url = `${this.config.baseUrl}${endpoint}`;
    
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };

    if (this.config.apiKey) {
      headers['Authorization'] = `Bearer ${this.config.apiKey}`;
    }

    try {
      const response = await fetch(url, {
        method,
        headers,
        body: data ? JSON.stringify(data) : undefined,
        signal: AbortSignal.timeout(this.config.timeout)
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const result = await response.json();
      
      return {
        success: true,
        data: result,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      console.error(`MCP request failed for ${endpoint}:`, error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        timestamp: new Date().toISOString()
      };
    }
  }

  async checkHealth(): Promise<SystemHealth> {
    try {
      const response = await this.makeRequest(this.config.endpoints.health);
      
      if (response.success && response.data) {
        // Parse health check response
        return {
          employee: response.data.status === 'healthy' ? 'healthy' : 'unhealthy',
          asset: response.data.status === 'healthy' ? 'healthy' : 'unhealthy',
          email: response.data.status === 'healthy' ? 'healthy' : 'unhealthy'
        };
      }
    } catch (error) {
      console.error('Health check failed:', error);
    }

    return {
      employee: 'unhealthy',
      asset: 'unhealthy',
      email: 'unhealthy'
    };
  }

  async createEmployee(employeeData: EmployeeData): Promise<MCPResponse<EmployeeRecord>> {
    const payload = {
      name: `${employeeData.firstName} ${employeeData.lastName}`,
      firstName: employeeData.firstName,
      lastName: employeeData.lastName,
      email: employeeData.email,
      department: employeeData.department,
      position: employeeData.position,
      startDate: employeeData.startDate,
      manager: employeeData.manager,
      status: 'onboarding'
    };

    const response = await this.makeRequest<EmployeeRecord>(
      this.config.endpoints.employee,
      'POST',
      payload
    );

    if (response.success && response.data) {
      // Transform response to match EmployeeRecord interface
      const employeeRecord: EmployeeRecord = {
        id: response.data.employeeId || `EMP_${Date.now()}`,
        firstName: employeeData.firstName,
        lastName: employeeData.lastName,
        email: employeeData.email,
        department: employeeData.department,
        position: employeeData.position,
        startDate: employeeData.startDate,
        manager: employeeData.manager,
        status: 'onboarding',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };

      return {
        ...response,
        data: employeeRecord
      };
    }

    return response;
  }

  async allocateAssets(employeeId: string, assetTypes: string[]): Promise<MCPResponse<Asset[]>> {
    const allocatedAssets: Asset[] = [];
    
    for (const assetType of assetTypes) {
      const payload = {
        employeeId,
        assetType,
        requestedBy: 'system',
        priority: 'normal'
      };

      const response = await this.makeRequest<any>(
        this.config.endpoints.asset,
        'POST',
        payload
      );

      if (response.success && response.data) {
        const asset: Asset = {
          id: `${assetType.substring(0, 3).toUpperCase()}-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
          type: assetType,
          status: 'allocated',
          assignedTo: employeeId,
          allocatedDate: new Date().toISOString()
        };
        allocatedAssets.push(asset);
      }
    }

    return {
      success: allocatedAssets.length > 0,
      data: allocatedAssets,
      message: `Allocated ${allocatedAssets.length} assets`,
      timestamp: new Date().toISOString()
    };
  }

  async sendWelcomeEmail(employeeData: EmployeeData, assets: Asset[]): Promise<MCPResponse<NotificationResult>> {
    const emailData: EmailNotification = {
      to: [employeeData.email],
      cc: [employeeData.manager],
      subject: `Welcome to ${employeeData.department} - ${employeeData.firstName} ${employeeData.lastName}`,
      body: this.generateWelcomeEmailBody(employeeData, assets),
      template: 'welcome_employee',
      data: {
        employee: employeeData,
        assets: assets,
        department: employeeData.department
      }
    };

    const response = await this.makeRequest<any>(
      this.config.endpoints.email,
      'POST',
      emailData
    );

    if (response.success) {
      const notificationResult: NotificationResult = {
        success: true,
        messageId: `MSG_${Date.now()}`,
        recipients: emailData.to,
        timestamp: new Date().toISOString()
      };

      return {
        ...response,
        data: notificationResult
      };
    }

    return response;
  }

  private generateWelcomeEmailBody(employeeData: EmployeeData, assets: Asset[]): string {
    return `
    <html>
      <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
        <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
          <h1 style="color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px;">
            Welcome to ${employeeData.department}!
          </h1>
          
          <p>Dear ${employeeData.firstName},</p>
          
          <p>We're excited to welcome you to our team as ${employeeData.position}. 
          Your onboarding process has been initiated and here are the details:</p>
          
          <div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <h3 style="color: #2c3e50; margin-top: 0;">Employee Information:</h3>
            <ul style="list-style-type: none; padding-left: 0;">
              <li><strong>Name:</strong> ${employeeData.firstName} ${employeeData.lastName}</li>
              <li><strong>Position:</strong> ${employeeData.position}</li>
              <li><strong>Department:</strong> ${employeeData.department}</li>
              <li><strong>Start Date:</strong> ${new Date(employeeData.startDate).toLocaleDateString()}</li>
              <li><strong>Manager:</strong> ${employeeData.manager}</li>
            </ul>
          </div>

          ${assets.length > 0 ? `
          <div style="background-color: #e8f5e8; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <h3 style="color: #2c3e50; margin-top: 0;">Allocated Equipment:</h3>
            <ul>
              ${assets.map(asset => `<li>${asset.type} (ID: ${asset.id})</li>`).join('')}
            </ul>
            <p><em>Your equipment will be ready for pickup on your first day.</em></p>
          </div>
          ` : ''}

          <div style="background-color: #fff3cd; padding: 15px; border-radius: 5px; margin: 20px 0;">
            <h3 style="color: #2c3e50; margin-top: 0;">Next Steps:</h3>
            <ol>
              <li>Report to HR on your first day at 9:00 AM</li>
              <li>Complete your employment documentation</li>
              <li>Attend the new employee orientation session</li>
              <li>Meet with your manager and team</li>
              <li>Begin your department-specific training</li>
            </ol>
          </div>

          <p>If you have any questions before your start date, please don't hesitate to reach out to your manager or HR.</p>
          
          <p>We look forward to having you on the team!</p>
          
          <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd;">
            <p style="color: #666; font-size: 0.9em;">
              Best regards,<br>
              The ${employeeData.department} Team<br>
              Human Resources Department
            </p>
          </div>
        </div>
      </body>
    </html>`;
  }

  async processEmployeeOnboarding(employeeData: EmployeeData): Promise<WorkflowResult> {
    const result: WorkflowResult = {
      success: false,
      message: '',
      steps: [
        { title: 'Employee Profile', status: 'processing' },
        { title: 'Asset Allocation', status: 'pending' },
        { title: 'Email Notification', status: 'pending' }
      ]
    };

    try {
      // Step 1: Create Employee Profile
      const employeeResponse = await this.createEmployee(employeeData);
      
      if (employeeResponse.success && employeeResponse.data) {
        result.steps[0].status = 'completed';
        result.employeeRecord = employeeResponse.data;
        
        // Step 2: Allocate Assets
        result.steps[1].status = 'processing';
        
        if (employeeData.equipmentNeeds.length > 0) {
          const assetResponse = await this.allocateAssets(
            employeeResponse.data.id,
            employeeData.equipmentNeeds
          );
          
          if (assetResponse.success && assetResponse.data) {
            result.steps[1].status = 'completed';
            result.allocatedAssets = assetResponse.data;
          } else {
            result.steps[1].status = 'error';
            result.steps[1].message = 'Failed to allocate assets';
          }
        } else {
          result.steps[1].status = 'completed';
          result.steps[1].message = 'No equipment requested';
        }

        // Step 3: Send Welcome Email
        result.steps[2].status = 'processing';
        
        const emailResponse = await this.sendWelcomeEmail(
          employeeData,
          result.allocatedAssets || []
        );
        
        if (emailResponse.success) {
          result.steps[2].status = 'completed';
        } else {
          result.steps[2].status = 'error';
          result.steps[2].message = 'Failed to send welcome email';
        }

        // Determine overall success
        const hasErrors = result.steps.some(step => step.status === 'error');
        result.success = !hasErrors;
        result.message = hasErrors 
          ? 'Onboarding completed with some errors' 
          : 'Employee onboarding completed successfully';
        result.trackingId = `ONB-${Date.now()}`;

      } else {
        result.steps[0].status = 'error';
        result.steps[0].message = 'Failed to create employee profile';
        result.message = 'Failed to create employee profile';
      }

    } catch (error) {
      console.error('Onboarding workflow error:', error);
      result.message = 'Onboarding workflow failed due to system error';
      result.steps.forEach(step => {
        if (step.status === 'processing') {
          step.status = 'error';
        }
      });
    }

    return result;
  }

  async getEmployees(): Promise<EmployeeRecord[]> {
    try {
      const response = await this.makeRequest<EmployeeRecord[]>('/listEmployees');
      
      if (response.success && response.data) {
        return Array.isArray(response.data) ? response.data : 
               response.data.employees || [];
      }
    } catch (error) {
      console.error('Failed to fetch employees:', error);
    }

    return [];
  }

  // Utility method to update configuration
  updateConfig(newConfig: Partial<MCPConfig>): void {
    this.config = { ...this.config, ...newConfig };
  }

  // Get current configuration
  getConfig(): MCPConfig {
    return { ...this.config };
  }
}

export default MCPClient;
