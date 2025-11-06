#!/bin/bash
# ============================================================================
# GTME - Master Deployment Script
# ============================================================================
# Deploys Snowflake Cortex AI Agent with Google Workspace and/or Salesforce
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# ============================================================================
# STEP 0: Prerequisites Check
# ============================================================================
print_header "STEP 0: Checking Prerequisites"

# Check if .env exists
if [ ! -f .env ]; then
    print_error ".env file not found!"
    echo "Please copy .env.example to .env and fill in your credentials:"
    echo "  cp .env.example .env"
    exit 1
fi

# Load environment variables
source .env

# Check Snow CLI
if ! command -v snow &> /dev/null; then
    print_error "Snow CLI not found!"
    echo "Please install: pip install snowflake-cli-labs"
    exit 1
fi
print_success "Snow CLI installed"

# Check Python
if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
    print_error "Python not found!"
    exit 1
fi
PYTHON_CMD=$(command -v python3 || command -v python)
print_success "Python found: $PYTHON_CMD"

# Check required environment variables
if [ -z "$SNOWFLAKE_ACCOUNT" ] || [ "$SNOWFLAKE_ACCOUNT" = "YOUR_ACCOUNT_ID" ]; then
    print_error "SNOWFLAKE_ACCOUNT not set in .env"
    exit 1
fi

# Determine what to deploy
DEPLOY_GSUITE=${DEPLOY_GOOGLE_WORKSPACE:-true}
DEPLOY_SFDC=${DEPLOY_SALESFORCE:-true}

print_info "Deployment Configuration:"
echo "  - Google Workspace: $DEPLOY_GSUITE"
echo "  - Salesforce: $DEPLOY_SFDC"

if [ "$DEPLOY_GSUITE" = "false" ] && [ "$DEPLOY_SFDC" = "false" ]; then
    print_error "Both integrations disabled! Set DEPLOY_GOOGLE_WORKSPACE=true or DEPLOY_SALESFORCE=true"
    exit 1
fi

# ============================================================================
# STEP 1: Snowflake Infrastructure Setup
# ============================================================================
print_header "STEP 1: Setting Up Snowflake Infrastructure"

print_info "Creating service user, role, database, warehouse..."
snow sql -f deployment/setup_snowflake.sql

if [ $? -ne 0 ]; then
    print_error "Snowflake setup failed"
    exit 1
fi

print_success "Snowflake infrastructure created"
print_warning "IMPORTANT: Copy the PAT token from above and add to .env as SNOWFLAKE_PAT"
echo ""
read -p "Press Enter after updating .env with PAT token..."

# Reload .env to get PAT
source .env

if [ -z "$SNOWFLAKE_PAT" ] || [ "$SNOWFLAKE_PAT" = "YOUR_PERSONAL_ACCESS_TOKEN" ]; then
    print_error "SNOWFLAKE_PAT not set in .env"
    exit 1
fi

# ============================================================================
# STEP 2: Google Workspace Deployment (Optional)
# ============================================================================
if [ "$DEPLOY_GSUITE" = "true" ]; then
    print_header "STEP 2: Deploying Google Workspace Tools"
    
    # Check credentials
    if [ -z "$GOOGLE_CLIENT_ID" ] || [ "$GOOGLE_CLIENT_ID" = "your-client-id.apps.googleusercontent.com" ]; then
        print_error "GOOGLE_CLIENT_ID not set in .env"
        exit 1
    fi
    
    # Get OAuth refresh token
    print_info "Getting Google OAuth refresh token..."
    print_warning "A browser window will open. Please authorize the application."
    $PYTHON_CMD tools/gsuite/get_oauth_url.py
    
    echo ""
    read -p "Enter the refresh token from the browser: " REFRESH_TOKEN
    
    if [ -z "$REFRESH_TOKEN" ]; then
        print_error "No refresh token provided"
        exit 1
    fi
    
    # Create OAuth secret
    print_info "Creating OAuth secret in Snowflake..."
    $PYTHON_CMD tools/gsuite/create_oauth_secret.py "$REFRESH_TOKEN"
    
    # Deploy handlers
    print_info "Uploading Python handlers to Snowflake stage..."
    $PYTHON_CMD deployment/deploy_gsuite.py
    
    # Create UDFs
    print_info "Creating Google Workspace UDFs..."
    $PYTHON_CMD deployment/create_udfs.py
    
    print_success "Google Workspace tools deployed (22 tools)"
