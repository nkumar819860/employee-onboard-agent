// MCP Client Type Definitions
export interface MCPRequest {
  jsonrpc: string;
  id: string;
  method: string;
  params?: any;
}

export interface MCPResponse {
  jsonrpc: string;
  id: string;
  result?: any;
  error?: MCPError;
}

export interface MCPError {
  code: number;
  message: string;
  data?: any;
}

export interface EmployeeData {
  name: string | null;
  email: string | null;
  role: string;
  department: string;
  confidence: number;
}

export interface EmployeeRecord {
  id: number;
  name: string;
  email: string;
  role: string;
  department: string;
  status: string;
  created_at: string;
}

export interface Asset {
  asset_id: string;
  emp_id: number;
  type: string;
  cost: number;
  status: string;
  delivery_date?: string;
}

export interface Notification {
  channel: string;
  recipient: string;
  status: string;
}

export interface WorkflowStep {
  step: number;
  service: string;
  action: string;
  result: {
    success: boolean;
    result?: any;
    error?: string;
    request_id: string;
  };
}

export interface WorkflowResult {
  workflow_id: string;
  input: string;
  extracted_data: EmployeeData;
  steps: WorkflowStep[];
  overall_success: boolean;
  employee_id?: number;
  completion_time?: string;
  error?: string;
}

export interface OnboardingResult {
  employee: EmployeeRecord;
  assets: Asset[];
  notifications: Notification[];
  total_cost: number;
  welcome_message: string;
}

export interface MCPServiceStatus {
  'postgres-mcp': 'healthy' | 'unhealthy';
  'assets-mcp': 'healthy' | 'unhealthy';
  'notifications-mcp': 'healthy' | 'unhealthy';
}

export interface MCPClientConfig {
  baseUrl: string;
  endpoints: {
    broker: string;
    postgres_mcp: string;
    assets_mcp: string;
    notifications_mcp: string;
  };
}

export type ProcessingStatus = 
  | 'idle'
  | 'processing'
  | 'nlp_complete'
  | 'step_1'
  | 'step_2' 
  | 'step_3'
  | 'completed'
  | 'error';

export interface NLPPatterns {
  email: RegExp;
  name: RegExp;
  single_name: RegExp;
  role: RegExp;
  department: RegExp;
}
