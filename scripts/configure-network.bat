@echo off
echo ========================================
echo Network Configuration for Server Monitor
echo ========================================
echo.

echo This script will configure Windows Firewall to allow connections
echo to the Server Monitor on ports 8080 and 5173.
echo.
echo You need to run this as Administrator.
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script must be run as Administrator.
    echo.
    echo Right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo [INFO] Running as Administrator - configuring firewall...
echo.

REM Add firewall rules
echo Adding firewall rule for Central Server (port 8080)...
netsh advfirewall firewall add rule name="Server Monitor Central" dir=in action=allow protocol=TCP localport=8080

echo Adding firewall rule for Dashboard (port 5173)...
netsh advfirewall firewall add rule name="Server Monitor Dashboard" dir=in action=allow protocol=TCP localport=5173

echo Adding firewall rule for Agent (port 3000)...
netsh advfirewall firewall add rule name="Server Monitor Agent" dir=in action=allow protocol=TCP localport=3000

echo.
echo ========================================
echo Network Configuration Complete!
echo ========================================
echo.
echo Firewall rules added for:
echo - Port 8080 (Central Server)
echo - Port 5173 (Dashboard)
echo - Port 3000 (Agent)
echo.
echo Your IP address for other computers to connect:
ipconfig | findstr "IPv4"
echo.
echo Next steps:
echo 1. Restart your central server and agent
echo 2. Use your IP address in agent installations on other computers
echo 3. Other computers can access dashboard at: http://YOUR_IP:5173
echo.
pause
