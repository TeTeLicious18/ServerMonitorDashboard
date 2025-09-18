@echo off
echo ========================================
echo Restarting Services for Network Access
echo ========================================
echo.

echo Stopping existing services...
taskkill /f /im python.exe 2>nul

echo Waiting 3 seconds...
timeout /t 3 /nobreak >nul

echo Starting Central Server (network accessible)...
start "Central Server" cmd /k "cd /d %~dp0central-server && python main.py"

echo Waiting 3 seconds for central server...
timeout /t 3 /nobreak >nul

echo Starting Agent (network accessible)...
start "Agent" cmd /k "cd /d %~dp0agent && python main.py"

echo.
echo ========================================
echo Services Restarted for Network Access
echo ========================================
echo.
echo Central Server: http://0.0.0.0:8080 (accessible from network)
echo Agent: http://0.0.0.0:3000 (accessible from network)
echo Dashboard: http://localhost:5173 (Docker container)
echo.
echo Your IP for other computers: 192.168.1.52
echo Other computers can now connect to: ws://192.168.1.52:8080
echo.
echo Next: Run configure-network.bat as Administrator to set firewall rules
echo.
pause
