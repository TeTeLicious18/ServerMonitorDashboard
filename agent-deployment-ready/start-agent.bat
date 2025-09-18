@echo off
echo ====================================
echo Server Monitor Agent - Starting
echo ====================================
echo.

REM Set the central server URL with correct network IP
set CENTRAL_SERVER_URL=ws://192.168.1.52:8080
set AGENT_ID=%COMPUTERNAME%
set AGENT_PORT=3000

echo Agent Configuration:
echo - Server URL: %CENTRAL_SERVER_URL%
echo - Agent ID: %AGENT_ID%
echo - Agent Port: %AGENT_PORT%
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.8+ first
    echo.
    pause
    exit /b 1
)

REM Check if requirements are installed
echo Checking Python dependencies...
python -c "import fastapi, uvicorn, psutil, websockets" >nul 2>&1
if errorlevel 1 (
    echo Installing required Python packages...
    pip install -r "%~dp0requirements.txt"
    if errorlevel 1 (
        echo ERROR: Failed to install dependencies
        echo Please check your internet connection and try again
        pause
        exit /b 1
    )
)

echo.
echo Starting Server Monitor Agent...
echo Connecting to central server at: %CENTRAL_SERVER_URL%
echo.
echo Agent will appear in dashboard within 30 seconds
echo Dashboard: http://192.168.1.52:5173
echo.
echo Press Ctrl+C to stop the agent
echo.

REM Start the agent
python main.py

echo.
echo Agent stopped.
pause
