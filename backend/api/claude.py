"""
Harvia Cloud API Python Client
A comprehensive client library for the MyHarvia Cloud API v0.5.0

Usage:
    from harvia_api import HarviaAPI

    # Initialize client
    client = HarviaAPI(username="your-username", password="your-password")

    # Get devices
    devices = client.devices.list_devices()

    # Get device by serial number
    device = client.devices.get_device_by_serial("2513005304")

    # Get latest telemetry data
    data = client.data.get_latest_data(device_id="device-123")

    # Send device command
    client.devices.send_command(device_id="device-123", command="POWER_ON")
"""

import requests
from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
from dataclasses import dataclass


class HarviaAPIError(Exception):
    """Base exception for Harvia API errors"""
    pass


class AuthenticationError(HarviaAPIError):
    """Authentication related errors"""
    pass


class APIRequestError(HarviaAPIError):
    """API request errors"""
    pass


@dataclass
class DeviceAttribute:
    """Device attribute key-value pair"""
    key: str
    value: str

    @classmethod
    def from_dict(cls, data: Dict[str, str]) -> 'DeviceAttribute':
        return cls(key=data['key'], value=data['value'])

    def to_dict(self) -> Dict[str, str]:
        return {'key': self.key, 'value': self.value}


@dataclass
class Device:
    """Harvia device object"""
    name: str  # Device UUID
    type: str  # Device type (e.g., 'Fenix', 'SaunaSensor')
    attributes: List[DeviceAttribute]

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Device':
        return cls(
            name=data['name'],
            type=data['type'],
            attributes=[DeviceAttribute.from_dict(attr) for attr in data.get('attr', [])]
        )

    def to_dict(self) -> Dict[str, Any]:
        return {
            'name': self.name,
            'type': self.type,
            'attr': [attr.to_dict() for attr in self.attributes]
        }

    def get_attribute(self, key: str) -> Optional[str]:
        """Get attribute value by key"""
        for attr in self.attributes:
            if attr.key == key:
                return attr.value
        return None

    def get_attributes_dict(self) -> Dict[str, str]:
        """Get all attributes as a dictionary"""
        return {attr.key: attr.value for attr in self.attributes}

    @property
    def device_id(self) -> str:
        """Device UUID (alias for name)"""
        return self.name

    @property
    def serial_number(self) -> Optional[str]:
        """Device serial number"""
        return self.get_attribute('serialNumber')

    @property
    def brand(self) -> Optional[str]:
        """Device brand"""
        return self.get_attribute('brand')

    @property
    def is_connected(self) -> bool:
        """Check if device is connected"""
        return self.get_attribute('connected') == 'true'

    @property
    def bt_mac(self) -> Optional[str]:
        """Bluetooth MAC address"""
        return self.get_attribute('BT_MAC')

    @property
    def organization(self) -> Optional[str]:
        """Organization ID"""
        return self.get_attribute('organization')

    @property
    def created_at(self) -> Optional[str]:
        """Device creation timestamp"""
        return self.get_attribute('createdAt')

    def __repr__(self) -> str:
        return f"Device(name='{self.name}', type='{self.type}', serial='{self.serial_number}', connected={self.is_connected})"


