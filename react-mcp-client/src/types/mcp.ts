// MCP Type Definitions for Employee Onboarding System

export interface EmployeeData {
  firstName: string;
  lastName: string;
  email: string;
  department: string;
  position: string;
  startDate: string;
  manager: string;
  equipmentNeeds: string[];
}

export interface EmployeeRecord {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  department: string;
  position: string;
  startDate: string;
  manager: string;
  status: 'pending' | 'onboarding' | 'active' | 'inactive';
  createdAt: string;
  updatedAt: string;
}

export interface Asset {
  id: string;
  type: string;
  model?: string;
  serialNumber?: string;
  status: 'available' | 'allocated' | 'maintenance' | 'retired';
  assignedTo?: string;
  allocatedDate?: string;
}

export interface WorkflowStep {
  title: string;
  status: 'pending' | 'processing' | 'completed' | 'error';
  message?: string;
  timestamp?: string;
}

export interface WorkflowResult {
  success: boolean;
  message: string;
  steps: WorkflowStep[];
  employeeRecord?: EmployeeRecord;
  allocatedAssets?: Asset[];
  trackingId?: string;
}

export interface ProcessingStatus {
  employeeCreation: 'pending' | 'processing' | 'completed' | 'error';
  assetAllocation: 'pending' | 'processing' | 'completed' | 'error';
  emailNotification: 'pending' | 'processing' | 'completed' | 'error';
  overallStatus: 'pending' | 'processing' | 'completed' | 'error';
}

export interface MCPResponse<T = any> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
  timestamp: string;
}

export interface SystemHealth {
  employee: 'healthy' | 'unhealthy';
  asset: 'healthy' | 'unhealthy';
  email: 'healthy' | 'unhealthy';
}

export interface MCPEndpoints {
  employee: string;
  asset: string;
  email: string;
  health: string;
}

// Tool definitions for MCP protocol
export interface MCPTool {
  name: string;
  description: string;
  inputSchema: {
    type: string;
    properties: Record<string, any>;
    required?: string[];
  };
}

export interface MCPToolCall {
  tool: string;
  arguments: Record<string, any>;
}

export interface MCPToolResult {
  success: boolean;
  content: any[];
  error?: string;
}

// Resource definitions for MCP protocol
export interface MCPResource {
  uri: string;
  name: string;
  description?: string;
  mimeType?: string;
}

export interface MCPResourceContent {
  uri: string;
  mimeType: string;
  text?: string;
  blob?: string;
}

// Notification definitions
export interface EmailNotification {
  to: string[];
  cc?: string[];
  bcc?: string[];
  subject: string;
  body: string;
  template?: string;
  data?: Record<string, any>;
  attachments?: Array<{
    filename: string;
    content: string;
    contentType: string;
  }>;
}

export interface NotificationResult {
  success: boolean;
  messageId?: string;
  recipients: string[];
  error?: string;
  timestamp: string;
}

// Configuration interfaces
export interface MCPConfig {
  baseUrl: string;
  endpoints: MCPEndpoints;
  timeout: number;
  retryAttempts: number;
  apiKey?: string;
}

export interface OnboardingConfig {
  departments: string[];
  equipmentTypes: string[];
  defaultAssets: Record<string, string[]>;
  emailTemplates: Record<string, string>;
  workflowSteps: string[];
}
