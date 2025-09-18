@echo off
echo ====================================
echo Server Monitor Agent - Installation
echo ====================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if errorlevel 1 (
    echo This script requires administrator privileges.
    echo Please right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo Installing Server Monitor Agent...
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo Python is not installed. Installing Python...
    echo.
    echo Please download and install Python 3.8+ from:
    echo https://www.python.org/downloads/
    echo.
    echo Make sure to check "Add Python to PATH" during installation
    echo.
    pause
    exit /b 1
)

echo Python found. Installing dependencies...
pip install --upgrade pip
pip install -r "%~dp0requirements.txt"

if errorlevel 1 (
    echo.
    echo ERROR: Failed to install Python dependencies
    echo Please check your internet connection and try again
    echo.
    pause
    exit /b 1
)

echo.
echo ====================================
echo Installation Complete!
echo ====================================
echo.
echo To start monitoring:
echo 1. Run: start-agent.bat
echo 2. Check dashboard: http://192.168.1.52:5173
echo.
echo Agent will connect to: ws://192.168.1.52:8080
echo.
pause
