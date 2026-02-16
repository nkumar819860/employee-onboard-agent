#!/usr/bin/env python3
"""
Web UI for MCP Employee Onboarding Client
Modern Flask web application with NLP-powered employee onboarding interface
"""

from flask import Flask, render_template, request, jsonify, session
from flask_socketio import SocketIO, emit
import json
import asyncio
import uuid
import re
from datetime import datetime
from typing import Dict, List, Any
import threading
import time

app = Flask(__name__)
app.config['SECRET_KEY'] = 'mcp-onboarding-secret-key-2024'
socketio = SocketIO(app, cors_allowed_origins="*")

class MCPClientUI:
    """MCP Client backend for the web UI"""
    
    def __init__(self):
        self.active_sessions = {}
        self.conversation_history = []
        self.simulated_employees = []
        self.simulated_assets = []
        
        # Enhanced NLP patterns
        self.nlp_patterns = {
            "email": r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
            "name": r'\b([A-Za-z]+(?:\s+[A-Za-z]+)+)(?=,|,\s*[\w._%+-]+@)',
            "single_name": r'(?:employee|onboard|add|create|process).*?([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)',
            "role": r'\b(?:as|for|role)\s+([a-zA-Z]+)(?:\s|$|,)',
            "department": r'\b(?:in|department|dept)\s+([a-zA-Z]+)(?:\s|$|,)'
        }
    
    def extract_employee_data_nlp(self, text: str) -> Dict[str, Any]:
        """Enhanced NLP extraction for employee information"""
        extracted = {
            "name": None,
            "email": None,
            "role": "employee",
            "department": "general",
            "confidence": 0.0
        }
        
        # Extract email
        email_match = re.search(self.nlp_patterns["email"], text, re.IGNORECASE)
        if email_match:
            extracted["email"] = email_match.group()
            extracted["confidence"] += 0.4
            
        # Try enhanced name extraction
        name_match = re.search(self.nlp_patterns["name"], text, re.IGNORECASE)
        if name_match:
            extracted["name"] = name_match.group(1).strip()
            extracted["confidence"] += 0.3
        else:
            # Fallback to single name extraction
            single_name_match = re.search(self.nlp_patterns["single_name"], text, re.IGNORECASE)
            if single_name_match:
                extracted["name"] = single_name_match.group(1).strip()
                extracted["confidence"] += 0.25
                
        # Extract role
        role_match = re.search(self.nlp_patterns["role"], text, re.IGNORECASE)
        if role_match:
            role = role_match.group(1).strip().lower()
            if role in ["developer", "manager", "intern", "executive", "admin"]:
                extracted["role"] = role
                extracted["confidence"] += 0.2
                
        # Extract department
        dept_match = re.search(self.nlp_patterns["department"], text, re.IGNORECASE)
        if dept_match:
            extracted["department"] = dept_match.group(1).strip()
            extracted["confidence"] += 0.1
            
        return extracted
    
    def simulate_mcp_workflow(self, employee_data: Dict[str, Any]) -> Dict[str, Any]:
        """Simulate complete MCP workflow"""
        workflow_id = str(uuid.uuid4())
        
        # Step 1: Create employee record
        emp_id = len(self.simulated_employees) + 1
        employee_record = {
            "id": emp_id,
            "name": employee_data["name"],
            "email": employee_data["email"],
            "role": employee_data["role"],
            "department": employee_data["department"],
            "status": "active",
            "created_at": datetime.now().isoformat()
        }
        self.simulated_employees.append(employee_record)
        
        # Step 2: Allocate assets
        role = employee_data["role"]
        asset_templates = {
            "employee": ["laptop", "ID_card", "welcome_bag", "access_card"],
            "manager": ["laptop", "ID_card", "welcome_bag", "access_card", "parking_pass", "mobile_phone"],
            "intern": ["laptop", "ID_card", "temporary_badge"],
            "executive": ["laptop", "ID_card", "welcome_bag", "access_card", "parking_pass", "mobile_phone", "company_car"],
            "developer": ["laptop", "ID_card", "welcome_bag", "access_card", "development_tools"]
        }
        
        assets = asset_templates.get(role, asset_templates["employee"])
        allocated_assets = []
        total_cost = 0
        
        for asset in assets:
            cost = 1200 if "laptop" in asset else 800 if "phone" in asset else 50 if "bag" in asset else 25
            asset_record = {
                "asset_id": str(uuid.uuid4()),
                "emp_id": emp_id,
                "type": asset,
                "cost": cost,
                "status": "allocated",
                "delivery_date": "2026-02-18" if "laptop" in asset else "2026-02-17"
            }
            allocated_assets.append(asset_record)
            total_cost += cost
        
        self.simulated_assets.extend(allocated_assets)
        
        # Step 3: Send notifications
        notifications = [
            {"channel": "email", "recipient": employee_data["email"], "status": "sent"},
            {"channel": "sms", "recipient": "+1234567890", "status": "sent"},
            {"channel": "slack", "recipient": f"@{employee_data['name'].lower().replace(' ', '')}", "status": "sent"}
        ]
        
        workflow_result = {
            "workflow_id": workflow_id,
            "status": "completed",
            "employee": employee_record,
            "assets": allocated_assets,
            "total_cost": total_cost,
            "notifications": notifications,
            "completion_time": datetime.now().isoformat(),
            "steps": [
                {"step": 1, "service": "postgres-mcp", "action": "create_employee", "status": "success"},
                {"step": 2, "service": "assets-mcp", "action": "allocate_assets", "status": "success"},
                {"step": 3, "service": "notifications-mcp", "action": "send_welcome", "status": "success"}
            ]
        }
        
        return workflow_result

