# Multi-Computer Deployment Guide

This guide explains how to install the Server Monitor agent on other computers to monitor them from your central dashboard.

## Architecture Overview

- **Central Server**: Runs on your main computer (current setup)
- **Agents**: Install on each computer you want to monitor
- **Dashboard**: Access from any browser on your network

## Prerequisites for Target Computers

- Python 3.8+ installed
- Network access to your central server
- Windows, Linux, or macOS

## Deployment Options

### Option 1: Simple Agent-Only Installation (Recommended)

For each computer you want to monitor:

1. **Copy the agent folder** to the target computer
2. **Install Python dependencies**
3. **Configure the central server URL**
4. **Run the agent**

### Option 2: Portable Installation Package

Use the pre-built installation package (see below).

### Option 3: Network Share Installation

Set up a network share for easy deployment across multiple computers.

## Step-by-Step Instructions

### 1. Prepare the Agent Package

On your main computer, create a deployment package:

```bash
# Create deployment folder
mkdir server-monitor-agent-deploy
cd server-monitor-agent-deploy

# Copy agent files
copy ..\agent\*.py .
copy ..\agent\requirements.txt .

# Create configuration file
echo CENTRAL_SERVER_URL=ws://YOUR_MAIN_COMPUTER_IP:8080 > .env
```

### 2. Find Your Central Server IP Address

On your main computer, run:
```cmd
ipconfig
```
Look for your local IP address (usually 192.168.x.x or 10.x.x.x)

### 3. Install on Target Computers

#### Windows Installation:

1. **Copy the agent folder** to target computer
2. **Install Python** (if not installed):
   - Download from https://python.org
   - Check "Add Python to PATH" during installation
3. **Open Command Prompt as Administrator**
4. **Navigate to agent folder**:
   ```cmd
   cd path\to\server-monitor-agent
   ```
5. **Install dependencies**:
   ```cmd
   pip install -r requirements.txt
   ```
