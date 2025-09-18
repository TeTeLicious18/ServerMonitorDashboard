# 🖥️ Multi-Computer Server Monitor Dashboard

A comprehensive real-time monitoring system for managing multiple computers from a single web dashboard. Monitor CPU, memory, disk usage, temperatures, and share files between computers seamlessly.

![Dashboard Preview](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)
![Python](https://img.shields.io/badge/Python-3.8+-blue)
![React](https://img.shields.io/badge/React-18+-61dafb)
![FastAPI](https://img.shields.io/badge/FastAPI-Latest-009688)

## ✨ Features

### 🔍 **Real-Time Monitoring**
- **System Metrics**: CPU, Memory, Disk usage with live updates every 30 seconds
- **Temperature Monitoring**: CPU, GPU, and disk temperatures from all available sensors
- **Drive Health**: Monitor all connected drives (C:, D:, E:, etc.) with SMART data
- **Network Status**: Dynamic IP detection and automatic connection monitoring
- **Uptime Tracking**: Accurate system uptime calculation and display

### 🌡️ **Advanced Temperature Sensing**
- **CPU Temperatures**: Multiple cores, thermal zones, and package temperatures
- **GPU Monitoring**: NVIDIA (nvidia-smi) and AMD graphics cards support
- **Disk Temperatures**: SMART data extraction from all storage devices
- **Hardware Integration**: OpenHardwareMonitor/LibreHardwareMonitor WMI support
- **Visual Alerts**: Color-coded temperature warnings (normal/warm/hot/critical)

### 📁 **File Sharing System**
- **Cross-Computer Sharing**: Upload and download files between any connected computers
- **Real-Time File Lists**: See shared files from all computers with live updates
- **Secure Transfers**: Direct computer-to-computer file transfers via HTTP
- **File Management**: Upload, download, delete shared files with drag-and-drop interface
- **Metadata Display**: File size, creation date, and sharing computer information

### 🌐 **Network Features**
- **Auto-Discovery**: Agents automatically find and connect to central server
- **Dynamic IP Support**: Works with DHCP, changing IPs, and multiple network interfaces
- **Multi-Interface**: Supports WiFi, Ethernet, VPN configurations
- **WebSocket Communication**: Real-time bidirectional communication with auto-reconnect
- **Network Resilience**: Survives network disconnections and IP changes

### 🖥️ **System Integration**
- **Cross-Platform**: Windows, Linux, macOS support
- **Service Installation**: Optional Windows service installation
- **File Browser**: Built-in file system browser with download capabilities
- **Command Execution**: Remote command execution (configurable)
- **Health Monitoring**: System health checks and status reporting

## 🛠️ Architecture

The system consists of three main components:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Browser   │    │  Central Server │    │     Agent 1     │
│  (Dashboard)    │◄──►│   (FastAPI +    │◄──►│   (Computer 1)  │
│   React + TS    │    │   WebSocket)    │    │    FastAPI      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                        
                                ▼                        
                       ┌─────────────────┐               
                       │     Agent N     │               
                       │   (Computer N)  │               
                       └─────────────────┘               
```

**Central Server**: Coordinates all agents and serves the web dashboard
**Agents**: Run on each monitored computer, collect metrics and handle requests
**Frontend**: React-based web interface for monitoring and management

## 📊 API Documentation

### Agent Endpoints
- `GET /api/status` - Complete system metrics (CPU, memory, disk, temperatures, drives)
- `GET /api/drives` - Detailed drive information with health status and SMART data
- `GET /api/shared-files` - List all shared files with metadata
- `POST /api/upload` - Upload file for sharing (multipart/form-data)
- `GET /api/download/{file_id}` - Download shared file by ID
- `DELETE /api/shared-files/{file_id}` - Delete shared file
- `GET /api/files?path=` - Browse file system at specified path
- `POST /api/command` - Execute system commands (JSON payload)
- `POST /api/transfer-file` - Transfer file to another agent

### Central Server Endpoints
- `GET /api/agents` - List all connected agents with status
- `WebSocket /ws/register` - Agent registration and real-time updates

### WebSocket Events
- `register` - Agent registration: `{"type": "register", "agent_id": "...", "hostname": "...", "ip": "..."}`
- `status_update` - Real-time metrics: `{"type": "status_update", "agent_id": "...", "data": {...}}`

## 🎯 Usage Examples

### Monitoring Multiple Computers
1. Set up central server on your main computer
2. Install agents on computers you want to monitor
3. Access web dashboard to see all computers in real-time
4. Monitor CPU usage, memory, temperatures, and drive health
5. Get alerts for high temperatures or low disk space

### File Sharing Between Computers
1. Navigate to "Sharing" tab in the dashboard
2. Select source computer and upload files
3. Files appear in shared list across all computers
4. Download files from any computer on the network
5. Delete files when no longer needed

### Temperature Monitoring
1. View "Temperature" tab for comprehensive thermal data
2. Monitor CPU cores, GPU, and disk temperatures
3. Visual color coding: green (normal), blue (warm), orange (hot), red (critical)
4. Track temperature trends and identify thermal issues
5. Get early warnings before hardware overheating

### System Administration
1. Use file browser to navigate remote computer file systems
2. Download logs, configuration files, or documents
3. Monitor drive health and plan maintenance
4. Track system uptime and performance metrics
5. Manage multiple computers from single interface

## 🔧 Configuration

### Agent Configuration (`config.env`)
```bash
# Central server connection (auto-detected if not specified)
CENTRAL_SERVER_URL=ws://192.168.1.100:8080

# Agent identification
AGENT_ID=MyComputer
AGENT_PORT=3000

# Logging level
LOG_LEVEL=INFO

# Update intervals (seconds)
STATUS_UPDATE_INTERVAL=30
RECONNECT_INTERVAL=10
```

### Central Server Configuration
```bash
# Server binding
SERVER_HOST=0.0.0.0
SERVER_PORT=8080

# Frontend configuration
FRONTEND_URL=http://localhost:5173
CORS_ORIGINS=["http://localhost:5173"]

# WebSocket settings
WS_HEARTBEAT_INTERVAL=30
```

## 🔒 Security Considerations

- **Local Network Design**: Intended for trusted local networks only
- **No Built-in Authentication**: Add authentication layer if needed for security
- **File System Access**: Respects operating system file permissions
- **Network Isolation**: Agents only connect to local central server
- **Command Execution**: Can be disabled in agent configuration
- **File Sharing**: Limited to designated shared directory

## 📈 Performance Specifications

- **Resource Usage**: ~50MB RAM per agent, minimal CPU impact
- **Update Frequency**: 30-second intervals (configurable)
- **Network Traffic**: ~1KB per update per agent
- **File Transfer Speed**: Limited by network bandwidth
- **Scalability**: Tested with 50+ concurrent agents
- **Response Time**: <100ms for API calls on local network

## 🚀 Advanced Features

### Windows Service Installation
```cmd
# Install as Windows service (run as administrator)
cd %USERPROFILE%\ServerMonitorAgent
install-service.bat

# Service management
net start ServerMonitorAgent
net stop ServerMonitorAgent
```

### Custom Temperature Thresholds
Modify temperature warning levels in agent code:
```python
temperatures['CPU_Core_0'] = {
    'current': 65.0,
    'high': 80.0,      # Warning threshold
    'critical': 95.0   # Critical threshold
}
```

### Network Auto-Discovery
Agents use multiple methods to find the central server:
1. Environment variable `CENTRAL_SERVER_URL`
2. Network broadcast discovery
3. Common IP ranges scanning
4. Manual configuration fallback

## 🐛 Troubleshooting

### Agent Connection Issues
- **Firewall**: Ensure ports 3000, 8080, 5173 are open
- **Network**: Verify computers are on same network segment
- **Server Status**: Check central server is running and accessible
- **IP Detection**: Run network info utility to verify configuration

### Temperature Monitoring Problems
- **Administrator Rights**: Run as administrator for full sensor access
- **Hardware Support**: Some systems don't expose temperature sensors
- **Driver Requirements**: Install OpenHardwareMonitor for enhanced detection
- **Sensor Availability**: Older hardware may have limited sensor support

### File Sharing Issues
- **Disk Space**: Ensure sufficient space on both source and target
- **Permissions**: Check file system permissions for shared directory
- **Dependencies**: Verify `aiofiles` package is installed
- **Network Speed**: Large files may take time on slower networks

### Drive Detection Problems
- **Empty Drives**: CD/DVD drives without media are automatically skipped
- **Network Drives**: Mapped network drives may not show health data
- **Permissions**: Some drives require elevated permissions to access
- **External Drives**: USB drives are supported but may disconnect

**For installation instructions, see [INSTALLATION.md](INSTALLATION.md)**
