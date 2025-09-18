import psutil
import platform
import socket
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, List, Optional
import asyncio
import websockets
import json
import os

app = FastAPI(title="Server Monitor Agent")

# CORS middleware to allow requests from the central server
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with the central server's address
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class SystemInfo(BaseModel):
    hostname: str
    os: str
    os_version: str
    cpu_count: int
    total_ram: int  # in MB
    disks: List[Dict[str, str]]
    last_updated: str

class CommandRequest(BaseModel):
    command: str
    args: Optional[Dict[str, str]] = None

class CommandResponse(BaseModel):
    success: bool
    output: str
    error: Optional[str] = None

def get_system_info() -> SystemInfo:
    """Gather system information."""
    hostname = socket.gethostname()
    system = platform.system()
    version = platform.version()
    
    # Get CPU count
    cpu_count = psutil.cpu_count()
    
    # Get total RAM in MB
    total_ram = psutil.virtual_memory().total // (1024 * 1024)
    
    # Get disk information
    disks = []
    for partition in psutil.disk_partitions():
        try:
            usage = psutil.disk_usage(partition.mountpoint)
            disks.append({
                'device': partition.device,
                'mountpoint': partition.mountpoint,
                'fstype': partition.fstype,
                'total_gb': round(usage.total / (1024**3), 2),
                'used_gb': round(usage.used / (1024**3), 2),
                'free_gb': round(usage.free / (1024**3), 2),
                'percent_used': usage.percent
            })
        except Exception as e:
            print(f"Error getting disk info for {partition.mountpoint}: {e}")
    
    return SystemInfo(
        hostname=hostname,
        os=system,
        os_version=version,
        cpu_count=cpu_count,
        total_ram=total_ram,
        disks=disks,
        last_updated=psutil.boot_time()
    )

@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": "Server Monitor Agent", "status": "running"}

