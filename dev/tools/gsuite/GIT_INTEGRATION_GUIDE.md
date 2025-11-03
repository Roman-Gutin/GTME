# Git Integration with Snowflake Workspace

Complete guide to integrating your GTME repository with Snowflake Workspace for seamless code viewing and deployment.

## 🎯 Overview

Snowflake Workspace allows you to:
- View your Git repository code directly in Snowsight
- Execute SQL files from Git
- Automatically sync changes from your repository
- Manage versions and branches
- Deploy code directly from Git

## 📋 Prerequisites

- Snowflake account (Enterprise Edition or higher recommended)
- GitHub repository: `https://github.com/Roman-Gutin/GTME`
- ACCOUNTADMIN or equivalent role
- Personal Access Token (PAT) from GitHub

## 🚀 Step-by-Step Setup

### Step 1: Create GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Configure the token:
   - **Note**: `Snowflake GTME Integration`
   - **Expiration**: 90 days (or custom)
   - **Scopes**: Select `repo` (Full control of private repositories)
4. Click "Generate token"
5. **IMPORTANT**: Copy the token immediately (you won't see it again)

### Step 2: Create Git Repository in Snowflake

```sql
USE ROLE ACCOUNTADMIN;
USE DATABASE TEST;
USE SCHEMA PUBLIC;

-- Create API integration for GitHub
CREATE OR REPLACE API INTEGRATION git_api_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/Roman-Gutin/')
  ENABLED = TRUE;

-- Create secret for GitHub authentication
CREATE OR REPLACE SECRET github_secret
  TYPE = PASSWORD
  USERNAME = 'Roman-Gutin'
  PASSWORD = 'your-github-personal-access-token-here';

-- Create Git repository object
CREATE OR REPLACE GIT REPOSITORY gtme_repo
  API_INTEGRATION = git_api_integration
  ORIGIN = 'https://github.com/Roman-Gutin/GTME'
  GIT_CREDENTIALS = github_secret;

-- Verify repository is created
SHOW GIT REPOSITORIES;
```

### Step 3: Fetch Repository Content

```sql
-- Fetch the latest code from the main branch
ALTER GIT REPOSITORY gtme_repo FETCH;

-- List all branches
SHOW GIT BRANCHES IN gtme_repo;

-- List files in the repository
LS @gtme_repo/branches/main;

-- List files in the dev/tools/gsuite directory
LS @gtme_repo/branches/main/dev/tools/gsuite/;
```

### Step 4: View Code in Snowflake Workspace

#### Option A: Using Snowsight UI

1. Log into Snowsight (https://app.snowflake.com)
2. Navigate to **Data** → **Databases** → **TEST** → **PUBLIC**
3. Click on **Git Repositories**
4. Select **GTME_REPO**
5. Browse the file tree and view code directly

#### Option B: Using SQL

```sql
-- View a specific file
SELECT $1 FROM @gtme_repo/branches/main/dev/tools/gsuite/gsuite_tools/gdocs_handler.py;

-- View the README
SELECT $1 FROM @gtme_repo/branches/main/README.md;

-- View the setup SQL
SELECT $1 FROM @gtme_repo/branches/main/dev/tools/gsuite/snowflake_google_docs_complete_setup.sql;
```

### Step 5: Execute SQL Files from Git

```sql
-- Execute the setup script directly from Git
EXECUTE IMMEDIATE FROM @gtme_repo/branches/main/dev/tools/gsuite/snowflake_google_docs_complete_setup.sql;

-- Execute the test suite
EXECUTE IMMEDIATE FROM @gtme_repo/branches/main/dev/tools/gsuite/test_tools.sql;
```

### Step 6: Set Up Automatic Sync (Optional)

```sql
-- Create a task to automatically fetch updates every hour
CREATE OR REPLACE TASK sync_gtme_repo
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = 'USING CRON 0 * * * * UTC'  -- Every hour
AS
  ALTER GIT REPOSITORY gtme_repo FETCH;

-- Enable the task
ALTER TASK sync_gtme_repo RESUME;

-- Verify task is running
SHOW TASKS LIKE 'sync_gtme_repo';
```

## 📁 Repository Structure for Snowflake

Organize your GTME repository as follows:

```
GTME/
├── README.md                                    # Main repository README
├── dev/
│   └── tools/
│       └── gsuite/
│           ├── README.md                        # GTME_README.md
│           ├── GIT_INTEGRATION_GUIDE.md         # This file
│           ├── SNOWFLAKE_SETUP_GUIDE.md         # Setup guide
│           ├── snowflake.yml                    # Snow CLI config
│           ├── snowflake_google_docs_complete_setup.sql
│           ├── test_tools.sql
│           ├── deploy_to_snowflake.sh
│           ├── deploy_to_snowflake.bat
│           └── gsuite_tools/
│               ├── __init__.py
│               ├── gdocs_handler.py
│               └── README.md
```

## 🔄 Workflow: Local Development → Git → Snowflake

### 1. Local Development

```bash
# Make changes to your code
cd c:/Users/Owner/alpaca

# Test locally (if applicable)
python -m pytest tests/

# Commit changes
git add .
git commit -m "Add new feature"
```

### 2. Push to GitHub

```bash
# Push to dev branch first
git checkout -b dev
git push origin dev

# After testing, merge to main
git checkout main
git merge dev
git push origin main
```

### 3. Sync in Snowflake

```sql
-- Fetch latest changes
ALTER GIT REPOSITORY gtme_repo FETCH;

-- Verify new files/changes
LS @gtme_repo/branches/main/dev/tools/gsuite/;

-- Deploy updated code
EXECUTE IMMEDIATE FROM @gtme_repo/branches/main/dev/tools/gsuite/snowflake_google_docs_complete_setup.sql;
```

## 🎨 Using Snowflake Workspace UI

### Viewing Code

1. **Navigate to Repository**:
   - Snowsight → Data → Databases → TEST → PUBLIC → Git Repositories → GTME_REPO

2. **Browse Files**:
   - Click on folders to expand
   - Click on files to view content
   - Use search to find specific files

3. **View File History**:
   - Select a file
   - Click "History" to see commits
   - Compare versions

### Executing SQL from Workspace

1. **Open SQL File**:
   - Navigate to the SQL file in the repository
   - Click "Open in Worksheet"

2. **Execute**:
   - Review the SQL
   - Click "Run All" or select specific statements
   - View results in the output pane

## 🔐 Security Best Practices

### 1. Protect Your Credentials

```sql
-- Never commit credentials to Git
-- Use Snowflake secrets instead

-- Example: Reference secret in UDF
CREATE OR REPLACE FUNCTION my_function()
RETURNS VARIANT
SECRETS = ('cred' = google_oauth_secret)
AS ...
```

### 2. Use Separate Environments

```sql
-- Development
CREATE DATABASE DEV;
CREATE GIT REPOSITORY dev_gtme_repo
  ORIGIN = 'https://github.com/Roman-Gutin/GTME'
  GIT_CREDENTIALS = github_secret;

-- Production
CREATE DATABASE PROD;
CREATE GIT REPOSITORY prod_gtme_repo
  ORIGIN = 'https://github.com/Roman-Gutin/GTME'
  GIT_CREDENTIALS = github_secret;
```

### 3. Limit Access

```sql
-- Grant read-only access to developers
GRANT USAGE ON GIT REPOSITORY gtme_repo TO ROLE developer;

-- Grant full access to admins only
GRANT ALL ON GIT REPOSITORY gtme_repo TO ROLE sysadmin;
```

## 🐛 Troubleshooting

### Issue: "Authentication failed"

**Solution**: Regenerate GitHub PAT and update secret:

```sql
ALTER SECRET github_secret SET PASSWORD = 'new-token-here';
ALTER GIT REPOSITORY gtme_repo FETCH;
```

### Issue: "Repository not found"

**Solution**: Verify repository URL and permissions:

```sql
-- Check repository configuration
DESC GIT REPOSITORY gtme_repo;

-- Verify API integration
SHOW API INTEGRATIONS LIKE 'git_api_integration';
```

### Issue: "File not found in repository"

**Solution**: Ensure you're on the correct branch and path:

```sql
-- List all branches
SHOW GIT BRANCHES IN gtme_repo;

-- Check file path
LS @gtme_repo/branches/main/;
LS @gtme_repo/branches/dev/;
```

### Issue: "Cannot execute SQL from Git"

**Solution**: Verify file format and permissions:

```sql
-- Check file content
SELECT $1 FROM @gtme_repo/branches/main/your-file.sql LIMIT 10;

-- Ensure you have EXECUTE privilege
SHOW GRANTS ON GIT REPOSITORY gtme_repo;
```

## 📊 Monitoring Git Integration

```sql
-- View repository metadata
SELECT 
    SYSTEM$GIT_REPOSITORY_METADATA('gtme_repo') AS metadata;

-- Check last fetch time
SELECT 
    PARSE_JSON(SYSTEM$GIT_REPOSITORY_METADATA('gtme_repo')):last_fetch_time AS last_fetch;

-- View current branch
SELECT 
    PARSE_JSON(SYSTEM$GIT_REPOSITORY_METADATA('gtme_repo')):current_branch AS current_branch;
```

## 🎯 Advanced: CI/CD with GitHub Actions

Create `.github/workflows/deploy-to-snowflake.yml`:

```yaml
name: Deploy to Snowflake

on:
  push:
    branches: [ main ]
    paths:
      - 'dev/tools/gsuite/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Snow CLI
        run: pip install snowflake-cli-labs
      
      - name: Deploy to Snowflake
        env:
          SNOWFLAKE_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          SNOWFLAKE_USER: ${{ secrets.SNOWFLAKE_USER }}
          SNOWFLAKE_PASSWORD: ${{ secrets.SNOWFLAKE_PASSWORD }}
        run: |
          cd dev/tools/gsuite
          ./deploy_to_snowflake.sh
```

## ✅ Verification Checklist

- [ ] GitHub PAT created and saved securely
- [ ] API integration created in Snowflake
- [ ] Secret created with GitHub credentials
- [ ] Git repository object created
- [ ] Repository fetched successfully
- [ ] Files visible in Snowsight
- [ ] SQL files executable from Git
- [ ] Automatic sync task created (optional)
- [ ] Access controls configured
- [ ] CI/CD pipeline set up (optional)

## 📚 Additional Resources

- [Snowflake Git Integration Docs](https://docs.snowflake.com/en/developer-guide/git/git-overview)
- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [Snowflake Workspace Guide](https://docs.snowflake.com/en/user-guide/ui-snowsight-worksheets-gs)

---

**You're now ready to use Git integration with Snowflake Workspace!** 🎉

