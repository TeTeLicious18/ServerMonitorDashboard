@echo off
echo ====================================
echo Server Monitor - QUICK START
echo ====================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if errorlevel 1 (
    echo This script requires administrator privileges for installation.
    echo Please right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo One-click installation and startup...
echo.

REM Step 1: Install Python if needed
echo [1/4] Checking Python installation...
python --version >nul 2>&1
if errorlevel 1 (
    echo Python not found. Please install Python 3.8+ first:
    echo https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH"
    echo.
    pause
    exit /b 1
) else (
    echo ✅ Python found
)

REM Step 2: Install dependencies
echo [2/4] Installing Python dependencies...
pip install --upgrade pip >nul 2>&1
pip install -r "%~dp0requirements.txt"
if errorlevel 1 (
    echo ❌ Failed to install dependencies
    echo Check internet connection and try again
    pause
    exit /b 1
) else (
    echo ✅ Dependencies installed
)

REM Step 3: Test connection
echo [3/4] Testing connection to central server...
ping -n 1 192.168.1.52 >nul 2>&1
if errorlevel 1 (
    echo ❌ Cannot reach central server at 192.168.1.52
    echo Check network connection
    pause
    exit /b 1
) else (
    echo ✅ Central server reachable
)

REM Step 4: Start agent
echo [4/4] Starting Server Monitor Agent...
echo.
echo ====================================
echo Agent Starting Successfully!
echo ====================================
echo.
echo Configuration:
echo - Central Server: ws://192.168.1.52:8080
echo - Agent ID: %COMPUTERNAME%
echo - Dashboard: http://192.168.1.52:5173
echo.
echo Agent will appear in dashboard within 30 seconds
echo Keep this window open to maintain monitoring
echo Press Ctrl+C to stop monitoring
echo.

REM Set environment and start
set CENTRAL_SERVER_URL=ws://192.168.1.52:8080
set AGENT_ID=%COMPUTERNAME%
set AGENT_PORT=3000

python main.py

echo.
echo Agent stopped.
pause
