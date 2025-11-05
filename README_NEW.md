# Snowflake Cortex AI Agent with Google Workspace Integration

A production-ready implementation of Snowflake Cortex AI Agent with Google Workspace tools (Docs, Sheets, Drive). This repository provides a clean, modular structure that makes it easy to deploy a fully functional AI agent in under 30 minutes.

## 🎯 What You'll Get

- **Snowflake Cortex AI Agent** powered by Claude Sonnet 4
- **22 Google Workspace Tools**:
  - 📄 5 Google Docs tools (create, read, insert, delete, replace)
  - 📊 6 Google Sheets tools (create, read, write, append, update, clear)
  - 📁 11 Google Drive tools (folders, files, sharing, metadata)
- **Extensible Architecture** ready for Salesforce and other integrations
- **Single-Command Deployment** with validation and error handling

## 📋 Prerequisites

### Required Access
- Snowflake account with **ACCOUNTADMIN** role
- Google Cloud Project with OAuth 2.0 credentials
- Python 3.8+ installed locally

### Required Tools
```bash
# Snowflake CLI
pip install snowflake-cli-labs

# Python dependencies
pip install -r requirements.txt
```

### Google Cloud Setup
1. Create a Google Cloud Project
2. Enable Google Docs, Sheets, and Drive APIs
3. Create OAuth 2.0 credentials (Desktop application)
4. Download credentials JSON file

## 🚀 Quick Start (30 Minutes)

### Step 1: Clone and Configure (5 minutes)

```bash
# Clone repository
git clone <your-repo-url>
cd alpaca

# Copy environment template
cp .env.example .env

# Edit .env with your credentials
nano .env
```

Required `.env` variables:
```bash
# Snowflake Configuration
SNOWFLAKE_ACCOUNT=YOUR_ACCOUNT_ID
SNOWFLAKE_USER=SERVICE_USER
SNOWFLAKE_WAREHOUSE=AGENTS_DEMO_WH
SNOWFLAKE_DATABASE=AGENTS_DEMO
SNOWFLAKE_SCHEMA=PUBLIC
SNOWFLAKE_ROLE=AGENTS_SERVICE_ROLE
SNOWFLAKE_PAT=YOUR_PERSONAL_ACCESS_TOKEN

# Google OAuth (from downloaded JSON)
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
GOOGLE_REDIRECT_URI=http://localhost:8080

# Agent Configuration (optional)
AGENT_NAME=GTM_ENGINEER_AGENT
AGENT_DATABASE=snowflake_intelligence
AGENT_SCHEMA=agents
AGENT_MODEL=claude-4-sonnet
```

### Step 2: Snowflake Infrastructure Setup (10 minutes)

Run as **ACCOUNTADMIN** in Snowsight:

