#!/bin/bash

# Salesforce Wrapper - Snowflake Deployment Script
# This script uploads Python files to Snowflake stage and creates UDF functions

set -e  # Exit on error

echo "=========================================="
echo "Salesforce Wrapper - Snowflake Deployment"
echo "=========================================="
echo ""
echo "This script will:"
echo "  1. Upload Python files to Snowflake stage"
echo "  2. Verify uploaded files"
echo ""
echo "Prerequisites:"
echo "  - Snow CLI installed (pip install snowflake-cli-labs)"
echo "  - Snowflake connection configured"
echo "  - Stage TEST.PUBLIC.SALESFORCE_STAGE created"
echo ""

# Check if snow CLI is installed
if ! command -v snow &> /dev/null; then
    echo "ERROR: Snow CLI not found. Install with: pip install snowflake-cli-labs"
    exit 1
fi

echo "========================================="
echo "Step 1: Upload Python Files to Stage"
echo "========================================="
echo ""

# List of Python files to upload
files=(
    "__init__.py"
    "auth.py"
    "data_api.py"
    "metadata_api.py"
    "discovery.py"
    "shortcuts.py"
    "field_creators.py"
    "sf_handler.py"
    "utils.py"
    "constants.py"
    "exceptions.py"
)

# Upload each file
for file in "${files[@]}"; do
    echo "Uploading salesforce_wrapper/$file..."
    snow stage copy "salesforce_wrapper/$file" \
        @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/ \
        --overwrite \
        --auto-compress false
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Uploaded successfully"
    else
        echo "  ✗ Upload failed"
        exit 1
    fi
done

echo ""
echo "Python files uploaded successfully"
echo ""

# Verify files are uploaded
echo "Verifying uploaded files..."
snow stage list @TEST.PUBLIC.SALESFORCE_STAGE/salesforce_wrapper/

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Review SNOWFLAKE_INTEGRATION.md for setup instructions"
echo "  2. Create network rules and external access integration"
echo "  3. Create secret with Salesforce credentials"
echo "  4. Deploy UDF functions using provided SQL scripts"
echo ""
echo "Test with:"
echo "  SELECT TEST.PUBLIC.SALESFORCE_DISCOVER_ORG();"
echo ""