class HarviaAuth:
    """Handles authentication and token management"""

    def __init__(self, rest_api_base_url: str):
        self.rest_api_base_url = rest_api_base_url
        self.id_token: Optional[str] = None
        self.access_token: Optional[str] = None
        self.refresh_token: Optional[str] = None
        self.token_expiry: Optional[datetime] = None
        self.username: Optional[str] = None

    def sign_in(self, username: str, password: str) -> Dict[str, Any]:
        """
        Authenticate and obtain JWT tokens

        Args:
            username: User's username/email
            password: User's password

        Returns:
            Dictionary containing tokens and expiry info

        Raises:
            AuthenticationError: If authentication fails
        """
        try:
            response = requests.post(
                f"{self.rest_api_base_url}/auth/token",
                headers={"Content-Type": "application/json"},
                json={"username": username, "password": password}
            )

            if not response.ok:
                error_data = response.json() if response.content else {}
                error_msg = error_data.get("message", f"Authentication failed: {response.status_code}")
                raise AuthenticationError(error_msg)

            tokens = response.json()
            self.id_token = tokens["idToken"]
            self.access_token = tokens["accessToken"]
            self.refresh_token = tokens["refreshToken"]
            self.username = username

            # Set token expiry (expires_in is in seconds, default 3600 = 1 hour)
            expires_in = tokens.get("expiresIn", 3600)
            self.token_expiry = datetime.now() + timedelta(seconds=expires_in - 60)  # Refresh 1 min early

            return {
                "id_token": self.id_token,
                "access_token": self.access_token,
                "refresh_token": self.refresh_token,
                "expires_in": expires_in
            }
        except requests.RequestException as e:
            raise AuthenticationError(f"Network error during authentication: {str(e)}")

    def refresh(self) -> Dict[str, Any]:
        """
        Refresh JWT tokens using refresh token

        Returns:
            Dictionary containing new tokens and expiry info

        Raises:
            AuthenticationError: If token refresh fails
        """
        if not self.refresh_token or not self.username:
            raise AuthenticationError("No refresh token or username available. Please sign in first.")

        try:
            response = requests.post(
                f"{self.rest_api_base_url}/auth/refresh",
                headers={"Content-Type": "application/json"},
                json={"refreshToken": self.refresh_token, "email": self.username}
            )

            if not response.ok:
                error_data = response.json() if response.content else {}
                error_msg = error_data.get("message", f"Token refresh failed: {response.status_code}")
                raise AuthenticationError(error_msg)

            tokens = response.json()
            self.id_token = tokens["idToken"]
            self.access_token = tokens["accessToken"]

            # Update token expiry
            expires_in = tokens.get("expiresIn", 3600)
            self.token_expiry = datetime.now() + timedelta(seconds=expires_in - 60)

            return {
                "id_token": self.id_token,
                "access_token": self.access_token,
                "expires_in": expires_in
            }
        except requests.RequestException as e:
            raise AuthenticationError(f"Network error during token refresh: {str(e)}")

    def revoke(self) -> Dict[str, bool]:
        """
        Revoke refresh token

        Returns:
            Dictionary with success status

        Raises:
            AuthenticationError: If token revocation fails
        """
        if not self.refresh_token or not self.username:
            raise AuthenticationError("No refresh token or username available.")

        try:
            response = requests.post(
                f"{self.rest_api_base_url}/auth/revoke",
                headers={"Content-Type": "application/json"},
                json={"refreshToken": self.refresh_token, "email": self.username}
            )

            if not response.ok:
                error_data = response.json() if response.content else {}
                error_msg = error_data.get("message", f"Token revocation failed: {response.status_code}")
                raise AuthenticationError(error_msg)

            result = response.json()

            # Clear tokens after successful revocation
            self.refresh_token = None

            return result
        except requests.RequestException as e:
            raise AuthenticationError(f"Network error during token revocation: {str(e)}")

    def is_token_expired(self) -> bool:
        """Check if the current token is expired or about to expire"""
        if not self.token_expiry:
            return True
        return datetime.now() >= self.token_expiry

    def ensure_valid_token(self):
        """Ensure we have a valid token, refresh if necessary"""
        if self.is_token_expired():
            if self.refresh_token:
                self.refresh()
            else:
                raise AuthenticationError("Token expired and no refresh token available. Please sign in again.")

    def get_auth_header(self) -> Dict[str, str]:
        """Get authorization header with valid token"""
        self.ensure_valid_token()
        return {"Authorization": f"Bearer {self.id_token}"}


