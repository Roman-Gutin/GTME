-- Deploy FindAll UDFs (run after integration is created by ACCOUNTADMIN)
USE ROLE AGENTS_SERVICE_ROLE;
USE DATABASE AGENTS_DEMO;
USE SCHEMA PUBLIC;
USE WAREHOUSE AGENTS_DEMO_WH;

-- Create FindAll Run
CREATE OR REPLACE FUNCTION CREATE_FINDALL_RUN(
    OBJECTIVE VARCHAR,
    ENTITY_TYPE VARCHAR,
    MATCH_CONDITIONS VARCHAR,
    GENERATOR VARCHAR DEFAULT 'core',
    MATCH_LIMIT INTEGER DEFAULT 10
)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
EXTERNAL_ACCESS_INTEGRATIONS = (PARALLEL_API_INTEGRATION)
SECRETS = ('api_key' = PARALLEL_API_KEY)
HANDLER = 'create_findall_handler'
AS
$$
import json
import requests
import _snowflake

BETA_HEADER = 'findall-2025-09-15'
BASE_URL = 'https://api.parallel.ai'

def create_findall_handler(objective, entity_type, match_conditions, generator, match_limit):
    try:
        api_key = _snowflake.get_generic_secret_string('api_key')
        headers = {'x-api-key': api_key, 'Content-Type': 'application/json', 'parallel-beta': BETA_HEADER}
        conditions = json.loads(match_conditions) if isinstance(match_conditions, str) else match_conditions
        payload = {'objective': objective, 'entity_type': entity_type, 'match_conditions': conditions, 'generator': generator, 'match_limit': match_limit}
        response = requests.post(f'{BASE_URL}/v1beta/findall/runs', headers=headers, json=payload, timeout=120)
        if response.status_code == 200:
            result = response.json()
            return json.dumps({'success': True, 'findall_id': result.get('findall_id'), 'status': result.get('status', {}).get('status'), 'is_active': result.get('status', {}).get('is_active'), 'generator': result.get('generator')})
        else:
            return json.dumps({'success': False, 'error': f'HTTP {response.status_code}: {response.text}'})
    except Exception as e:
        return json.dumps({'success': False, 'error': str(e)})
$$;

-- Get FindAll Status
CREATE OR REPLACE FUNCTION GET_FINDALL_STATUS(FINDALL_ID VARCHAR)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
EXTERNAL_ACCESS_INTEGRATIONS = (PARALLEL_API_INTEGRATION)
SECRETS = ('api_key' = PARALLEL_API_KEY)
HANDLER = 'get_status_handler'
AS
$$
import json
import requests
import _snowflake

BETA_HEADER = 'findall-2025-09-15'
BASE_URL = 'https://api.parallel.ai'

def get_status_handler(findall_id):
    try:
        api_key = _snowflake.get_generic_secret_string('api_key')
        headers = {'x-api-key': api_key, 'Content-Type': 'application/json', 'parallel-beta': BETA_HEADER}
        response = requests.get(f'{BASE_URL}/v1beta/findall/runs/{findall_id}', headers=headers, timeout=120)
        if response.status_code == 200:
            result = response.json()
            status_obj = result.get('status', {})
            return json.dumps({'success': True, 'findall_id': findall_id, 'status': status_obj.get('status'), 'is_active': status_obj.get('is_active'), 'metrics': status_obj.get('metrics', {})})
        else:
            return json.dumps({'success': False, 'error': f'HTTP {response.status_code}: {response.text}'})
    except Exception as e:
        return json.dumps({'success': False, 'error': str(e)})
$$;

-- Get FindAll Results
CREATE OR REPLACE FUNCTION GET_FINDALL_RESULTS(FINDALL_ID VARCHAR)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
EXTERNAL_ACCESS_INTEGRATIONS = (PARALLEL_API_INTEGRATION)
SECRETS = ('api_key' = PARALLEL_API_KEY)
HANDLER = 'get_results_handler'
AS
$$
import json
import requests
import _snowflake

BETA_HEADER = 'findall-2025-09-15'
BASE_URL = 'https://api.parallel.ai'

def get_results_handler(findall_id):
    try:
        api_key = _snowflake.get_generic_secret_string('api_key')
        headers = {'x-api-key': api_key, 'Content-Type': 'application/json', 'parallel-beta': BETA_HEADER}
        response = requests.get(f'{BASE_URL}/v1beta/findall/runs/{findall_id}/result', headers=headers, timeout=120)
        if response.status_code == 200:
            result = response.json()
            run = result.get('run', {})
            candidates = result.get('candidates', [])
            matched = [c for c in candidates if c.get('match_status') == 'matched']
            return json.dumps({'success': True, 'findall_id': findall_id, 'status': run.get('status', {}).get('status'), 'is_active': run.get('status', {}).get('is_active'), 'matched_count': len(matched), 'candidates': matched})
        else:
            return json.dumps({'success': False, 'error': f'HTTP {response.status_code}: {response.text}'})
    except Exception as e:
        return json.dumps({'success': False, 'error': str(e)})
$$;

-- Extend FindAll Run
CREATE OR REPLACE FUNCTION EXTEND_FINDALL(FINDALL_ID VARCHAR, ADDITIONAL_MATCH_LIMIT INTEGER)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests')
EXTERNAL_ACCESS_INTEGRATIONS = (PARALLEL_API_INTEGRATION)
SECRETS = ('api_key' = PARALLEL_API_KEY)
HANDLER = 'extend_handler'
AS
$$
import json
import requests
import _snowflake

BETA_HEADER = 'findall-2025-09-15'
BASE_URL = 'https://api.parallel.ai'

def extend_handler(findall_id, additional_match_limit):
    try:
        api_key = _snowflake.get_generic_secret_string('api_key')
        headers = {'x-api-key': api_key, 'Content-Type': 'application/json', 'parallel-beta': BETA_HEADER}
        payload = {'additional_match_limit': additional_match_limit}
        response = requests.post(f'{BASE_URL}/v1beta/findall/runs/{findall_id}/extend', headers=headers, json=payload, timeout=120)
        if response.status_code == 200:
            result = response.json()
            return json.dumps({'success': True, 'findall_id': findall_id, 'new_match_limit': result.get('match_limit')})
        else:
            return json.dumps({'success': False, 'error': f'HTTP {response.status_code}: {response.text}'})
    except Exception as e:
        return json.dumps({'success': False, 'error': str(e)})
$$;