```sql
-- 1. Create service user
CREATE USER IF NOT EXISTS SERVICE_USER
  TYPE = SERVICE
  COMMENT = 'Service user for Cortex AI Agent';

-- 2. Create service role
CREATE ROLE IF NOT EXISTS AGENTS_SERVICE_ROLE
  COMMENT = 'Role for managing Cortex AI Agents';

GRANT ROLE AGENTS_SERVICE_ROLE TO USER SERVICE_USER;

-- 3. Create network policy (required for service users)
CREATE NETWORK RULE IF NOT EXISTS allow_all_ips
  TYPE = IPV4
  VALUE_LIST = ('0.0.0.0/0')
  MODE = INGRESS;

CREATE NETWORK POLICY IF NOT EXISTS service_user_network_policy
  ALLOWED_NETWORK_RULE_LIST = ('allow_all_ips');

ALTER USER SERVICE_USER SET NETWORK_POLICY = service_user_network_policy;

-- 4. Create Personal Access Token
ALTER USER SERVICE_USER ADD PROGRAMMATIC ACCESS TOKEN agent_pat;
-- Copy the token and add to .env as SNOWFLAKE_PAT

-- 5. Create database and warehouse
CREATE DATABASE IF NOT EXISTS AGENTS_DEMO;
CREATE WAREHOUSE IF NOT EXISTS AGENTS_DEMO_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;

-- 6. Grant privileges
GRANT USAGE ON DATABASE AGENTS_DEMO TO ROLE AGENTS_SERVICE_ROLE;
GRANT USAGE ON SCHEMA AGENTS_DEMO.PUBLIC TO ROLE AGENTS_SERVICE_ROLE;
GRANT USAGE ON WAREHOUSE AGENTS_DEMO_WH TO ROLE AGENTS_SERVICE_ROLE;
GRANT CREATE FUNCTION ON SCHEMA AGENTS_DEMO.PUBLIC TO ROLE AGENTS_SERVICE_ROLE;
GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE AGENTS_SERVICE_ROLE;

-- 7. Create snowflake_intelligence database (for Snowsight visibility)
CREATE DATABASE IF NOT EXISTS snowflake_intelligence;
CREATE SCHEMA IF NOT EXISTS snowflake_intelligence.agents;

GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE PUBLIC;
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE AGENTS_SERVICE_ROLE;
GRANT USAGE, CREATE AGENT ON SCHEMA snowflake_intelligence.agents TO ROLE AGENTS_SERVICE_ROLE;

-- 8. Grant to your user (replace ROMAN with your username)
GRANT USAGE ON DATABASE snowflake_intelligence TO USER ROMAN;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO USER ROMAN;
```

### Step 3: Google OAuth Setup (5 minutes)

```bash
# Generate OAuth URL
python tools/gsuite/get_oauth_url.py

# Follow the URL, authorize, and copy the authorization code
# The script will exchange it for tokens and create the secret
```

This creates `google_oauth_secret_demo` in Snowflake.

### Step 4: Deploy Google Workspace Tools (5 minutes)

```bash
# Deploy all Google Workspace functions to Snowflake
python deployment/deploy_gsuite.py
```

This script:
- ✅ Uploads Python handlers to Snowflake stage
- ✅ Creates OAuth integration
- ✅ Creates 22 UDFs for Google Workspace operations
- ✅ Validates all functions are working

### Step 5: Create the Agent (5 minutes)

```bash
# Create agent with all tools
python agent/create_agent.py

# Or force recreate if agent exists
python agent/create_agent.py --force
```

Output:
```
================================================================================
SNOWFLAKE CORTEX AI AGENT CREATION
================================================================================
Agent: GTM_ENGINEER_AGENT
Location: snowflake_intelligence.agents
Model: claude-4-sonnet
================================================================================

Step 1: Initializing API client...
✅ API client initialized

Step 2: Discovering tools...
✅ Loaded 5 tools from gsuite/docs_tools.json
✅ Loaded 6 tools from gsuite/sheets_tools.json
✅ Loaded 11 tools from gsuite/drive_tools.json
✅ Discovered 22 tools

Tools by integration:
  📦 gsuite: 22 tools

Step 3: Validating tools...
✅ All tools validated

Step 4: Creating agent...
✅ Agent created successfully!

================================================================================
✅ AGENT CREATION COMPLETE!
================================================================================

Agent Details:
  Name: GTM_ENGINEER_AGENT
  Location: snowflake_intelligence.agents.GTM_ENGINEER_AGENT
  Model: claude-4-sonnet
  Total Tools: 22

Next Steps:
  1. Go to Snowsight: https://app.snowflake.com/
  2. Navigate to: AI & ML → Cortex → Agents
  3. Select: GTM_ENGINEER_AGENT
  4. Start chatting!

================================================================================
```

### Step 6: Test Your Agent (5 minutes)

1. Go to **Snowsight** → **AI & ML** → **Cortex** → **Agents**
2. Select **GTM_ENGINEER_AGENT**
3. Try these commands:

