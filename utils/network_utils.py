import socket
import subprocess
import platform
import re
from typing import Optional, List

def get_local_ip() -> str:
    """Get the local IP address of this machine."""
    try:
        # Create a socket connection to determine the local IP
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            # Connect to a remote address (doesn't actually send data)
            s.connect(("8.8.8.8", 80))
            local_ip = s.getsockname()[0]
            return local_ip
    except Exception:
        # Fallback method
        try:
            hostname = socket.gethostname()
            local_ip = socket.gethostbyname(hostname)
            if local_ip.startswith("127."):
                # If we get localhost, try another method
                return get_network_ip_windows() if platform.system() == "Windows" else "localhost"
            return local_ip
        except Exception:
            return "localhost"

def get_network_ip_windows() -> str:
    """Get network IP on Windows using ipconfig."""
    try:
        result = subprocess.run(['ipconfig'], capture_output=True, text=True)
        output = result.stdout
        
        # Look for IPv4 addresses that are not localhost
        ip_pattern = r'IPv4 Address[.\s]*:\s*(\d+\.\d+\.\d+\.\d+)'
        matches = re.findall(ip_pattern, output)
        
        for ip in matches:
            if not ip.startswith('127.') and not ip.startswith('169.254.'):
                return ip
        
        return "localhost"
    except Exception:
        return "localhost"

def get_all_network_interfaces() -> List[dict]:
    """Get all network interfaces with their IP addresses."""
    interfaces = []
    
    if platform.system() == "Windows":
        try:
            result = subprocess.run(['ipconfig', '/all'], capture_output=True, text=True)
            output = result.stdout
            
            # Parse the output to extract interface information
            current_interface = None
            for line in output.split('\n'):
                line = line.strip()
                
                if 'adapter' in line.lower() and ':' in line:
                    current_interface = {
                        'name': line.split(':')[0].strip(),
                        'ips': []
                    }
                elif current_interface and 'IPv4 Address' in line:
                    ip_match = re.search(r'(\d+\.\d+\.\d+\.\d+)', line)
                    if ip_match:
                        ip = ip_match.group(1)
                        if not ip.startswith('127.') and not ip.startswith('169.254.'):
                            current_interface['ips'].append(ip)
                            if current_interface not in interfaces:
                                interfaces.append(current_interface)
        except Exception as e:
            print(f"Error getting network interfaces: {e}")
    
    return interfaces

def test_port_connectivity(ip: str, port: int, timeout: int = 5) -> bool:
    """Test if a port is accessible on the given IP."""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.settimeout(timeout)
            result = sock.connect_ex((ip, port))
            return result == 0
    except Exception:
        return False

def find_best_ip_for_network() -> str:
    """Find the best IP address for network communication."""
    local_ip = get_local_ip()
    
    # Test if the detected IP is accessible
    if test_port_connectivity(local_ip, 80, timeout=1):
        return local_ip
    
    # If not, try other interfaces
    interfaces = get_all_network_interfaces()
    for interface in interfaces:
        for ip in interface['ips']:
            if test_port_connectivity(ip, 80, timeout=1):
                return ip
    
    return local_ip  # Return the detected IP as fallback
