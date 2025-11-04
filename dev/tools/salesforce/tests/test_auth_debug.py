"""
Debug authentication test with detailed error output.
"""

import requests
import json

# Credentials - Replace with your actual Salesforce credentials
username = "your-username@example.com"
password = "your-password"  # Append security token if required
client_id = "your-connected-app-client-id"
client_secret = "your-connected-app-client-secret"

print("Testing Salesforce OAuth Authentication")
print("=" * 60)
print(f"Username: {username}")
print(f"Client ID: {client_id[:20]}...")
print()

# Try authentication
token_url = "https://login.salesforce.com/services/oauth2/token"

payload = {
    'grant_type': 'password',
    'client_id': client_id,
    'client_secret': client_secret,
    'username': username,
    'password': password,  # Try without security token first
}

print("Attempting authentication...")
print(f"Token URL: {token_url}")
print()

try:
    response = requests.post(token_url, data=payload, timeout=30)
    
    print(f"Response Status: {response.status_code}")
    print(f"Response Headers: {dict(response.headers)}")
    print()
    
    if response.status_code == 200:
        data = response.json()
        print("✅ Authentication successful!")
        print(f"Access Token: {data.get('access_token', '')[:20]}...")
        print(f"Instance URL: {data.get('instance_url')}")
        print(f"Token Type: {data.get('token_type')}")
    else:
        print("❌ Authentication failed!")
        print(f"Response Text: {response.text}")
        
        try:
            error_data = response.json()
            print(f"Error: {error_data.get('error')}")
            print(f"Error Description: {error_data.get('error_description')}")
        except:
            pass

except Exception as e:
    print(f"❌ Exception occurred: {e}")
    import traceback
    traceback.print_exc()

