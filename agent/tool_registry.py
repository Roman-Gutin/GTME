"""
Tool Registry for Snowflake Cortex AI Agent

This module provides a centralized registry for discovering and managing tools
from multiple integrations (Google Workspace, Salesforce, etc.). It validates
tool specifications and generates the complete tool configuration for the agent.
"""

import json
from typing import Dict, List, Any, Optional
from pathlib import Path
from dataclasses import dataclass


@dataclass
class ToolSpec:
    """Specification for a single tool."""
    name: str
    description: str
    input_schema: Dict[str, Any]
    function_identifier: str
    warehouse: str
    integration: str  # e.g., 'gsuite', 'salesforce'
    
    def to_agent_format(self) -> Dict[str, Any]:
        """
        Convert tool spec to Snowflake Agent API format.
        
        Returns:
            Dictionary with 'tool_spec' and 'tool_resource' keys
        """
        return {
            "tool_spec": {
                "type": "generic",
                "name": self.name,
                "description": self.description,
                "input_schema": self.input_schema
            },
            "tool_resource": {
                "type": "function",
                "execution_environment": {
                    "type": "warehouse",
                    "warehouse": self.warehouse
                },
                "identifier": self.function_identifier
            }
        }


class ToolRegistry:
    """Central registry for all agent tools across integrations."""
    
    def __init__(self, warehouse: str = "AGENTS_DEMO_WH"):
        """
        Initialize the tool registry.
        
        Args:
            warehouse: Default warehouse for tool execution
        """
        self.warehouse = warehouse
        self.tools: List[ToolSpec] = []
        self._tools_by_integration: Dict[str, List[ToolSpec]] = {}
    
    def register_tool(self, tool: ToolSpec) -> None:
        """
        Register a single tool.
        
        Args:
            tool: Tool specification to register
        """
        self.tools.append(tool)
        
        if tool.integration not in self._tools_by_integration:
            self._tools_by_integration[tool.integration] = []
        self._tools_by_integration[tool.integration].append(tool)
    
    def register_tools_from_json(
        self,
        json_path: Path,
        integration: str,
        functions_database: str = "AGENTS_DEMO",
        functions_schema: str = "PUBLIC"
    ) -> int:
        """
        Register tools from a JSON specification file.
        
        Args:
            json_path: Path to JSON file containing tool specifications
            integration: Integration name (e.g., 'gsuite', 'salesforce')
            functions_database: Database where UDFs are deployed
            functions_schema: Schema where UDFs are deployed
        
        Returns:
            Number of tools registered
        """
        if not json_path.exists():
            raise FileNotFoundError(f"Tool spec file not found: {json_path}")
        
        with open(json_path, 'r') as f:
            specs = json.load(f)
        
        count = 0
        for spec in specs:
            # Extract function name from tool name (convert to uppercase for Snowflake)
            function_name = spec['name'].upper()
            function_identifier = f"{functions_database}.{functions_schema}.{function_name}"
            
            tool = ToolSpec(
                name=spec['name'],
                description=spec['description'],
                input_schema=spec['input_schema'],
                function_identifier=function_identifier,
                warehouse=self.warehouse,
                integration=integration
            )
            
            self.register_tool(tool)
            count += 1
        
        return count
    
    def discover_tools(
        self,
        tools_dir: Path,
        functions_database: str = "AGENTS_DEMO",
        functions_schema: str = "PUBLIC"
    ) -> int:
        """
        Automatically discover and register tools from all integrations.
        
        Looks for tool specification files in:
        - tools/gsuite/specs/*.json
        - tools/salesforce/specs/*.json
        - etc.
        
        Args:
            tools_dir: Root tools directory (e.g., Path('tools'))
            functions_database: Database where UDFs are deployed
            functions_schema: Schema where UDFs are deployed
        
        Returns:
            Total number of tools discovered
        """
        total_count = 0
        
        # Discover all integration directories
        if not tools_dir.exists():
            raise FileNotFoundError(f"Tools directory not found: {tools_dir}")
        
        for integration_dir in tools_dir.iterdir():
            if not integration_dir.is_dir():
                continue
            
            integration_name = integration_dir.name
            specs_dir = integration_dir / 'specs'
            
            if not specs_dir.exists():
                continue
            
            # Load all JSON spec files
            for spec_file in specs_dir.glob('*.json'):
                count = self.register_tools_from_json(
                    json_path=spec_file,
                    integration=integration_name,
                    functions_database=functions_database,
                    functions_schema=functions_schema
                )
                total_count += count
                print(f"✅ Loaded {count} tools from {integration_name}/{spec_file.name}")
        
        return total_count
    
    def get_tools_by_integration(self, integration: str) -> List[ToolSpec]:
        """
        Get all tools for a specific integration.
        
        Args:
            integration: Integration name (e.g., 'gsuite')
        
        Returns:
            List of tool specifications
        """
        return self._tools_by_integration.get(integration, [])
    
    def get_all_tools_for_agent(self) -> List[Dict[str, Any]]:
        """
        Get all registered tools in Snowflake Agent API format.
        
        Returns:
            List of tool configurations ready for agent creation
        """
        return [tool.to_agent_format() for tool in self.tools]
    
    def validate_tools(self) -> List[str]:
        """
        Validate all registered tools.
        
        Returns:
            List of validation errors (empty if all valid)
        """
        errors = []
        
        for tool in self.tools:
            # Check required fields
            if not tool.name:
                errors.append(f"Tool missing name: {tool}")
            
            if not tool.description:
                errors.append(f"Tool '{tool.name}' missing description")
            
            if not tool.input_schema:
                errors.append(f"Tool '{tool.name}' missing input_schema")
            
            if not tool.function_identifier:
                errors.append(f"Tool '{tool.name}' missing function_identifier")
            
            # Validate input schema structure
            if 'type' not in tool.input_schema:
                errors.append(f"Tool '{tool.name}' input_schema missing 'type'")
            
            if 'properties' not in tool.input_schema:
                errors.append(f"Tool '{tool.name}' input_schema missing 'properties'")
            
            # Check for array parameters (not warehouse-compatible)
            for param_name, param_spec in tool.input_schema.get('properties', {}).items():
                if param_spec.get('type') == 'array':
                    errors.append(
                        f"Tool '{tool.name}' parameter '{param_name}' uses 'array' type "
                        f"(not warehouse-compatible). Use 'string' with JSON format instead."
                    )
        
        return errors
    
    def get_summary(self) -> Dict[str, Any]:
        """
        Get summary of registered tools.
        
        Returns:
            Dictionary with tool counts by integration
        """
        summary = {
            "total_tools": len(self.tools),
            "by_integration": {}
        }
        
        for integration, tools in self._tools_by_integration.items():
            summary["by_integration"][integration] = len(tools)
        
        return summary

