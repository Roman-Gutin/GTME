# GTME - Go-To-Market Engineer AI Agent

> **Solve CRM hygiene with AI.** A connected agent that automates the most common and dreadful problem in sales: keeping your CRM up to date.

Deploy a fully functional AI agent powered by Claude Sonnet 4 with access to the tools sellers actually use—Google Workspace and Salesforce—in under 30 minutes.

## 🎯 What You Get

**A Connected Agent with access to the tools sellers use every day:**

- **📄 Google Workspace** (22 tools): Docs, Sheets, Drive
- **💼 Salesforce** (11 tools): Accounts, Opportunities, Contacts, Discovery
- **🤖 Claude Sonnet 4**: Industry-leading AI model for reasoning and execution

**Automate CRM Hygiene:**
- Update Salesforce opportunities from meeting notes in Google Docs
- Create pipeline reports in Google Sheets from Salesforce data
- Sync account information between systems automatically
- Generate proposals in Google Docs using Salesforce opportunity data
- Keep contact information current across both platforms

**Production-Ready Infrastructure:**
- Single-command deployment (30 minutes)
- Flexible deployment (Google only, Salesforce only, or both)
- Extensible architecture for adding more integrations
- Enterprise-grade security with Snowflake RBAC

## 📊 Tool Breakdown

### Google Workspace (22 tools)
- **Google Docs** (5): Create, read, insert, delete, replace text
- **Google Sheets** (6): Create, read, write, append, update, clear
- **Google Drive** (11): Folders, files, sharing, metadata, permissions

### Salesforce (11 tools)
- **Accounts** (4): Query, get, create, summarize
- **Opportunities** (4): Get, create, update, pipeline summary
- **Contacts** (1): Get contact details
- **Discovery** (2): List objects, get metadata

## 🏗️ Architecture Overview

### How It Works

This system deploys a **Snowflake Cortex AI Agent** that uses **Snowpark Python UDFs** as tools to interact with external APIs.

```
┌─────────────────────────────────────────────────────────────┐
│                    Snowflake Account                        │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Cortex AI Agent (Claude Sonnet 4)            │  │
│  │  - Created via REST API                              │  │
│  │  - Authenticated with Personal Access Token (PAT)    │  │
│  │  - Receives tool specifications (JSON)               │  │
│  └────────────┬─────────────────────────────────────────┘  │
│               │ Calls tools                                 │
│               ▼                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Snowpark Python UDFs (Tools)                 │  │
│  │  - Google Docs: CREATE_GOOGLE_DOC()                  │  │
│  │  - Google Sheets: CREATE_GOOGLE_SHEET()              │  │
│  │  - Salesforce: QUERY_SALESFORCE_ACCOUNTS()           │  │
│  │  - 33 total UDFs registered                          │  │
│  └────────────┬─────────────────────────────────────────┘  │
│               │ Uses External Access                        │
│               ▼                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │      External Access Integrations                    │  │
│  │  - Network rules (allowed endpoints)                 │  │
│  │  - Secrets (OAuth tokens, API keys)                  │  │
│  │  - Enables UDFs to call external APIs                │  │
│  └────────────┬─────────────────────────────────────────┘  │
│               │                                             │
└───────────────┼─────────────────────────────────────────────┘
                │
                ▼
    ┌───────────────────────┐      ┌──────────────────────┐
    │   Google Workspace    │      │     Salesforce       │
    │   - Docs API          │      │   - REST API         │
    │   - Sheets API        │      │   - SOQL queries     │
    │   - Drive API         │      │   - CRUD operations  │
    └───────────────────────┘      └──────────────────────┘
```

### Key Components

1. **Personal Access Token (PAT)**
   - Required to authenticate REST API calls to create/manage agents
   - Service user (`AGENT_SERVICE_USER`) needs network policy to use PAT
   - Created via: `ALTER USER AGENT_SERVICE_USER ADD PROGRAMMATIC ACCESS TOKEN`

2. **Snowpark Python UDFs**
   - Python functions that run inside Snowflake
   - Can be called as SQL functions: `SELECT CREATE_GOOGLE_DOC('My Doc')`
   - Can be used as AI agent tools via tool specifications
   - Uploaded to Snowflake stage as `.py` files

