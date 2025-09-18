# 📦 Installation Guide - Server Monitor Dashboard

Complete setup instructions for the Multi-Computer Server Monitor Dashboard system.

## 🚀 Quick Installation

### For New Client Computers (Recommended)

**Option 1: Automated Installer Scripts**
1. Copy `install-client.bat` or `install-client.ps1` to the target computer
2. Run the installer:
   ```cmd
   # Windows Command Prompt
   install-client.bat
   
   # PowerShell (recommended - run as administrator)
   powershell -ExecutionPolicy Bypass -File install-client.ps1
   ```
3. The installer will:
   - Check for Python 3.8+
   - Install dependencies automatically
   - Create desktop shortcuts
   - Set up Windows service (optional)
   - Start the agent automatically

**Option 2: Deployment Package**
1. Use the pre-built deployment package in `agent-deployment-ready/`
2. Run `QUICK-START.bat` as administrator
3. Agent starts automatically and connects to central server

### For Central Server Setup

**Prerequisites:**
- Python 3.8+ ([Download from python.org](https://python.org))
- Node.js 16+ ([Download from nodejs.org](https://nodejs.org))
- Git (optional, for development)

**Step 1: Install Python Dependencies**
```bash
# Install central server dependencies
cd central-server
pip install -r requirements.txt

# Install agent dependencies (for local monitoring)
cd ../agent
pip install -r requirements.txt
```

**Step 2: Install Frontend Dependencies**
```bash
cd frontend
npm install
```

**Step 3: Start All Services**
```bash
# Option A: Use startup scripts
start-all.bat                    # Windows
./start-all.sh                   # Linux/macOS

# Option B: Manual startup (3 terminals)
# Terminal 1 - Central Server
cd central-server
python main.py

# Terminal 2 - Local Agent
cd agent
python main.py

# Terminal 3 - Frontend
cd frontend
npm run dev
```

## 🔧 Manual Installation

### Step 1: Python Installation

**Windows:**
```cmd
# Download from python.org or use Microsoft Store
# Ensure "Add Python to PATH" is checked during installation

# Verify installation
python --version
pip --version
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv
```

**macOS:**
```bash
# Using Homebrew
brew install python3

# Or download from python.org
```

### Step 2: Project Setup

**Clone or Download Project:**
```bash
# If using Git
git clone <repository-url>
cd server-monitor

# Or download and extract ZIP file
```

**Install Backend Dependencies:**
```bash
# Central server
cd central-server
pip install fastapi uvicorn websockets python-multipart
# Or: pip install -r requirements.txt

# Agent
cd ../agent
pip install fastapi uvicorn psutil websockets aiofiles python-multipart
# Or: pip install -r requirements.txt
```

**Install Frontend Dependencies:**
```bash
cd frontend
npm install
# This installs React, TypeScript, Vite, TailwindCSS, and other dependencies
```

### Step 3: Configuration

**Agent Configuration (Optional):**
Create `agent/config.env`:
```bash
# Central server URL (auto-detected if not set)
CENTRAL_SERVER_URL=ws://192.168.1.100:8080

# Agent identification
AGENT_ID=MyComputer
AGENT_PORT=3000

# Logging
LOG_LEVEL=INFO
```

**Central Server Configuration (Optional):**
Create `central-server/config.env`:
```bash
# Server settings
SERVER_HOST=0.0.0.0
SERVER_PORT=8080

# Frontend URL
FRONTEND_URL=http://localhost:5173
```

## 🌐 Network Setup

### Automatic IP Detection
The system automatically detects network configuration. No manual IP setup required.

### Manual IP Configuration (If Needed)
If automatic detection fails:

1. **Find Your IP Address:**
   ```cmd
   # Windows
   ipconfig
   
   # Linux/macOS
   ifconfig
   ```

2. **Update Agent Configuration:**
   ```bash
   # Set environment variable
   set CENTRAL_SERVER_URL=ws://YOUR_SERVER_IP:8080
   
   # Or modify agent/main.py
   central_server_url = "ws://YOUR_SERVER_IP:8080"
   ```

## 🔍 Verification

### Test Central Server
```bash
# Start central server
cd central-server
python main.py

# Test in browser
http://localhost:8080/docs
```

### Test Agent
```bash
# Start agent
cd agent
python main.py

# Test API endpoints
http://localhost:3000/api/status
http://localhost:3000/api/drives
```

### Test Frontend
```bash
# Start frontend
cd frontend
npm run dev

# Access dashboard
http://localhost:5173
```

## 🖥️ Windows Service Installation

**Install Agent as Windows Service:**
```cmd
# Run as administrator
cd agent
python -m pip install pywin32
python install-service.py install

# Start service
net start ServerMonitorAgent

# Stop service
net stop ServerMonitorAgent

# Remove service
python install-service.py remove
```

## 📱 Deployment to Multiple Computers

### Method 1: Installer Scripts
1. Copy `install-client.bat` to each target computer
2. Run as administrator
3. Agent automatically connects to central server

### Method 2: Manual Deployment
1. Copy `agent/` folder to target computer
2. Install Python 3.8+ on target computer
3. Install dependencies: `pip install -r requirements.txt`
4. Run: `python main.py`

### Method 3: Deployment Package
1. Use pre-built package in `agent-deployment-ready/`
2. Copy entire folder to target computer
3. Run `QUICK-START.bat`

## 🐛 Troubleshooting

### Python Installation Issues
- **Error 0x80070659**: Use Microsoft Store Python or portable version
- **PATH Issues**: Restart command prompt after Python installation
- **Permission Denied**: Run installer as administrator

### Dependency Installation Problems
```bash
# Update pip first
python -m pip install --upgrade pip

# Install with user flag if permission issues
pip install --user -r requirements.txt

# Use virtual environment
python -m venv venv
venv\Scripts\activate  # Windows
source venv/bin/activate  # Linux/macOS
pip install -r requirements.txt
```

### Network Connection Issues
- **Firewall**: Open ports 3000, 8080, 5173
- **Network Discovery**: Run `python get-network-info.py`
- **Manual IP**: Set `CENTRAL_SERVER_URL` environment variable
- **Same Network**: Ensure all computers on same network segment

### Agent Connection Problems
```bash
# Check central server is running
curl http://SERVER_IP:8080/api/agents

# Test WebSocket connection
# Use browser developer tools to test ws://SERVER_IP:8080/ws/register

# Check agent logs for connection errors
```

### Temperature Monitoring Issues
- **No Sensors**: Run as administrator for better sensor access
- **Hardware Support**: Install OpenHardwareMonitor for enhanced detection
- **Driver Issues**: Update motherboard and GPU drivers

### File Sharing Problems
- **Missing aiofiles**: `pip install aiofiles`
- **Permissions**: Check shared directory permissions
- **Disk Space**: Ensure sufficient space for file transfers

## 🔒 Security Setup

### For Production Use
1. **Add Authentication:**
   - Implement JWT tokens
   - Add user management
   - Secure API endpoints

2. **Network Security:**
   - Use HTTPS/WSS protocols
   - Configure firewall rules
   - Limit network access

3. **File System Security:**
   - Restrict shared directories
   - Implement file type filtering
   - Add virus scanning

## 📊 Performance Optimization

### System Requirements
- **Minimum**: 512MB RAM, Python 3.8+
- **Recommended**: 1GB RAM, Python 3.10+, SSD storage
- **Network**: 100Mbps for file transfers

### Optimization Tips
```bash
# Reduce update frequency for lower resource usage
STATUS_UPDATE_INTERVAL=60  # Default: 30 seconds

# Limit file sharing directory size
MAX_SHARED_FILES=100
MAX_FILE_SIZE=100MB
```

## 🆘 Getting Help

### Log Files
- **Agent Logs**: Check console output or log files
- **Central Server Logs**: Monitor server console
- **Frontend Logs**: Use browser developer tools

### Common Commands
```bash
# Check Python version
python --version

# Test network connectivity
ping SERVER_IP

# Check running processes
tasklist | findstr python  # Windows
ps aux | grep python       # Linux/macOS

# Check open ports
netstat -an | findstr :8080
```

### Support Resources
1. Check console output for error messages
2. Verify all dependencies are installed
3. Test network connectivity between computers
4. Ensure firewall allows required ports
5. Run installers as administrator when needed

---

**Installation complete! Access your dashboard at `http://localhost:5173`**
