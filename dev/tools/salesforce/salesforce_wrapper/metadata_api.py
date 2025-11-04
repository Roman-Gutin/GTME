"""
Metadata API module for Salesforce schema operations.
Pure Python SOAP implementation for creating objects and fields.
"""

import requests
import time
import xml.etree.ElementTree as ET
from typing import Dict, List, Any, Optional
from .constants import (
    METADATA_API_ENDPOINT, SOAP_NAMESPACES, DEPLOYMENT_STATUS,
    DEFAULT_TIMEOUT, METADATA_DEPLOY_TIMEOUT, FIELD_TYPES,
    DEFAULT_TEXT_LENGTH, DEFAULT_TEXTAREA_LENGTH,
    DEFAULT_NUMBER_PRECISION, DEFAULT_NUMBER_SCALE,
    DEFAULT_CURRENCY_PRECISION, DEFAULT_CURRENCY_SCALE
)
from .exceptions import MetadataAPIError, DeploymentError
from .utils import sanitize_api_name, build_custom_object_api_name


class MetadataAPI:
    """
    Handles Salesforce Metadata API operations using pure Python SOAP calls.
    
    This class provides methods for creating and modifying Salesforce metadata
    such as custom objects and fields.
    """
    
    def __init__(self, session_id: str, instance_url: str):
        """
        Initialize Metadata API client.
        
        Args:
            session_id: Salesforce session ID (access token)
            instance_url: Salesforce instance URL
        """
        self.session_id = session_id
        self.instance_url = instance_url.rstrip('/')
        self.metadata_url = f"{self.instance_url}{METADATA_API_ENDPOINT}"
    
    def _build_soap_envelope(self, body: str) -> str:
        """
        Build a SOAP envelope with session header.
        
        Args:
            body: SOAP body content
            
        Returns:
            str: Complete SOAP envelope XML
        """
        envelope = f"""<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" 
                  xmlns:met="http://soap.sforce.com/2006/04/metadata"
                  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <soapenv:Header>
        <met:SessionHeader>
            <met:sessionId>{self.session_id}</met:sessionId>
        </met:SessionHeader>
    </soapenv:Header>
    <soapenv:Body>
        {body}
    </soapenv:Body>
</soapenv:Envelope>"""
        return envelope
    
    def _make_soap_request(self, soap_body: str, soap_action: str = "") -> ET.Element:
        """
        Make a SOAP request to Metadata API.
        
        Args:
            soap_body: SOAP body content
            soap_action: SOAP action header value
            
        Returns:
            ElementTree.Element: Parsed XML response
            
        Raises:
            MetadataAPIError: If request fails
        """
        envelope = self._build_soap_envelope(soap_body)
        
        headers = {
            'Content-Type': 'text/xml; charset=UTF-8',
            'SOAPAction': soap_action,
        }
        
        try:
            response = requests.post(
                self.metadata_url,
                data=envelope.encode('utf-8'),
                headers=headers,
                timeout=DEFAULT_TIMEOUT
            )
            
            if response.status_code != 200:
                raise MetadataAPIError(f"SOAP request failed: HTTP {response.status_code} - {response.text}")
            
            # Parse XML response
            root = ET.fromstring(response.content)
            return root
            
        except requests.exceptions.RequestException as e:
            raise MetadataAPIError(f"Network error during SOAP request: {str(e)}")
        except ET.ParseError as e:
            raise MetadataAPIError(f"Failed to parse SOAP response: {str(e)}")
    
    def _parse_create_response(self, root: ET.Element) -> Dict[str, Any]:
        """
        Parse the response from a create metadata operation.
        
        Args:
            root: XML root element
            
        Returns:
            dict: Parsed response with success status and async process ID
        """
        # Define namespaces for parsing
        ns = {
            'soapenv': 'http://schemas.xmlsoap.org/soap/envelope/',
            'met': 'http://soap.sforce.com/2006/04/metadata'
        }
        
        # Find the result element
        result = root.find('.//met:result', ns)
        
        if result is None:
            # Check for fault
            fault = root.find('.//soapenv:Fault', ns)
            if fault is not None:
                fault_string = fault.find('.//faultstring', ns)
                error_msg = fault_string.text if fault_string is not None else "Unknown SOAP fault"
                raise MetadataAPIError(f"SOAP Fault: {error_msg}")
            raise MetadataAPIError("No result found in SOAP response")
        
        # Extract result fields
        success = result.find('met:success', ns)
        async_id = result.find('met:id', ns)
        
        return {
            'success': success is not None and success.text == 'true',
            'id': async_id.text if async_id is not None else None,
        }
    
    def check_deploy_status(self, async_process_id: str, max_wait: int = METADATA_DEPLOY_TIMEOUT) -> Dict[str, Any]:
        """
        Poll deployment status until complete or timeout.
        
        Args:
            async_process_id: Async process ID from create operation
            max_wait: Maximum seconds to wait
            
        Returns:
            dict: Deployment status and details
        """
        soap_body = f"""
        <met:checkDeployStatus>
            <met:asyncProcessId>{async_process_id}</met:asyncProcessId>
            <met:includeDetails>true</met:includeDetails>
        </met:checkDeployStatus>"""
        
        start_time = time.time()
        poll_interval = 2  # seconds
        
        while time.time() - start_time < max_wait:
            try:
                root = self._make_soap_request(soap_body, 'checkDeployStatus')
                status = self._parse_deploy_status(root)
                
                if status['done']:
                    return status
                
                time.sleep(poll_interval)
                
            except Exception as e:
                return {
                    'done': True,
                    'success': False,
                    'error': f"Failed to check deploy status: {str(e)}"
                }
        
        return {
            'done': False,
            'success': False,
            'error': f"Deployment timeout after {max_wait} seconds"
        }

    def _parse_deploy_status(self, root: ET.Element) -> Dict[str, Any]:
        """
        Parse deployment status response.

        Args:
            root: XML root element

        Returns:
            dict: Deployment status details
        """
        ns = {
            'soapenv': 'http://schemas.xmlsoap.org/soap/envelope/',
            'met': 'http://soap.sforce.com/2006/04/metadata'
        }

        result = root.find('.//met:result', ns)
        if result is None:
            return {'done': True, 'success': False, 'error': 'No result in response'}

        done = result.find('met:done', ns)
        success = result.find('met:success', ns)
        status = result.find('met:status', ns)

        # Get error details if any
        errors = []
        for error in result.findall('.//met:errors', ns):
            message = error.find('met:message', ns)
            if message is not None:
                errors.append(message.text)

        return {
            'done': done is not None and done.text == 'true',
            'success': success is not None and success.text == 'true',
            'status': status.text if status is not None else 'Unknown',
            'errors': errors,
        }

    def create_custom_object(
        self,
        label: str,
        plural_label: str,
        name_field_label: str = "Name",
        name_field_type: str = "Text",
        deployment_status: str = "Deployed",
        sharing_model: str = "ReadWrite",
        enable_activities: bool = True,
        enable_reports: bool = True,
        enable_search: bool = True,
        description: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Create a custom object in Salesforce.

        Args:
            label: Object label (e.g., "Use Case")
            plural_label: Plural label (e.g., "Use Cases")
            name_field_label: Label for the Name field
            name_field_type: Type of Name field (Text or AutoNumber)
            deployment_status: Deployed or InDevelopment
            sharing_model: ReadWrite, Read, Private, or ControlledByParent
            enable_activities: Enable activities (tasks/events)
            enable_reports: Enable in reports
            enable_search: Enable in search
            description: Optional description

        Returns:
            dict: Creation result with success status
        """
        # Build API name
        api_name = build_custom_object_api_name(label)

        # Build name field configuration
        name_field_xml = ""
        if name_field_type == "AutoNumber":
            name_field_xml = f"""
            <met:nameField xsi:type="met:AutoNumber">
                <met:label>{name_field_label}</met:label>
                <met:displayFormat>{{0000}}</met:displayFormat>
                <met:startingNumber>1</met:startingNumber>
            </met:nameField>"""
        else:
            name_field_xml = f"""
            <met:nameField xsi:type="met:Text">
                <met:label>{name_field_label}</met:label>
                <met:type>Text</met:type>
            </met:nameField>"""

        description_xml = f"<met:description>{description}</met:description>" if description else ""

        # Build SOAP body
        soap_body = f"""
        <met:createMetadata>
            <met:metadata xsi:type="met:CustomObject">
                <met:fullName>{api_name}</met:fullName>
                <met:label>{label}</met:label>
                <met:pluralLabel>{plural_label}</met:pluralLabel>
                <met:deploymentStatus>{deployment_status}</met:deploymentStatus>
                <met:sharingModel>{sharing_model}</met:sharingModel>
                <met:enableActivities>{str(enable_activities).lower()}</met:enableActivities>
                <met:enableReports>{str(enable_reports).lower()}</met:enableReports>
                <met:enableSearch>{str(enable_search).lower()}</met:enableSearch>
                {description_xml}
                {name_field_xml}
            </met:metadata>
        </met:createMetadata>"""

        try:
            root = self._make_soap_request(soap_body, 'createMetadata')
            result = self._parse_create_response(root)

            if result['success']:
                return {
                    'success': True,
                    'object_name': api_name,
                    'label': label,
                    'message': f"Custom object '{label}' created successfully"
                }
            else:
                return {
                    'success': False,
                    'error': 'Object creation failed',
                    'details': result
                }

        except Exception as e:
            raise MetadataAPIError(f"Failed to create custom object: {str(e)}")

    def create_custom_field(
        self,
        object_name: str,
        field_metadata: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Create a custom field on an object.

        Args:
            object_name: Object API name (e.g., "Use_Case__c")
            field_metadata: Field configuration dictionary

        Returns:
            dict: Creation result
        """
        field_type = field_metadata.get('type')
        label = field_metadata.get('label')

        if not field_type or not label:
            raise ValueError("Field metadata must include 'type' and 'label'")

        # Build field API name
        field_api_name = sanitize_api_name(label)
        if not field_api_name.endswith('__c'):
            field_api_name += '__c'

        full_name = f"{object_name}.{field_api_name}"

        # Build field-specific XML based on type
        field_xml = self._build_field_xml(field_type, field_metadata)

        soap_body = f"""
        <met:createMetadata>
            <met:metadata xsi:type="met:CustomField">
                <met:fullName>{full_name}</met:fullName>
                <met:label>{label}</met:label>
                {field_xml}
            </met:metadata>
        </met:createMetadata>"""

        try:
            root = self._make_soap_request(soap_body, 'createMetadata')
            result = self._parse_create_response(root)

            if result['success']:
                return {
                    'success': True,
                    'field_name': field_api_name,
                    'full_name': full_name,
                    'label': label,
                    'message': f"Field '{label}' created successfully"
                }
            else:
                return {
                    'success': False,
                    'error': 'Field creation failed',
                    'details': result
                }

        except Exception as e:
            raise MetadataAPIError(f"Failed to create custom field: {str(e)}")

    def _build_field_xml(self, field_type: str, metadata: Dict[str, Any]) -> str:
        """
        Build field-specific XML based on field type.

        Args:
            field_type: Field type (Text, Number, Picklist, etc.)
            metadata: Field configuration

        Returns:
            str: Field XML fragment
        """
        required = metadata.get('required', False)
        description = metadata.get('description', '')

        required_xml = f"<met:required>{str(required).lower()}</met:required>"
        description_xml = f"<met:description>{description}</met:description>" if description else ""

        if field_type == 'Text':
            length = metadata.get('length', DEFAULT_TEXT_LENGTH)
            return f"""
                <met:type>Text</met:type>
                <met:length>{length}</met:length>
                {required_xml}
                {description_xml}"""

        elif field_type == 'LongTextArea':
            length = metadata.get('length', DEFAULT_TEXTAREA_LENGTH)
            visible_lines = metadata.get('visible_lines', 3)
            return f"""
                <met:type>LongTextArea</met:type>
                <met:length>{length}</met:length>
                <met:visibleLines>{visible_lines}</met:visibleLines>
                {description_xml}"""

        elif field_type == 'Number':
            precision = metadata.get('precision', DEFAULT_NUMBER_PRECISION)
            scale = metadata.get('scale', DEFAULT_NUMBER_SCALE)
            unique = metadata.get('unique', False)
            return f"""
                <met:type>Number</met:type>
                <met:precision>{precision}</met:precision>
                <met:scale>{scale}</met:scale>
                <met:unique>{str(unique).lower()}</met:unique>
                {required_xml}
                {description_xml}"""

        elif field_type == 'Currency':
            precision = metadata.get('precision', DEFAULT_CURRENCY_PRECISION)
            scale = metadata.get('scale', DEFAULT_CURRENCY_SCALE)
            return f"""
                <met:type>Currency</met:type>
                <met:precision>{precision}</met:precision>
                <met:scale>{scale}</met:scale>
                {required_xml}
                {description_xml}"""

        elif field_type == 'Date':
            return f"""
                <met:type>Date</met:type>
                {required_xml}
                {description_xml}"""

        elif field_type == 'DateTime':
            return f"""
                <met:type>DateTime</met:type>
                {required_xml}
                {description_xml}"""

        elif field_type == 'Checkbox':
            default_value = metadata.get('default_value', False)
            return f"""
                <met:type>Checkbox</met:type>
                <met:defaultValue>{str(default_value).lower()}</met:defaultValue>
                {description_xml}"""

        elif field_type == 'Picklist':
            values = metadata.get('values', [])
            picklist_xml = self._build_picklist_xml(values)
            return f"""
                <met:type>Picklist</met:type>
                {picklist_xml}
                {required_xml}
                {description_xml}"""

        elif field_type == 'Email':
            unique = metadata.get('unique', False)
            return f"""
                <met:type>Email</met:type>
                <met:unique>{str(unique).lower()}</met:unique>
                {required_xml}
                {description_xml}"""

        elif field_type == 'Phone':
            return f"""
                <met:type>Phone</met:type>
                {required_xml}
                {description_xml}"""

        elif field_type == 'Url':
            return f"""
                <met:type>Url</met:type>
                {required_xml}
                {description_xml}"""

        elif field_type == 'Percent':
            precision = metadata.get('precision', DEFAULT_NUMBER_PRECISION)
            scale = metadata.get('scale', DEFAULT_NUMBER_SCALE)
            return f"""
                <met:type>Percent</met:type>
                <met:precision>{precision}</met:precision>
                <met:scale>{scale}</met:scale>
                {required_xml}
                {description_xml}"""

        elif field_type == 'Lookup':
            related_to = metadata.get('related_to')
            relationship_name = metadata.get('relationship_name')
            if not related_to:
                raise ValueError("Lookup field requires 'related_to' parameter")

            rel_name_xml = f"<met:relationshipName>{relationship_name}</met:relationshipName>" if relationship_name else ""
            return f"""
                <met:type>Lookup</met:type>
                <met:referenceTo>{related_to}</met:referenceTo>
                {rel_name_xml}
                <met:relationshipLabel>{metadata.get('label')}</met:relationshipLabel>
                {required_xml}
                {description_xml}"""

        elif field_type == 'MasterDetail':
            related_to = metadata.get('related_to')
            relationship_name = metadata.get('relationship_name')
            if not related_to:
                raise ValueError("MasterDetail field requires 'related_to' parameter")

            rel_name_xml = f"<met:relationshipName>{relationship_name}</met:relationshipName>" if relationship_name else ""
            return f"""
                <met:type>MasterDetail</met:type>
                <met:referenceTo>{related_to}</met:referenceTo>
                {rel_name_xml}
                <met:relationshipLabel>{metadata.get('label')}</met:relationshipLabel>
                <met:writeRequiresMasterRead>false</met:writeRequiresMasterRead>
                {description_xml}"""

        else:
            raise ValueError(f"Unsupported field type: {field_type}")

    def _build_picklist_xml(self, values: List[str]) -> str:
        """
        Build picklist values XML.

        Args:
            values: List of picklist values

        Returns:
            str: Picklist XML fragment
        """
        if not values:
            raise ValueError("Picklist must have at least one value")

        values_xml = []
        for i, value in enumerate(values):
            default = "true" if i == 0 else "false"
            values_xml.append(f"""
                <met:picklistValues>
                    <met:fullName>{value}</met:fullName>
                    <met:default>{default}</met:default>
                </met:picklistValues>""")

        return f"""
            <met:picklist>
                <met:sorted>false</met:sorted>
                {''.join(values_xml)}
            </met:picklist>"""