class HarviaDeviceService:
    """Device Service - Device management and control"""

    def __init__(self, auth: HarviaAuth, device_rest_api_url: str, graphql_endpoint: str):
        self.auth = auth
        self.device_rest_api_url = device_rest_api_url
        self.graphql_endpoint = graphql_endpoint

    def list_devices(self) -> List[Device]:
        """
        List user's devices (REST API)

        Returns:
            List of Device objects
        """
        try:
            response = requests.get(
                f"{self.device_rest_api_url}/devices",
                headers={
                    "Content-Type": "application/json",
                    **self.auth.get_auth_header()
                }
            )

            if not response.ok:
                error_body = response.text
                try:
                    error_data = response.json()
                    error_msg = error_data.get("message", error_body)
                except:
                    error_msg = error_body
                raise APIRequestError(f"Failed to list devices (HTTP {response.status_code}): {error_msg}")

            data = response.json()
            devices_data = data.get('devices', [])
            return [Device.from_dict(device_data) for device_data in devices_data]
        except requests.RequestException as e:
            raise APIRequestError(f"Network error listing devices: {str(e)}")

    def get_device_by_id(self, device_id: str) -> Optional[Device]:
        """
        Get device by UUID/name

        Args:
            device_id: Device UUID (name field)

        Returns:
            Device object or None if not found
        """
        devices = self.list_devices()
        for device in devices:
            if device.name == device_id:
                return device
        return None

    def get_device_by_serial(self, serial_number: str) -> Optional[Device]:
        """
        Get device by serial number

        Args:
            serial_number: Device serial number

        Returns:
            Device object or None if not found
        """
        devices = self.list_devices()
        for device in devices:
            if device.serial_number == serial_number:
                return device
        return None

    def get_devices_by_type(self, device_type: str) -> List[Device]:
        """
        Get all devices of a specific type

        Args:
            device_type: Device type (e.g., 'Fenix', 'SaunaSensor')

        Returns:
            List of Device objects
        """
        devices = self.list_devices()
        return [device for device in devices if device.type == device_type]

    def get_connected_devices(self) -> List[Device]:
        """
        Get all connected devices

        Returns:
            List of connected Device objects
        """
        devices = self.list_devices()
        return [device for device in devices if device.is_connected]

    def send_command(self, device_id: str, state: str) -> Dict[str, Any]:
        """
        Send command to a device (REST API)

        Args:
            device_id: Device identifier (UUID)
            command: Command to send (e.g., "POWER_ON", "POWER_OFF")
            **params: Additional command parameters

        Returns:
            Command response
        """
        try:
            payload = {
                "deviceId": device_id,
                "command": {"type": "SAUNA", "state": state}
            }

            response = requests.post(
                f"{self.device_rest_api_url}/devices/command",
                headers={
                    "Content-Type": "application/json",
                    **self.auth.get_auth_header()
                },
                json=payload
            )

            if not response.ok:
                error_body = response.text
                try:
                    error_data = response.json()
                    error_msg = error_data.get("message", error_body)
                except:
                    error_msg = error_body
                raise APIRequestError(f"Failed to send command (HTTP {response.status_code}): {error_msg}")

            return response.json()
        except requests.RequestException as e:
            raise APIRequestError(f"Network error sending command: {str(e)}")

    def get_device_state(self, device_id: str) -> Dict[str, Any]:
        """
        Get device state/shadow (REST API)

        Args:
            device_id: Device identifier (UUID)

        Returns:
            Device state object
        """
        try:
            response = requests.get(
                f"{self.device_rest_api_url}/devices/state",
                headers={
                    "Content-Type": "application/json",
                    **self.auth.get_auth_header()
                },
                params={"deviceId": device_id}
            )

            if not response.ok:
                error_body = response.text
                try:
                    error_data = response.json()
                    error_msg = error_data.get("message", error_body)
                except:
                    error_msg = error_body
                raise APIRequestError(f"Failed to get device state (HTTP {response.status_code}): {error_msg}")

            return response.json()
        except requests.RequestException as e:
            raise APIRequestError(f"Network error getting device state: {str(e)}")

    def set_target(self, device_id: str, temperature: Optional[float] = None,
                   humidity: Optional[float] = None) -> Dict[str, Any]:
        """
        Set target temperature and/or humidity (REST API)

        Args:
            device_id: Device identifier (UUID)
            temperature: Target temperature
            humidity: Target humidity

        Returns:
            Update response
        """
        try:
            payload = {"deviceId": device_id}
            if temperature is not None:
                payload["temperature"] = temperature
            if humidity is not None:
                payload["humidity"] = humidity

            response = requests.patch(
                f"{self.device_rest_api_url}/devices/target",
                headers={
                    "Content-Type": "application/json",
                    **self.auth.get_auth_header()
                },
                json=payload
            )

            if not response.ok:
                error_body = response.text
                try:
                    error_data = response.json()
                    error_msg = error_data.get("message", error_body)
                except:
                    error_msg = error_body
                raise APIRequestError(f"Failed to set target (HTTP {response.status_code}): {error_msg}")

            return response.json()
        except requests.RequestException as e:
            raise APIRequestError(f"Network error setting target: {str(e)}")

    def change_profile(self, device_id: str, profile: str) -> Dict[str, Any]:
        """
        Change device profile (REST API)

        Args:
            device_id: Device identifier (UUID)
            profile: Profile name/identifier

        Returns:
            Update response
        """
        try:
            response = requests.patch(
                f"{self.device_rest_api_url}/devices/profile",
                headers={
                    "Content-Type": "application/json",
                    **self.auth.get_auth_header()
                },
                json={"deviceId": device_id, "profile": profile}
            )

            if not response.ok:
                error_body = response.text
                try:
                    error_data = response.json()
                    error_msg = error_data.get("message", error_body)
                except:
                    error_msg = error_body
                raise APIRequestError(f"Failed to change profile (HTTP {response.status_code}): {error_msg}")

            return response.json()
        except requests.RequestException as e:
            raise APIRequestError(f"Network error changing profile: {str(e)}")

    def graphql_query(self, query: str, variables: Optional[Dict] = None) -> Dict[str, Any]:
        """
        Execute a GraphQL query on the Device Service

        Args:
            query: GraphQL query string
            variables: Query variables

        Returns:
            GraphQL response data
        """
        try:
            response = requests.post(
                self.graphql_endpoint,
                headers={
                    "Content-Type": "application/json",
                    **self.auth.get_auth_header()
                },
                json={"query": query, "variables": variables or {}}
            )

            if not response.ok:
                raise APIRequestError(f"GraphQL query failed: {response.status_code}")

            result = response.json()
            if "errors" in result:
                raise APIRequestError(f"GraphQL errors: {result['errors']}")

            return result.get("data", {})
        except requests.RequestException as e:
            raise APIRequestError(f"Network error in GraphQL query: {str(e)}")


