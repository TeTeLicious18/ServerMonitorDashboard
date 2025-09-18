@echo off
echo ====================================
echo Server Monitor Agent - Stopping
echo ====================================
echo.

echo Stopping Server Monitor Agent...

REM Kill Python processes (agent)
taskkill /f /im python.exe >nul 2>&1

echo Agent stopped successfully.
echo.
pause