3. **External Access Integrations**
   - Allow UDFs to make HTTP requests to external APIs
   - Require network rules (whitelist of allowed endpoints)
   - Can attach secrets for authentication
   - Example: `GOOGLE_EXTERNAL_ACCESS` allows calls to `*.googleapis.com`

4. **Tool Specifications (JSON)**
   - Define how the agent uses UDFs as tools
   - Include: function name, description, parameters, return type
   - Agent receives these specs and knows when/how to call each tool
   - Example:
     ```json
     {
       "type": "FUNCTION",
       "function": {
         "name": "CREATE_GOOGLE_DOC",
         "description": "Creates a new Google Doc",
         "parameters": {
           "type": "object",
           "properties": {
             "title": {"type": "string", "description": "Document title"}
           }
         }
       }
     }
     ```

5. **Agent Deployment via REST API**
   - Agents are created via POST to Snowflake REST API
   - Must be in `snowflake_intelligence.agents` schema to appear in Snowsight UI
   - Configuration includes:
     - Tools (tool specs + UDF references)
     - Model (Claude Sonnet 4)
     - Instructions (system prompt)
     - Response format

---

### RBAC Model

This system implements enterprise-grade security using Snowflake's Role-Based Access Control (RBAC).

```
┌─────────────────────────────────────────────────────────────┐
│                    Snowflake Account                        │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              ACCOUNTADMIN Role                       │  │
│  │  - Creates all infrastructure (one-time setup)       │  │
│  │  - Grants permissions to service role                │  │
│  └────────────┬─────────────────────────────────────────┘  │
│               │ Grants permissions                          │
│               ▼                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           AGENTS_SERVICE_ROLE                        │  │
│  │  - Owns all agent infrastructure                     │  │
│  │  - Can create/modify UDFs                            │  │
│  │  - Can use external access integrations              │  │
│  │  - Can read/write secrets                            │  │
│  │  - Can execute agent operations                      │  │
│  └────────────┬─────────────────────────────────────────┘  │
│               │ Assigned to                                 │
│               ▼                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         AGENT_SERVICE_USER (TYPE=SERVICE)            │  │
│  │  - Service account for agent operations              │  │
│  │  - Uses Personal Access Token (PAT) for REST API     │  │
│  │  - Requires network policy for PAT usage             │  │
│  │  - Executes UDFs on behalf of agent                  │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Key Security Components

**1. Service User (AGENT_SERVICE_USER)**
- **Type:** SERVICE (not a human user)
- **Purpose:** Execute agent operations and UDFs
- **Authentication:** Personal Access Token (PAT)
- **Network Policy:** Required for PAT usage (security requirement)

**2. Service Role (AGENTS_SERVICE_ROLE)**
- **Owns:** Database, warehouse, stage, UDFs, secrets, integrations
- **Permissions:**
  - `USAGE` on database and warehouse
  - `CREATE FUNCTION` on schema
  - `USAGE` on external access integrations
  - `READ` on secrets
  - `EXECUTE` on all UDFs

**3. Separation of Duties**
- **ACCOUNTADMIN:** Sets up infrastructure (one-time)
- **AGENTS_SERVICE_ROLE:** Owns and operates agent resources
- **AGENT_SERVICE_USER:** Executes operations (no direct login)

**4. Network Policy**
```sql
CREATE NETWORK POLICY AGENTS_SERVICE_NETWORK_POLICY
  ALLOWED_IP_LIST = ('0.0.0.0/0')  -- Adjust for production
  COMMENT = 'Required for service user to use PAT';

ALTER USER AGENT_SERVICE_USER
  SET NETWORK_POLICY = AGENTS_SERVICE_NETWORK_POLICY;
```

**Why this matters:**
- Service users (TYPE=SERVICE) **cannot** use PAT without a network policy
- Network policy defines allowed IP ranges for authentication
- In production, restrict to specific IP ranges or VPCs

**5. Secret Management**
```sql
-- Secrets are owned by AGENTS_SERVICE_ROLE
CREATE SECRET google_oauth_secret
  TYPE = GENERIC_STRING
  SECRET_STRING = '<oauth_refresh_token>';

-- Only AGENTS_SERVICE_ROLE can read
GRANT READ ON SECRET google_oauth_secret
  TO ROLE AGENTS_SERVICE_ROLE;
