"""
Authentication module for Salesforce API.
Handles OAuth 2.0 Username-Password Flow and session management.
"""

import requests
from typing import Dict, Optional
from .constants import OAUTH_TOKEN_ENDPOINT, DEFAULT_TIMEOUT
from .exceptions import AuthenticationError, SessionExpiredError


class SalesforceAuth:
    """
    Handles Salesforce authentication using OAuth 2.0 Username-Password Flow.
    
    This class manages session tokens and provides methods for authentication
    and token refresh.
    """
    
    def __init__(
        self,
        username: str,
        password: str,
        client_id: str,
        client_secret: str,
        instance_url: str,
        security_token: Optional[str] = None
    ):
        """
        Initialize Salesforce authentication.
        
        Args:
            username: Salesforce username
            password: Salesforce password
            client_id: Connected App Client ID
            client_secret: Connected App Client Secret
            instance_url: Salesforce instance URL (e.g., https://login.salesforce.com)
            security_token: Security token (optional, required if IP not whitelisted)
        """
        self.username = username
        self.password = password
        self.client_id = client_id
        self.client_secret = client_secret
        self.instance_url = instance_url.rstrip('/')
        self.security_token = security_token or ''
        
        self._session_id: Optional[str] = None
        self._access_token: Optional[str] = None
        self._instance_url: Optional[str] = None
        
    def authenticate(self) -> Dict[str, str]:
        """
        Authenticate with Salesforce using OAuth 2.0 Username-Password Flow.
        
        Returns:
            dict: Authentication response containing access_token, instance_url, etc.
            
        Raises:
            AuthenticationError: If authentication fails
        """
        try:
            # Prepare OAuth request
            token_url = f"{self.instance_url}{OAUTH_TOKEN_ENDPOINT}"
            
            # Combine password with security token if provided
            full_password = f"{self.password}{self.security_token}"
            
            payload = {
                'grant_type': 'password',
                'client_id': self.client_id,
                'client_secret': self.client_secret,
                'username': self.username,
                'password': full_password,
            }
            
            headers = {
                'Content-Type': 'application/x-www-form-urlencoded',
            }
            
            response = requests.post(
                token_url,
                data=payload,
                headers=headers,
                timeout=DEFAULT_TIMEOUT
            )
            
            if response.status_code != 200:
                error_data = response.json() if response.text else {}
                error_msg = error_data.get('error_description', response.text)
                raise AuthenticationError(f"Authentication failed: {error_msg}")
            
            auth_data = response.json()
            
            # Store authentication details
            self._access_token = auth_data.get('access_token')
            self._instance_url = auth_data.get('instance_url')
            self._session_id = self._access_token  # For compatibility
            
            return {
                'access_token': self._access_token,
                'instance_url': self._instance_url,
                'token_type': auth_data.get('token_type', 'Bearer'),
                'issued_at': auth_data.get('issued_at'),
                'signature': auth_data.get('signature'),
            }
            
        except requests.exceptions.RequestException as e:
            raise AuthenticationError(f"Network error during authentication: {str(e)}")
        except Exception as e:
            raise AuthenticationError(f"Unexpected error during authentication: {str(e)}")
    
    def get_session_id(self) -> str:
        """
        Get the current session ID (access token).
        
        Returns:
            str: Current session ID
            
        Raises:
            SessionExpiredError: If no valid session exists
        """
        if not self._session_id:
            raise SessionExpiredError("No active session. Please authenticate first.")
        return self._session_id
    
    def get_access_token(self) -> str:
        """
        Get the current access token.
        
        Returns:
            str: Current access token
            
        Raises:
            SessionExpiredError: If no valid session exists
        """
        if not self._access_token:
            raise SessionExpiredError("No active session. Please authenticate first.")
        return self._access_token
    
    def get_instance_url(self) -> str:
        """
        Get the Salesforce instance URL.
        
        Returns:
            str: Instance URL
            
        Raises:
            SessionExpiredError: If not authenticated
        """
        if not self._instance_url:
            raise SessionExpiredError("No active session. Please authenticate first.")
        return self._instance_url
    
    def refresh_session(self) -> Dict[str, str]:
        """
        Refresh the current session by re-authenticating.
        
        Returns:
            dict: New authentication response
        """
        return self.authenticate()
    
    def is_authenticated(self) -> bool:
        """
        Check if currently authenticated.
        
        Returns:
            bool: True if authenticated, False otherwise
        """
        return self._access_token is not None and self._instance_url is not None

