#!/bin/bash
# ============================================================================
# GTME - Complete Deployment Script
# ============================================================================
# This script deploys the complete GTME Snowflake Cortex AI Agent
# Prerequisites:
#   - Snowflake CLI installed (pip install snowflake-cli-labs)
#   - .env file configured with credentials
#   - ACCOUNTADMIN access to Snowflake
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
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================================================${NC}"
}

print_step() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# ============================================================================
# Step 1: Check Prerequisites
# ============================================================================
print_header "Step 1: Checking Prerequisites"

# Check if .env exists
if [ ! -f .env ]; then
    print_error ".env file not found!"
    echo "Please copy .env.example to .env and fill in your credentials"
    exit 1
fi
print_step ".env file found"

# Check if snow CLI is installed
if ! command -v snow &> /dev/null; then
    print_error "Snowflake CLI not found!"
    echo "Install with: pip install snowflake-cli-labs"
    exit 1
fi
print_step "Snowflake CLI installed"

# Check if Python is installed
if ! command -v python &> /dev/null; then
    print_error "Python not found!"
    exit 1
fi
print_step "Python installed"

# Load environment variables
export $(cat .env | grep -v '^#' | xargs)
print_step "Environment variables loaded"

# ============================================================================
# Step 2: Setup Snowflake Infrastructure
# ============================================================================
print_header "Step 2: Setting Up Snowflake Infrastructure"

print_warning "This step requires ACCOUNTADMIN role"
echo "Please update deployment/setup_snowflake.sql with your username (line 93)"
read -p "Press Enter to continue or Ctrl+C to cancel..."

# Run setup SQL
snow sql -f deployment/setup_snowflake.sql

print_step "Snowflake infrastructure created"
print_warning "IMPORTANT: Copy the PAT token from the output above to your .env file as SNOWFLAKE_PAT"
read -p "Press Enter after updating .env with the PAT token..."

# Reload environment variables
export $(cat .env | grep -v '^#' | xargs)

# ============================================================================
# Step 3: Setup Google OAuth (if not already done)
# ============================================================================
print_header "Step 3: Google OAuth Setup"

echo "Have you already set up Google OAuth? (y/n)"
read -r oauth_done

if [ "$oauth_done" != "y" ]; then
    print_warning "Please follow these steps:"
    echo "1. Go to Google Cloud Console"
    echo "2. Create OAuth 2.0 credentials (Desktop application)"
    echo "3. Add credentials to .env file"
    echo "4. Run: python tools/gsuite/get_oauth_url.py"
    read -p "Press Enter after completing OAuth setup..."
else
    print_step "Google OAuth already configured"
fi

# ============================================================================
# Step 4: Deploy Google Workspace Tools
# ============================================================================
print_header "Step 4: Deploying Google Workspace Tools"

# Check if deployment script exists
if [ ! -f deployment/deploy_gsuite.py ]; then
    print_warning "deployment/deploy_gsuite.py not found - skipping for now"
    print_warning "You'll need to manually deploy Google Workspace functions"
else
    python deployment/deploy_gsuite.py
    print_step "Google Workspace tools deployed"
fi

# ============================================================================
# Step 5: Create Agent
# ============================================================================
print_header "Step 5: Creating GTME Cortex AI Agent"

python agent/create_agent.py --force

print_step "Agent created successfully!"

# ============================================================================
# Deployment Complete!
# ============================================================================
print_header "✓ DEPLOYMENT COMPLETE!"

echo ""
echo "Your GTME Cortex AI Agent is ready!"
echo ""
echo "Next Steps:"
echo "  1. Go to Snowsight: https://app.snowflake.com/"
echo "  2. Navigate to: AI & ML → Cortex → Agents"
echo "  3. Select: GTM_ENGINEER_AGENT"
echo "  4. Start chatting!"
echo ""
echo "Try these commands:"
echo "  - Create a Google Doc called 'Meeting Notes'"
echo "  - Create a Google Sheet called 'Sales Data' with headers"
echo "  - Create a folder in Google Drive called 'Q1 Reports'"
echo ""
print_header "============================================================================"