6. **Configure central server URL**:
   ```cmd
   set CENTRAL_SERVER_URL=ws://192.168.1.100:8080
   ```
   (Replace 192.168.1.100 with your main computer's IP)
7. **Run the agent**:
   ```cmd
   python main.py
   ```

#### Linux/macOS Installation:

1. **Copy the agent folder** to target computer
2. **Install Python** (if not installed):
   ```bash
   # Ubuntu/Debian
   sudo apt update && sudo apt install python3 python3-pip
   
   # macOS (with Homebrew)
   brew install python3
   ```
3. **Navigate to agent folder**:
   ```bash
   cd /path/to/server-monitor-agent
   ```
4. **Install dependencies**:
   ```bash
   pip3 install -r requirements.txt
   ```
5. **Configure and run**:
   ```bash
   export CENTRAL_SERVER_URL=ws://192.168.1.100:8080
   python3 main.py
   ```

## Network Configuration

### Firewall Settings

On your **main computer** (central server), ensure these ports are open:

- **Port 8080**: Central Server API
- **Port 5173**: Dashboard (if accessing remotely)

#### Windows Firewall:
```cmd
netsh advfirewall firewall add rule name="Server Monitor Central" dir=in action=allow protocol=TCP localport=8080
netsh advfirewall firewall add rule name="Server Monitor Dashboard" dir=in action=allow protocol=TCP localport=5173
```

#### Linux (ufw):
```bash
sudo ufw allow 8080
sudo ufw allow 5173
```

### Router Configuration (Optional)

For monitoring computers outside your local network:
1. Configure port forwarding on your router
2. Forward ports 8080 and 5173 to your main computer
3. Use your public IP address in agent configuration

## Automated Installation Scripts

### Windows Auto-Install Script

Save as `install-agent.bat` on target computers:

```batch
@echo off
echo Installing Server Monitor Agent...
echo.

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python is not installed. Please install Python first.
    echo Download from: https://python.org
    pause
    exit /b 1
)

REM Install dependencies
echo Installing dependencies...
pip install -r requirements.txt

REM Get central server IP
set /p CENTRAL_IP="Enter your central server IP address (e.g., 192.168.1.100): "

REM Create environment file
echo CENTRAL_SERVER_URL=ws://%CENTRAL_IP%:8080 > .env

REM Create startup script
echo @echo off > start-agent.bat
echo set CENTRAL_SERVER_URL=ws://%CENTRAL_IP%:8080 >> start-agent.bat
echo python main.py >> start-agent.bat

echo.
echo Installation complete!
echo Run 'start-agent.bat' to start monitoring this computer.
pause
```

### Linux/macOS Auto-Install Script

Save as `install-agent.sh`:

```bash
#!/bin/bash
echo "Installing Server Monitor Agent..."

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Python 3 is not installed. Please install it first."
    exit 1
fi

# Install dependencies
echo "Installing dependencies..."
pip3 install -r requirements.txt

# Get central server IP
read -p "Enter your central server IP address (e.g., 192.168.1.100): " CENTRAL_IP

# Create environment file
echo "CENTRAL_SERVER_URL=ws://$CENTRAL_IP:8080" > .env

# Create startup script
cat > start-agent.sh << EOF
#!/bin/bash
export CENTRAL_SERVER_URL=ws://$CENTRAL_IP:8080
python3 main.py
EOF

chmod +x start-agent.sh

echo "Installation complete!"
echo "Run './start-agent.sh' to start monitoring this computer."
```

## Running as a Service

### Windows Service (Optional)

To run the agent automatically on startup:

1. **Install NSSM** (Non-Sucking Service Manager):
   - Download from https://nssm.cc/
2. **Create service**:
   ```cmd
   nssm install ServerMonitorAgent
   nssm set ServerMonitorAgent Application "C:\Python39\python.exe"
   nssm set ServerMonitorAgent AppParameters "C:\path\to\agent\main.py"
   nssm set ServerMonitorAgent AppDirectory "C:\path\to\agent"
   nssm start ServerMonitorAgent
   ```

### Linux Systemd Service

Create `/etc/systemd/system/server-monitor-agent.service`:

```ini
[Unit]
Description=Server Monitor Agent
After=network.target

[Service]
Type=simple
User=your-username
WorkingDirectory=/path/to/agent
Environment=CENTRAL_SERVER_URL=ws://192.168.1.100:8080
ExecStart=/usr/bin/python3 /path/to/agent/main.py
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable server-monitor-agent
sudo systemctl start server-monitor-agent
```

## Troubleshooting

### Common Issues:

1. **Agent not connecting**:
   - Check firewall settings
   - Verify IP address is correct
   - Ensure central server is running

2. **Permission errors**:
   - Run as administrator/sudo
   - Check file permissions

3. **Python not found**:
   - Ensure Python is in PATH
   - Use full path to python executable

4. **Network connectivity**:
   - Test with: `telnet CENTRAL_IP 8080`
   - Check if computers are on same network

### Verification Steps:

1. **Check agent connection**:
   ```bash
   # On central server
   curl http://localhost:8080/api/agents
   ```

2. **View agent logs**:
   - Check console output for connection status
   - Look for "Connected to central server" message

3. **Test dashboard**:
   - Open http://YOUR_CENTRAL_IP:5173
   - Verify new agents appear in sidebar

## Security Considerations

1. **Network Security**:
   - Use VPN for remote monitoring
   - Restrict firewall rules to specific IP ranges
   - Consider HTTPS/WSS for production

2. **Access Control**:
   - Limit dashboard access to authorized users
   - Use strong passwords for computer accounts
   - Monitor agent connections regularly

## Scaling Tips

- **Large Networks**: Use configuration management tools (Ansible, Puppet)
- **Multiple Subnets**: Configure routing or use multiple central servers
- **High Availability**: Run multiple central server instances with load balancing
- **Database Storage**: Add database backend for historical data (future enhancement)

## Next Steps

After installation:
1. Verify all agents appear in dashboard
2. Test real-time monitoring
3. Configure alerts (future feature)
4. Set up automated backups
5. Plan maintenance schedules
