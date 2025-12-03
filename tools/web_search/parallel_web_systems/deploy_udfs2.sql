-- Additional FindAll UDFs
USE ROLE AGENTS_SERVICE_ROLE;
USE DATABASE AGENTS_DEMO;
USE SCHEMA PUBLIC;
USE WAREHOUSE AGENTS_DEMO_WH;

-- Enrich FindAll Run
CREATE OR REPLACE FUNCTION ENRICH_FINDALL(FINDALL_ID VARCHAR, OUTPUT_SCHEMA VARCHAR, PROCESSOR VARCHAR DEFAULT 'core')
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
EXTERNAL_ACCESS_INTEGRATIONS = (PARALLEL_API_INTEGRATION)
SECRETS = ('api_key' = PARALLEL_API_KEY)
HANDLER = 'enrich_handler'
AS
$$
import json
import requests
import _snowflake

BETA_HEADER = 'findall-2025-09-15'
BASE_URL = 'https://api.parallel.ai'

def enrich_handler(findall_id, output_schema, processor):
    try:
        api_key = _snowflake.get_generic_secret_string('api_key')
        headers = {'x-api-key': api_key, 'Content-Type': 'application/json', 'parallel-beta': BETA_HEADER}
        schema = json.loads(output_schema) if isinstance(output_schema, str) else output_schema
        payload = {'processor': processor, 'output_schema': schema}
        response = requests.post(f'{BASE_URL}/v1beta/findall/runs/{findall_id}/enrich', headers=headers, json=payload, timeout=120)
        if response.status_code == 200:
            result = response.json()
            return json.dumps({'success': True, 'findall_id': findall_id, 'enrichments': result.get('enrichments', [])})
        else:
            return json.dumps({'success': False, 'error': f'HTTP {response.status_code}: {response.text}'})
    except Exception as e:
        return json.dumps({'success': False, 'error': str(e)})
$$;

-- Cancel FindAll Run
CREATE OR REPLACE FUNCTION CANCEL_FINDALL(FINDALL_ID VARCHAR)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
EXTERNAL_ACCESS_INTEGRATIONS = (PARALLEL_API_INTEGRATION)
SECRETS = ('api_key' = PARALLEL_API_KEY)
HANDLER = 'cancel_handler'
AS
$$
import json
import requests
import _snowflake

BETA_HEADER = 'findall-2025-09-15'
BASE_URL = 'https://api.parallel.ai'

def cancel_handler(findall_id):
    try:
        api_key = _snowflake.get_generic_secret_string('api_key')
        headers = {'x-api-key': api_key, 'Content-Type': 'application/json', 'parallel-beta': BETA_HEADER}
        response = requests.post(f'{BASE_URL}/v1beta/findall/runs/{findall_id}/cancel', headers=headers, timeout=120)
        if response.status_code == 200:
            result = response.json()
            return json.dumps({'success': True, 'findall_id': findall_id, 'status': result.get('status', {}).get('status'), 'message': 'FindAll run cancelled'})
        else:
            return json.dumps({'success': False, 'error': f'HTTP {response.status_code}: {response.text}'})
    except Exception as e:
        return json.dumps({'success': False, 'error': str(e)})
$$;

-- Verify all FindAll functions
SHOW FUNCTIONS LIKE '%FINDALL%' IN SCHEMA AGENTS_DEMO.PUBLIC;

