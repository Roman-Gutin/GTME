# Salesforce Python Wrapper for Snowflake Cortex Agent

A comprehensive Python library for interacting with Salesforce Data API and Metadata API, designed specifically for deployment as Snowflake Cortex Agent tools.

## 🎯 Overview

This library provides **40+ functions** covering:
- **Discovery & Exploration**: Discover org structure, list objects, describe metadata
- **Data Operations (CRUD)**: Query, create, update, delete records
- **Metadata Operations**: Create custom objects and fields via pure Python SOAP implementation
- **High-Level Orchestration**: Complete workflows for object creation from requirements
- **Shortcuts**: Convenient functions for Account, Contact, and Opportunity objects

## ✨ Key Features

- ✅ **Pure Python Implementation** - No CLI dependencies, suitable for Snowflake UDFs
- ✅ **Metadata API via SOAP** - Create custom objects and fields programmatically
- ✅ **OAuth 2.0 Authentication** - Secure username-password flow
- ✅ **Comprehensive Error Handling** - Structured error responses
- ✅ **Type Hints** - Full type annotations for better IDE support
- ✅ **Retry Logic** - Automatic retry with exponential backoff

## 📦 Installation

```bash
# Install dependencies
pip install -r requirements.txt

# Or install individually
pip install simple-salesforce==1.12.5 requests>=2.31.0
```

## 🚀 Quick Start

### Basic Usage

```python
from salesforce_wrapper.sf_handler import SalesforceHandler

# Initialize handler
handler = SalesforceHandler(
    username="your-username@example.com",
    password="your-password",
    client_id="your-client-id",
    client_secret="your-client-secret",
    instance_url="https://your-instance.salesforce.com"
)

# Discover org
org_info = handler.discover_org()
print(f"Total objects: {org_info['total_objects']}")

# Query records
accounts = handler.get_all_accounts()

# Create a record
account_id = handler.create_account(
    name="Acme Corp",
    Type="Customer",
    Industry="Technology"
)

# Create a custom object
result = handler.create_custom_object(
    label="Use Case",
    plural_label="Use Cases",
    description="Track customer use cases"
)
```

### Complete Object Creation Example

```python
# Define requirements
requirements = {
    'label': 'Use Case',
    'plural_label': 'Use Cases',
    'description': 'Customer use case tracking',
    'fields': [
        {
            'type': 'Picklist',
            'label': 'Status',
            'values': ['Discovery', 'In Progress', 'Implemented'],
            'required': True
        },
        {
            'type': 'Picklist',
            'label': 'Priority',
            'values': ['High', 'Medium', 'Low']
        },
        {
            'type': 'LongTextArea',
            'label': 'Description',
            'length': 5000
        },
        {
            'type': 'Currency',
            'label': 'Expected ROI',
            'precision': 18,
            'scale': 2
        },
        {
            'type': 'Date',
            'label': 'Implementation Date'
        }
    ],
    'lookups': [
        {
            'label': 'Account',
            'related_to': 'Account'
        }
    ]
}

# Create complete object with all fields
result = handler.create_complete_custom_object(requirements)

if result['success']:
    print(f"✓ Object created: {result['object_name']}")
    print(f"✓ Fields created: {len(result['fields_created'])}")
else:
    print(f"✗ Errors: {result['errors']}")
```

## 📚 API Reference

### Discovery Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `discover_org()` | Get complete org overview | Dict with org info |
| `list_all_objects()` | List all objects | List[str] |
| `list_custom_objects()` | List custom objects only | List[str] |
| `describe_object(name)` | Get object metadata | Dict |
| `get_field_names(object_name)` | Get field names | List[str] |
| `search_objects(keyword)` | Search objects by keyword | List[Dict] |

### Data Operations (CRUD)

| Function | Description | Returns |
|----------|-------------|---------|
| `query_records(soql)` | Execute SOQL query | List[Dict] |
| `get_record(object, id)` | Get single record | Dict |
| `get_all_records(object, fields)` | Get all records | List[Dict] |
| `search_records(object, field, value)` | Search records | List[Dict] |
| `create_record(object, data)` | Create record | str (ID) |
| `update_record(object, id, data)` | Update record | bool |
| `delete_record(object, id)` | Delete record | bool |
| `count_records(object, where)` | Count records | int |

### Metadata Operations

| Function | Description | Returns |
|----------|-------------|---------|
| `create_custom_object(label, plural_label)` | Create custom object | Dict |
| `create_text_field(object, label, length)` | Create text field | Dict |
| `create_picklist_field(object, label, values)` | Create picklist | Dict |
| `create_textarea_field(object, label, length)` | Create long text | Dict |
| `create_number_field(object, label, precision, scale)` | Create number field | Dict |
| `create_currency_field(object, label, precision, scale)` | Create currency field | Dict |
| `create_date_field(object, label)` | Create date field | Dict |
| `create_lookup_field(object, label, related_to)` | Create lookup | Dict |
| `verify_object_exists(object_name)` | Check if object exists | bool |
| `verify_field_exists(object, field)` | Check if field exists | bool |

### High-Level Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `create_complete_custom_object(requirements)` | Create object with all fields | Dict |
| `test_object_creation(object_name)` | Verify object works | Dict |

### Account Shortcuts

| Function | Description | Returns |
|----------|-------------|---------|
| `get_all_accounts(fields)` | Get all accounts | List[Dict] |
| `create_account(name, **kwargs)` | Create account | str (ID) |
| `search_accounts(name)` | Search by name | List[Dict] |
| `get_account_by_id(id)` | Get single account | Dict |

## 🧪 Testing

```bash
# Test authentication
python tests/test_auth.py

# Run integration tests
python tests/test_integration.py
```

## 📁 Project Structure

```
salesforce_wrapper/
├── __init__.py              # Package initialization
├── auth.py                  # OAuth authentication
├── data_api.py             # REST API / CRUD operations
├── metadata_api.py         # SOAP API / Schema operations
├── discovery.py            # Discovery & exploration
├── shortcuts.py            # Account/Contact/Opportunity shortcuts
├── field_creators.py       # Field creation helpers
├── sf_handler.py           # Main handler (all functions)
├── utils.py                # Helper functions
├── constants.py            # Constants and configuration
└── exceptions.py           # Custom exceptions
```

## 🔧 Configuration

Create a `config.py` file:

```python
SALESFORCE_CONFIG = {
    'username': 'your-username@example.com',
    'password': 'your-password',
    'client_id': 'your-connected-app-client-id',
    'client_secret': 'your-connected-app-client-secret',
    'instance_url': 'https://your-instance.salesforce.com',
    'security_token': ''  # Optional if IP whitelisted
}
```

## 📖 Next Steps

See [SNOWFLAKE_INTEGRATION.md](SNOWFLAKE_INTEGRATION.md) for detailed instructions on deploying these functions as Snowflake Cortex Agent tools.

## 🤝 Contributing

This library is part of the GTME (Google Tools for Modern Enterprises) project.

## 📄 License

MIT License

