import React, { useState, useEffect } from 'react';
import { MCPClient } from './services/MCPClient';
import { EmployeeData, WorkflowResult, ProcessingStatus, Asset, EmployeeRecord } from './types/mcp';

// Component interfaces
interface StatusCardProps {
  icon: string;
  title: string;
  status: 'healthy' | 'unhealthy';
}

interface StepIndicatorProps {
  step: number;
  title: string;
  status: 'pending' | 'processing' | 'completed' | 'error';
}

interface EmployeeFormProps {
  onSubmit: (data: EmployeeData) => void;
  processing: boolean;
}

interface WorkflowStatusProps {
  result: WorkflowResult | null;
}

// Status Card Component
const StatusCard: React.FC<StatusCardProps> = ({ icon, title, status }) => (
  <div className={`status-card ${status}`}>
    <div className="status-icon">{icon}</div>
    <div className="status-info">
      <h3>{title}</h3>
      <span className={`status-badge ${status}`}>
        {status === 'healthy' ? 'Online' : 'Offline'}
      </span>
    </div>
  </div>
);

// Step Indicator Component
const StepIndicator: React.FC<StepIndicatorProps> = ({ step, title, status }) => (
  <div className={`step-indicator ${status}`}>
    <div className="step-number">{step}</div>
    <div className="step-content">
      <h4>{title}</h4>
      <div className="step-status">{status}</div>
    </div>
  </div>
);

