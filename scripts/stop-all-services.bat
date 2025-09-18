@echo off
echo ========================================
echo Stopping Server Monitor Dashboard
echo ========================================
echo.

echo Stopping Docker frontend container...
docker stop server-monitor-frontend 2>nul
docker rm server-monitor-frontend 2>nul

echo Stopping Python services...
taskkill /f /im python.exe 2>nul

echo Stopping any remaining processes...
for /f "tokens=5" %%a in ('netstat -aon ^| find ":8080" ^| find "LISTENING"') do taskkill /f /pid %%a 2>nul
for /f "tokens=5" %%a in ('netstat -aon ^| find ":3000" ^| find "LISTENING"') do taskkill /f /pid %%a 2>nul
for /f "tokens=5" %%a in ('netstat -aon ^| find ":5173" ^| find "LISTENING"') do taskkill /f /pid %%a 2>nul

echo.
echo All services stopped successfully!
echo.
pause
