@echo off
echo ========================================
echo Server Monitor Agent - Manual Start
echo ========================================
echo.

echo Starting Server Monitor Agent...
echo Connecting to central server at 192.168.1.52:8080
echo.

set CENTRAL_SERVER_URL=ws://192.168.1.52:8080
cd /d "%~dp0"
python main.py

pause
