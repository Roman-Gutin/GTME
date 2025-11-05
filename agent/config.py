"""
Agent Configuration

This module defines the configuration for the Snowflake Cortex AI Agent,
including model selection, orchestration instructions, and response formatting.
"""

from typing import Dict, List, Any, Optional
from dataclasses import dataclass, asdict


@dataclass
class AgentConfig:
    """Configuration for Snowflake Cortex AI Agent."""
    
    # Agent identity
    name: str = "GTM_ENGINEER_AGENT"
    description: str = (
        "GTM Engineer AI agent with essential CRUD tools for Google Workspace "
        "(Docs, Sheets, Drive) and Salesforce integration"
    )
    
    # Deployment location
    database: str = "snowflake_intelligence"
    schema: str = "agents"
    
    # Model configuration
    model: str = "claude-4-sonnet"
    
    # Orchestration instructions
    orchestration_instructions: str = """You are a GTM (Go-To-Market) Engineer AI assistant with access to Google Workspace and Salesforce tools.

Your capabilities:
- Create, read, and modify Google Docs
- Create, read, and update Google Sheets with data
- Manage Google Drive folders and files
- Query and update Salesforce records (when available)

Guidelines:
1. Always confirm actions before executing destructive operations
2. Provide clear, actionable responses with relevant URLs
3. When creating documents or sheets, return the web link for easy access
4. Use appropriate tools for the task - don't try to do everything manually
5. If you need more information to complete a task, ask clarifying questions

Response format:
- Be concise but complete
- Include relevant URLs (Google Docs, Sheets, Drive links)
- Summarize what was accomplished
- Suggest next steps when appropriate"""
    
    # Response instructions
    response_instructions: str = """When you create or modify Google Workspace resources:
1. Always include the web link (webViewLink or alternateLink) in your response
2. Format links as clickable markdown: [Document Name](URL)
3. Summarize what was created/modified
4. If multiple items were created, list them with their links

Example response format:
"I've created the document: [Meeting Notes](https://docs.google.com/document/d/abc123/edit)

The document includes:
- Meeting agenda
- Action items section
- Notes area

You can access it directly using the link above."
"""
    
    def to_api_format(self, tools: List[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Convert configuration to Snowflake Agent API format.
        
        Args:
            tools: List of tool configurations from ToolRegistry
        
        Returns:
            Complete agent configuration for API
        """
        return {
            "description": self.description,
            "orchestration": {
                "model": self.model,
                "instructions": self.orchestration_instructions
            },
            "response": {
                "instructions": self.response_instructions
            },
            "tools": tools
        }
    
    @classmethod
    def from_env(cls, **kwargs) -> 'AgentConfig':
        """
        Create configuration from environment variables with optional overrides.
        
        Args:
            **kwargs: Optional overrides for any configuration field
        
        Returns:
            AgentConfig instance
        """
        import os
        
        config_dict = {
            "name": os.getenv("AGENT_NAME", cls.name),
            "description": os.getenv("AGENT_DESCRIPTION", cls.description),
            "database": os.getenv("AGENT_DATABASE", cls.database),
            "schema": os.getenv("AGENT_SCHEMA", cls.schema),
            "model": os.getenv("AGENT_MODEL", cls.model),
        }
        
        # Apply overrides
        config_dict.update(kwargs)
        
        return cls(**config_dict)


# Predefined configurations for different use cases

MINIMAL_CONFIG = AgentConfig(
    name="MINIMAL_AGENT",
    description="Minimal agent for testing",
    orchestration_instructions="You are a helpful AI assistant.",
    response_instructions="Provide clear, concise responses."
)

GTM_ENGINEER_CONFIG = AgentConfig(
    name="GTM_ENGINEER_AGENT",
    description=(
        "GTM Engineer AI agent with essential CRUD tools (22 tools: "
        "5 Docs, 6 Sheets, 11 Drive)"
    ),
)

SALESFORCE_CONFIG = AgentConfig(
    name="SALESFORCE_AGENT",
    description="Salesforce integration agent for CRM operations",
    orchestration_instructions="""You are a Salesforce AI assistant with access to CRM tools.

Your capabilities:
- Query Salesforce records (Accounts, Contacts, Opportunities, Leads)
- Create and update Salesforce records
- Search across Salesforce objects
- Generate reports and insights

Guidelines:
1. Always validate data before creating/updating records
2. Use SOQL queries efficiently
3. Provide clear summaries of query results
4. Suggest related actions based on the data""",
    response_instructions="""When working with Salesforce:
1. Include record IDs and links when available
2. Format query results in clear tables
3. Highlight important fields (Amount, Stage, Close Date, etc.)
4. Suggest next steps based on the data"""
)


def get_config(config_name: str = "gtm_engineer") -> AgentConfig:
    """
    Get a predefined configuration by name.
    
    Args:
        config_name: Name of configuration ('minimal', 'gtm_engineer', 'salesforce')
    
    Returns:
        AgentConfig instance
    
    Raises:
        ValueError: If config_name is not recognized
    """
    configs = {
        "minimal": MINIMAL_CONFIG,
        "gtm_engineer": GTM_ENGINEER_CONFIG,
        "salesforce": SALESFORCE_CONFIG,
    }
    
    if config_name not in configs:
        raise ValueError(
            f"Unknown config: {config_name}. "
            f"Available: {', '.join(configs.keys())}"
        )
    
    return configs[config_name]

