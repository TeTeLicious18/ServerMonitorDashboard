@echo off
echo ====================================
echo Server Monitor Agent Installer
echo ====================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.8+ from https://python.org
    echo Make sure to check "Add Python to PATH" during installation
    pause
    exit /b 1
)

echo Python found. Installing dependencies...
pip install fastapi uvicorn psutil websockets

if errorlevel 1 (
    echo ERROR: Failed to install Python dependencies
    echo Please check your internet connection and try again
    pause
    exit /b 1
)

echo.
echo Dependencies installed successfully!
echo.

REM Set the central server IP (update this to your actual server IP)
set CENTRAL_SERVER_IP=192.168.1.52

echo Central Server IP: %CENTRAL_SERVER_IP%
echo.
echo Testing connection to central server...
powershell -Command "try { Test-NetConnection -ComputerName %CENTRAL_SERVER_IP% -Port 8080 -WarningAction SilentlyContinue | Out-Null; Write-Host 'SUCCESS: Can reach central server' } catch { Write-Host 'WARNING: Cannot reach central server. Check network connection.' }"
echo.

echo Creating startup scripts...

REM Create start-agent.bat in the current directory
echo @echo off > start-agent.bat
echo echo Starting Server Monitor Agent... >> start-agent.bat
echo echo Connecting to central server at %CENTRAL_SERVER_IP%:8080 >> start-agent.bat
echo set CENTRAL_SERVER_URL=ws://%CENTRAL_SERVER_IP%:8080 >> start-agent.bat
echo python "%~dp0main.py" >> start-agent.bat
echo pause >> start-agent.bat

REM Create stop-agent.bat in the current directory
echo @echo off > stop-agent.bat
echo echo Stopping Server Monitor Agent... >> stop-agent.bat
echo taskkill /f /im python.exe >> stop-agent.bat
echo echo Agent stopped. >> stop-agent.bat
echo pause >> stop-agent.bat

REM Create test-connection.bat for troubleshooting
echo @echo off > test-connection.bat
echo echo Testing connection to central server... >> test-connection.bat
echo powershell -Command "Test-NetConnection -ComputerName %CENTRAL_SERVER_IP% -Port 8080" >> test-connection.bat
echo echo. >> test-connection.bat
echo echo Testing API endpoint... >> test-connection.bat
echo powershell -Command "try { Invoke-WebRequest -Uri http://%CENTRAL_SERVER_IP%:8080/api/agents -UseBasicParsing -TimeoutSec 5 | Select-Object StatusCode } catch { Write-Host 'Connection failed:' $_.Exception.Message }" >> test-connection.bat
echo pause >> test-connection.bat

echo.
echo ====================================
echo Installation Complete!
echo ====================================
echo.
echo Central Server: %CENTRAL_SERVER_IP%:8080
echo Agent files created in: %CD%
echo.
echo IMPORTANT: Make sure the central server computer has:
echo   - Central server running on port 8080
echo   - Windows Firewall rule allowing port 8080
echo   - Both computers on the same network
echo.
echo To start the agent:
echo   1. Double-click start-agent.bat
echo   2. Or run: start-agent.bat
echo.
echo To test connection:
echo   1. Double-click test-connection.bat
echo.
echo To stop the agent:
echo   1. Double-click stop-agent.bat
echo   2. Or press Ctrl+C in the agent window
echo.
echo The agent will automatically connect to the central server
echo and appear in the dashboard within 30 seconds.
echo.
pause
