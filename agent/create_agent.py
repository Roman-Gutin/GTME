#!/usr/bin/env python3
"""
Create Snowflake Cortex AI Agent

This script creates a Snowflake Cortex AI Agent with all registered tools
from multiple integrations (Google Workspace, Salesforce, etc.).

Usage:
    python agent/create_agent.py [--config CONFIG_NAME] [--force]

Examples:
    # Create agent with default GTM Engineer configuration
    python agent/create_agent.py
    
    # Create agent with specific configuration
    python agent/create_agent.py --config salesforce
    
    # Force recreate (delete existing agent first)
    python agent/create_agent.py --force
"""

import argparse
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from agent.api_client import SnowflakeAgentAPIClient
from agent.tool_registry import ToolRegistry
from agent.config import AgentConfig, get_config


def create_agent(
    config: AgentConfig,
    tools_dir: Path,
    force: bool = False,
    functions_database: str = "AGENTS_DEMO",
    functions_schema: str = "PUBLIC",
    warehouse: str = "AGENTS_DEMO_WH"
) -> None:
    """
    Create Snowflake Cortex AI Agent with all tools.
    
    Args:
        config: Agent configuration
        tools_dir: Path to tools directory
        force: If True, delete existing agent before creating
        functions_database: Database where UDFs are deployed
        functions_schema: Schema where UDFs are deployed
        warehouse: Warehouse for tool execution
    """
    print("=" * 80)
    print("SNOWFLAKE CORTEX AI AGENT CREATION")
    print("=" * 80)
    print(f"Agent: {config.name}")
    print(f"Location: {config.database}.{config.schema}")
    print(f"Model: {config.model}")
    print("=" * 80)
    print()
    
    # Initialize API client
    print("Step 1: Initializing API client...")
    try:
        client = SnowflakeAgentAPIClient.from_env()
        print("✅ API client initialized")
    except Exception as e:
        print(f"❌ Failed to initialize API client: {e}")
        sys.exit(1)
    
    # Initialize tool registry
    print("\nStep 2: Discovering tools...")
    registry = ToolRegistry(warehouse=warehouse)
    
    try:
        total_tools = registry.discover_tools(
            tools_dir=tools_dir,
            functions_database=functions_database,
            functions_schema=functions_schema
        )
        print(f"✅ Discovered {total_tools} tools")
        
        # Print summary
        summary = registry.get_summary()
        print("\nTools by integration:")
        for integration, count in summary["by_integration"].items():
            print(f"  📦 {integration}: {count} tools")
    
    except Exception as e:
        print(f"❌ Failed to discover tools: {e}")
        sys.exit(1)
    
    # Validate tools
    print("\nStep 3: Validating tools...")
    errors = registry.validate_tools()
    if errors:
        print("❌ Tool validation failed:")
        for error in errors:
            print(f"  - {error}")
        sys.exit(1)
    print("✅ All tools validated")
    
    # Handle existing agent
    if force:
        print(f"\nStep 4: Deleting existing agent (--force)...")
        try:
            client.delete_agent(
                database=config.database,
                schema=config.schema,
                name=config.name
            )
            print(f"✅ Deleted existing agent: {config.name}")
        except Exception as e:
            print(f"⚠️  No existing agent to delete (or delete failed): {e}")
    
    # Create agent
    print(f"\nStep {'5' if force else '4'}: Creating agent...")
    
    tools = registry.get_all_tools_for_agent()
    agent_config = config.to_api_format(tools=tools)
    
    try:
        response = client.create_agent(
            database=config.database,
            schema=config.schema,
            name=config.name,
            agent_config=agent_config
        )
        print("✅ Agent created successfully!")
        print(f"\nResponse: {response}")
    
    except Exception as e:
        print(f"❌ Failed to create agent: {e}")
        sys.exit(1)
    
    # Success summary
    print("\n" + "=" * 80)
    print("✅ AGENT CREATION COMPLETE!")
    print("=" * 80)
    print(f"\nAgent Details:")
    print(f"  Name: {config.name}")
    print(f"  Location: {config.database}.{config.schema}.{config.name}")
    print(f"  Model: {config.model}")
    print(f"  Total Tools: {len(tools)}")
    print(f"\nNext Steps:")
    print(f"  1. Go to Snowsight: https://app.snowflake.com/")
    print(f"  2. Navigate to: AI & ML → Cortex → Agents")
    print(f"  3. Select: {config.name}")
    print(f"  4. Start chatting!")
    print("\n" + "=" * 80)


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Create Snowflake Cortex AI Agent with all tools",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Create agent with default configuration
  python agent/create_agent.py
  
  # Create agent with specific configuration
  python agent/create_agent.py --config salesforce
  
  # Force recreate (delete existing first)
  python agent/create_agent.py --force
  
  # Use custom tools directory
  python agent/create_agent.py --tools-dir /path/to/tools
        """
    )
    
    parser.add_argument(
        '--config',
        default='gtm_engineer',
        help='Configuration name (minimal, gtm_engineer, salesforce)'
    )
    
    parser.add_argument(
        '--force',
        action='store_true',
        help='Delete existing agent before creating'
    )
    
    parser.add_argument(
        '--tools-dir',
        type=Path,
        default=Path(__file__).parent.parent / 'tools',
        help='Path to tools directory (default: ./tools)'
    )
    
    parser.add_argument(
        '--functions-database',
        default='AGENTS_DEMO',
        help='Database where UDFs are deployed (default: AGENTS_DEMO)'
    )
    
    parser.add_argument(
        '--functions-schema',
        default='PUBLIC',
        help='Schema where UDFs are deployed (default: PUBLIC)'
    )
    
    parser.add_argument(
        '--warehouse',
        default='AGENTS_DEMO_WH',
        help='Warehouse for tool execution (default: AGENTS_DEMO_WH)'
    )
    
    args = parser.parse_args()
    
    # Get configuration
    try:
        config = get_config(args.config)
    except ValueError as e:
        print(f"Error: {e}")
        sys.exit(1)
    
    # Create agent
    create_agent(
        config=config,
        tools_dir=args.tools_dir,
        force=args.force,
        functions_database=args.functions_database,
        functions_schema=args.functions_schema,
        warehouse=args.warehouse
    )


if __name__ == "__main__":
    main()