```
Create a Google Doc called "Meeting Notes" with an agenda section

Create a Google Sheet called "Sales Data" with headers: Name, Revenue, Region

Create a folder in Google Drive called "Q1 Reports"
```

## 📁 Repository Structure

```
alpaca/
├── agent/                          # Agent creation and management
│   ├── create_agent.py            # Main agent creation script
│   ├── api_client.py              # Snowflake REST API client
│   ├── tool_registry.py           # Tool discovery and validation
│   └── config.py                  # Agent configuration
│
├── tools/                          # Tool integrations
│   ├── gsuite/                    # Google Workspace integration
│   │   ├── specs/                 # Tool specifications (JSON)
│   │   │   ├── docs_tools.json
│   │   │   ├── sheets_tools.json
│   │   │   └── drive_tools.json
│   │   ├── handlers/              # Python handlers
│   │   │   ├── gdocs_handler.py
│   │   │   ├── gsheets_handler.py
│   │   │   └── gdrive_handler.py
│   │   ├── sql/                   # Snowflake SQL functions
│   │   │   ├── create_docs_functions.sql
│   │   │   ├── create_sheets_functions.sql
│   │   │   └── create_drive_functions.sql
│   │   └── deploy.py              # Deployment script
│   │
│   └── salesforce/                # Salesforce integration (future)
│       └── specs/
│
├── deployment/                     # Deployment automation
│   ├── deploy_all.py              # Single-command deployment
│   ├── deploy_gsuite.py           # Google Workspace deployment
│   └── validate.py                # Validation scripts
│
├── docs/                           # Documentation
│   ├── ARCHITECTURE.md            # System architecture
│   ├── TROUBLESHOOTING.md         # Common issues and solutions
│   └── API_REFERENCE.md           # API documentation
│
├── .env.example                    # Environment template
├── requirements.txt                # Python dependencies
└── README.md                       # This file
```

## 🔧 Advanced Usage

### Custom Agent Configuration

```python
from agent.config import AgentConfig
from agent.create_agent import create_agent

# Create custom configuration
config = AgentConfig(
    name="CUSTOM_AGENT",
    description="My custom agent",
    model="claude-4-sonnet",
    orchestration_instructions="Custom instructions here..."
)

# Create agent
create_agent(config=config, tools_dir=Path('tools'))
```

### Adding New Tools

1. Create tool specification JSON in `tools/{integration}/specs/`
2. Implement Python handler in `tools/{integration}/handlers/`
3. Create Snowflake UDF in `tools/{integration}/sql/`
4. Run `python agent/create_agent.py --force` to recreate agent

### Deployment to Different Environments

```bash
# Development
python agent/create_agent.py --functions-database DEV_DB

# Production
python agent/create_agent.py --functions-database PROD_DB
```

## 🐛 Troubleshooting

### Agent Not Visible in Snowsight

**Problem**: Agent created but not showing in Snowsight UI

**Solution**: Agent must be in `snowflake_intelligence.agents` schema
```bash
python agent/create_agent.py --force
```

### "Array Not Supported" Error

**Problem**: Tool parameter uses `array` type

**Solution**: Use `string` type with JSON format instead
```json
{
  "data_values": {
    "type": "string",
    "description": "JSON string: '[[\"Name\", \"Age\"], [\"Alice\", 30]]'"
  }
}
```

### Network Policy Error

**Problem**: Service user cannot use PAT

**Solution**: Create network policy (see Step 2 above)

### OAuth Token Expired

**Problem**: Google API returns 401 Unauthorized

**Solution**: Regenerate OAuth tokens
```bash
python tools/gsuite/get_oauth_url.py
```

## 📚 Additional Resources

- [Snowflake Cortex AI Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-ai)
- [Google Workspace API Documentation](https://developers.google.com/workspace)
- [Architecture Guide](docs/ARCHITECTURE.md)
- [API Reference](docs/API_REFERENCE.md)

## 🤝 Contributing

Contributions welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

