-- Fix all IMPORTS paths to use TEST.PUBLIC.SALESFORCE_STAGE

CREATE OR REPLACE FUNCTION salesforce_create_account(account_data VARIANT)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('simple-salesforce==1.12.5')
IMPORTS = ('@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/core.py', '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/accounts.py')
HANDLER = 'create_account_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (salesforce_api_integration)
SECRETS = ('username' = salesforce_username, 'password' = salesforce_password, 'token' = salesforce_token)
AS
$$
import _snowflake
from accounts import AccountOperations

def create_account_handler(account_data):
    try:
        username = _snowflake.get_generic_secret_string('username')
        password = _snowflake.get_generic_secret_string('password')
        token = _snowflake.get_generic_secret_string('token')
        sf = AccountOperations(username, password, token)
        name = account_data.get('Name')
        if not name:
            return {'error': 'Name is required'}
        kwargs = {k: v for k, v in account_data.items() if k != 'Name'}
        account_id = sf.create_account(name, **kwargs)
        return account_id
    except Exception as e:
        return {'error': str(e)}
$$;

CREATE OR REPLACE FUNCTION salesforce_get_account_summary(account_id STRING)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('simple-salesforce==1.12.5')
IMPORTS = ('@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/core.py', '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/accounts.py')
HANDLER = 'get_account_summary_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (salesforce_api_integration)
SECRETS = ('username' = salesforce_username, 'password' = salesforce_password, 'token' = salesforce_token)
AS
$$
import _snowflake
from accounts import AccountOperations

def get_account_summary_handler(account_id):
    try:
        username = _snowflake.get_generic_secret_string('username')
        password = _snowflake.get_generic_secret_string('password')
        token = _snowflake.get_generic_secret_string('token')
        sf = AccountOperations(username, password, token)
        return sf.get_account_summary(account_id)
    except Exception as e:
        return {'error': str(e)}
$$;

CREATE OR REPLACE FUNCTION salesforce_get_opportunity(opportunity_id STRING)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('simple-salesforce==1.12.5')
IMPORTS = ('@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/core.py', '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/opportunities.py')
HANDLER = 'get_opportunity_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (salesforce_api_integration)
SECRETS = ('username' = salesforce_username, 'password' = salesforce_password, 'token' = salesforce_token)
AS
$$
import _snowflake
from opportunities import OpportunityOperations

def get_opportunity_handler(opportunity_id):
    try:
        username = _snowflake.get_generic_secret_string('username')
        password = _snowflake.get_generic_secret_string('password')
        token = _snowflake.get_generic_secret_string('token')
        sf = OpportunityOperations(username, password, token)
        return sf.get_opportunity(opportunity_id)
    except Exception as e:
        return {'error': str(e)}
$$;

CREATE OR REPLACE FUNCTION salesforce_create_opportunity(opportunity_data VARIANT)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('simple-salesforce==1.12.5')
IMPORTS = ('@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/core.py', '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/opportunities.py')
HANDLER = 'create_opportunity_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (salesforce_api_integration)
SECRETS = ('username' = salesforce_username, 'password' = salesforce_password, 'token' = salesforce_token)
AS
$$
import _snowflake
from opportunities import OpportunityOperations

def create_opportunity_handler(opportunity_data):
    try:
        username = _snowflake.get_generic_secret_string('username')
        password = _snowflake.get_generic_secret_string('password')
        token = _snowflake.get_generic_secret_string('token')
        sf = OpportunityOperations(username, password, token)
        return sf.create_opportunity(opportunity_data)
    except Exception as e:
        return {'error': str(e)}
$$;

CREATE OR REPLACE FUNCTION salesforce_update_opportunity(opportunity_id STRING, update_data VARIANT)
RETURNS BOOLEAN
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('simple-salesforce==1.12.5')
IMPORTS = ('@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/core.py', '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/opportunities.py')
HANDLER = 'update_opportunity_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (salesforce_api_integration)
SECRETS = ('username' = salesforce_username, 'password' = salesforce_password, 'token' = salesforce_token)
AS
$$
import _snowflake
from opportunities import OpportunityOperations