class HarviaDataService:
    """Data Service - Device measurements and session data"""

    def __init__(self, auth: HarviaAuth, data_rest_api_url: str, graphql_endpoint: str):
        self.auth = auth
        self.data_rest_api_url = data_rest_api_url
        self.graphql_endpoint = graphql_endpoint

    def get_latest_data(self, device_id: str) -> Dict[str, Any]:
        """
        Get latest telemetry data (REST API)

        Args:
            device_id: Device identifier (UUID)

        Returns:
            Latest telemetry data
        """
        try:
            response = requests.get(
                f"{self.data_rest_api_url}/data/latest-data",
                headers={
                    "Content-Type": "application/json",
                    **self.auth.get_auth_header()
                },
                params={"deviceId": device_id}
            )

            if not response.ok:
                error_body = response.text
                try:
                    error_data = response.json()
                    error_msg = error_data.get("message", error_body)
                except:
                    error_msg = error_body
                raise APIRequestError(f"Failed to get latest data (HTTP {response.status_code}): {error_msg}")

            return response.json()
        except requests.RequestException as e:
            raise APIRequestError(f"Network error getting latest data: {str(e)}")

    def get_telemetry_history(self, device_id: str, start_time: str,
                              end_time: str) -> List[Dict[str, Any]]:
        """
        Get telemetry history for a time range (REST API)

        Args:
            device_id: Device identifier (UUID)
            start_time: Start time (ISO 8601 format)
            end_time: End time (ISO 8601 format)

        Returns:
            List of telemetry data points
        """
        try:
            response = requests.get(
                f"{self.data_rest_api_url}/data/telemetry-history",
                headers={
                    "Content-Type": "application/json",
                    **self.auth.get_auth_header()
                },
                params={
                    "deviceId": device_id,
                    "startTime": start_time,
                    "endTime": end_time
                }
            )

            if not response.ok:
                error_body = response.text
                try:
                    error_data = response.json()
                    error_msg = error_data.get("message", error_body)
                except:
                    error_msg = error_body
                raise APIRequestError(f"Failed to get telemetry history (HTTP {response.status_code}): {error_msg}")

            return response.json()
        except requests.RequestException as e:
            raise APIRequestError(f"Network error getting telemetry history: {str(e)}")

    def graphql_query(self, query: str, variables: Optional[Dict] = None) -> Dict[str, Any]:
        """
        Execute a GraphQL query on the Data Service

        Args:
            query: GraphQL query string
            variables: Query variables

        Returns:
            GraphQL response data
        """
        try:
            response = requests.post(
                self.graphql_endpoint,
                headers={
                    "Content-Type": "application/json",
                    **self.auth.get_auth_header()
                },
                json={"query": query, "variables": variables or {}}
            )

            if not response.ok:
                raise APIRequestError(f"GraphQL query failed: {response.status_code}")

            result = response.json()
            if "errors" in result:
                raise APIRequestError(f"GraphQL errors: {result['errors']}")

            return result.get("data", {})
        except requests.RequestException as e:
            raise APIRequestError(f"Network error in GraphQL query: {str(e)}")


