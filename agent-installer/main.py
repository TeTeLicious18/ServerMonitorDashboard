import asyncio
import json
import os
import platform
import socket
import time
from datetime import datetime
from typing import Dict, Any
import psutil
import websockets
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

# Configuration
CENTRAL_SERVER_URL = os.getenv("CENTRAL_SERVER_URL", "ws://localhost:8080")
AGENT_ID = os.getenv("AGENT_ID", socket.gethostname())
AGENT_PORT = int(os.getenv("AGENT_PORT", "3000"))

app = FastAPI(title="Server Monitor Agent")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class CommandRequest(BaseModel):
    command: str

def get_system_info() -> Dict[str, Any]:
    """Get static system information."""
    boot_time = psutil.boot_time()
    
    return {
        "hostname": socket.gethostname(),
        "platform": platform.system(),
        "platform_release": platform.release(),
        "platform_version": platform.version(),
        "architecture": platform.machine(),
        "processor": platform.processor(),
        "cpu_cores": psutil.cpu_count(logical=False),
        "cpu_threads": psutil.cpu_count(logical=True),
        "memory_total": psutil.virtual_memory().total,
        "boot_time": boot_time,
        "python_version": platform.python_version(),
        "agent_id": AGENT_ID
    }

def get_system_status() -> Dict[str, Any]:
    """Get current system status/metrics."""
    # CPU usage
    cpu_percent = psutil.cpu_percent(interval=1)
    
    # Memory usage
    memory = psutil.virtual_memory()
    
    # Disk usage (main drive)
    disk = psutil.disk_usage('/')
    
    # Network I/O
    network = psutil.net_io_counters()
    
    # System uptime
    boot_time = psutil.boot_time()
    uptime = time.time() - boot_time
    
    return {
        "timestamp": datetime.utcnow().isoformat(),
        "cpu_percent": round(cpu_percent, 1),
        "memory_percent": round(memory.percent, 1),
        "memory_used": memory.used,
        "memory_total": memory.total,
        "memory_used_mb": round(memory.used / (1024 * 1024), 1),
        "memory_total_mb": round(memory.total / (1024 * 1024), 1),
        "disk_percent": round(disk.percent, 1),
        "disk_used": disk.used,
        "disk_total": disk.total,
        "disk_used_gb": round(disk.used / (1024 ** 3), 2),
        "disk_total_gb": round(disk.total / (1024 ** 3), 2),
        "network_bytes_sent": network.bytes_sent,
        "network_bytes_recv": network.bytes_recv,
        "uptime": round(uptime, 0),
        "uptime_seconds": int(uptime)
    }

# API Routes
@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": f"Server Monitor Agent - {AGENT_ID}", "status": "running"}

@app.get("/info")
async def get_info():
    """Get system information."""
    try:
        return get_system_info()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/status")
async def get_status():
    """Get current system status."""
    try:
        return get_system_status()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

@app.post("/execute")
async def execute_command(request: CommandRequest):
    """Execute a system command (basic implementation)."""
    # For security, only allow specific safe commands
    allowed_commands = ["hostname", "whoami", "date", "uptime"]
    
    if request.command not in allowed_commands:
        raise HTTPException(status_code=403, detail="Command not allowed")
    
    try:
        import subprocess
        result = subprocess.run(
            request.command, 
            shell=True, 
            capture_output=True, 
            text=True, 
            timeout=10
        )
        return {
            "command": request.command,
            "returncode": result.returncode,
            "stdout": result.stdout,
            "stderr": result.stderr
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# WebSocket connection to central server
async def connect_to_central_server():
    """Connect to central server via WebSocket."""
    while True:
        try:
            print(f"Connecting to central server at {CENTRAL_SERVER_URL}/ws/register")
            
            async with websockets.connect(f"{CENTRAL_SERVER_URL}/ws/register") as websocket:
                # Register with central server
                registration_data = {
                    "type": "register",
                    "agent_id": AGENT_ID,
                    "hostname": socket.gethostname(),
                    "ip": socket.gethostbyname(socket.gethostname())
                }
                
                await websocket.send(json.dumps(registration_data))
                print(f"Registered with central server as {AGENT_ID}")
                
                # Send status updates every 30 seconds
                while True:
                    try:
                        status_data = get_system_status()
                        message = {
                            "type": "status_update",
                            "agent_id": AGENT_ID,
                            "data": status_data
                        }
                        
                        await websocket.send(json.dumps(message))
                        print(f"Sent status update to central server")
                        
                        await asyncio.sleep(30)  # Wait 30 seconds
                        
                    except websockets.exceptions.ConnectionClosed:
                        print("Connection to central server lost")
                        break
                    except Exception as e:
                        print(f"Error sending status update: {e}")
                        await asyncio.sleep(5)
                        
        except Exception as e:
            print(f"Failed to connect to central server: {e}")
            print("Retrying in 10 seconds...")
            await asyncio.sleep(10)

@app.on_event("startup")
async def startup_event():
    """Start background tasks when the application starts."""
    # Start WebSocket connection to central server
    asyncio.create_task(connect_to_central_server())

if __name__ == "__main__":
    print(f"Starting Server Monitor Agent: {AGENT_ID}")
    print(f"Central Server: {CENTRAL_SERVER_URL}")
    print(f"Agent API will be available at: http://localhost:{AGENT_PORT}")
    print(f"System: {platform.system()} {platform.release()}")
    print("Press Ctrl+C to stop")
    
    try:
        uvicorn.run(app, host="127.0.0.1", port=AGENT_PORT)
    except KeyboardInterrupt:
        print("\nAgent stopped by user")
    except Exception as e:
        print(f"Error starting agent: {e}")
        input("Press Enter to exit...")
