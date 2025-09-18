#!/usr/bin/env python3
"""
Network Information Utility
Shows current network configuration for the server monitor system.
"""

import sys
import os
from pathlib import Path

# Add utils directory to path
sys.path.append(str(Path(__file__).parent / "utils"))
from network_utils import get_local_ip, find_best_ip_for_network, get_all_network_interfaces

def main():
    print("=" * 50)
    print("Server Monitor - Network Configuration")
    print("=" * 50)
    print()
    
    # Get IP information
    local_ip = get_local_ip()
    best_ip = find_best_ip_for_network()
    
    print(f"Local IP Address: {local_ip}")
    print(f"Best Network IP: {best_ip}")
    print()
    
    # Show all interfaces
    interfaces = get_all_network_interfaces()
    if interfaces:
        print("Available Network Interfaces:")
        print("-" * 30)
        for interface in interfaces:
            print(f"Interface: {interface['name']}")
            for ip in interface['ips']:
                print(f"  IP: {ip}")
        print()
    
    # Show service URLs
    print("Service URLs:")
    print("-" * 20)
    print(f"Central Server: http://{best_ip}:8080")
    print(f"API Endpoint: http://{best_ip}:8080/api/agents")
    print(f"WebSocket: ws://{best_ip}:8080/ws/register")
    print(f"Frontend: http://localhost:5173")
    print()
    
    print("For other computers to connect:")
    print(f"- Use IP: {best_ip}")
    print(f"- Central Server URL: ws://{best_ip}:8080")
    print()

if __name__ == "__main__":
    main()
