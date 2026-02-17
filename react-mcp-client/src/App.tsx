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
  currentStep: ProcessingStatus;
  progress: number;
}

interface NLPResultsProps {
  employeeData: EmployeeData | null;
}

interface WorkflowResultsProps {
  workflowResult: WorkflowResult | null;
}

// Status Card Component
const StatusCard: React.FC<StatusCardProps> = ({ icon, title, status }) => (
  <div className="col-md-4 mb-3">
    <div className="card status-card text-center">
      <div className="card-body">
        <div className={`text-${status === 'healthy' ? 'success' : 'danger'} mb-2`}>
          <i className={`fas ${icon} fa-2x`}></i>
        </div>
        <h6>{title}</h6>
        <span className={`badge bg-${status === 'healthy' ? 'success' : 'danger'}`}>
          {status === 'healthy' ? 'Healthy' : 'Unhealthy'}
        </span>
      </div>
    </div>
  </div>
);

// Step Indicator Component
const StepIndicator: React.FC<StepIndicatorProps> = ({ currentStep, progress }) => {
  const getStepClass = (step: number): string => {
    if (currentStep === 'completed') return 'step-completed';
    if ((currentStep === 'processing' && step === 1) ||
        (currentStep === 'nlp_complete' && step === 1) ||
        (currentStep === 'step_1' && step === 2) ||
        (currentStep === 'step_2' && step === 3) ||
        (currentStep === 'step_3' && step === 4)) {
      return 'step-active';
    }
    if ((currentStep === 'nlp_complete' && step === 1) ||
        (currentStep === 'step_1' && step === 1) ||
        (currentStep === 'step_2' && step <= 2) ||
        (currentStep === 'step_3' && step <= 3) ||
        (currentStep === 'completed' && step <= 4)) {
      return 'step-completed';
    }
    return 'step-inactive';
  };

  return (
    <div className="step-indicator">
      <div className="step">
        <div className={`step-icon ${getStepClass(1)}`}>
          <i className="fas fa-brain"></i>
        </div>
        <small>NLP Processing</small>
      </div>
      <div className="step">
        <div className={`step-icon ${getStepClass(2)}`}>
          <i className="fas fa-database"></i>
        </div>
        <small>Create Employee</small>
      </div>
      <div className="step">
        <div className={`step-icon ${getStepClass(3)}`}>
          <i className="fas fa-box"></i>
        </div>
        <small>Allocate Assets</small>
      </div>
      <div className="step">
        <div className={`step-icon ${getStepClass(4)}`}>
          <i className="fas fa-bell"></i>
        </div>
        <small>Send Notifications</small>
      </div>
    </div>
  );
};

// NLP Results Component
const NLPResults: React.FC<NLPResultsProps> = ({ employeeData }) => {
  if (!employeeData) return null;

  const confidencePercent = Math.round(employeeData.confidence * 100);

  return (
    <div className="card mb-4">
      <div className="card-header">
        <h6><i className="fas fa-brain"></i> NLP Extraction Results</h6>
      </div>
      <div className="card-body">
        <div className="mb-3">
          <strong>Name:</strong> {employeeData.name || 'Not extracted'}<br />
          <strong>Email:</strong> {employeeData.email || 'Not extracted'}<br />
          <strong>Role:</strong> {employeeData.role}<br />
          <strong>Department:</strong> {employeeData.department}
        </div>
        <div className="mb-2">
          <strong>Confidence Score:</strong> {confidencePercent}%
        </div>
        <div className="confidence-bar">
          <div className="confidence-fill" style={{ width: `${confidencePercent}%` }}></div>
        </div>
      </div>
    </div>
  );
};

