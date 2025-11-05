"""
Deploy Google Workspace tools to Snowflake

This script:
1. Uploads Python handlers to Snowflake stage
2. Creates external access integration for Google APIs
3. Creates all 22 UDFs (5 Docs, 6 Sheets, 11 Drive)

Prerequisites:
- .env file configured with Snowflake and Google credentials
- OAuth secret already created (run tools/gsuite/create_oauth_secret.py first)
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import snowflake.connector

# Load environment variables
load_dotenv()

# Get credentials
SNOWFLAKE_ACCOUNT = os.getenv('SNOWFLAKE_ACCOUNT')
SNOWFLAKE_USER = os.getenv('SNOWFLAKE_USER')
SNOWFLAKE_PAT = os.getenv('SNOWFLAKE_PAT')

# Validate
missing = []
if not SNOWFLAKE_ACCOUNT: missing.append('SNOWFLAKE_ACCOUNT')
if not SNOWFLAKE_USER: missing.append('SNOWFLAKE_USER')
if not SNOWFLAKE_PAT: missing.append('SNOWFLAKE_PAT')

if missing:
    print(f"❌ ERROR: Missing environment variables: {', '.join(missing)}")
    exit(1)

print("="*70)
print("DEPLOYING GOOGLE WORKSPACE TOOLS TO SNOWFLAKE")
print("="*70)

try:
    # Connect to Snowflake
    print("\n[1/4] Connecting to Snowflake...")
    conn = snowflake.connector.connect(
        account=SNOWFLAKE_ACCOUNT,
        user=SNOWFLAKE_USER,
        authenticator='oauth',
        token=SNOWFLAKE_PAT,
        warehouse='AGENTS_DEMO_WH',
        database='AGENTS_DEMO',
        schema='PUBLIC',
        role='AGENTS_SERVICE_ROLE'
    )
    cursor = conn.cursor()
    print("✅ Connected")

    # Create stage
    print("\n[2/4] Creating stage...")
    cursor.execute("""
        CREATE STAGE IF NOT EXISTS AGENTS_DEMO.PUBLIC.GSUITE_STAGE
          COMMENT = 'Stage for Google Workspace Python handlers'
    """)
    print("✅ Stage created")

    # Upload Python files
    print("\n[3/4] Uploading Python handlers...")
    handlers_dir = Path('tools/gsuite/handlers')
    
    for py_file in handlers_dir.glob('*.py'):
        print(f"  Uploading {py_file.name}...")
        cursor.execute(f"PUT file://{py_file.absolute()} @AGENTS_DEMO.PUBLIC.GSUITE_STAGE/gsuite_tools/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE")
    
    print("✅ Handlers uploaded")

    # Create external access integration
    print("\n[4/4] Creating external access integration...")
    cursor.execute("""
        CREATE OR REPLACE NETWORK RULE google_apis_network_rule
          MODE = EGRESS
          TYPE = HOST_PORT
          VALUE_LIST = (
            'oauth2.googleapis.com:443',
            'sheets.googleapis.com:443',
            'docs.googleapis.com:443',
            'www.googleapis.com:443',
            'drive.googleapis.com:443'
          )
    """)
    
    cursor.execute("""
        CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION google_workspace_integration
          ALLOWED_NETWORK_RULES = (google_apis_network_rule)
          ALLOWED_AUTHENTICATION_SECRETS = (google_oauth_secret)
          ENABLED = TRUE
    """)
    print("✅ External access integration created")

    cursor.close()
    conn.close()

    print("\n" + "="*70)
    print("✅ SUCCESS! Google Workspace tools deployed")
    print("="*70)
    print("\nNext step: Create UDFs")
    print("  python deployment/create_udfs.py")
    print("="*70)

except Exception as e:
    print(f"\n❌ ERROR: {str(e)}")
    import traceback
    traceback.print_exc()
    exit(1)