```

**6. External Access Control**
```sql
-- External access integrations are owned by AGENTS_SERVICE_ROLE
CREATE EXTERNAL ACCESS INTEGRATION GOOGLE_EXTERNAL_ACCESS
  ALLOWED_NETWORK_RULES = (google_apis_network_rule)
  ALLOWED_AUTHENTICATION_SECRETS = (google_oauth_secret);

-- Only AGENTS_SERVICE_ROLE can use
GRANT USAGE ON INTEGRATION GOOGLE_EXTERNAL_ACCESS
  TO ROLE AGENTS_SERVICE_ROLE;
```

#### Production Hardening

**For production deployments, consider:**

1. **Restrict network policy:**
   ```sql
   CREATE NETWORK POLICY AGENTS_SERVICE_NETWORK_POLICY
     ALLOWED_IP_LIST = ('203.0.113.0/24')  -- Your VPC CIDR
     BLOCKED_IP_LIST = ('0.0.0.0/0');
   ```

2. **Rotate PAT regularly:**
   ```sql
   -- Revoke old token
   ALTER USER AGENT_SERVICE_USER DROP PROGRAMMATIC ACCESS TOKEN old_token;

   -- Create new token
   ALTER USER AGENT_SERVICE_USER ADD PROGRAMMATIC ACCESS TOKEN new_token;
   ```

3. **Audit access:**
   ```sql
   -- Query access history
   SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY
   WHERE USER_NAME = 'AGENT_SERVICE_USER'
   ORDER BY QUERY_START_TIME DESC;
   ```

4. **Separate environments:**
   - Dev: `AGENTS_DEMO` database
   - Prod: `AGENTS_PROD` database
   - Different service users per environment

---

## 📋 Prerequisites

- **Snowflake account** with ACCOUNTADMIN role
- **Python 3.8+** installed
- **Snowflake CLI** installed: `pip install snowflake-cli-labs`
- **Integration credentials** (choose what you need):
  - Google Cloud OAuth 2.0 (for Google Workspace)
  - Salesforce username/password/token (for Salesforce)

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/Roman-Gutin/GTME.git
cd GTME
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env
```

**Edit `.env` and configure:**

**Required (all deployments):**
- `SNOWFLAKE_ACCOUNT` - Your Snowflake account identifier
- `DEPLOY_GOOGLE_WORKSPACE` - Set to `true` or `false`
- `DEPLOY_SALESFORCE` - Set to `true` or `false`

**For Google Workspace** (if `DEPLOY_GOOGLE_WORKSPACE=true`):
- `GOOGLE_CLIENT_ID` - From Google Cloud Console
- `GOOGLE_CLIENT_SECRET` - From Google Cloud Console

**For Salesforce** (if `DEPLOY_SALESFORCE=true`):
- `SALESFORCE_USERNAME` - Your Salesforce username
- `SALESFORCE_PASSWORD` - Your Salesforce password
- `SALESFORCE_SECURITY_TOKEN` - Your Salesforce security token

### 3. Get Integration Credentials

<details>
<summary><b>Google Workspace Setup</b> (click to expand)</summary>

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Create a new project or select existing
3. Enable APIs: **Google Docs API**, **Google Sheets API**, **Google Drive API**
4. Create **OAuth 2.0 Client ID**:
   - Application type: **Desktop app**
   - Name: `GTME Agent`
5. Copy **Client ID** and **Client Secret** to `.env`

</details>

<details>
<summary><b>Salesforce Setup</b> (click to expand)</summary>

1. Log in to Salesforce
2. Go to **Setup** → **My Personal Information** → **Reset Security Token**
3. Check your email for the security token
4. Add to `.env`:
   - `SALESFORCE_USERNAME`: Your Salesforce login email
   - `SALESFORCE_PASSWORD`: Your Salesforce password
   - `SALESFORCE_SECURITY_TOKEN`: Token from email

</details>

### 4. Run Deployment

**Linux/Mac:**
```bash
chmod +x deploy.sh
./deploy.sh
```

**Windows:**
```cmd
deploy.bat
```

The script will:
1. ✅ Validate prerequisites and check credentials
2. ✅ Create Snowflake infrastructure (user, role, database, warehouse)
3. ✅ Deploy selected integrations:
   - Google Workspace: OAuth setup, upload handlers, create 22 UDFs
   - Salesforce: Upload handlers, create secrets, create 11 UDFs
4. ✅ Create the GTME Cortex AI Agent with selected tools
5. ✅ Run verification tests

