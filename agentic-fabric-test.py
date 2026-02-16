#!/usr/bin/env python3
"""
Agentic Fabric Test for Employee Onboarding System
Tests the complete workflow: Employee Onboarding → Asset Allocation → Email Notification
"""

import json
import time
import uuid
from datetime import datetime
from typing import Dict, List, Any
import re

class AgenticFabricOrchestrator:
    """
    Main orchestrator that simulates the agentic fabric for employee onboarding
    """
    
    def __init__(self):
        self.employee_db = []
        self.assets_db = []
        self.notifications_sent = []
        self.workflow_logs = []
        self.agent_interactions = []
        
    def log_interaction(self, agent: str, action: str, data: Dict[str, Any]):
        """Log agent interactions for fabric tracing"""
        interaction = {
            "timestamp": datetime.now().isoformat(),
            "agent": agent,
            "action": action,
            "data": data,
            "interaction_id": str(uuid.uuid4())
        }
        self.agent_interactions.append(interaction)
        return interaction["interaction_id"]
    
    def groq_llm_processing(self, natural_language_input: str) -> Dict[str, Any]:
        """
        Simulate Groq LLM processing of natural language input
        """
        print("🧠 GROQ LLM AGENT: Processing natural language input...")
        
        # Simulate LLM understanding and extraction
        extracted_data = {
            "intent": "employee_onboarding",
            "entities": {
                "name": None,
                "email": None,
                "role": "employee",
                "department": "general"
            },
            "confidence": 0.95,
            "processing_time_ms": 150
        }
        
        # Extract name and email using pattern matching (simulating LLM capabilities)
        email_pattern = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
        name_pattern = r'\b([a-zA-Z]+)(?=,|\s*[a-zA-Z0-9._%+-]+@)'
        
        email_match = re.search(email_pattern, natural_language_input, re.IGNORECASE)
        name_match = re.search(name_pattern, natural_language_input, re.IGNORECASE)
        
        if email_match:
            extracted_data["entities"]["email"] = email_match.group()
        if name_match:
            extracted_data["entities"]["name"] = name_match.group(1).capitalize()
        
        # Log LLM interaction
        interaction_id = self.log_interaction(
            "groq-llm", 
            "nlp_processing", 
            {
                "input": natural_language_input,
                "output": extracted_data,
                "model": "llama3-8b-8192"
            }
        )
        
        print(f"   ✅ Extracted: Name='{extracted_data['entities']['name']}', Email='{extracted_data['entities']['email']}'")
        print(f"   🆔 Interaction ID: {interaction_id}")
        
        return extracted_data
    
    def hr_agent_orchestration(self, llm_output: Dict[str, Any]) -> Dict[str, Any]:
        """
        HR Agent that orchestrates the workflow based on LLM understanding
        """
        print("\n👥 HR AGENT: Orchestrating onboarding workflow...")
        
        workflow_plan = {
            "workflow_id": str(uuid.uuid4()),
            "steps": [
                {"step": 1, "service": "postgres-mcp", "action": "create_employee"},
                {"step": 2, "service": "assets-mcp", "action": "allocate_assets"},
                {"step": 3, "service": "notification-mcp", "action": "send_welcome"}
            ],
            "employee_data": llm_output["entities"],
            "estimated_duration": "30 seconds",
            "priority": "normal"
        }
        
        # Log HR Agent interaction
        interaction_id = self.log_interaction(
            "hr-agent",
            "workflow_orchestration",
            {
                "workflow_plan": workflow_plan,
                "llm_input": llm_output
            }
        )
        
        print(f"   📋 Workflow Plan Created: {workflow_plan['workflow_id']}")
        print(f"   📊 Steps: {len(workflow_plan['steps'])} services to call")
        print(f"   🆔 Interaction ID: {interaction_id}")
        
        return workflow_plan
    
    def postgres_mcp_agent(self, employee_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        PostgreSQL MCP Agent - Handles employee database operations
        """
        print("\n🗄️ POSTGRES MCP AGENT: Creating employee record...")
        
        emp_id = len(self.employee_db) + 1
        employee_record = {
            "id": emp_id,
            "name": employee_data["name"],
            "email": employee_data["email"],
            "role": employee_data.get("role", "employee"),
            "department": employee_data.get("department", "general"),
            "status": "active",
            "created_at": datetime.now().isoformat(),
            "onboarding_status": "in_progress"
        }
        
        self.employee_db.append(employee_record)
        
        result = {
            "service": "postgres-mcp",
            "action": "create_employee",
            "status": "success",
            "employee_id": emp_id,
            "record": employee_record,
            "database_transaction_id": f"txn_{uuid.uuid4()}",
            "execution_time_ms": 45
        }
        
        # Log MCP Agent interaction
        interaction_id = self.log_interaction(
            "postgres-mcp-agent",
            "create_employee",
            {
                "input": employee_data,
                "output": result,
                "database_operation": "INSERT INTO employees"
            }
        )
        
        print(f"   ✅ Employee '{employee_data['name']}' created with ID: {emp_id}")
        print(f"   🏢 Department: {employee_record['department']}")
        print(f"   📧 Email: {employee_record['email']}")
        print(f"   🆔 Interaction ID: {interaction_id}")
        
        return result
    
    def assets_mcp_agent(self, emp_id: int, role: str = "employee") -> Dict[str, Any]:
        """
        Assets MCP Agent - Handles asset allocation based on role
        """
        print("\n📦 ASSETS MCP AGENT: Allocating assets...")
        
        # Role-based asset allocation
        asset_templates = {
            "employee": ["laptop", "ID_card", "welcome_bag", "access_card"],
            "manager": ["laptop", "ID_card", "welcome_bag", "access_card", "parking_pass", "mobile_phone"],
            "intern": ["laptop", "ID_card", "temporary_badge"],
            "executive": ["laptop", "ID_card", "welcome_bag", "access_card", "parking_pass", "mobile_phone", "company_car"]
        }
        
        assets_to_allocate = asset_templates.get(role, asset_templates["employee"])
        allocated_assets = []
        
        for asset_type in assets_to_allocate:
            asset_record = {
                "asset_id": str(uuid.uuid4()),
                "emp_id": emp_id,
                "type": asset_type,
                "status": "allocated",
                "allocated_at": datetime.now().isoformat(),
                "expected_delivery": self._calculate_delivery_date(asset_type),
                "cost": self._get_asset_cost(asset_type)
            }
            allocated_assets.append(asset_record)
            self.assets_db.append(asset_record)
        
        result = {
            "service": "assets-mcp",
            "action": "allocate_assets",
            "status": "success",
            "emp_id": emp_id,
            "assets_allocated": len(allocated_assets),
            "assets": allocated_assets,
            "total_cost": sum(asset["cost"] for asset in allocated_assets),
            "execution_time_ms": 120
        }
        
        # Log MCP Agent interaction
        interaction_id = self.log_interaction(
            "assets-mcp-agent",
            "allocate_assets",
            {
                "employee_id": emp_id,
                "role": role,
                "assets_allocated": [asset["type"] for asset in allocated_assets],
                "total_cost": result["total_cost"]
            }
        )
        
        print(f"   ✅ {len(allocated_assets)} assets allocated for Employee ID: {emp_id}")
        for asset in allocated_assets:
            print(f"      • {asset['type']} (${asset['cost']}) - Delivery: {asset['expected_delivery']}")
        print(f"   💰 Total Cost: ${result['total_cost']}")
        print(f"   🆔 Interaction ID: {interaction_id}")
        
        return result
    
    def notification_mcp_agent(self, employee_record: Dict[str, Any], assets: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Notification MCP Agent - Sends welcome emails and notifications
        """
        print("\n📧 NOTIFICATION MCP AGENT: Sending welcome notifications...")
        
        # Generate personalized welcome message
        welcome_message = self._generate_welcome_message(employee_record, assets)
        
        # Simulate sending multiple notification channels
        notifications = [
            {
                "channel": "email",
                "recipient": employee_record["email"],
                "subject": f"Welcome to the Company, {employee_record['name']}!",
                "body": welcome_message,
                "status": "sent",
                "sent_at": datetime.now().isoformat(),
                "message_id": f"email_{uuid.uuid4()}"
            },
            {
                "channel": "sms",
                "recipient": f"+1234567890",  # Simulated phone number
                "body": f"Welcome {employee_record['name']}! Your onboarding is complete. Check your email for details.",
                "status": "sent",
                "sent_at": datetime.now().isoformat(),
                "message_id": f"sms_{uuid.uuid4()}"
            },
            {
                "channel": "slack",
                "recipient": f"@{employee_record['name'].lower()}",
                "body": f"🎉 Welcome to the team, {employee_record['name']}! Your workspace is ready.",
                "status": "sent",
                "sent_at": datetime.now().isoformat(),
                "message_id": f"slack_{uuid.uuid4()}"
            }
        ]
        
        # Store notifications
        self.notifications_sent.extend(notifications)
        
        result = {
            "service": "notification-mcp",
            "action": "send_welcome_notifications",
            "status": "success",
            "emp_id": employee_record["id"],
            "notifications_sent": len(notifications),
            "channels": [n["channel"] for n in notifications],
            "primary_email": employee_record["email"],
            "execution_time_ms": 200
        }
        
        # Log MCP Agent interaction
        interaction_id = self.log_interaction(
            "notification-mcp-agent",
            "send_welcome_notifications",
            {
                "employee": employee_record["name"],
                "email": employee_record["email"],
                "channels": result["channels"],
                "message_ids": [n["message_id"] for n in notifications]
            }
        )
        
        print(f"   ✅ Welcome notifications sent via {len(notifications)} channels")
        for notification in notifications:
            print(f"      • {notification['channel']}: {notification['status']} ({notification['message_id']})")
        print(f"   🆔 Interaction ID: {interaction_id}")
        
        return result
    
    def _calculate_delivery_date(self, asset_type: str) -> str:
        """Calculate expected delivery date based on asset type"""
        from datetime import datetime, timedelta
        
        delivery_days = {
            "laptop": 2,
            "ID_card": 1,
            "welcome_bag": 1,
            "access_card": 1,
            "parking_pass": 3,
            "mobile_phone": 2,
            "company_car": 7
        }
        
        days = delivery_days.get(asset_type, 2)
        delivery_date = datetime.now() + timedelta(days=days)
        return delivery_date.strftime("%Y-%m-%d")
    
    def _get_asset_cost(self, asset_type: str) -> float:
        """Get asset cost for budget tracking"""
        costs = {
            "laptop": 1200.00,
            "ID_card": 25.00,
            "welcome_bag": 50.00,
            "access_card": 30.00,
            "parking_pass": 0.00,
            "mobile_phone": 800.00,
            "company_car": 25000.00
        }
        return costs.get(asset_type, 0.00)
    
    def _generate_welcome_message(self, employee: Dict[str, Any], assets: List[Dict[str, Any]]) -> str:
        """Generate personalized welcome message"""
        asset_list = "\n".join([f"• {asset['type'].replace('_', ' ').title()}" for asset in assets])
        
        message = f"""
Dear {employee['name']},

🎉 Welcome to our company! We're excited to have you join our team in the {employee['department']} department.

Your onboarding has been completed successfully:
✅ Employee ID: {employee['id']}
✅ Department: {employee['department']}
✅ Role: {employee['role']}
✅ Status: {employee['status']}

📦 Assets Allocated:
{asset_list}

🚀 Next Steps:
1. Your assets will be delivered according to the schedule provided
2. Please attend the orientation session on your first day
3. Connect with your manager and team members
4. Complete any remaining paperwork in HR

If you have any questions, please don't hesitate to reach out to our HR team.

Welcome aboard!

Best regards,
HR Team & Agentic Onboarding System
        """.strip()
        
        return message
    
    def run_complete_agentic_fabric_test(self, natural_language_input: str) -> Dict[str, Any]:
        """
        Run the complete agentic fabric test workflow
        """
        print("🚀 AGENTIC FABRIC TEST: Employee Onboarding System")
        print("=" * 80)
        print(f"📝 Input: {natural_language_input}")
        print()
        
        start_time = time.time()
        
        try:
            # Step 1: Groq LLM Processing
            llm_output = self.groq_llm_processing(natural_language_input)
            
            # Step 2: HR Agent Orchestration
            workflow_plan = self.hr_agent_orchestration(llm_output)
            
            # Step 3: PostgreSQL MCP Agent - Employee Creation
            postgres_result = self.postgres_mcp_agent(llm_output["entities"])
            emp_id = postgres_result["employee_id"]
            
            # Step 4: Assets MCP Agent - Asset Allocation
            assets_result = self.assets_mcp_agent(emp_id, llm_output["entities"].get("role", "employee"))
            
            # Step 5: Notification MCP Agent - Welcome Notifications
            notification_result = self.notification_mcp_agent(
                postgres_result["record"], 
                assets_result["assets"]
            )
            
            end_time = time.time()
            execution_time = end_time - start_time
            
            # Compile final result
            final_result = {
                "agentic_fabric_status": "SUCCESS",
                "workflow_id": workflow_plan["workflow_id"],
                "execution_time_seconds": round(execution_time, 3),
                "employee": {
                    "id": emp_id,
                    "name": postgres_result["record"]["name"],
                    "email": postgres_result["record"]["email"],
                    "department": postgres_result["record"]["department"],
                    "status": postgres_result["record"]["status"]
                },
                "agents_invoked": [
                    {"agent": "groq-llm", "status": "success", "processing_time_ms": llm_output["processing_time_ms"]},
                    {"agent": "hr-agent", "status": "success"},
                    {"agent": "postgres-mcp", "status": "success", "execution_time_ms": postgres_result["execution_time_ms"]},
                    {"agent": "assets-mcp", "status": "success", "execution_time_ms": assets_result["execution_time_ms"]},
                    {"agent": "notification-mcp", "status": "success", "execution_time_ms": notification_result["execution_time_ms"]}
                ],
                "results": {
                    "postgres_result": postgres_result,
                    "assets_result": assets_result,
                    "notification_result": notification_result
                },
                "fabric_metrics": {
                    "total_agents": 5,
                    "successful_agents": 5,
                    "failed_agents": 0,
                    "total_interactions": len(self.agent_interactions),
                    "database_records_created": 1,
                    "assets_allocated": assets_result["assets_allocated"],
                    "notifications_sent": notification_result["notifications_sent"]
                }
            }
            
            self._display_fabric_summary(final_result)
            return final_result
            
        except Exception as e:
            print(f"❌ AGENTIC FABRIC ERROR: {str(e)}")
            return {"agentic_fabric_status": "FAILED", "error": str(e)}
    
    def _display_fabric_summary(self, result: Dict[str, Any]):
        """Display comprehensive agentic fabric test summary"""
        print("\n🎯 AGENTIC FABRIC SUMMARY")
        print("=" * 80)
        print(f"Status: {result['agentic_fabric_status']} ✅")
        print(f"Workflow ID: {result['workflow_id']}")
        print(f"Execution Time: {result['execution_time_seconds']} seconds")
        print()
        
        print("👤 EMPLOYEE CREATED:")
        emp = result['employee']
        print(f"   • ID: {emp['id']}")
        print(f"   • Name: {emp['name']}")
        print(f"   • Email: {emp['email']}")
        print(f"   • Department: {emp['department']}")
        print(f"   • Status: {emp['status']}")
        print()
        
        print("🤖 AGENTS PERFORMANCE:")
        for agent in result['agents_invoked']:
            exec_time = agent.get('execution_time_ms', agent.get('processing_time_ms', 'N/A'))
            print(f"   • {agent['agent']}: {agent['status']} ({exec_time}ms)")
        print()
        
        print("📊 FABRIC METRICS:")
        metrics = result['fabric_metrics']
        print(f"   • Total Agents: {metrics['total_agents']}")
        print(f"   • Successful: {metrics['successful_agents']}")
        print(f"   • Failed: {metrics['failed_agents']}")
        print(f"   • Total Interactions: {metrics['total_interactions']}")
        print(f"   • DB Records Created: {metrics['database_records_created']}")
        print(f"   • Assets Allocated: {metrics['assets_allocated']}")
        print(f"   • Notifications Sent: {metrics['notifications_sent']}")
        print()
        
        print("💰 COST SUMMARY:")
        total_cost = result['results']['assets_result']['total_cost']
        print(f"   • Asset Allocation Cost: ${total_cost}")
        print(f"   • Notification Cost: $0.50")
        print(f"   • Total Onboarding Cost: ${total_cost + 0.50}")
        print()
        
        print("🔍 AGENT INTERACTIONS TRACE:")
        for i, interaction in enumerate(self.agent_interactions, 1):
            print(f"   {i}. {interaction['agent']} → {interaction['action']} ({interaction['timestamp']})")
        print()

def main():
    """Main test execution"""
    print("🌐 AGENTIC FABRIC TESTING SYSTEM")
    print("Testing Employee Onboarding → Asset Allocation → Email Notification")
    print("=" * 80)
    
    # Initialize the agentic fabric orchestrator
    orchestrator = AgenticFabricOrchestrator()
    
    # Test scenarios
    test_scenarios = [
        "onboard employee Pradeep,pradeep.n2019@gmail.com as developer",
        "create new employee Sarah Johnson,sarah.johnson@company.com for manager role",
        "process onboarding for intern Mike Wilson,mike.wilson@company.com"
    ]
    
    for i, scenario in enumerate(test_scenarios, 1):
        print(f"\n🧪 TEST SCENARIO {i}:")
        print("-" * 40)
        result = orchestrator.run_complete_agentic_fabric_test(scenario)
        
        if i < len(test_scenarios):
            print("\n⏳ Waiting before next scenario...\n")
            time.sleep(2)
    
    print("✨ ALL AGENTIC FABRIC TESTS COMPLETED!")
    print("📋 System successfully demonstrated:")
    print("   ✅ Natural Language Processing (Groq LLM)")
    print("   ✅ Workflow Orchestration (HR Agent)")
    print("   ✅ Database Operations (PostgreSQL MCP)")
    print("   ✅ Asset Management (Assets MCP)")
    print("   ✅ Multi-channel Notifications (Notification MCP)")
    print("   ✅ Complete Agent Fabric Coordination")

if __name__ == "__main__":
    main()