else
    print_warning "Skipping Google Workspace deployment (DEPLOY_GOOGLE_WORKSPACE=false)"
fi

# ============================================================================
# STEP 3: Salesforce Deployment (Optional)
# ============================================================================
if [ "$DEPLOY_SFDC" = "true" ]; then
    print_header "STEP 3: Deploying Salesforce Tools"
    
    # Check credentials
    if [ -z "$SALESFORCE_USERNAME" ] || [ "$SALESFORCE_USERNAME" = "your-username@salesforce.com" ]; then
        print_error "SALESFORCE_USERNAME not set in .env"
        exit 1
    fi
    
    # Run Salesforce deployment
    print_info "Running Salesforce deployment script..."
    cd tools/salesforce
    ./deploy_to_snowflake.sh
    cd ../..
    
    # Update secrets with credentials from .env
    print_info "Updating Salesforce secrets..."
    snow sql -q "ALTER SECRET AGENTS_DEMO.PUBLIC.salesforce_username SET SECRET_STRING = '$SALESFORCE_USERNAME';"
    snow sql -q "ALTER SECRET AGENTS_DEMO.PUBLIC.salesforce_password SET SECRET_STRING = '$SALESFORCE_PASSWORD';"
    snow sql -q "ALTER SECRET AGENTS_DEMO.PUBLIC.salesforce_token SET SECRET_STRING = '$SALESFORCE_SECURITY_TOKEN';"
    
    print_success "Salesforce tools deployed (11 tools)"
else
    print_warning "Skipping Salesforce deployment (DEPLOY_SALESFORCE=false)"
fi

# ============================================================================
# STEP 4: Create Agent
# ============================================================================
print_header "STEP 4: Creating Cortex AI Agent"

# Determine agent configuration
if [ "$DEPLOY_GSUITE" = "true" ] && [ "$DEPLOY_SFDC" = "true" ]; then
    AGENT_CONFIG="gtm_engineer"
    TOOL_COUNT=33
elif [ "$DEPLOY_GSUITE" = "true" ]; then
    AGENT_CONFIG="minimal"
    TOOL_COUNT=22
elif [ "$DEPLOY_SFDC" = "true" ]; then
    AGENT_CONFIG="salesforce"
    TOOL_COUNT=11
fi

print_info "Creating agent with configuration: $AGENT_CONFIG ($TOOL_COUNT tools)"
$PYTHON_CMD agent/create_agent.py --config "$AGENT_CONFIG"

print_success "Agent created: $AGENT_NAME"

# ============================================================================
# STEP 5: Verification
# ============================================================================
print_header "STEP 5: Deployment Verification"

print_info "Running verification tests..."
snow sql -f deployment/test_deployment.sql

# ============================================================================
# DEPLOYMENT COMPLETE
# ============================================================================
print_header "🎉 DEPLOYMENT COMPLETE!"

echo -e "${GREEN}Your GTME agent is ready!${NC}\n"
echo "📊 Deployment Summary:"
echo "  - Agent Name: $AGENT_NAME"
echo "  - Total Tools: $TOOL_COUNT"
if [ "$DEPLOY_GSUITE" = "true" ]; then
    echo "  - Google Workspace: ✅ 22 tools"
fi
if [ "$DEPLOY_SFDC" = "true" ]; then
    echo "  - Salesforce: ✅ 11 tools"
fi

echo ""
echo "🚀 Next Steps:"
echo "  1. Go to Snowsight: https://app.snowflake.com/"
echo "  2. Navigate to: AI & ML → Cortex → Agents"
echo "  3. Select: $AGENT_NAME"
echo "  4. Start chatting!"

echo ""
echo "🧪 Run Tests (Optional):"
if [ "$DEPLOY_GSUITE" = "true" ]; then
    echo "  Google Workspace: snow sql -f deployment/test_tools.sql"
fi
if [ "$DEPLOY_SFDC" = "true" ]; then
    echo "  Salesforce: snow sql -f tools/salesforce/test_sfdc_tools.sql"
fi

echo ""
print_success "Deployment completed successfully! 🎉"