// Employee Form Component
const EmployeeForm: React.FC<EmployeeFormProps> = ({ onSubmit, processing }) => {
  const [formData, setFormData] = useState<EmployeeData>({
    firstName: '',
    lastName: '',
    email: '',
    department: '',
    position: '',
    startDate: '',
    manager: '',
    equipmentNeeds: []
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit(formData);
  };

  const handleEquipmentChange = (equipment: string, checked: boolean) => {
    setFormData(prev => ({
      ...prev,
      equipmentNeeds: checked
        ? [...prev.equipmentNeeds, equipment]
        : prev.equipmentNeeds.filter(e => e !== equipment)
    }));
  };

  return (
    <form onSubmit={handleSubmit} className="employee-form">
      <div className="form-section">
        <h3>Employee Information</h3>
        <div className="form-row">
          <input
            type="text"
            placeholder="First Name"
            value={formData.firstName}
            onChange={(e) => setFormData(prev => ({ ...prev, firstName: e.target.value }))}
            required
          />
          <input
            type="text"
            placeholder="Last Name"
            value={formData.lastName}
            onChange={(e) => setFormData(prev => ({ ...prev, lastName: e.target.value }))}
            required
          />
        </div>
        <input
          type="email"
          placeholder="Email Address"
          value={formData.email}
          onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
          required
        />
        <div className="form-row">
          <select
            value={formData.department}
            onChange={(e) => setFormData(prev => ({ ...prev, department: e.target.value }))}
            required
          >
            <option value="">Select Department</option>
            <option value="Engineering">Engineering</option>
            <option value="Marketing">Marketing</option>
            <option value="Sales">Sales</option>
            <option value="HR">Human Resources</option>
            <option value="Finance">Finance</option>
            <option value="Operations">Operations</option>
          </select>
          <input
            type="text"
            placeholder="Position"
            value={formData.position}
            onChange={(e) => setFormData(prev => ({ ...prev, position: e.target.value }))}
            required
          />
        </div>
        <div className="form-row">
          <input
            type="date"
            placeholder="Start Date"
            value={formData.startDate}
            onChange={(e) => setFormData(prev => ({ ...prev, startDate: e.target.value }))}
            required
          />
          <input
            type="text"
            placeholder="Manager"
            value={formData.manager}
            onChange={(e) => setFormData(prev => ({ ...prev, manager: e.target.value }))}
            required
          />
        </div>
      </div>

      <div className="form-section">
        <h3>Equipment Requirements</h3>
        <div className="equipment-grid">
          {['Laptop', 'Monitor', 'Phone', 'Headset', 'Keyboard', 'Mouse'].map(equipment => (
            <label key={equipment} className="equipment-item">
              <input
                type="checkbox"
                onChange={(e) => handleEquipmentChange(equipment, e.target.checked)}
              />
              <span>{equipment}</span>
            </label>
          ))}
        </div>
      </div>

      <button type="submit" className="submit-button" disabled={processing}>
        {processing ? 'Processing...' : 'Start Onboarding'}
      </button>
    </form>
  );
};

// Workflow Status Component
const WorkflowStatus: React.FC<WorkflowStatusProps> = ({ result }) => {
  if (!result) return null;

  return (
    <div className="workflow-status">
      <h3>Onboarding Progress</h3>
      <div className="workflow-steps">
        {result.steps.map((step, index) => (
          <StepIndicator
            key={index}
            step={index + 1}
            title={step.title}
            status={step.status}
          />
        ))}
      </div>
      
      {result.employeeRecord && (
        <div className="employee-summary">
          <h4>Employee Record Created</h4>
          <div className="record-details">
            <p><strong>ID:</strong> {result.employeeRecord.id}</p>
            <p><strong>Name:</strong> {result.employeeRecord.firstName} {result.employeeRecord.lastName}</p>
            <p><strong>Email:</strong> {result.employeeRecord.email}</p>
            <p><strong>Department:</strong> {result.employeeRecord.department}</p>
            <p><strong>Status:</strong> {result.employeeRecord.status}</p>
          </div>
        </div>
      )}

      {result.allocatedAssets && result.allocatedAssets.length > 0 && (
        <div className="asset-summary">
          <h4>Allocated Assets</h4>
          <div className="asset-list">
            {result.allocatedAssets.map(asset => (
              <div key={asset.id} className="asset-item">
                <span className="asset-type">{asset.type}</span>
                <span className="asset-id">#{asset.id}</span>
                <span className={`asset-status ${asset.status.toLowerCase()}`}>
                  {asset.status}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

// Main App Component
const App: React.FC = () => {
  const [mcpClient] = useState(new MCPClient());
  const [systemStatus, setSystemStatus] = useState<{[key: string]: 'healthy' | 'unhealthy'}>({
    employee: 'unhealthy',
    asset: 'unhealthy',
    email: 'unhealthy'
  });
  const [processing, setProcessing] = useState(false);
  const [workflowResult, setWorkflowResult] = useState<WorkflowResult | null>(null);
  const [employees, setEmployees] = useState<EmployeeRecord[]>([]);

  useEffect(() => {
    checkSystemHealth();
    loadEmployees();
  }, []);

  const checkSystemHealth = async () => {
    try {
      const health = await mcpClient.checkHealth();
      setSystemStatus(health);
    } catch (error) {
      console.error('Health check failed:', error);
    }
  };

  const loadEmployees = async () => {
    try {
      const employeeList = await mcpClient.getEmployees();
      setEmployees(employeeList);
    } catch (error) {
      console.error('Failed to load employees:', error);
    }
  };

  const handleEmployeeSubmit = async (employeeData: EmployeeData) => {
    setProcessing(true);
    setWorkflowResult(null);
    
    try {
      const result = await mcpClient.processEmployeeOnboarding(employeeData);
      setWorkflowResult(result);
      await loadEmployees(); // Refresh employee list
    } catch (error) {
      console.error('Onboarding failed:', error);
      setWorkflowResult({
        success: false,
        message: 'Onboarding process failed. Please try again.',
        steps: [
          { title: 'Employee Profile', status: 'error' },
          { title: 'Asset Allocation', status: 'pending' },
          { title: 'Email Notification', status: 'pending' }
        ]
      });
    } finally {
      setProcessing(false);
    }
  };

  return (
    <div className="app">
      <header className="app-header">
        <h1>🏢 Employee Onboarding System</h1>
        <p>Automated MCP-powered employee onboarding workflow</p>
      </header>

      <div className="system-status">
        <h2>System Status</h2>
        <div className="status-grid">
          <StatusCard 
            icon="👤" 
            title="Employee Service" 
            status={systemStatus.employee} 
          />
          <StatusCard 
            icon="💻" 
            title="Asset Service" 
            status={systemStatus.asset} 
          />
          <StatusCard 
            icon="📧" 
            title="Email Service" 
            status={systemStatus.email} 
          />
        </div>
      </div>

      <div className="main-content">
        <div className="left-panel">
          <EmployeeForm onSubmit={handleEmployeeSubmit} processing={processing} />
        </div>
        
        <div className="right-panel">
          <WorkflowStatus result={workflowResult} />
          
          {employees.length > 0 && (
            <div className="employee-list">
              <h3>Recent Employees</h3>
              <div className="employee-cards">
                {employees.slice(0, 5).map(employee => (
                  <div key={employee.id} className="employee-card">
                    <h4>{employee.firstName} {employee.lastName}</h4>
                    <p>{employee.department} • {employee.position}</p>
                    <span className={`status-badge ${employee.status.toLowerCase()}`}>
                      {employee.status}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default App;