# Initialize MCP client
mcp_client = MCPClientUI()

@app.route('/')
def index():
    """Main UI page"""
    return render_template('index.html')

@app.route('/api/health')
def health_check():
    """API health check endpoint"""
    return jsonify({
        "status": "healthy",
        "services": {
            "postgres-mcp": "healthy",
            "assets-mcp": "healthy", 
            "notifications-mcp": "healthy"
        },
        "timestamp": datetime.now().isoformat()
    })

@app.route('/api/onboard', methods=['POST'])
def onboard_employee():
    """Process employee onboarding via API"""
    try:
        data = request.get_json()
        natural_language_input = data.get('input', '')
        
        if not natural_language_input:
            return jsonify({
                "success": False,
                "error": "No input provided"
            }), 400
        
        # Extract employee data using NLP
        employee_data = mcp_client.extract_employee_data_nlp(natural_language_input)
        
        if not employee_data["name"] or not employee_data["email"]:
            return jsonify({
                "success": False,
                "error": "Could not extract required employee information (name and email)",
                "extracted_data": employee_data
            }), 400
        
        # Process workflow
        workflow_result = mcp_client.simulate_mcp_workflow(employee_data)
        workflow_result["extracted_data"] = employee_data
        
        # Store in conversation history
        mcp_client.conversation_history.append({
            "timestamp": datetime.now().isoformat(),
            "input": natural_language_input,
            "workflow": workflow_result
        })
        
        return jsonify({
            "success": True,
            "result": workflow_result
        })
        
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

@app.route('/api/employees')
def get_employees():
    """Get all employees"""
    return jsonify({
        "employees": mcp_client.simulated_employees,
        "total": len(mcp_client.simulated_employees)
    })

@app.route('/api/assets')
def get_assets():
    """Get all assets"""
    return jsonify({
        "assets": mcp_client.simulated_assets,
        "total": len(mcp_client.simulated_assets),
        "total_cost": sum(asset.get("cost", 0) for asset in mcp_client.simulated_assets)
    })

@app.route('/api/history')
def get_conversation_history():
    """Get conversation history"""
    return jsonify({
        "history": mcp_client.conversation_history,
        "total": len(mcp_client.conversation_history)
    })

@socketio.on('connect')
def handle_connect():
    """Handle WebSocket connection"""
    session_id = str(uuid.uuid4())
    session['session_id'] = session_id
    mcp_client.active_sessions[session_id] = {
        "connected_at": datetime.now().isoformat(),
        "status": "active"
    }
    emit('connected', {
        "session_id": session_id,
        "message": "Connected to MCP Employee Onboarding System"
    })

@socketio.on('disconnect')
def handle_disconnect():
    """Handle WebSocket disconnection"""
    session_id = session.get('session_id')
    if session_id in mcp_client.active_sessions:
        del mcp_client.active_sessions[session_id]

@socketio.on('onboard_employee')
def handle_onboard_employee(data):
    """Handle real-time employee onboarding via WebSocket"""
    try:
        natural_language_input = data.get('input', '')
        
        # Emit processing started
        emit('onboarding_status', {
            "status": "processing",
            "message": "Processing natural language input with NLP..."
        })
        
        # Extract employee data
        employee_data = mcp_client.extract_employee_data_nlp(natural_language_input)
        
        emit('onboarding_status', {
            "status": "nlp_complete",
            "message": "NLP extraction completed",
            "extracted_data": employee_data
        })
        
        if not employee_data["name"] or not employee_data["email"]:
            emit('onboarding_error', {
                "error": "Could not extract required employee information",
                "extracted_data": employee_data
            })
            return
        
        # Simulate workflow steps with real-time updates
        emit('onboarding_status', {
            "status": "step_1",
            "message": "Creating employee record in database..."
        })
        time.sleep(1)  # Simulate processing time
        
        emit('onboarding_status', {
            "status": "step_2", 
            "message": "Allocating role-based assets..."
        })
        time.sleep(1)
        
        emit('onboarding_status', {
            "status": "step_3",
            "message": "Sending welcome notifications..."
        })
        time.sleep(1)
        
        # Complete workflow
        workflow_result = mcp_client.simulate_mcp_workflow(employee_data)
        workflow_result["extracted_data"] = employee_data
        
        emit('onboarding_complete', {
            "success": True,
            "result": workflow_result
        })
        
        # Store in conversation history
        mcp_client.conversation_history.append({
            "timestamp": datetime.now().isoformat(),
            "input": natural_language_input,
            "workflow": workflow_result
        })
        
    except Exception as e:
        emit('onboarding_error', {
            "error": str(e)
        })

if __name__ == '__main__':
    print("🌐 Starting MCP Employee Onboarding Web UI...")
    print("📱 Access the application at: http://localhost:5000")
    print("🔧 Features: NLP Processing, Real-time Updates, MCP Integration")
    socketio.run(app, debug=True, host='0.0.0.0', port=5000)
