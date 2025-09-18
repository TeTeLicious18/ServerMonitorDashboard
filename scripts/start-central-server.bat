@echo off
echo Starting Server Monitor Central Server...
echo.

cd /d "%~dp0central-server"

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in PATH
    echo Please run install-python.bat first
    pause
    exit /b 1
)

echo Checking if dependencies are installed...
python -c "import fastapi, uvicorn, websockets" >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing dependencies...
    pip install -r requirements.txt
    if %errorlevel% neq 0 (
        echo ERROR: Failed to install dependencies
        pause
        exit /b 1
    )
)

echo.
echo Central Server starting on http://localhost:8080
echo WebSocket endpoint: ws://localhost:8080/ws/register
echo Press Ctrl+C to stop
echo.

python main.py
