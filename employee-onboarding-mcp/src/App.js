import React, { useState, useEffect } from 'react';
import './App.css';

// MCP Client Configuration
const MCP_BASE_URL = process.env.REACT_APP_MCP_URL || 'http://localhost:8081';

function App() {
  const [prompt, setPrompt] = useState('');
  const [responses, setResponses] = useState([]);
  const [loading, setLoading] = useState(false);
  const [activeTab, setActiveTab] = useState('onboarding');
  const [employees, setEmployees] = useState([]);
  const [mcpConnected, setMcpConnected] = useState(false);

  // Check MCP connection on component mount
  useEffect(() => {
    checkMcpConnection();
    loadEmployees();
  }, []);

  const checkMcpConnection = async () => {
    try {
      const response = await fetch(`${MCP_BASE_URL}/health`);
      setMcpConnected(response.ok);
    } catch (error) {
      console.error('MCP connection failed:', error);
      setMcpConnected(false);
    }
  };

  const loadEmployees = async () => {
    try {
      const response = await fetch(`${MCP_BASE_URL}/listEmployees`);
      if (response.ok) {
        const data = await response.json();
        setEmployees(data.employees || []);
      }
    } catch (error) {
      console.error('Failed to load employees:', error);
    }
  };

  const callMcpEndpoint = async (endpoint, payload) => {
    try {
      const response = await fetch(`${MCP_BASE_URL}${endpoint}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      return await response.json();
    } catch (error) {
      console.error(`MCP call failed for ${endpoint}:`, error);
      throw error;
    }
  };

  // Sample onboarding questions
  const sampleQuestions = [
    "What department will the new employee be joining?",
    "What is the employee's job title and responsibilities?",
    "What equipment and access permissions does the employee need?",
    "Who should be notified about the new hire?",
    "What training programs should the employee complete?",
    "What is the employee's start date and work schedule?"
  ];

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!prompt.trim()) return;

    setLoading(true);
    
    try {
      // Call the real MCP NLP processing endpoint
      const response = await callMcpEndpoint('/processOnboardingRequest', {
        prompt: prompt,
        timestamp: new Date().toISOString(),
        requestId: `REQ-${Date.now()}`
      });
      
      const newResponse = {
        id: Date.now(),
        prompt: prompt,
        timestamp: new Date().toLocaleString(),
        response: response.summary || 'Processing completed successfully.',
        mcpResponse: response,
        trackingId: response.trackingId,
        extractedEntities: response.processedRequest?.extractedEntities
      };
      
      setResponses(prev => [newResponse, ...prev]);
      setPrompt('');
      
      // Reload employees list to show any new entries
      await loadEmployees();
      
    } catch (error) {
      console.error('MCP processing failed:', error);
      
      // Fall back to mock response if MCP call fails
      const newResponse = {
        id: Date.now(),
        prompt: prompt,
        timestamp: new Date().toLocaleString(),
        response: generateMockResponse(prompt) + '\n\n⚠️ Note: Using mock response (MCP server unavailable)',
        isMockResponse: true
      };
      
      setResponses(prev => [newResponse, ...prev]);
      setPrompt('');
    } finally {
      setLoading(false);
    }
  };

  const generateMockResponse = (userPrompt) => {
    // Mock aggregated response based on prompt content
    const responses = {
      department: {
        hr: "HR Department onboarding checklist activated. Documentation preparation in progress.",
        it: "IT Department setup initiated. Equipment allocation and system access requests submitted.",
        sales: "Sales Department onboarding protocol engaged. CRM access and training schedule prepared.",
        marketing: "Marketing Department integration started. Brand guidelines and campaign access configured."
      },
      equipment: {
        laptop: "Laptop allocation: Dell Latitude 7420 assigned. IT setup scheduled for day 1.",
        phone: "Mobile device: iPhone 14 Pro allocated. Corporate plan activation in progress.",
        badge: "Security badge generation initiated. Building access permissions configured."
      },
      training: {
        safety: "Safety training modules assigned. Completion required within first week.",
        compliance: "Compliance training scheduled. Legal and regulatory requirements identified.",
        technical: "Technical skills assessment completed. Role-specific training path determined."
      }
    };

    const lowerPrompt = userPrompt.toLowerCase();
    
    if (lowerPrompt.includes('department') || lowerPrompt.includes('team')) {
      if (lowerPrompt.includes('hr')) return responses.department.hr;
      if (lowerPrompt.includes('it') || lowerPrompt.includes('technology')) return responses.department.it;
      if (lowerPrompt.includes('sales')) return responses.department.sales;
      if (lowerPrompt.includes('marketing')) return responses.department.marketing;
    }
    
    if (lowerPrompt.includes('equipment') || lowerPrompt.includes('laptop') || lowerPrompt.includes('computer')) {
      return responses.equipment.laptop;
    }
    
    if (lowerPrompt.includes('phone') || lowerPrompt.includes('mobile')) {
      return responses.equipment.phone;
    }
    
    if (lowerPrompt.includes('training') || lowerPrompt.includes('learning')) {
      return responses.training.technical;
    }

    // Default aggregated response
    return `Onboarding request processed successfully. The following systems have been notified:
    
    ✅ HR Information System - Employee profile created
    ✅ IT Asset Management - Equipment allocation initiated  
    ✅ Security System - Badge and access permissions configured
    ✅ Payroll System - Employee setup scheduled
    ✅ Learning Management - Training modules assigned
    ✅ Email Notification - Stakeholders informed
    
    Estimated completion: 2-3 business days. Tracking ID: ONB-${Date.now().toString().slice(-6)}`;
  };

  const clearHistory = () => {
    setResponses([]);
  };

  return (
    <div className="App">
      <header className="app-header">
        <div className="header-content">
          <h1>🏢 Employee Onboarding System</h1>
          <p>Intelligent automation for seamless employee integration</p>
        </div>
      </header>

      <nav className="tab-navigation">
        <button 
          className={`tab ${activeTab === 'onboarding' ? 'active' : ''}`}
          onClick={() => setActiveTab('onboarding')}
        >
          📝 New Onboarding
        </button>
        <button 
          className={`tab ${activeTab === 'history' ? 'active' : ''}`}
          onClick={() => setActiveTab('history')}
        >
          📋 History ({responses.length})
        </button>
      </nav>

      <main className="main-content">
        {activeTab === 'onboarding' && (
          <div className="onboarding-section">
            <div className="prompt-section">
              <h2>Employee Onboarding Request</h2>
              <p>Describe your onboarding requirements and let our system coordinate across all departments:</p>
              
              <form onSubmit={handleSubmit} className="prompt-form">
                <div className="input-group">
                  <textarea
                    value={prompt}
                    onChange={(e) => setPrompt(e.target.value)}
                    placeholder="Example: I need to onboard a new Software Engineer in the IT department starting Monday. They'll need a laptop, development environment access, and technical training..."
                    rows="4"
                    className="prompt-input"
                    disabled={loading}
                  />
                  <button 
                    type="submit" 
                    className="submit-btn"
                    disabled={loading || !prompt.trim()}
                  >
                    {loading ? '⏳ Processing...' : '🚀 Submit Request'}
                  </button>
                </div>
              </form>

              <div className="sample-questions">
                <h3>💡 Sample Questions:</h3>
                <div className="questions-grid">
                  {sampleQuestions.map((question, index) => (
                    <button
                      key={index}
                      className="sample-question"
                      onClick={() => setPrompt(question)}
                      disabled={loading}
                    >
                      {question}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {responses.length > 0 && (
              <div className="latest-response">
                <h3>🎯 Latest Response:</h3>
                <div className="response-card latest">
                  <div className="response-header">
                    <span className="timestamp">{responses[0].timestamp}</span>
                    <span className="status success">✅ Completed</span>
                  </div>
                  <div className="response-prompt">
                    <strong>Request:</strong> {responses[0].prompt}
                  </div>
                  <div className="response-content">
                    <strong>Aggregated Response:</strong>
                    <pre>{responses[0].response}</pre>
                  </div>
                </div>
              </div>
            )}
          </div>
        )}

        {activeTab === 'history' && (
          <div className="history-section">
            <div className="history-header">
              <h2>📋 Onboarding History</h2>
              {responses.length > 0 && (
                <button onClick={clearHistory} className="clear-btn">
                  🗑️ Clear History
                </button>
              )}
            </div>

            {responses.length === 0 ? (
              <div className="empty-state">
                <p>No onboarding requests yet. Submit your first request to get started!</p>
              </div>
            ) : (
              <div className="responses-list">
                {responses.map((response) => (
                  <div key={response.id} className="response-card">
                    <div className="response-header">
                      <span className="timestamp">{response.timestamp}</span>
                      <span className="status success">✅ Processed</span>
                    </div>
                    <div className="response-prompt">
                      <strong>Request:</strong> {response.prompt}
                    </div>
                    <div className="response-content">
                      <strong>Aggregated Response:</strong>
                      <pre>{response.response}</pre>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </main>

      <footer className="app-footer">
        <p>🤖 Powered by Agent Fabric - Intelligent Employee Onboarding Automation</p>
      </footer>
    </div>
  );
}

export default App;
