@echo off
echo ====================================
echo Server Monitor - Complete Shutdown
echo ====================================
echo.

echo Stopping all Server Monitor services...

REM Stop Docker container
echo Stopping Dashboard (Docker)...
docker stop server-monitor-frontend >nul 2>&1
docker rm server-monitor-frontend >nul 2>&1

REM Kill all Python processes
echo Stopping Central Server and Agents...
taskkill /f /im python.exe >nul 2>&1

REM Close any command windows with our services
echo Closing service windows...
taskkill /f /fi "WindowTitle eq Central Server*" >nul 2>&1
taskkill /f /fi "WindowTitle eq Local Agent*" >nul 2>&1

echo.
echo All services stopped successfully!
echo.
pause
