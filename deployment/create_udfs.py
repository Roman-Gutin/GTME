"""
Create all Google Workspace UDFs in Snowflake

This script creates 22 UDFs (5 Docs, 6 Sheets, 11 Drive) by reading
the tool specifications and generating the appropriate SQL.

Prerequisites:
- Python handlers uploaded to stage (run deploy_gsuite.py first)
- OAuth secret created (run tools/gsuite/create_oauth_secret.py first)
"""

import os
import json
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

# UDF mapping: tool name -> (handler_file, handler_class, handler_method)
UDF_MAPPINGS = {
    # Google Docs (5 tools)
    'create_google_doc': ('gdocs_handler.py', 'GDocsHandler', 'create_document', ['title']),
    'read_google_doc': ('gdocs_handler.py', 'GDocsHandler', 'read_document', ['document_id', 'extract_sections']),
    'insert_text_google_doc': ('gdocs_handler.py', 'GDocsHandler', 'insert_text', ['document_id', 'text', 'index_pos']),
    'delete_content_google_doc': ('gdocs_handler.py', 'GDocsHandler', 'delete_content', ['document_id', 'start_index', 'end_index']),
    'replace_all_text_google_doc': ('gdocs_handler.py', 'GDocsHandler', 'replace_all_text', ['document_id', 'find_text', 'replace_text', 'match_case']),
    
    # Google Sheets (6 tools)
    'create_google_sheet': ('gsheets_handler.py', 'GSheetsHandler', 'create_spreadsheet', ['title']),
    'read_sheet_data': ('gsheets_handler.py', 'GSheetsHandler', 'read_range', ['spreadsheet_id', 'range_notation']),
    'write_sheet_data': ('gsheets_handler.py', 'GSheetsHandler', 'write_range', ['spreadsheet_id', 'range_notation', 'data_values']),
    'append_sheet_data': ('gsheets_handler.py', 'GSheetsHandler', 'append_range', ['spreadsheet_id', 'range_notation', 'data_values']),
    'update_cell': ('gsheets_handler.py', 'GSheetsHandler', 'update_cell', ['spreadsheet_id', 'cell_notation', 'value']),
    'clear_sheet_data': ('gsheets_handler.py', 'GSheetsHandler', 'clear_range', ['spreadsheet_id', 'range_notation']),
    
    # Google Drive (11 tools)
    'create_drive_folder': ('gdrive_handler.py', 'GDriveHandler', 'create_folder', ['name', 'parent_id']),
    'list_folder_contents': ('gdrive_handler.py', 'GDriveHandler', 'list_folder_contents', ['folder_id', 'page_size', 'order_by']),
    'get_folder_metadata': ('gdrive_handler.py', 'GDriveHandler', 'get_file_metadata', ['folder_id']),
    'get_file_metadata': ('gdrive_handler.py', 'GDriveHandler', 'get_file_metadata', ['file_id']),
    'move_file': ('gdrive_handler.py', 'GDriveHandler', 'move_file', ['file_id', 'new_parent_id']),
    'copy_file': ('gdrive_handler.py', 'GDriveHandler', 'copy_file', ['file_id', 'new_name', 'parent_id']),
    'rename_file': ('gdrive_handler.py', 'GDriveHandler', 'rename_file', ['file_id', 'new_name']),
    'delete_file': ('gdrive_handler.py', 'GDriveHandler', 'delete_file', ['file_id']),
    'share_file': ('gdrive_handler.py', 'GDriveHandler', 'share_file', ['file_id', 'email', 'role', 'send_notification']),
    'list_permissions': ('gdrive_handler.py', 'GDriveHandler', 'list_permissions', ['file_id']),
    'remove_permission': ('gdrive_handler.py', 'GDriveHandler', 'remove_permission', ['file_id', 'permission_id']),
}

def generate_udf_sql(tool_name, handler_file, handler_class, handler_method, params):
    """Generate SQL to create a UDF"""
    
    # Build parameter list for SQL function signature
    sql_params = []
    for param in params:
        sql_params.append(f"{param.upper()} VARCHAR")
    
    params_str = ', '.join(sql_params) if sql_params else ''
    
    # Build handler call
    handler_params = ', '.join(params)
    
    # Get handler module name (without .py)
    handler_module = handler_file.replace('.py', '')
    
    sql = f"""
CREATE OR REPLACE FUNCTION AGENTS_DEMO.PUBLIC.{tool_name.upper()}({params_str})
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
HANDLER = '{tool_name}_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (google_workspace_integration)
SECRETS = ('cred' = google_oauth_secret)
IMPORTS = ('@AGENTS_DEMO.PUBLIC.GSUITE_STAGE/gsuite_tools/__init__.py', '@AGENTS_DEMO.PUBLIC.GSUITE_STAGE/gsuite_tools/{handler_file}')
AS $$
import _snowflake
from {handler_module} import {handler_class}

def {tool_name}_handler({handler_params}):
    handler = {handler_class}(_snowflake)
    return handler.{handler_method}({handler_params})
$$;
"""
    return sql

print("="*70)
print("CREATING GOOGLE WORKSPACE UDFS")
print("="*70)

try:
    # Connect to Snowflake
    print("\n[1/2] Connecting to Snowflake...")
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

    # Create UDFs
    print(f"\n[2/2] Creating {len(UDF_MAPPINGS)} UDFs...")
    
    for tool_name, (handler_file, handler_class, handler_method, params) in UDF_MAPPINGS.items():
        print(f"  Creating {tool_name.upper()}...")
        sql = generate_udf_sql(tool_name, handler_file, handler_class, handler_method, params)
        cursor.execute(sql)
    
    print(f"✅ Created {len(UDF_MAPPINGS)} UDFs")

    cursor.close()
    conn.close()

    print("\n" + "="*70)
    print("✅ SUCCESS! All Google Workspace UDFs created")
    print("="*70)
    print("\nNext step: Create agent")
    print("  python agent/create_agent.py")
    print("="*70)

except Exception as e:
    print(f"\n❌ ERROR: {str(e)}")
    import traceback
    traceback.print_exc()
    exit(1)

