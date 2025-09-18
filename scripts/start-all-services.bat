@echo off
echo ========================================
echo Starting Server Monitor Dashboard
echo ========================================
echo.

echo Starting Central Server...
start "Central Server" cmd /k "cd /d %~dp0 && start-central-server.bat"

echo Waiting 3 seconds for central server to start...
timeout /t 3 /nobreak >nul

echo Starting Agent Service...
start "Agent Service" cmd /k "cd /d %~dp0 && start-agent.bat"

echo Waiting 2 seconds for agent to start...
timeout /t 2 /nobreak >nul

echo Starting Frontend (Docker)...
docker run -d -p 5173:5173 --name server-monitor-frontend server-monitor-frontend 2>nul
if %errorlevel% neq 0 (
    echo Frontend container already running or failed to start
    echo Stopping existing container and restarting...
    docker stop server-monitor-frontend 2>nul
    docker rm server-monitor-frontend 2>nul
    docker run -d -p 5173:5173 --name server-monitor-frontend server-monitor-frontend
)

echo.
echo ========================================
echo All services started!
echo ========================================
echo.
echo Services:
echo - Central Server: http://localhost:8080
echo - Agent Service: http://localhost:3000  
echo - React Frontend: http://localhost:5173
echo - Simple HTML Dashboard: %~dp0simple-dashboard.html
echo.
echo Opening dashboards...
start http://localhost:5173
timeout /t 2 /nobreak >nul
start %~dp0simple-dashboard.html
echo.
echo Press any key to stop all services...
pause >nul

echo.
echo Stopping services...
docker stop server-monitor-frontend 2>nul
docker rm server-monitor-frontend 2>nul
taskkill /f /im python.exe 2>nul
echo Services stopped.
pause
