#!/usr/bin/env python3
"""
MCP Client for Employee Onboarding System with NLP Testing
Implements the Model Context Protocol to interact with the employee onboarding services
"""

import json
import asyncio
import uuid
import re
from datetime import datetime
from typing import Dict, List, Any, Optional
import aiohttp
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MCPOnboardingClient:
    """
    MCP Client for Employee Onboarding System
    Provides NLP-powered interface to interact with onboarding services
    """
    
    def __init__(self, base_url: str = "http://localhost:8080"):
        self.base_url = base_url
        self.session_id = str(uuid.uuid4())
        self.conversation_history = []
        
        # MCP Server endpoints
        self.endpoints = {
            "broker": f"{base_url}/broker/onboard",
            "postgres_mcp": f"{base_url}/mcp/postgres",
            "assets_mcp": f"{base_url}/mcp/assets", 
            "notifications_mcp": f"{base_url}/mcp/notifications"
        }
        
        # NLP patterns for extracting employee information
        self.nlp_patterns = {
            "email": r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
            "name": r'\b([A-Za-z]+(?:\s+[A-Za-z]+)*?)(?=,|\s+[\w._%+-]+@)',
            "role": r'\b(?:as|for|role)\s+([a-zA-Z\s]+?)(?:\s|$|,)',
            "department": r'\b(?:in|department|dept)\s+([a-zA-Z\s]+?)(?:\s|$|,)'
        }
        
    async def create_session(self):
        """Initialize MCP session"""
        logger.info(f"🔌 Initializing MCP Client Session: {self.session_id}")
        return {
            "jsonrpc": "2.0",
            "id": str(uuid.uuid4()),
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {
                    "roots": {
                        "listChanged": True
                    },
                    "sampling": {}
                },
                "clientInfo": {
                    "name": "employee-onboarding-mcp-client",
                    "version": "1.0.0"
                }
            }
        }
    
    def extract_employee_data_nlp(self, text: str) -> Dict[str, Any]:
        """
        Extract employee information from natural language using NLP patterns
        """
        logger.info("🧠 Processing natural language input with NLP extraction...")
        
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
            
        # Extract name (before comma or email)
        name_match = re.search(self.nlp_patterns["name"], text, re.IGNORECASE)
        if name_match:
            extracted["name"] = name_match.group(1).strip()
            extracted["confidence"] += 0.3
            
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
            
        logger.info(f"   ✅ NLP Extraction Results: {extracted}")
        return extracted
    
    async def call_mcp_tool(self, tool_name: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """
        Make MCP tool call following the protocol specification
        """
        request_id = str(uuid.uuid4())
        
        mcp_request = {
            "jsonrpc": "2.0",
            "id": request_id,
            "method": "tools/call",
            "params": {
                "name": tool_name,
                "arguments": parameters
            }
        }
        
        logger.info(f"🔧 MCP Tool Call: {tool_name}")
        logger.debug(f"   Request: {json.dumps(mcp_request, indent=2)}")
        
        try:
            async with aiohttp.ClientSession() as session:
                # Determine the appropriate endpoint
                if "postgres" in tool_name.lower():
                    endpoint = self.endpoints["postgres_mcp"]
                elif "asset" in tool_name.lower():
                    endpoint = self.endpoints["assets_mcp"]
                elif "notification" in tool_name.lower():
                    endpoint = self.endpoints["notifications_mcp"]
                else:
                    endpoint = self.endpoints["broker"]
                
                async with session.post(
                    endpoint,
                    json=mcp_request,
                    headers={"Content-Type": "application/json"}
                ) as response:
                    
                    if response.status == 200:
                        result = await response.json()
                        logger.info(f"   ✅ MCP Tool Success: {tool_name}")
                        return {
                            "success": True,
                            "result": result,
                            "request_id": request_id
                        }
                    else:
                        error_text = await response.text()
                        logger.error(f"   ❌ MCP Tool Error: {response.status} - {error_text}")
                        return {
                            "success": False,
                            "error": f"HTTP {response.status}: {error_text}",
                            "request_id": request_id
                        }
                        
        except Exception as e:
            logger.error(f"   ❌ MCP Tool Exception: {str(e)}")
            return {
                "success": False,
                "error": str(e),
                "request_id": request_id
            }
    
    async def onboard_employee_nlp(self, natural_language_input: str) -> Dict[str, Any]:
        """
        Complete employee onboarding using natural language input
        """
        logger.info("🚀 Starting Employee Onboarding via MCP Client")
        logger.info(f"📝 Natural Language Input: {natural_language_input}")
        
        # Store conversation
        self.conversation_history.append({
            "timestamp": datetime.now().isoformat(),
            "type": "user_input",
            "content": natural_language_input
        })
        
        # Step 1: Extract employee data using NLP
        employee_data = self.extract_employee_data_nlp(natural_language_input)
        
        if not employee_data["name"] or not employee_data["email"]:
            error_msg = "Could not extract required employee information (name and email) from input"
            logger.error(f"❌ {error_msg}")
            return {
                "success": False,
                "error": error_msg,
                "extracted_data": employee_data
            }
        
        workflow_results = {
            "workflow_id": str(uuid.uuid4()),
            "input": natural_language_input,
            "extracted_data": employee_data,
            "steps": [],
            "overall_success": True
        }
        
        try:
            # Step 2: Create employee record via PostgreSQL MCP
            logger.info("🗄️ Step 1: Creating employee record via PostgreSQL MCP")
            postgres_result = await self.call_mcp_tool(
                "postgres_create_employee",
                {
                    "name": employee_data["name"],
                    "email": employee_data["email"],
                    "role": employee_data["role"],
                    "department": employee_data["department"]
                }
            )
            workflow_results["steps"].append({
                "step": 1,
                "service": "postgres-mcp",
                "action": "create_employee",
                "result": postgres_result
            })
            
            if not postgres_result["success"]:
                workflow_results["overall_success"] = False
                return workflow_results
                
            # Simulate employee ID (in real system, would come from database)
            emp_id = len(self.conversation_history)
            
            # Step 3: Allocate assets via Assets MCP
            logger.info("📦 Step 2: Allocating assets via Assets MCP")
            assets_result = await self.call_mcp_tool(
                "assets_allocate",
                {
                    "employee_id": emp_id,
                    "role": employee_data["role"],
                    "department": employee_data["department"]
                }
            )
            workflow_results["steps"].append({
                "step": 2,
                "service": "assets-mcp", 
                "action": "allocate_assets",
                "result": assets_result
            })
            
            # Step 4: Send notifications via Notifications MCP
            logger.info("📧 Step 3: Sending welcome notifications via Notifications MCP")
            notification_result = await self.call_mcp_tool(
                "notification_send_welcome",
                {
                    "employee_id": emp_id,
                    "name": employee_data["name"],
                    "email": employee_data["email"],
                    "role": employee_data["role"]
                }
            )
            workflow_results["steps"].append({
                "step": 3,
                "service": "notifications-mcp",
                "action": "send_welcome",
                "result": notification_result
            })
            
            # Compile final results
            workflow_results["employee_id"] = emp_id
            workflow_results["completion_time"] = datetime.now().isoformat()
            
            # Store in conversation history
            self.conversation_history.append({
                "timestamp": datetime.now().isoformat(),
                "type": "workflow_result",
                "content": workflow_results
            })
            
            logger.info("🎉 Employee onboarding workflow completed successfully!")
            return workflow_results
            
        except Exception as e:
            logger.error(f"❌ Workflow error: {str(e)}")
            workflow_results["overall_success"] = False
            workflow_results["error"] = str(e)
            return workflow_results
    
    async def test_mcp_tools_individually(self) -> Dict[str, Any]:
        """
        Test individual MCP tools for debugging and validation
        """
        logger.info("🧪 Testing individual MCP tools...")
        
        test_results = {
            "postgres_mcp": None,
            "assets_mcp": None,
            "notifications_mcp": None
        }
        
        # Test PostgreSQL MCP
        logger.info("Testing PostgreSQL MCP health check...")
        postgres_test = await self.call_mcp_tool(
            "postgres_health_check",
            {"action": "health_check"}
        )
        test_results["postgres_mcp"] = postgres_test
        
        # Test Assets MCP  
        logger.info("Testing Assets MCP health check...")
        assets_test = await self.call_mcp_tool(
            "assets_health_check", 
            {"action": "health_check"}
        )
        test_results["assets_mcp"] = assets_test
        
        # Test Notifications MCP
        logger.info("Testing Notifications MCP health check...")
        notifications_test = await self.call_mcp_tool(
            "notifications_health_check",
            {"action": "health_check"}
        )
        test_results["notifications_mcp"] = notifications_test
        
        return test_results
    
    def get_conversation_history(self) -> List[Dict[str, Any]]:
        """Get the conversation history for analysis"""
        return self.conversation_history
    
    def display_results(self, results: Dict[str, Any]):
        """Display formatted results"""
        print("\n" + "="*80)
        print("📋 MCP CLIENT ONBOARDING RESULTS")
        print("="*80)
        
        if results.get("overall_success", False):
            print(f"✅ Status: SUCCESS")
            print(f"🆔 Workflow ID: {results['workflow_id']}")
            print(f"👤 Employee ID: {results.get('employee_id', 'N/A')}")
            
            print(f"\n🧠 NLP Extraction:")
            extracted = results["extracted_data"]
            print(f"   • Name: {extracted['name']}")
            print(f"   • Email: {extracted['email']}")
            print(f"   • Role: {extracted['role']}")
            print(f"   • Department: {extracted['department']}")
            print(f"   • Confidence: {extracted['confidence']:.1%}")
            
            print(f"\n🔧 MCP Tool Results:")
            for step in results["steps"]:
                status = "✅ SUCCESS" if step["result"]["success"] else "❌ FAILED"
                print(f"   Step {step['step']} - {step['service']}: {status}")
                
        else:
            print(f"❌ Status: FAILED")
            if "error" in results:
                print(f"Error: {results['error']}")
        
        print("="*80 + "\n")

async def main():
    """Main test execution"""
    print("🌐 MCP CLIENT FOR EMPLOYEE ONBOARDING SYSTEM")
    print("Testing Employee Onboarding with Natural Language Processing")
    print("="*80)
    
    # Initialize MCP client
    client = MCPOnboardingClient()
    
    # Create MCP session
    session = await client.create_session()
    logger.info("MCP Session initialized")
    
    # Test scenarios with natural language input
    test_scenarios = [
        "onboard employee Pradeep Kumar,pradeep.n2019@gmail.com as developer in engineering",
        "create new employee Sarah Johnson,sarah.johnson@company.com for manager role",
        "process onboarding for intern Mike Wilson,mike.wilson@company.com in IT department",
        "add employee Jessica Smith,jessica.smith@company.com as executive in operations"
    ]
    
    print(f"\n🧪 Running {len(test_scenarios)} NLP onboarding test scenarios...\n")
    
    for i, scenario in enumerate(test_scenarios, 1):
        print(f"📝 Scenario {i}: {scenario}")
        print("-" * 60)
        
        # Execute onboarding via MCP client
        result = await client.onboard_employee_nlp(scenario)
        client.display_results(result)
        
        # Wait between scenarios
        if i < len(test_scenarios):
            await asyncio.sleep(1)
    
    # Test individual MCP tools
    print("\n🔍 Testing individual MCP tools...")
    tool_tests = await client.test_mcp_tools_individually()
    
    print("\n📊 MCP Tool Health Check Results:")
    for service, result in tool_tests.items():
        status = "✅ HEALTHY" if result and result.get("success") else "❌ UNHEALTHY"
        print(f"   • {service}: {status}")
    
    print("\n✨ MCP Client Testing Complete!")
    print(f"📜 Conversation history contains {len(client.get_conversation_history())} entries")

if __name__ == "__main__":
    # Run the MCP client test
    asyncio.run(main())
