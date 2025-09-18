@echo off
echo ====================================
echo Server Monitor - Complete Startup
echo ====================================
echo.

REM Kill any existing Python processes to avoid conflicts
echo Stopping any existing services...
taskkill /f /im python.exe >nul 2>&1

REM Stop and remove existing Docker container
docker stop server-monitor-frontend >nul 2>&1
docker rm server-monitor-frontend >nul 2>&1

echo.
echo Starting services in correct order...
echo.

REM 1. Start Central Server
echo [1/3] Starting Central Server on port 8080...
cd /d "%~dp0central-server"
start "Central Server" cmd /k "echo Central Server Starting... && python main.py"
cd /d "%~dp0"

REM Wait for central server to start
echo Waiting for central server to initialize...
timeout /t 5 /nobreak >nul

REM 2. Start Local Agent with correct network IP
echo [2/3] Starting Local Agent with network connection...
cd /d "%~dp0agent"
start "Local Agent" cmd /k "echo Local Agent Starting... && set CENTRAL_SERVER_URL=ws://192.168.1.52:8080 && python main.py"
cd /d "%~dp0"

REM Wait for agent to connect
echo Waiting for agent to connect...
timeout /t 3 /nobreak >nul

REM 3. Start Dashboard (Docker)
echo [3/3] Starting Dashboard (Docker container)...
docker run -d --name server-monitor-frontend -p 5173:5173 server-monitor-frontend >nul 2>&1

if errorlevel 1 (
    echo Building Docker image first...
    docker build -t server-monitor-frontend ./frontend
    docker run -d --name server-monitor-frontend -p 5173:5173 server-monitor-frontend
)

echo.
echo Waiting for all services to be ready...
timeout /t 8 /nobreak >nul

echo.
echo ====================================
echo Service Status Check
echo ====================================

REM Check Central Server
echo Testing Central Server API...
powershell -Command "try { $response = Invoke-WebRequest -Uri http://localhost:8080/api/agents -UseBasicParsing -TimeoutSec 5; Write-Host 'Central Server: ONLINE' -ForegroundColor Green; Write-Host 'Connected Agents:' $response.Content.Split('[{').Length } catch { Write-Host 'Central Server: FAILED' -ForegroundColor Red }"

REM Check Dashboard
echo Testing Dashboard...
powershell -Command "try { Invoke-WebRequest -Uri http://localhost:5173 -UseBasicParsing -TimeoutSec 5 | Out-Null; Write-Host 'Dashboard: ONLINE' -ForegroundColor Green } catch { Write-Host 'Dashboard: FAILED' -ForegroundColor Red }"

REM Check Network Access
echo Testing Network Access...
powershell -Command "try { Invoke-WebRequest -Uri http://192.168.1.52:8080/api/agents -UseBasicParsing -TimeoutSec 5 | Out-Null; Write-Host 'Network Access: WORKING' -ForegroundColor Green } catch { Write-Host 'Network Access: FAILED' -ForegroundColor Red }"

echo.
echo ====================================
echo Server Monitor Dashboard Ready!
echo ====================================
echo.
echo Access Points:
echo - Dashboard: http://localhost:5173
echo - Network Dashboard: http://192.168.1.52:5173
echo - API: http://192.168.1.52:8080/api/agents
echo.
echo For other computers:
echo 1. Copy 'agent-deployment-ready' folder
echo 2. Run QUICK-START.bat
echo 3. Start with start-agent.bat
echo.
echo Press any key to open dashboard in browser...
pause >nul
start http://localhost:5173
echo.
echo Services are running in separate windows.
echo Close those windows to stop the services.
pause
