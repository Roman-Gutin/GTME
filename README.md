# GTME - Go-To-Market Engineer AI Agent

> Production-ready Snowflake Cortex AI Agent with Google Workspace integration

Deploy a fully functional AI agent powered by Claude Sonnet 4 with 22 Google Workspace tools in under 30 minutes.

## 🎯 What You Get

- **Snowflake Cortex AI Agent** with Claude Sonnet 4
- **22 Google Workspace Tools**:
  - 📄 5 Google Docs tools (create, read, insert, delete, replace)
  - 📊 6 Google Sheets tools (create, read, write, append, update, clear)
  - 📁 11 Google Drive tools (folders, files, sharing, metadata)
- **Extensible Architecture** ready for Salesforce and other integrations
- **Single-Command Deployment** with automated setup scripts

## 📋 Prerequisites

- Snowflake account with **ACCOUNTADMIN** role
- Google Cloud Project with OAuth 2.0 credentials
- Python 3.8+ and Snowflake CLI installed

```bash
pip install snowflake-cli-labs
```

## 🚀 Quick Start

### 1. Clone and Configure

```bash
git clone https://github.com/Roman-Gutin/GTME.git
cd GTME

# Copy and edit environment file
cp .env.example .env
# Edit .env with your Snowflake account and Google OAuth credentials
```

### 2. Run Deployment Script

**Linux/Mac:**
```bash
chmod +x deployment/deploy.sh
./deployment/deploy.sh
```

**Windows:**
```cmd
deployment\deploy.bat
```

The script will:
1. ✅ Validate prerequisites
2. ✅ Create Snowflake infrastructure (user, role, database, warehouse)
3. ✅ Set up Google OAuth integration
4. ✅ Deploy Google Workspace functions
5. ✅ Create the GTME Cortex AI Agent

### 3. Access Your Agent

1. Go to [Snowsight](https://app.snowflake.com/)
2. Navigate to **AI & ML** → **Cortex** → **Agents**
3. Select **GTM_ENGINEER_AGENT**
4. Start chatting!

**Try these commands:**
```
Create a Google Doc called "Meeting Notes" with an agenda section

Create a Google Sheet called "Sales Data" with headers: Name, Revenue, Region

Create a folder in Google Drive called "Q1 Reports"
```

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
│   ├── gsuite/                    # Google Workspace integration
│   │   └── specs/                 # Tool specifications (JSON)
│   └── salesforce/                # Salesforce integration (future)
│
├── deployment/                     # Deployment automation
│   ├── deploy.sh                  # Linux/Mac deployment script
│   ├── deploy.bat                 # Windows deployment script
│   └── setup_snowflake.sql        # Snowflake infrastructure SQL
│
├── .env.example                    # Environment template
└── README.md                       # This file
```

## 🔧 Manual Setup (Alternative)

If you prefer manual setup, see the detailed steps below:

<details>
<summary>Click to expand manual setup instructions</summary>

### Step 1: Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with your credentials:
```bash
SNOWFLAKE_ACCOUNT=YOUR_ACCOUNT_ID
SNOWFLAKE_USER=AGENT_SERVICE_USER
SNOWFLAKE_PAT=YOUR_PERSONAL_ACCESS_TOKEN
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
```

### Step 2: Setup Snowflake Infrastructure

Run as **ACCOUNTADMIN**:
```bash
snow sql -f deployment/setup_snowflake.sql
```

This creates:
- Service user (`AGENT_SERVICE_USER`)
- Service role (`AGENTS_SERVICE_ROLE`)
- Database (`AGENTS_DEMO`)
- Warehouse (`AGENTS_DEMO_WH`)
- Network policy for PAT authentication
- `snowflake_intelligence.agents` schema for Snowsight visibility

**Important:** Copy the PAT token from the output and add to `.env`

### Step 3: Setup Google OAuth

```bash
python tools/gsuite/get_oauth_url.py
```

Follow the URL, authorize, and the script will create the OAuth secret in Snowflake.

### Step 4: Deploy Google Workspace Tools

```bash
python deployment/deploy_gsuite.py
```

### Step 5: Create Agent

```bash
python agent/create_agent.py
```

</details>

## 🔄 Adding New Integrations

The architecture is designed to be extensible. To add new tools:

1. Create tool specifications in `tools/{integration}/specs/*.json`
2. Implement handlers in `tools/{integration}/handlers/`
3. Create Snowflake UDFs in `tools/{integration}/sql/`
4. Run `python agent/create_agent.py --force`

The tool registry automatically discovers and validates all tools.

## 🐛 Troubleshooting

### Agent Not Visible in Snowsight

**Solution:** Agent must be in `snowflake_intelligence.agents` schema. The deployment script handles this automatically.

### "Array Not Supported" Error

**Solution:** Tool parameters must use `string` type with JSON format, not `array` type. All included tools are already configured correctly.

### Network Policy Error

**Solution:** Service users require a network policy to use PAT. The deployment script creates this automatically.

### OAuth Token Expired

**Solution:** Regenerate OAuth tokens:
```bash
python tools/gsuite/get_oauth_url.py
```

## 📚 Documentation

- [Snowflake Cortex AI Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-ai)
- [Google Workspace API Documentation](https://developers.google.com/workspace)
- [Refactoring Status](REFACTORING_STATUS.md) - Implementation details

## 🤝 Contributing

Contributions welcome! This repository demonstrates a clean, modular architecture for Snowflake Cortex AI Agents that can serve as a reference implementation.

## 📄 License

MIT License

---

**Built with ❤️ for GTM teams using Snowflake Cortex AI**