def update_opportunity_handler(opportunity_id, update_data):
    try:
        username = _snowflake.get_generic_secret_string('username')
        password = _snowflake.get_generic_secret_string('password')
        token = _snowflake.get_generic_secret_string('token')
        sf = OpportunityOperations(username, password, token)
        return sf.update_opportunity(opportunity_id, update_data)
    except Exception as e:
        return False
$$;

CREATE OR REPLACE FUNCTION salesforce_get_pipeline_summary()
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('simple-salesforce==1.12.5')
IMPORTS = ('@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/core.py', '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/opportunities.py')
HANDLER = 'get_pipeline_summary_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (salesforce_api_integration)
SECRETS = ('username' = salesforce_username, 'password' = salesforce_password, 'token' = salesforce_token)
AS
$$
import _snowflake
from opportunities import OpportunityOperations

def get_pipeline_summary_handler():
    try:
        username = _snowflake.get_generic_secret_string('username')
        password = _snowflake.get_generic_secret_string('password')
        token = _snowflake.get_generic_secret_string('token')
        sf = OpportunityOperations(username, password, token)
        return sf.get_pipeline_summary()
    except Exception as e:
        return {'error': str(e)}
$$;

CREATE OR REPLACE FUNCTION salesforce_get_contact(contact_id STRING)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('simple-salesforce==1.12.5')
IMPORTS = ('@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/core.py', '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/contacts.py')
HANDLER = 'get_contact_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (salesforce_api_integration)
SECRETS = ('username' = salesforce_username, 'password' = salesforce_password, 'token' = salesforce_token)
AS
$$
import _snowflake
from contacts import ContactOperations

def get_contact_handler(contact_id):
    try:
        username = _snowflake.get_generic_secret_string('username')
        password = _snowflake.get_generic_secret_string('password')
        token = _snowflake.get_generic_secret_string('token')
        sf = ContactOperations(username, password, token)
        return sf.get_contact(contact_id)
    except Exception as e:
        return {'error': str(e)}
$$;

CREATE OR REPLACE FUNCTION salesforce_list_objects()
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('simple-salesforce==1.12.5')
IMPORTS = ('@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/core.py', '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/discovery.py')
HANDLER = 'list_objects_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (salesforce_api_integration)
SECRETS = ('username' = salesforce_username, 'password' = salesforce_password, 'token' = salesforce_token)
AS
$$
import _snowflake
from discovery import DiscoveryOperations

def list_objects_handler():
    try:
        username = _snowflake.get_generic_secret_string('username')
        password = _snowflake.get_generic_secret_string('password')
        token = _snowflake.get_generic_secret_string('token')
        sf = DiscoveryOperations(username, password, token)
        return sf.list_all_objects()
    except Exception as e:
        return {'error': str(e)}
$$;

CREATE OR REPLACE FUNCTION salesforce_get_object_summary(object_name STRING)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('simple-salesforce==1.12.5')
IMPORTS = ('@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/core.py', '@TEST.PUBLIC.SALESFORCE_STAGE/salesforce_tools/discovery.py')
HANDLER = 'get_object_summary_handler'
EXTERNAL_ACCESS_INTEGRATIONS = (salesforce_api_integration)
SECRETS = ('username' = salesforce_username, 'password' = salesforce_password, 'token' = salesforce_token)
AS
$$
import _snowflake
from discovery import DiscoveryOperations

def get_object_summary_handler(object_name):
    try:
        username = _snowflake.get_generic_secret_string('username')
        password = _snowflake.get_generic_secret_string('password')
        token = _snowflake.get_generic_secret_string('token')
        sf = DiscoveryOperations(username, password, token)
        return sf.get_object_summary(object_name)
    except Exception as e:
        return {'error': str(e)}
$$;

SELECT 'All IMPORTS paths fixed to use TEST.PUBLIC.SALESFORCE_STAGE!' AS status;

