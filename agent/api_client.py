"""
Snowflake Cortex AI Agent REST API Client

This module provides a clean interface to the Snowflake REST API for managing
Cortex AI Agents. It handles authentication, request formatting, and error handling.
"""

import os
import requests
from typing import Dict, List, Optional, Any
from pathlib import Path


class SnowflakeAgentAPIClient:
    """Client for interacting with Snowflake Cortex AI Agent REST API."""
    
    def __init__(self, account: str, pat: str):
        """
        Initialize the API client.
        
        Args:
            account: Snowflake account identifier (e.g., 'RNRIZGX-AUB95186')
            pat: Personal Access Token for authentication
        """
        self.account = account
        self.pat = pat
        self.base_url = f"https://{account}.snowflakecomputing.com/api/v2"
        self.headers = {
            "Authorization": f"Bearer {pat}",
            "Accept": "application/json",
            "Content-Type": "application/json"
        }
    
    def create_agent(
        self,
        database: str,
        schema: str,
        name: str,
        agent_config: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Create a new Cortex AI Agent.
        
        Args:
            database: Database name (e.g., 'snowflake_intelligence')
            schema: Schema name (e.g., 'agents')
            name: Agent name (e.g., 'GTM_ENGINEER_AGENT')
            agent_config: Complete agent configuration including tools, orchestration, etc.
        
        Returns:
            API response as dictionary
            
        Raises:
            requests.HTTPError: If the API request fails
        """
        url = f"{self.base_url}/databases/{database}/schemas/{schema}/agents/{name}"
        
        response = requests.post(url, headers=self.headers, json=agent_config)
        
        if response.status_code not in [200, 201]:
            raise requests.HTTPError(
                f"Failed to create agent: {response.status_code} - {response.text}"
            )
        
        return response.json()
    
    def get_agent(
        self,
        database: str,
        schema: str,
        name: str
    ) -> Dict[str, Any]:
        """
        Get agent details.
        
        Args:
            database: Database name
            schema: Schema name
            name: Agent name
        
        Returns:
            Agent configuration as dictionary
            
        Raises:
            requests.HTTPError: If the API request fails
        """
        url = f"{self.base_url}/databases/{database}/schemas/{schema}/agents/{name}"
        
        response = requests.get(url, headers=self.headers)
        
        if response.status_code != 200:
            raise requests.HTTPError(
                f"Failed to get agent: {response.status_code} - {response.text}"
            )
        
        return response.json()
    
    def delete_agent(
        self,
        database: str,
        schema: str,
        name: str
    ) -> Dict[str, Any]:
        """
        Delete an agent.
        
        Args:
            database: Database name
            schema: Schema name
            name: Agent name
        
        Returns:
            API response as dictionary
            
        Raises:
            requests.HTTPError: If the API request fails
        """
        url = f"{self.base_url}/databases/{database}/schemas/{schema}/agents/{name}"
        
        response = requests.delete(url, headers=self.headers)
        
        if response.status_code != 200:
            raise requests.HTTPError(
                f"Failed to delete agent: {response.status_code} - {response.text}"
            )
        
        return response.json()
    
    @classmethod
    def from_env(cls, env_path: Optional[Path] = None) -> 'SnowflakeAgentAPIClient':
        """
        Create API client from environment variables.
        
        Args:
            env_path: Optional path to .env file. If not provided, uses repository root.
        
        Returns:
            Configured API client instance
            
        Raises:
            ValueError: If required environment variables are missing
        """
        if env_path is None:
            # Default to repository root
            env_path = Path(__file__).parent.parent / '.env'
        
        # Load environment variables
        if env_path.exists():
            from dotenv import load_dotenv
            load_dotenv(env_path)
        
        account = os.getenv('SNOWFLAKE_ACCOUNT')
        pat = os.getenv('SNOWFLAKE_PAT')
        
        if not account or not pat:
            raise ValueError(
                "Missing required environment variables: SNOWFLAKE_ACCOUNT and SNOWFLAKE_PAT"
            )
        
        return cls(account=account, pat=pat)

