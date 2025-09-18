@echo off
echo ====================================
echo Server Monitor - Quick Restart
echo ====================================
echo.

echo Restarting all services...
call stop.bat
timeout /t 2 /nobreak >nul
call start.bat