### 5. Test Your Tools (Optional)

**Test Google Workspace:**
```bash
snow sql -f deployment/test_tools.sql
```

**Test Salesforce:**
```bash
snow sql -f tools/salesforce/test_sfdc_tools.sql
```

### 6. Access Your Agent

1. Go to [Snowsight](https://app.snowflake.com/)
2. Navigate to **AI & ML** → **Cortex** → **Agents**
3. Select **GTM_ENGINEER_AGENT**
4. Start chatting!

**Example prompts:**

<details>
<summary><b>Google Workspace Examples</b></summary>

```
Create a Google Doc called "Meeting Notes" with an agenda section

Create a Google Sheet called "Sales Pipeline" with columns:
Company, Contact, Stage, Amount, Close Date

Create a folder in Google Drive called "Q1 2025 Reports" and
share it with team@company.com

Search my Drive for all PDFs modified in the last week
```

</details>

<details>
<summary><b>Salesforce Examples</b></summary>

```
Show me all opportunities closing this quarter

Get details for account "Acme Corporation"

Create a new opportunity for account 001xxx with amount $50,000

What's the total pipeline value for this quarter?

List all custom objects in my Salesforce org
```

</details>

<details>
<summary><b>Combined Workflow Examples</b></summary>

```
Pull the top 10 opportunities from Salesforce and create a
Google Sheet with their details

Create a Google Doc summarizing all accounts in the
"Negotiation" stage

For each opportunity closing this month, create a folder in
Google Drive with the account name
```

</details>

---

## 🔧 Technical Deep Dive

### Understanding the Infrastructure

#### 1. Personal Access Token (PAT) Setup

**Why PAT is needed:**
- Snowflake Cortex AI Agents are created via REST API, not SQL
- REST API requires authentication via Personal Access Token
- Service users (TYPE=SERVICE) need a network policy to use PATs

**What the deployment does:**
```sql
-- Create service user
CREATE USER AGENT_SERVICE_USER TYPE = SERVICE;

-- Create network policy (required for PAT usage)
CREATE NETWORK POLICY AGENTS_SERVICE_NETWORK_POLICY
  ALLOWED_IP_LIST = ('0.0.0.0/0');

-- Attach policy to user
ALTER USER AGENT_SERVICE_USER
  SET NETWORK_POLICY = AGENTS_SERVICE_NETWORK_POLICY;

-- Generate PAT (done via Snow CLI)
snow sql -q "ALTER USER AGENT_SERVICE_USER
  ADD PROGRAMMATIC ACCESS TOKEN gtme_agent_token;"
```

**How it's used:**
```python
# In agent/api_client.py
headers = {
    "Authorization": f"Bearer {pat_token}",
    "Content-Type": "application/json"
}
response = requests.post(
    f"https://{account}.snowflakecomputing.com/api/v2/databases/..."
)
```

---

#### 2. Snowpark Python UDFs as Tools

**What are Snowpark UDFs?**
- Python functions that run inside Snowflake's compute environment
- Can import packages (via Anaconda or uploaded files)
- Can make HTTP requests (via External Access Integrations)
- Can be called as SQL functions OR used as AI agent tools

**Example: Google Docs UDF**

Handler file (`tools/gsuite/handlers/docs_handler.py`):
```python
def create_google_doc(title: str, content: str = "") -> str:
    import _snowflake
    import requests

    # Get OAuth token from secret
    token = _snowflake.get_generic_secret_string('google_oauth_secret')

    # Call Google Docs API
    response = requests.post(
        'https://docs.googleapis.com/v1/documents',
        headers={'Authorization': f'Bearer {token}'},
        json={'title': title}
    )
    return response.json()['documentId']
```

UDF registration (generated by `deployment/create_udfs.py`):
```sql
CREATE OR REPLACE FUNCTION CREATE_GOOGLE_DOC(title STRING, content STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('requests', 'snowflake-snowpark-python')
IMPORTS = ('@gtme_stage/docs_handler.py')
HANDLER = 'docs_handler.create_google_doc'
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_EXTERNAL_ACCESS)
SECRETS = ('google_oauth_secret' = google_oauth_secret);
```

**Dual usage:**

As SQL function:
```sql
SELECT CREATE_GOOGLE_DOC('My Document', 'Hello World');
-- Returns: document_id
```

As AI agent tool:
- Agent receives tool specification (JSON)
- Agent decides when to call the tool
- Agent calls: `CREATE_GOOGLE_DOC('Meeting Notes', '')`
- UDF executes and returns result

---

#### 3. External Access Integrations

**Purpose:**
- By default, Snowpark UDFs cannot make HTTP requests
- External Access Integrations whitelist allowed endpoints
- Can attach secrets for authentication

**Example: Google Workspace**

Network rule (allowed endpoints):
```sql
CREATE OR REPLACE NETWORK RULE google_apis_network_rule
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = (
    'docs.googleapis.com:443',
    'sheets.googleapis.com:443',
    'www.googleapis.com:443'
  );
```

External access integration:
```sql
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION GOOGLE_EXTERNAL_ACCESS
  ALLOWED_NETWORK_RULES = (google_apis_network_rule)
  ALLOWED_AUTHENTICATION_SECRETS = (google_oauth_secret)
  ENABLED = TRUE;
```

Attached to UDF:
```sql
CREATE FUNCTION CREATE_GOOGLE_DOC(...)
...
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_EXTERNAL_ACCESS)
SECRETS = ('google_oauth_secret' = google_oauth_secret);
```

**How it works:**
1. UDF calls `requests.post('https://docs.googleapis.com/...')`
2. Snowflake checks: Is `docs.googleapis.com` in allowed rules? ✅
3. UDF accesses secret: `_snowflake.get_generic_secret_string(...)`
4. Request made with OAuth token
5. Response returned to UDF, then to agent

---

#### 4. Tool Specifications

**What are tool specs?**
- JSON definitions that tell the agent how to use each UDF
- Include: function name, description, parameters, return type
- Agent uses these to decide when and how to call tools

**Example:** `tools/gsuite/specs/docs_tools.json`
```json
{
  "type": "FUNCTION",
  "function": {
    "name": "CREATE_GOOGLE_DOC",
    "description": "Creates a new Google Document",
    "parameters": {
      "type": "object",
      "properties": {
        "title": {
          "type": "string",
          "description": "The title of the new document"
        }
      },
      "required": ["title"]
    }
  }
}
```

**How agent uses it:**
1. User: "Create a doc called Meeting Notes"
2. Agent: "I need CREATE_GOOGLE_DOC tool"
3. Agent calls: `CREATE_GOOGLE_DOC(title='Meeting Notes')`
4. UDF executes, returns document ID
5. Agent responds with result

---

#### 5. Agent Deployment via REST API

**Why REST API?**
- Cortex AI Agents cannot be created via SQL (yet)
- Must use Snowflake REST API
- Requires Personal Access Token authentication

**Endpoint:**
```
POST https://{account}.snowflakecomputing.com/api/v2/
     databases/{db}/schemas/{schema}/agents/{name}
```

**Request body:**
```json
{
  "tools": [
    {
      "tool_spec": {
        "type": "FUNCTION",
        "function": {
          "name": "CREATE_GOOGLE_DOC",
          "description": "Creates a new Google Document",
          "parameters": { ... }
        }
      },
      "tool_resource": {
        "type": "FUNCTION",
        "function": { "name": "CREATE_GOOGLE_DOC" }
      }
    }
  ],
  "orchestration": {
    "model": "claude-sonnet-4",
    "instructions": "You are a GTM Engineer..."
  }
}
```

**Key points:**
- `tool_spec`: JSON definition (what agent sees)
- `tool_resource`: UDF reference (what gets executed)
- Must be in `snowflake_intelligence.agents` schema for Snowsight UI

**What deployment does:**
```python
# In agent/create_agent.py
from agent.tool_registry import ToolRegistry

# Load all tool specs from JSON files
registry = ToolRegistry()
registry.discover_tools()  # Finds tools/*/specs/*.json

# Create agent via REST API
client.create_agent(
    name="GTM_ENGINEER_AGENT",
    tools=registry.get_all_tools(),
    model="claude-sonnet-4"
)
```

---

## 📁 Repository Structure

```
GTME/
├── agent/                          # Agent creation and management
│   ├── create_agent.py            # Main agent creation script
│   ├── api_client.py              # Snowflake REST API client
│   ├── tool_registry.py           # Tool discovery and validation
│   └── config.py                  # Agent configuration
│
├── tools/                          # Tool integrations
│   ├── gsuite/                    # Google Workspace (22 tools)
│   │   ├── handlers/              # Python API wrappers
│   │   ├── specs/                 # Tool specifications (JSON)
│   │   ├── get_oauth_url.py       # OAuth helper
│   │   └── create_oauth_secret.py # Secret creation
│   │
│   └── salesforce/                # Salesforce CRM (11 tools)
│       ├── salesforce_tools/      # Python API wrappers
│       ├── deploy_to_snowflake.sh # Deployment script
│       ├── snowflake_setup.sql    # UDF creation
│       └── test_sfdc_tools.sql    # Test suite
│
├── deployment/                     # Deployment automation
│   ├── setup_snowflake.sql        # Infrastructure setup
│   ├── deploy_gsuite.py           # Google Workspace deployment
│   ├── create_udfs.py             # Dynamic UDF generation
│   ├── test_deployment.sql        # Infrastructure verification
│   └── test_tools.sql             # Google Workspace tests
│
├── deploy.sh                       # Master deployment (Linux/Mac)
├── deploy.bat                      # Master deployment (Windows)
├── .env.example                    # Environment template
└── README.md                       # This file
```

---

## 🎛️ Deployment Scenarios

### Scenario 1: Google Workspace Only

**Use case:** You only need Google Docs, Sheets, and Drive integration.

**Configuration in `.env`:**
```bash
DEPLOY_GOOGLE_WORKSPACE=true
DEPLOY_SALESFORCE=false
```

**Result:** Agent with 22 Google Workspace tools

---

### Scenario 2: Salesforce Only

**Use case:** You only need Salesforce CRM integration.

**Configuration in `.env`:**
```bash
DEPLOY_GOOGLE_WORKSPACE=false
DEPLOY_SALESFORCE=true
```

**Result:** Agent with 11 Salesforce tools

---

### Scenario 3: Full GTM Stack (Both)

**Use case:** Complete go-to-market automation with both platforms.

**Configuration in `.env`:**
```bash
DEPLOY_GOOGLE_WORKSPACE=true
DEPLOY_SALESFORCE=true
```

**Result:** Agent with 33 tools (22 Google + 11 Salesforce)

---

## 🧪 Testing Your Deployment

### Verify Infrastructure

```bash
snow sql -f deployment/test_deployment.sql
```

**Checks:**
- ✅ Snowflake stage created
- ✅ Python files uploaded
- ✅ External access integrations configured
- ✅ Secrets created
- ✅ UDFs registered
- ✅ Agent created

### Test Google Workspace Tools

```bash
snow sql -f deployment/test_tools.sql
```

**Tests all 22 tools:**
- Creates test documents, sheets, folders
- Performs CRUD operations
- Verifies sharing and permissions
- Cleans up test data

### Test Salesforce Tools

```bash
snow sql -f tools/salesforce/test_sfdc_tools.sql
```

**Tests all 11 tools:**
- Queries accounts and opportunities
- Creates test records
- Updates and retrieves data
- Tests discovery functions

---

## 🔧 Troubleshooting

<details>
<summary><b>Snow CLI not found</b></summary>

**Error:** `snow: command not found`

**Solution:**
```bash
pip install snowflake-cli-labs
```

Verify installation:
```bash
snow --version
```

</details>

<details>
<summary><b>Google OAuth authorization failed</b></summary>

**Error:** `Invalid OAuth credentials` or `Redirect URI mismatch`

**Solution:**
1. Verify `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` in `.env`
2. Check redirect URI in Google Cloud Console is `http://localhost:8080`
3. Ensure APIs are enabled: Docs, Sheets, Drive
4. Try generating a new OAuth token:
   ```bash
   python tools/gsuite/get_oauth_url.py
   ```

</details>

<details>
<summary><b>Salesforce authentication failed</b></summary>

**Error:** `INVALID_LOGIN` or `Authentication failure`

**Solution:**
1. Verify credentials in `.env`:
   - `SALESFORCE_USERNAME` - Your Salesforce email
   - `SALESFORCE_PASSWORD` - Your password
   - `SALESFORCE_SECURITY_TOKEN` - From email (reset if needed)
2. Reset security token: Setup → My Personal Information → Reset Security Token
3. Update secrets in Snowflake:
   ```bash
   snow sql -q "ALTER SECRET salesforce_username SET SECRET_STRING = 'your-email@salesforce.com';"
   ```

</details>

<details>
<summary><b>Agent not visible in Snowsight</b></summary>

**Error:** Agent created but not showing in UI

**Solution:**
1. Verify agent is in correct schema:
   ```bash
   snow sql -q "SHOW AGENTS IN SCHEMA snowflake_intelligence.agents;"
   ```
2. Check you're using the correct role: `AGENTS_SERVICE_ROLE`
3. Refresh Snowsight browser page
4. Navigate to: AI & ML → Cortex → Agents

</details>

<details>
<summary><b>UDF creation failed</b></summary>

**Error:** `Function already exists` or `Import path not found`

**Solution:**
1. Verify stage has files:
   ```bash
   snow sql -q "LIST @AGENTS_DEMO.PUBLIC.GSUITE_STAGE;"
   ```
2. Drop and recreate UDFs:
   ```bash
   python deployment/create_udfs.py
   ```
3. Check external access integration exists:
   ```bash
   snow sql -q "SHOW EXTERNAL ACCESS INTEGRATIONS;"
   ```

</details>

---

## 🔄 Adding New Integrations

The architecture is designed to be extensible. To add new tools (e.g., HubSpot, Slack, Jira):

1. **Create tool specifications** in `tools/{integration}/specs/*.json`
2. **Implement Python handlers** in `tools/{integration}/handlers/`
3. **Create deployment script** following the gsuite pattern
4. **Add to master deployment** in `deploy.sh` and `deploy.bat`
5. **Update agent configuration** in `agent/config.py`

See `tools/gsuite/` for reference implementation.
4. Run `python agent/create_agent.py --force`

The tool registry automatically discovers and validates all tools.

---

## 📚 Additional Documentation

### Integration-Specific Guides

- **Google Workspace**: See `tools/gsuite/` for OAuth setup and handler details
- **Salesforce**: See `tools/salesforce/README.md` for detailed Salesforce setup
- **Deployment Guide**: See `tools/salesforce/DEPLOYMENT_GUIDE.md` for advanced options

### Reference Documentation

- [Snowflake Cortex AI Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-ai)
- [Google Workspace API Documentation](https://developers.google.com/workspace)
- [Salesforce API Documentation](https://developer.salesforce.com/docs/apis)
- [Refactoring Status](REFACTORING_STATUS.md) - Implementation details

---

## 🎯 What's Next?

After successful deployment, you can:

1. **Customize the agent** - Edit `agent/config.py` to modify instructions
2. **Add more tools** - Follow the extensible architecture pattern
3. **Create workflows** - Combine tools for complex automation
4. **Monitor usage** - Check execution logs in Snowflake
5. **Scale up** - Deploy to production with proper RBAC

---

## 💡 Use Cases

### Sales & Marketing
- Auto-generate sales proposals in Google Docs from Salesforce opportunities
- Create pipeline reports in Google Sheets from Salesforce data
- Sync meeting notes from Google Docs to Salesforce accounts

### Operations
- Automated folder creation in Drive for new Salesforce accounts
- Weekly pipeline summaries emailed via Google Workspace
- Document generation for contract management

### Analytics
- Pull Salesforce data into Google Sheets for analysis
- Create executive dashboards combining both platforms
- Automated reporting workflows

---

## 🤝 Contributing

Contributions welcome! This repository demonstrates a clean, modular architecture for Snowflake Cortex AI Agents that can serve as a reference implementation.

**Areas for contribution:**
- Additional integrations (HubSpot, Slack, Jira, etc.)
- Enhanced tool specifications
- Improved error handling
- Documentation improvements

---

## 📄 License

MIT License - See LICENSE file for details

---

## 🙏 Acknowledgments

Built with:
- **Snowflake Cortex AI** - Agent orchestration
- **Claude Sonnet 4** - Language model
- **Google Workspace APIs** - Productivity tools
- **Salesforce APIs** - CRM integration

---

## 📞 Support

For issues or questions:
1. Check the [Troubleshooting](#-troubleshooting) section
2. Review integration-specific documentation
3. Open an issue on GitHub

---

**🚀 Ready to deploy? Run `./deploy.sh` and get started in 30 minutes!**

---

*Production-ready reference implementation for Snowflake Cortex AI Agents with Google Workspace and Salesforce integration*