@app.get("/api/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}

@app.get("/api/system-info")
async def system_info():
    """Get system information."""
    return get_system_info()

@app.get("/api/status")
async def status():
    """Get current system status (CPU, memory, disk usage)."""
    cpu_percent = psutil.cpu_percent(interval=1)
    memory = psutil.virtual_memory()
    system_name = platform.system()
    
    # Get all drives information
    drives = []
    for partition in psutil.disk_partitions():
        try:
            usage = psutil.disk_usage(partition.mountpoint)
            health = get_drive_health(partition.device)
            drives.append({
                "device": partition.device,
                "mountpoint": partition.mountpoint,
                "fstype": partition.fstype,
                "total_gb": round(usage.total / (1024**3), 2),
                "used_gb": round(usage.used / (1024**3), 2),
                "free_gb": round(usage.free / (1024**3), 2),
                "percent_used": usage.percent,
                "health_status": health.get('status', 'Unknown'),
                "smart_available": health.get('smart_available', False)
            })
        except Exception as e:
            print(f"Error getting drive info: {e}")
    
    # Primary disk for backward compatibility
    primary_disk = psutil.disk_usage('/' if system_name == 'Linux' else 'C:\\')
    
    return {
        "cpu_percent": cpu_percent,
        "memory_percent": memory.percent,
        "memory_used_mb": memory.used // (1024 * 1024),
        "memory_total_mb": memory.total // (1024 * 1024),
        "disk_percent": primary_disk.percent,
        "disk_used_gb": round(primary_disk.used / (1024**3), 2),
        "disk_total_gb": round(primary_disk.total / (1024**3), 2),
        "uptime_seconds": int(psutil.boot_time()),
        "drives": drives
    }

@app.get("/api/drives")
async def get_drives():
    """Get all available drives with detailed information."""
    drives = []
    for partition in psutil.disk_partitions():
        try:
            usage = psutil.disk_usage(partition.mountpoint)
            health = get_drive_health(partition.device)
            
            drives.append({
                "device": partition.device,
                "mountpoint": partition.mountpoint,
                "fstype": partition.fstype,
                "total_gb": round(usage.total / (1024**3), 2),
                "used_gb": round(usage.used / (1024**3), 2),
                "free_gb": round(usage.free / (1024**3), 2),
                "percent_used": usage.percent,
                "health_status": health.get('status', 'Unknown'),
                "smart_available": health.get('smart_available', False),
                "opts": partition.opts if hasattr(partition, 'opts') else []
            })
        except Exception as e:
            print(f"Error getting drive info for {partition.mountpoint}: {e}")
    
    return {"drives": drives}

@app.get("/api/files")
async def list_files(path: str = "C:\\"):
    """List files and directories in the specified path."""
    try:
        if not os.path.exists(path):
            raise HTTPException(status_code=404, detail="Path not found")
        
        items = []
        try:
            for item in os.listdir(path):
                item_path = os.path.join(path, item)
                try:
                    stat = os.stat(item_path)
                    is_dir = os.path.isdir(item_path)
                    items.append({
                        "name": item,
                        "path": item_path,
                        "is_directory": is_dir,
                        "size": stat.st_size if not is_dir else 0,
                        "modified": stat.st_mtime,
                        "type": "folder" if is_dir else os.path.splitext(item)[1].lower()
                    })
                except (PermissionError, OSError):
                    # Skip files we can't access
                    continue
        except PermissionError:
            raise HTTPException(status_code=403, detail="Permission denied")
        
        return {
            "path": path,
            "items": sorted(items, key=lambda x: (not x["is_directory"], x["name"].lower()))
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/drives")
async def get_drives():
    """Get all available drives with detailed information."""
    drives = []
    for partition in psutil.disk_partitions():
        try:
            usage = psutil.disk_usage(partition.mountpoint)
            health = get_drive_health(partition.device)
            
            drives.append({
                "device": partition.device,
                "mountpoint": partition.mountpoint,
                "fstype": partition.fstype,
                "total_gb": round(usage.total / (1024**3), 2),
                "used_gb": round(usage.used / (1024**3), 2),
                "free_gb": round(usage.free / (1024**3), 2),
                "percent_used": usage.percent,
                "health_status": health.get('status', 'Unknown'),
                "smart_available": health.get('smart_available', False),
                "opts": partition.opts if hasattr(partition, 'opts') else []
            })
        except Exception as e:
            print(f"Error getting drive info for {partition.mountpoint}: {e}")
    
    return {"drives": drives}

@app.post("/api/command")
async def execute_command(command_req: CommandRequest) -> CommandResponse:
    """Execute a system command."""
    try:
        # In a real application, you would want to validate and sanitize the command
        if command_req.command == "echo":
            return CommandResponse(
                success=True,
                output=f"Echo: {command_req.args.get('message', '') if command_req.args else ''}"
            )
        else:
            return CommandResponse(
                success=False,
                output="",
                error=f"Unknown command: {command_req.command}"
            )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

async def register_with_central_server():
    """Register this agent with the central server."""
    central_server_url = os.getenv("CENTRAL_SERVER_URL", "ws://localhost:8080")
    agent_id = os.getenv("AGENT_ID", socket.gethostname())
    agent_port = os.getenv("AGENT_PORT", 3000)
    
    while True:
        try:
            async with websockets.connect(f"{central_server_url}/ws/register") as websocket:
                # Register with the central server
                await websocket.send(json.dumps({
                    "type": "register",
                    "agent_id": agent_id,
                    "hostname": socket.gethostname(),
                    "ip": socket.gethostbyname(socket.gethostname())
                }))
                
                # Keep the connection open and send periodic updates
                while True:
                    status_data = await status()
                    await websocket.send(json.dumps({
                        "type": "status_update",
                        "agent_id": agent_id,
                        "data": status_data
                    }))
                    await asyncio.sleep(30)  # Send update every 30 seconds
                    
        except Exception as e:
            print(f"Error connecting to central server: {e}. Retrying in 10 seconds...")
            await asyncio.sleep(10)

@app.on_event("startup")
async def startup_event():
    """Start background tasks when the application starts."""
    asyncio.create_task(register_with_central_server())

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=3000)
