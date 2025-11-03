#!/bin/bash

# ========================================
# Deploy Google Docs Tools to Snowflake
# ========================================

set -e  # Exit on error

echo "========================================="
echo "Google Docs Tools - Snowflake Deployment"
echo "========================================="
echo ""

# Configuration
SNOWFLAKE_ACCOUNT="${SNOWFLAKE_ACCOUNT:-}"
SNOWFLAKE_USER="${SNOWFLAKE_USER:-}"
SNOWFLAKE_DATABASE="${SNOWFLAKE_DATABASE:-TEST}"
SNOWFLAKE_SCHEMA="${SNOWFLAKE_SCHEMA:-PUBLIC}"
SNOWFLAKE_ROLE="${SNOWFLAKE_ROLE:-ACCOUNTADMIN}"
STAGE_NAME="GSUITE_STAGE"

# Check if Snow CLI is installed
if ! command -v snow &> /dev/null; then
    echo "❌ Snow CLI not found. Please install it first:"
    echo "   pip install snowflake-cli-labs"
    exit 1
fi

echo "✅ Snow CLI found"
echo ""

# Check if required files exist
echo "Checking required files..."
required_files=(
    "gsuite_tools/__init__.py"
    "gsuite_tools/gdocs_handler.py"
    "snowflake_google_docs_complete_setup.sql"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Required file not found: $file"
        exit 1
    fi
    echo "  ✓ $file"
done

echo ""
echo "========================================="
echo "Step 1: Upload Python Files to Stage"
echo "========================================="
echo ""

# Upload Python files using SnowSQL
echo "Uploading gsuite_tools/__init__.py..."
snow stage copy \
    gsuite_tools/__init__.py \
    "@${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.${STAGE_NAME}/gsuite_tools/" \
    --overwrite \
    --auto-compress false

echo "Uploading gsuite_tools/gdocs_handler.py..."
snow stage copy \
    gsuite_tools/gdocs_handler.py \
    "@${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.${STAGE_NAME}/gsuite_tools/" \
    --overwrite \
    --auto-compress false

echo ""
echo "✅ Python files uploaded successfully"
echo ""

# Verify files are uploaded
echo "Verifying uploaded files..."
snow stage list "@${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA}.${STAGE_NAME}/gsuite_tools/"

echo ""
echo "========================================="
echo "Step 2: Execute Setup SQL Script"
echo "========================================="
echo ""

# Execute the setup script
echo "Running snowflake_google_docs_complete_setup.sql..."
snow sql -f snowflake_google_docs_complete_setup.sql

echo ""
echo "✅ Setup script executed successfully"
echo ""

echo "========================================="
echo "Step 3: Verify Installation"
echo "========================================="
echo ""

# Verify functions are created
echo "Checking created functions..."
snow sql -q "SHOW FUNCTIONS LIKE '%GOOGLE_DOC%' IN SCHEMA ${SNOWFLAKE_DATABASE}.${SNOWFLAKE_SCHEMA};"

echo ""
echo "========================================="
echo "Deployment Complete! 🎉"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Run tests: snow sql -f test_tools.sql"
echo "2. Try reading a document:"
echo "   snow sql -q \"SELECT TEST.PUBLIC.READ_GOOGLE_DOC('your-doc-id', TRUE);\""
echo ""
echo "See SNOWFLAKE_SETUP_GUIDE.md for detailed usage instructions."
echo ""

