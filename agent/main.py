import asyncio
import json
import os
import platform
import socket
import subprocess
import shutil
import time
import psutil
import websockets
import sys
from pathlib import Path
from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, StreamingResponse
from pydantic import BaseModel
from typing import Optional, Dict, Any, List
import aiofiles
import uuid

# Add utils directory to path
sys.path.append(str(Path(__file__).parent.parent / "utils"))
from network_utils import get_local_ip, find_best_ip_for_network

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

class FileTransferRequest(BaseModel):
    source_path: str
    target_agent_id: str
    target_path: str

class FileShareInfo(BaseModel):
    file_id: str
    filename: str
    size: int
    shared_by: str
    created_at: str

def get_temperature_info():
    """Get comprehensive system temperature information from all available sensors."""
    temperatures = {}
    
    try:
        # Try to get temperature from psutil (Linux/some Windows systems)
        if hasattr(psutil, 'sensors_temperatures'):
            temps = psutil.sensors_temperatures()
            if temps:
                for name, entries in temps.items():
                    for i, entry in enumerate(entries):
                        temp_name = f"{name}_{entry.label}" if entry.label else f"{name}_{i}"
                        temperatures[temp_name] = {
                            'current': entry.current,
                            'high': entry.high if entry.high else None,
                            'critical': entry.critical if entry.critical else None
                        }
    except Exception as e:
        print(f"Error getting temperature from psutil: {e}")
    
    # Windows-specific comprehensive temperature monitoring
    if platform.system() == "Windows":
        # Method 1: Try OpenHardwareMonitor/LibreHardwareMonitor WMI
        for namespace in ['OpenHardwareMonitor', 'LibreHardwareMonitor']:
            try:
                cmd = f'Get-WmiObject -Namespace "root/{namespace}" -Class Sensor | Where-Object {{ $_.SensorType -eq "Temperature" }} | Select-Object Name, Value, Min, Max'
                result = subprocess.run(['powershell', '-Command', cmd], 
                                      capture_output=True, text=True, timeout=15)
                
                if result.returncode == 0 and result.stdout.strip():
                    lines = result.stdout.strip().split('\n')
                    current_sensor = {}
                    
                    for line in lines:
                        line = line.strip()
                        if line.startswith('Name'):
                            if current_sensor and 'name' in current_sensor and 'value' in current_sensor:
                                sensor_name = current_sensor['name'].replace('/', '_').replace(' ', '_')
                                temperatures[sensor_name] = {
                                    'current': current_sensor['value'],
                                    'high': current_sensor.get('max', 85.0),
                                    'critical': current_sensor.get('max', 95.0) if current_sensor.get('max') else 95.0
                                }
                            current_sensor = {'name': line.split(':', 1)[1].strip() if ':' in line else line}
                        elif line.startswith('Value') and ':' in line:
                            try:
                                value = float(line.split(':', 1)[1].strip())
                                current_sensor['value'] = value
                            except ValueError:
                                pass
                        elif line.startswith('Max') and ':' in line:
                            try:
                                max_val = float(line.split(':', 1)[1].strip())
                                current_sensor['max'] = max_val
                            except ValueError:
                                pass
                    
                    # Don't forget the last sensor
                    if current_sensor and 'name' in current_sensor and 'value' in current_sensor:
                        sensor_name = current_sensor['name'].replace('/', '_').replace(' ', '_')
                        temperatures[sensor_name] = {
                            'current': current_sensor['value'],
                            'high': current_sensor.get('max', 85.0),
                            'critical': current_sensor.get('max', 95.0) if current_sensor.get('max') else 95.0
                        }
                    
                    if temperatures:  # If we found sensors, break
                        break
                        
            except Exception as e:
                continue
        
        # Method 2: WMI Thermal Zone (fallback)
        if not temperatures:
            try:
                cmd = 'Get-WmiObject -Namespace "root/wmi" -Class MSAcpi_ThermalZoneTemperature | ForEach-Object { [math]::Round(($_.CurrentTemperature / 10) - 273.15, 1) }'
                result = subprocess.run(['powershell', '-Command', cmd], 
                                      capture_output=True, text=True, timeout=10)
                
                if result.returncode == 0 and result.stdout.strip():
                    lines = result.stdout.strip().split('\n')
                    for i, line in enumerate(lines):
                        if line.strip():
                            try:
                                temp_celsius = float(line.strip())
                                if 0 < temp_celsius < 150:  # Sanity check
                                    temperatures[f'Thermal_Zone_{i}'] = {
                                        'current': temp_celsius,
                                        'high': 80.0,
                                        'critical': 95.0
                                    }
                            except ValueError:
                                continue
            except Exception:
                pass
        
        # Method 3: WMIC fallback
        if not temperatures:
            try:
                result = subprocess.run([
                    'wmic', '/namespace:\\\\root\\wmi', 'PATH', 'MSAcpi_ThermalZoneTemperature', 
                    'get', 'CurrentTemperature', '/value'
                ], capture_output=True, text=True, timeout=10)
                
                if result.returncode == 0:
                    for line in result.stdout.split('\n'):
                        if 'CurrentTemperature=' in line:
                            temp_raw = line.split('=')[1].strip()
                            if temp_raw.isdigit():
                                temp_celsius = (int(temp_raw) / 10) - 273.15
                                if 0 < temp_celsius < 150:
                                    temperatures['CPU_Thermal_Zone'] = {
                                        'current': round(temp_celsius, 1),
                                        'high': 80.0,
                                        'critical': 95.0
                                    }
                                    break
            except Exception:
                pass
        
        # Method 4: GPU temperature (NVIDIA)
        try:
            result = subprocess.run([
                'nvidia-smi', '--query-gpu=temperature.gpu,name,memory.total,memory.used', '--format=csv,noheader,nounits'
            ], capture_output=True, text=True, timeout=5)
            
            if result.returncode == 0 and result.stdout.strip():
                lines = result.stdout.strip().split('\n')
                for i, line in enumerate(lines):
                    parts = line.split(',')
                    if len(parts) >= 2:
                        try:
                            gpu_temp = float(parts[0].strip())
                            gpu_name = parts[1].strip().replace(' ', '_').replace('NVIDIA_', '')
                            temperatures[f'GPU_{gpu_name}'] = {
                                'current': gpu_temp,
                                'high': 83.0,
                                'critical': 95.0
                            }
                        except ValueError:
                            pass
        except Exception:
            pass
        
        # Method 5: AMD GPU temperature via WMI
        try:
            cmd = 'Get-WmiObject -Namespace "root/OpenHardwareMonitor" -Class Sensor | Where-Object { $_.SensorType -eq "Temperature" -and $_.Name -like "*GPU*" } | Select-Object Name, Value'
            result = subprocess.run(['powershell', '-Command', cmd], 
                                  capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0 and result.stdout.strip():
                lines = result.stdout.strip().split('\n')
                current_sensor = {}
                
                for line in lines:
                    line = line.strip()
                    if line.startswith('Name') and ':' in line:
                        if current_sensor and 'name' in current_sensor and 'value' in current_sensor:
                            sensor_name = current_sensor['name'].replace('/', '_').replace(' ', '_')
                            temperatures[sensor_name] = {
                                'current': current_sensor['value'],
                                'high': 90.0,
                                'critical': 105.0
                            }
                        current_sensor = {'name': line.split(':', 1)[1].strip()}
                    elif line.startswith('Value') and ':' in line:
                        try:
                            value = float(line.split(':', 1)[1].strip())
                            current_sensor['value'] = value
                        except ValueError:
                            pass
                
                # Don't forget the last sensor
                if current_sensor and 'name' in current_sensor and 'value' in current_sensor:
                    sensor_name = current_sensor['name'].replace('/', '_').replace(' ', '_')
                    temperatures[sensor_name] = {
                        'current': current_sensor['value'],
                        'high': 90.0,
                        'critical': 105.0
                    }
        except Exception:
            pass
        
        # Method 6: Disk temperatures from all drives
        try:
            for partition in psutil.disk_partitions():
                if os.path.exists(partition.mountpoint):
                    health = get_drive_health(partition.device)
                    if health.get('temperature') is not None:
                        drive_name = partition.device.replace('\\', '').replace(':', '')
                        temperatures[f'Drive_{drive_name}'] = {
                            'current': float(health['temperature']),
                            'high': 50.0,  # Typical HDD warning temp
                            'critical': 60.0  # Typical HDD critical temp
                        }
        except Exception:
            pass
    
    # If still no temperatures found, add a mock sensor for testing
    if not temperatures:
        # Try to get CPU usage as a proxy for temperature estimation
        try:
            cpu_percent = psutil.cpu_percent(interval=1)
            estimated_temp = 30 + (cpu_percent * 0.5)  # Very rough estimation
            temperatures['CPU_Estimated'] = {
                'current': round(estimated_temp, 1),
                'high': 80.0,
                'critical': 95.0
            }
        except Exception:
            pass
    
    return temperatures

def get_drive_health(drive_path: str) -> dict:
    """Get drive health information using SMART data."""
    health_info = {
        "status": "unknown",
        "smart_available": False,
        "temperature": None,
        "power_on_hours": None,
        "error_count": None
    }
    
    # Try to get drive temperature using multiple methods
    try:
        # Method 1: Try smartctl if available
        result = subprocess.run([
            'smartctl', '-A', drive_path
        ], capture_output=True, text=True, timeout=10)
        
        if result.returncode == 0:
            for line in result.stdout.split('\n'):
                if 'Temperature_Celsius' in line or 'Airflow_Temperature_Cel' in line:
                    parts = line.split()
                    if len(parts) >= 10:
                        try:
                            temp = int(parts[9])
                            health_info["temperature"] = temp
                            health_info["smart_available"] = True
                            break
                        except (ValueError, IndexError):
                            pass
    except Exception:
        pass
    
    # Method 2: Try PowerShell for drive temperature
    if health_info["temperature"] is None and platform.system() == "Windows":
        try:
            # Get physical drive number from drive letter
            drive_letter = drive_path.replace('\\', '').replace(':', '')
            cmd = f'''
            $drive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object {{ $_.DeviceID -eq "{drive_letter}:" }}
            if ($drive) {{
                $partition = Get-WmiObject -Class Win32_LogicalDiskToPartition | Where-Object {{ $_.Dependent -like "*{drive_letter}:*" }}
                if ($partition) {{
                    $diskDrive = Get-WmiObject -Class Win32_DiskPartition | Where-Object {{ $_.DeviceID -eq $partition.Antecedent.Split('=')[1].Trim('"') }}
                    if ($diskDrive) {{
                        $physicalDisk = Get-WmiObject -Class Win32_DiskDriveToDiskPartition | Where-Object {{ $_.Dependent -eq $diskDrive.__PATH }}
                        if ($physicalDisk) {{
                            $temp = Get-WmiObject -Namespace "root/wmi" -Class MSStorageDriver_ATAPISmartData | Where-Object {{ $_.InstanceName -like "*$($physicalDisk.Antecedent.Split('=')[1].Trim('"'))*" }}
                            if ($temp) {{ $temp.VendorSpecific[194] }}
                        }}
                    }}
                }}
            }}
            '''
            result = subprocess.run(['powershell', '-Command', cmd], 
                                  capture_output=True, text=True, timeout=15)
            
            if result.returncode == 0 and result.stdout.strip():
                try:
                    return {"output": result.stdout, "error": result.stderr}
                except ValueError:
                    pass
        except Exception:
            pass
    
    if platform.system() == "Windows":
        try:
            # Simple fallback - if we can get disk usage, assume it's working
            usage = psutil.disk_usage(drive_path)
            if usage.total > 0:
                health_info["status"] = "healthy"
                health_info["smart_available"] = False
        except Exception:
            health_info["status"] = "unknown"
    
    return health_info

def get_system_info() -> SystemInfo:
    """Gather system information."""
    hostname = socket.gethostname()
    system = platform.system()
    version = platform.version()
    
    # Get CPU count
    cpu_count = psutil.cpu_count()
    
    # Get total RAM in MB
    total_ram = psutil.virtual_memory().total // (1024 * 1024)
    
    # Get detailed disk information
    disks = []
    for partition in psutil.disk_partitions():
        try:
            usage = psutil.disk_usage(partition.mountpoint)
            health = get_drive_health(partition.device)
            
            disks.append({
                'device': partition.device,
                'mountpoint': partition.mountpoint,
                'fstype': partition.fstype,
                'total_gb': round(usage.total / (1024**3), 2),
                'used_gb': round(usage.used / (1024**3), 2),
                'free_gb': round(usage.free / (1024**3), 2),
                'percent_used': usage.percent,
                'health_status': health.get('status', 'Unknown'),
                'smart_available': health.get('smart_available', False)
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
    """Get current system status (CPU, memory, disk usage, temperature)."""
    cpu_percent = psutil.cpu_percent(interval=1)
    memory = psutil.virtual_memory()
    system_name = platform.system()
    
    # Get temperature information
    temperatures = get_temperature_info()
    
    # Get all drives information
    drives = []
    for partition in psutil.disk_partitions():
        try:
            # Skip if device is not ready (like empty CD/DVD drives)
            if not os.path.exists(partition.mountpoint):
                continue
                
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
        except (OSError, PermissionError) as e:
            # Skip drives that are not ready or accessible
            if "device is not ready" in str(e).lower() or "access is denied" in str(e).lower():
                continue
            print(f"Error getting drive info for {partition.mountpoint}: {e}")
        except Exception as e:
            print(f"Error getting drive info for {partition.mountpoint}: {e}")
    
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
        "uptime_seconds": int(time.time() - psutil.boot_time()),
        "drives": drives,
        "temperatures": temperatures
    }

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
            # Skip if device is not ready (like empty CD/DVD drives)
            if not os.path.exists(partition.mountpoint):
                continue
                
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
        except (OSError, PermissionError) as e:
            # Skip drives that are not ready or accessible
            if "device is not ready" in str(e).lower() or "access is denied" in str(e).lower():
                continue
            print(f"Error getting drive info for {partition.mountpoint}: {e}")
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

# File sharing endpoints
SHARED_FILES_DIR = Path("shared_files")
SHARED_FILES_DIR.mkdir(exist_ok=True)

@app.post("/api/upload")
async def upload_file(file: UploadFile = File(...)):
    """Upload a file to be shared with other agents."""
    try:
        file_id = str(uuid.uuid4())
        file_path = SHARED_FILES_DIR / f"{file_id}_{file.filename}"
        
        async with aiofiles.open(file_path, 'wb') as f:
            content = await file.read()
            await f.write(content)
        
        return {
            "success": True,
            "file_id": file_id,
            "filename": file.filename,
            "size": len(content),
            "message": f"File uploaded successfully as {file_id}_{file.filename}"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")

@app.get("/api/download/{file_id}")
async def download_file(file_id: str):
    """Download a shared file by ID."""
    try:
        # Find file with matching ID
        for file_path in SHARED_FILES_DIR.glob(f"{file_id}_*"):
            if file_path.is_file():
                original_filename = file_path.name.split('_', 1)[1]
                return FileResponse(
                    path=str(file_path),
                    filename=original_filename,
                    media_type='application/octet-stream'
                )
        
        raise HTTPException(status_code=404, detail="File not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Download failed: {str(e)}")

@app.get("/api/shared-files")
async def list_shared_files():
    """List all shared files available for download."""
    try:
        files = []
        for file_path in SHARED_FILES_DIR.glob("*"):
            if file_path.is_file():
                parts = file_path.name.split('_', 1)
                if len(parts) == 2:
                    file_id, filename = parts
                    stat = file_path.stat()
                    files.append({
                        "file_id": file_id,
                        "filename": filename,
                        "size": stat.st_size,
                        "created_at": stat.st_ctime,
                        "shared_by": socket.gethostname()
                    })
        
        return {"files": files}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list files: {str(e)}")

@app.post("/api/transfer-file")
async def transfer_file_to_agent(request: FileTransferRequest):
    """Transfer a file from this agent to another agent."""
    try:
        # Check if source file exists
        if not os.path.exists(request.source_path):
            raise HTTPException(status_code=404, detail="Source file not found")
        
        # Read the file
        async with aiofiles.open(request.source_path, 'rb') as f:
            file_content = await f.read()
        
        filename = os.path.basename(request.source_path)
        
        # Here you would typically send the file to the target agent
        # For now, we'll simulate by uploading to our own shared directory
        file_id = str(uuid.uuid4())
        target_path = SHARED_FILES_DIR / f"{file_id}_{filename}"
        
        async with aiofiles.open(target_path, 'wb') as f:
            await f.write(file_content)
        
        return {
            "success": True,
            "message": f"File transferred successfully",
            "file_id": file_id,
            "filename": filename,
            "size": len(file_content)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Transfer failed: {str(e)}")

@app.delete("/api/shared-files/{file_id}")
async def delete_shared_file(file_id: str):
    """Delete a shared file."""
    try:
        for file_path in SHARED_FILES_DIR.glob(f"{file_id}_*"):
            if file_path.is_file():
                file_path.unlink()
                return {"success": True, "message": "File deleted successfully"}
        
        raise HTTPException(status_code=404, detail="File not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Delete failed: {str(e)}")

async def register_with_central_server():
    """Register this agent with the central server."""
    # Get dynamic IP address
    local_ip = get_local_ip()
    best_ip = find_best_ip_for_network()
    
    # Use environment variable or auto-detect central server
    central_server_url = os.getenv("CENTRAL_SERVER_URL")
    if not central_server_url:
        # Auto-detect central server URL using the best network IP
        central_server_url = f"ws://{best_ip}:8080"
    
    agent_id = os.getenv("AGENT_ID", socket.gethostname())
    agent_port = os.getenv("AGENT_PORT", 3000)
    
    print(f"Agent starting with IP: {local_ip}")
    print(f"Best network IP detected: {best_ip}")
    print(f"Connecting to central server: {central_server_url}")
    
    while True:
        try:
            async with websockets.connect(f"{central_server_url}/ws/register") as websocket:
                # Register with the central server
                await websocket.send(json.dumps({
                    "type": "register",
                    "agent_id": agent_id,
                    "hostname": socket.gethostname(),
                    "ip": local_ip
                }))
                
                print(f"Agent {agent_id} registered successfully")
                
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