class HarviaEventsService:
    """Events Service - Event monitoring and notifications (GraphQL only)"""

    def __init__(self, auth: HarviaAuth, graphql_endpoint: str):
        self.auth = auth
        self.graphql_endpoint = graphql_endpoint

    def graphql_query(self, query: str, variables: Optional[Dict] = None) -> Dict[str, Any]:
        """
        Execute a GraphQL query on the Events Service

        Args:
            query: GraphQL query string
            variables: Query variables

        Returns:
            GraphQL response data
        """
        try:
            response = requests.post(
                self.graphql_endpoint,
                headers={
                    "Content-Type": "application/json",
                    **self.auth.get_auth_header()
                },
                json={"query": query, "variables": variables or {}}
            )

            if not response.ok:
                raise APIRequestError(f"GraphQL query failed: {response.status_code}")

            result = response.json()
            if "errors" in result:
                raise APIRequestError(f"GraphQL errors: {result['errors']}")

            return result.get("data", {})
        except requests.RequestException as e:
            raise APIRequestError(f"Network error in GraphQL query: {str(e)}")


class HarviaAPI:
    """
    Main Harvia Cloud API client

    Usage:
        client = HarviaAPI(username="user@example.com", password="password")
        devices = client.devices.list_devices()
        data = client.data.get_latest_data(device_id="device-123")
    """

    ENDPOINTS_URL = "https://prod.api.harvia.io/endpoints"

    def __init__(self, username: Optional[str] = None, password: Optional[str] = None,
                 auto_authenticate: bool = True):
        """
        Initialize Harvia API client

        Args:
            username: User's username/email (optional if not auto_authenticating)
            password: User's password (optional if not auto_authenticating)
            auto_authenticate: Automatically authenticate on initialization
        """
        self.config = self._fetch_configuration()
        self.auth = HarviaAuth(self.config["generic_rest_api_url"])

        # Initialize services with proper REST API URLs
        self.devices = HarviaDeviceService(
            self.auth,
            self.config["device_rest_api_url"],
            self.config["graphql"]["device"]["https"]
        )

        self.data = HarviaDataService(
            self.auth,
            self.config["data_rest_api_url"],
            self.config["graphql"]["data"]["https"]
        )

        self.events = HarviaEventsService(
            self.auth,
            self.config["graphql"]["events"]["https"]
        )

        # Auto-authenticate if credentials provided
        if auto_authenticate and username and password:
            self.authenticate(username, password)

    def _fetch_configuration(self) -> Dict[str, Any]:
        """
        Fetch API configuration from endpoints

        Returns:
            Configuration dictionary
        """
        try:
            response = requests.get(self.ENDPOINTS_URL)
            if not response.ok:
                raise APIRequestError(f"Failed to fetch configuration: {response.status_code}")

            endpoints = response.json()["endpoints"]

            return {
                "generic_rest_api_url": endpoints["RestApi"]["generics"]["https"],
                "device_rest_api_url": endpoints["RestApi"]["device"]["https"],
                "data_rest_api_url": endpoints["RestApi"]["data"]["https"],
                "users_rest_api_url": endpoints["RestApi"]["users"]["https"],
                "graphql": endpoints["GraphQL"],
                "config": endpoints.get("Config", {}),
                "version": endpoints.get("version", "unknown")
            }
        except requests.RequestException as e:
            raise APIRequestError(f"Network error fetching configuration: {str(e)}")

    def authenticate(self, username: str, password: str) -> Dict[str, Any]:
        """
        Authenticate with username and password

        Args:
            username: User's username/email
            password: User's password

        Returns:
            Authentication tokens
        """
        return self.auth.sign_in(username, password)

    def refresh_token(self) -> Dict[str, Any]:
        """
        Refresh authentication token

        Returns:
            New authentication tokens
        """
        return self.auth.refresh()

    def revoke_token(self) -> Dict[str, bool]:
        """
        Revoke refresh token

        Returns:
            Revocation status
        """
        return self.auth.revoke()

    def get_api_version(self) -> str:
        """Get API version"""
        return self.config.get("version", "unknown")

    def get_graphql_endpoints(self) -> Dict[str, Dict[str, str]]:
        """Get all GraphQL endpoints"""
        return self.config["graphql"]

    def debug_info(self) -> Dict[str, Any]:
        """Get debug information about current configuration and auth state"""
        return {
            "api_version": self.get_api_version(),
            "generic_rest_api": self.config["generic_rest_api_url"],
            "device_rest_api": self.config["device_rest_api_url"],
            "data_rest_api": self.config["data_rest_api_url"],
            "has_id_token": self.auth.id_token is not None,
            "has_access_token": self.auth.access_token is not None,
            "has_refresh_token": self.auth.refresh_token is not None,
            "token_expired": self.auth.is_token_expired() if self.auth.token_expiry else None,
            "username": self.auth.username
        }


# # Example usage
# if __name__ == "__main__":
#     # Initialize client
#     client = HarviaAPI(username="harviahackathon2025@gmail.com", password="junction25!")
#
#
#     print(f"API Version: {client.get_api_version()}")
#     print(f"Debug Info: {client.debug_info()}")
#
#     # List all devices
#
#     try:
#         print(client.devices.get_devices_by_type(device_type="Fenix"))
#         # Get device by serial number
#         device = client.devices.get_device_by_serial("2513005304")
#         data = client.data.get_latest_data(device_id=device.device_id)
#         print(data)
#
#
#     except HarviaAPIError as e:
#         print(f"API Error: {e}")