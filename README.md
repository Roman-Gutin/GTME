# GTME - Go-To-Market Engineer AI Agent

> Production-ready Snowflake Cortex AI Agent with Google Workspace and Salesforce integration

Deploy a fully functional AI agent powered by Claude Sonnet 4 with up to **33 tools** in under 30 minutes.

## 🎯 What You Get

- **Snowflake Cortex AI Agent** with Claude Sonnet 4
- **Flexible Deployment Options**:
  - 📄 **Google Workspace** (22 tools): Docs, Sheets, Drive
  - 💼 **Salesforce** (11 tools): Accounts, Opportunities, Contacts, Discovery
  - 🚀 **Both Integrations** (33 tools): Full GTM automation
- **Single-Command Deployment** with automated setup scripts
- **Extensible Architecture** ready for additional integrations

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