// Workflow Results Component
const WorkflowResults: React.FC<WorkflowResultsProps> = ({ workflowResult }) => {
  if (!workflowResult || !workflowResult.overall_success) return null;

  const employee = workflowResult.extracted_data;
  const postgresStep = workflowResult.steps.find(s => s.service === 'postgres-mcp');
  const assetsStep = workflowResult.steps.find(s => s.service === 'assets-mcp');
  const notificationStep = workflowResult.steps.find(s => s.service === 'notifications-mcp');

  return (
    <div className="row">
      <div className="col-md-6 mb-4">
        <div className="card">
          <div className="card-header">
            <h6><i className="fas fa-user"></i> Employee Record</h6>
          </div>
          <div className="card-body">
            <div className="employee-card">
              <h6><i className="fas fa-user"></i> {employee.name}</h6>
              <p className="mb-1"><strong>ID:</strong> {workflowResult.employee_id}</p>
              <p className="mb-1"><strong>Email:</strong> {employee.email}</p>
              <p className="mb-1"><strong>Role:</strong> {employee.role}</p>
              <p className="mb-0"><strong>Department:</strong> {employee.department}</p>
            </div>
          </div>
        </div>
      </div>

      <div className="col-md-6 mb-4">
        <div className="card">
          <div className="card-header">
            <h6><i className="fas fa-box"></i> Assets Allocated</h6>
          </div>
          <div className="card-body">
            {assetsStep?.result?.result?.assets_allocated && (
              <>
                <div className="mb-2">
                  <strong>Total Cost: ${assetsStep.result.result.total_cost}</strong>
                </div>
                {assetsStep.result.result.assets_allocated.map((asset: Asset, index: number) => (
                  <div key={index} className="asset-item">
                    <strong>{asset.type.replace('_', ' ').toUpperCase()}</strong> - ${asset.cost}
                    {asset.delivery_date && (
                      <small className="text-muted d-block">Delivery: {asset.delivery_date}</small>
                    )}
                  </div>
                ))}
              </>
            )}
          </div>
        </div>
      </div>

      <div className="col-md-12 mb-4">
        <div className="card">
          <div className="card-header">
            <h6><i className="fas fa-bell"></i> Notifications Sent</h6>
          </div>
          <div className="card-body">
            {notificationStep?.result?.result?.notifications && (
              <>
                {notificationStep.result.result.notifications.map((notification: any, index: number) => (
                  <div key={index} className="notification-item">
                    <i className={`fas fa-${notification.channel === 'email' ? 'envelope' :
                      notification.channel === 'sms' ? 'mobile-alt' : 'slack'}`}></i>
                    <strong>{notification.channel.toUpperCase()}</strong>: {notification.recipient}
                    <span className={`badge bg-${notification.status === 'sent' ? 'success' : 'danger'} ms-2`}>
                      {notification.status}
                    </span>
                  </div>
                ))}
                {notificationStep.result.result.welcome_message && (
                  <div className="mt-3">
                    <strong>Welcome Message:</strong>
                    <pre className="small mt-2" style={{ whiteSpace: 'pre-wrap', background: '#f8f9fa', padding: '1rem', borderRadius: '0.5rem' }}>
                      {notificationStep.result.result.welcome_message}
                    </pre>
                  </div>
                )}
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

// Main App Component
const App: React.FC = () => {
  const [mcpClient] = useState(new MCPClient());
  const [nlpInput, setNlpInput] = useState('');
  const [isProcessing, setIsProcessing] = useState(false);
  const [currentStep, setCurrentStep] = useState<ProcessingStatus>('idle');
  const [progress, setProgress] = useState(0);
  const [statusMessage, setStatusMessage] = useState('Ready to process...');
  const [extractedData, setExtractedData] = useState<EmployeeData | null>(null);
  const [workflowResult, setWorkflowResult] = useState<WorkflowResult | null>(null);
  const [showResults, setShowResults] = useState(false);
  const [employees, setEmployees] = useState<EmployeeRecord[]>([]);
  const [assets, setAssets] = useState<Asset[]>([]);
  const [metrics, setMetrics] = useState({
    totalEmployees: 0,
    totalAssets: 0,
    totalCost: 0,
    avgProcessingTime: 0,
    successRate: 100
  });

  // Initialize MCP session and load existing data on component mount
  useEffect(() => {
    const initializeSession = async () => {
      try {
        await mcpClient.createSession();
        console.log('MCP Session initialized successfully');
        
        // Load existing data
        const existingEmployees = mcpClient.getSimulatedEmployees();
        const existingAssets = mcpClient.getSimulatedAssets();
        
        setEmployees(existingEmployees);
        setAssets(existingAssets);
        
      } catch (error) {
        console.error('Failed to initialize MCP session:', error);
      }
    };

    initializeSession();
  }, [mcpClient]);

  // Update metrics whenever employees or assets change
  useEffect(() => {
    setMetrics({
      totalEmployees: employees.length,
      totalAssets: assets.length,
      totalCost: assets.reduce((sum, asset) => sum + asset.cost, 0),
      avgProcessingTime: 2, // Mock average time
      successRate: 100
    });
  }, [employees, assets]);

  const handleProgressUpdate = (status: string, message: string, data?: any) => {
    setStatusMessage(message);
    
    switch (status) {
      case 'processing':
        setCurrentStep('processing');
        setProgress(10);
        break;
      case 'nlp_complete':
        setCurrentStep('nlp_complete');
        setProgress(25);
        if (data) setExtractedData(data);
        break;
      case 'step_1':
        setCurrentStep('step_1');
        setProgress(50);
        break;
      case 'step_2':
        setCurrentStep('step_2');
        setProgress(75);
        break;
      case 'step_3':
        setCurrentStep('step_3');
        setProgress(90);
        break;
      default:
        break;
    }
  };

  const handleProcessOnboarding = async () => {
    if (!nlpInput.trim()) {
      alert('Please enter an onboarding request.');
      return;
    }

    if (isProcessing) return;

    setIsProcessing(true);
    setShowResults(false);
    setExtractedData(null);
    setWorkflowResult(null);
    setCurrentStep('processing');
    setProgress(0);

    try {
      const result = await mcpClient.onboardEmployeeNLP(nlpInput, handleProgressUpdate);

      if (result.overall_success) {
        setWorkflowResult(result);
        setCurrentStep('completed');
        setProgress(100);
        setStatusMessage('Onboarding completed successfully!');
        setShowResults(true);
        
        // Update dashboard data
        setEmployees(mcpClient.getSimulatedEmployees());
        setAssets(mcpClient.getSimulatedAssets());

        // Reset after showing results
        setTimeout(() => {
          setCurrentStep('idle');
          setProgress(0);
          setStatusMessage('Ready to process...');
        }, 3000);
      } else {
        setCurrentStep('error');
        setStatusMessage(`Error: ${result.error}`);
        setTimeout(() => {
          setCurrentStep('idle');
          setStatusMessage('Ready to process...');
        }, 3000);
      }
    } catch (error) {
      console.error('Onboarding error:', error);
      setCurrentStep('error');
      setStatusMessage('An error occurred during processing');
      setTimeout(() => {
        setCurrentStep('idle');
        setStatusMessage('Ready to process...');
      }, 3000);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleClearForm = () => {
    setNlpInput('');
    setShowResults(false);
    setExtractedData(null);
    setWorkflowResult(null);
    setCurrentStep('idle');
    setProgress(0);
    setStatusMessage('Ready to process...');
  };

  const handleClearData = () => {
    mcpClient.clearSimulatedData();
    setEmployees([]);
    setAssets([]);
    setShowResults(false);
    setExtractedData(null);
    setWorkflowResult(null);
  };

  return (
    <div className="container">
      <div className="main-container">
        {/* Header */}
        <div className="header-section">
          <h1><i className="fas fa-robot"></i> React MCP Client - Employee Onboarding System</h1>
          <p className="mb-0">AI-Powered Employee Onboarding with Natural Language Processing</p>
          <div className="row mt-3">
            <div className="col-md-4">
              <small><i className="fas fa-brain"></i> NLP Processing</small>
            </div>
            <div className="col-md-4">
              <small><i className="fas fa-cogs"></i> MCP Integration</small>
            </div>
            <div className="col-md-4">
              <small><i className="fas fa-users"></i> Real-time Updates</small>
            </div>
          </div>
        </div>

        {/* Main Content */}
        <div className="p-4">
          {/* Status Cards */}
          <div className="row mb-4">
            <StatusCard icon="fa-database" title="PostgreSQL MCP" status="healthy" />
            <StatusCard icon="fa-box" title="Assets MCP" status="healthy" />
            <StatusCard icon="fa-bell" title="Notifications MCP" status="healthy" />
          </div>

          {/* Metrics Dashboard */}
          <div className="row mb-4">
            <div className="col-md-3">
              <div className="card text-center" style={{background: 'linear-gradient(135deg, #667eea, #764ba2)', color: 'white'}}>
                <div className="card-body">
                  <i className="fas fa-users fa-2x mb-2"></i>
                  <h4 className="mb-0">{employees.length}</h4>
                  <small>Total Employees</small>
                </div>
              </div>
            </div>
            <div className="col-md-3">
              <div className="card text-center" style={{background: 'linear-gradient(135deg, #43cea2, #185a9d)', color: 'white'}}>
                <div className="card-body">
                  <i className="fas fa-box fa-2x mb-2"></i>
                  <h4 className="mb-0">{assets.length}</h4>
                  <small>Assets Allocated</small>
                </div>
              </div>
            </div>
            <div className="col-md-3">
              <div className="card text-center" style={{background: 'linear-gradient(135deg, #f093fb, #f5576c)', color: 'white'}}>
                <div className="card-body">
                  <i className="fas fa-dollar-sign fa-2x mb-2"></i>
                  <h4 className="mb-0">${assets.reduce((sum, asset) => sum + asset.cost, 0)}</h4>
                  <small>Total Cost</small>
                </div>
              </div>
            </div>
            <div className="col-md-3">
              <div className="card text-center" style={{background: 'linear-gradient(135deg, #4facfe, #00f2fe)', color: 'white'}}>
                <div className="card-body">
                  <i className="fas fa-clock fa-2x mb-2"></i>
                  <h4 className="mb-0">~2s</h4>
                  <small>Avg Process Time</small>
                </div>
              </div>
            </div>
          </div>

          {/* NLP Input Section */}
          <div className="card mb-4" style={{border: '2px solid #e3f2fd', background: 'linear-gradient(145deg, #ffffff 0%, #f8f9fa 100%)'}}>
            <div className="card-header" style={{background: 'linear-gradient(45deg, #667eea, #764ba2)', color: 'white', borderRadius: '15px 15px 0 0'}}>
              <h5 className="mb-0"><i className="fas fa-comments"></i> Smart Employee Onboarding Assistant</h5>
              <small>💡 Just type naturally - press Enter to process instantly!</small>
            </div>
            <div className="card-body p-4">
              <div className="mb-3">
                <label htmlFor="nlpInput" className="form-label fw-bold" style={{color: '#495057'}}>
                  🗣️ Describe your onboarding request:
                </label>
                <textarea
                  className="form-control nlp-input"
                  id="nlpInput"
                  rows={4}
                  value={nlpInput}
                  onChange={(e) => setNlpInput(e.target.value)}
                  onKeyPress={(e) => {
                    if (e.key === 'Enter' && !e.shiftKey && !isProcessing && nlpInput.trim()) {
                      e.preventDefault();
                      handleProcessOnboarding();
                    }
                  }}
                  placeholder="🎯 Try: onboard employee John Smith, john.smith@company.com as senior developer in engineering department"
                  style={{
                    fontSize: '1.1rem',
                    fontFamily: 'Poppins, sans-serif',
                    borderRadius: '15px',
                    border: '2px solid #e3f2fd',
                    padding: '1rem 1.25rem',
                    boxShadow: '0 4px 6px rgba(0, 0, 0, 0.05)'
                  }}
                />
                <div className="form-text mt-3 p-3" style={{background: '#f0f9ff', borderRadius: '10px', border: '1px solid #e0f2fe'}}>
                  <div className="row">
                    <div className="col-md-6">
                      <strong style={{color: '#0369a1'}}>✨ Quick Examples:</strong><br />
                      <small>• "onboard Pradeep Kumar, pradeep.n2019@gmail.com as developer"</small><br />
                      <small>• "add Sarah Johnson, sarah@company.com as manager in sales"</small>
                    </div>
                    <div className="col-md-6">
                      <strong style={{color: '#0369a1'}}>🚀 Pro Tips:</strong><br />
                      <small>• Press <kbd>Enter</kbd> to process instantly</small><br />
                      <small>• Use <kbd>Shift+Enter</kbd> for new lines</small>
                    </div>
                  </div>
                </div>
              </div>
              <div className="d-flex justify-content-between align-items-center">
                <button
                  className="btn btn-primary btn-lg"
                  onClick={handleProcessOnboarding}
                  disabled={isProcessing || !nlpInput.trim()}
                  style={{
                    background: 'linear-gradient(45deg, #667eea, #764ba2)',
                    border: 'none',
                    borderRadius: '25px',
                    padding: '0.75rem 2.5rem',
                    fontWeight: '600',
                    fontFamily: 'Poppins, sans-serif',
                    boxShadow: '0 4px 15px rgba(102, 126, 234, 0.3)'
                  }}
                >
                  <i className="fas fa-magic me-2"></i>
                  {isProcessing ? '🔄 Processing...' : '✨ Process Onboarding'}
                </button>
                <div className="d-flex gap-2">
                  <button 
                    className="btn btn-outline-secondary"
                    onClick={handleClearForm}
                    style={{borderRadius: '20px', fontFamily: 'Poppins, sans-serif'}}
                  >
                    <i className="fas fa-eraser me-1"></i> Clear
                  </button>
                  <button 
                    className="btn btn-outline-warning"
                    onClick={handleClearData}
                    style={{borderRadius: '20px', fontFamily: 'Poppins, sans-serif'}}
                  >
                    <i className="fas fa-trash me-1"></i> Reset All
                  </button>
                </div>
              </div>

              {/* Progress Section */}
              {(isProcessing || currentStep !== 'idle') && (
                <div className="mt-4">
                  <StepIndicator currentStep={currentStep} progress={progress} />
                  <div className="progress mb-3">
                    <div
                      className="progress-bar"
                      style={{ width: `${progress}%` }}
                      aria-valuenow={progress}
                      aria-valuemin={0}
                      aria-valuemax={100}
                    ></div>
                  </div>
                  <div className="text-center">
                    <small>{statusMessage}</small>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* NLP Results */}
          <NLPResults employeeData={extractedData} />

          {/* Results Section */}
          {showResults && (
            <div className="mb-4">
              <WorkflowResults workflowResult={workflowResult} />
            </div>
          )}

          {/* Dashboard Section */}
          <div className="card">
            <div className="card-header">
              <ul className="nav nav-tabs card-header-tabs dashboard-tabs" id="dashboardTabs">
                <li className="nav-item">
                  <a className="nav-link active" data-bs-toggle="tab" href="#employees">
                    <i className="fas fa-users"></i> Employees ({employees.length})
                  </a>
                </li>
                <li className="nav-item">
                  <a className="nav-link" data-bs-toggle="tab" href="#assets">
                    <i className="fas fa-box"></i> Assets ({assets.length})
                  </a>
                </li>
              </ul>
            </div>
            <div className="card-body">
              <div className="tab-content">
                <div className="tab-pane fade show active" id="employees">
                  {employees.length === 0 ? (
                    <div className="text-center text-muted">
                      <i className="fas fa-users fa-3x mb-3"></i>
                      <p>No employees onboarded yet. Use the form above to get started!</p>
                    </div>
                  ) : (
                    employees.map((emp) => (
                      <div key={emp.id} className="card mb-2">
                        <div className="card-body">
                          <h6>{emp.name}</h6>
                          <p className="mb-1">Email: {emp.email}</p>
                          <p className="mb-0">Role: {emp.role} | Department: {emp.department}</p>
                          <small className="text-muted">Created: {new Date(emp.created_at).toLocaleString()}</small>
                        </div>
                      </div>
                    ))
                  )}
                </div>
                <div className="tab-pane fade" id="assets">
                  {assets.length === 0 ? (
                    <div className="text-center text-muted">
                      <i className="fas fa-box fa-3x mb-3"></i>
                      <p>No assets allocated yet.</p>
                    </div>
                  ) : (
                    assets.map((asset) => (
                      <div key={asset.asset_id} className="asset-item">
                        {asset.type.replace('_', ' ').toUpperCase()} - ${asset.cost}
                        <small className="text-muted d-block">
                          Employee ID: {asset.emp_id}
                          {asset.delivery_date && ` | Delivery: ${asset.delivery_date}`}
                        </small>
                      </div>
                    ))
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default App;
