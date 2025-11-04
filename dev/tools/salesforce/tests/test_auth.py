"""
Test authentication module.
"""

import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from salesforce_wrapper.auth import SalesforceAuth
from salesforce_wrapper.exceptions import AuthenticationError


def test_authentication():
    """Test basic authentication."""
    
    # Credentials - Replace with your actual Salesforce credentials
    username = "your-username@example.com"
    password = "your-password"  # Append security token if required
    client_id = "your-connected-app-client-id"
    client_secret = "your-connected-app-client-secret"
    # Use login.salesforce.com for OAuth, not the instance URL
    instance_url = "https://login.salesforce.com"
    
    print("Testing Salesforce Authentication...")
    print(f"Username: {username}")
    print(f"Instance: {instance_url}")
    
    try:
        # Initialize auth
        auth = SalesforceAuth(
            username=username,
            password=password,
            client_id=client_id,
            client_secret=client_secret,
            instance_url=instance_url
        )
        
        # Authenticate
        print("\nAuthenticating...")
        result = auth.authenticate()
        
        print("\n✓ Authentication successful!")
        print(f"Access Token: {result['access_token'][:20]}...")
        print(f"Instance URL: {result['instance_url']}")
        print(f"Token Type: {result['token_type']}")
        
        # Test session retrieval
        session_id = auth.get_session_id()
        print(f"\n✓ Session ID retrieved: {session_id[:20]}...")
        
        # Test instance URL retrieval
        inst_url = auth.get_instance_url()
        print(f"✓ Instance URL: {inst_url}")
        
        print("\n✅ All authentication tests passed!")
        return True
        
    except AuthenticationError as e:
        print(f"\n❌ Authentication failed: {e}")
        return False
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = test_authentication()
    sys.exit(0 if success else 1)

