@echo off
title Server Monitor - Unified Startup
color 0A

:MAIN_MENU
cls
echo.
echo ========================================================
echo                SERVER MONITOR - UNIFIED STARTUP
echo ========================================================
echo.
echo Choose your startup option:
echo.
echo [1] Complete System (Dynamic IP) - RECOMMENDED
echo     Start everything with automatic IP detection
echo.
echo [2] Agent Only (Dynamic Connection)
echo     Connect to existing central server automatically
echo.
echo [3] Complete System (Legacy/Docker)
echo     Original startup with Docker frontend
echo.
echo [4] Show Network Information
echo     Display current network configuration
echo.
echo [5] Central Server Only
echo     Start only the central server
echo.
echo [6] Frontend Only
echo     Start only the React dashboard
echo.
echo [0] Exit
echo.
echo ========================================================
set /p choice="Enter your choice (0-6): "

if "%choice%"=="1" goto DYNAMIC_COMPLETE
if "%choice%"=="2" goto AGENT_ONLY
if "%choice%"=="3" goto LEGACY_COMPLETE
if "%choice%"=="4" goto NETWORK_INFO
if "%choice%"=="5" goto CENTRAL_ONLY
if "%choice%"=="6" goto FRONTEND_ONLY
if "%choice%"=="0" goto EXIT
echo Invalid choice. Please try again.
timeout /t 2 >nul
goto MAIN_MENU

:DYNAMIC_COMPLETE
cls
echo ==========================================
echo Server Monitor - Dynamic IP Startup
echo ==========================================
echo.

REM Kill any existing processes
echo Stopping any existing services...
taskkill /f /im python.exe >nul 2>&1
taskkill /f /im node.exe >nul 2>&1

REM Get the current directory
set "PROJECT_DIR=%~dp0"

REM Start Central Server (it will auto-detect IP)
echo [1/3] Starting Central Server with dynamic IP detection...
cd /d "%PROJECT_DIR%central-server"
start "Central Server" cmd /k "echo Central Server Starting... && python main.py"
cd /d "%PROJECT_DIR%"

REM Wait for central server to start
echo Waiting for Central Server to initialize...
timeout /t 5 /nobreak >nul

REM Start Local Agent (it will auto-detect central server)
echo [2/3] Starting Local Agent with auto-detection...
cd /d "%PROJECT_DIR%agent"
start "Local Agent" cmd /k "echo Local Agent Starting... && python main.py"
cd /d "%PROJECT_DIR%"

REM Wait for agent to connect
echo Waiting for Agent to connect...
timeout /t 5 /nobreak >nul

REM Start Frontend
echo [3/3] Starting Frontend Dashboard...
cd /d "%PROJECT_DIR%frontend"
start "Frontend Dashboard" cmd /k "echo Frontend Starting... && npm run dev"
cd /d "%PROJECT_DIR%"

echo.
echo ====================================
echo All services started successfully!
echo ====================================
echo.
echo The system will automatically detect network configuration.
echo Check the console windows for the detected IP addresses.
echo.
echo Services:
echo - Central Server: Auto-detected IP on port 8080
echo - Local Agent: Auto-detected connection
echo - Frontend: http://localhost:5173
echo.
echo Wait 30 seconds for all services to fully initialize,
echo then check the dashboard for connected agents.
echo.
goto END_PAUSE

:AGENT_ONLY
cls
echo ==========================================
echo Server Monitor Agent - Dynamic Connection
echo ==========================================
echo.

REM Get the current directory
set "PROJECT_DIR=%~dp0"

echo Starting Agent with automatic central server detection...
echo.

REM Start the agent (it will auto-detect the central server)
cd /d "%PROJECT_DIR%agent"
echo Agent will automatically detect and connect to the central server.
echo Check the console output for connection details.
echo.
python main.py

goto END_PAUSE

:LEGACY_COMPLETE
cls
echo ====================================
echo Server Monitor - Legacy Startup
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

REM 2. Start Local Agent with network IP (will use dynamic detection now)
echo [2/3] Starting Local Agent with network connection...
cd /d "%~dp0agent"
start "Local Agent" cmd /k "echo Local Agent Starting... && python main.py"
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

echo.
echo ====================================
echo Server Monitor Dashboard Ready!
echo ====================================
echo.
echo Access Points:
echo - Dashboard: http://localhost:5173
echo.
echo Press any key to open dashboard in browser...
pause >nul
start http://localhost:5173
echo.
echo Services are running in separate windows.
echo Close those windows to stop the services.
goto END_PAUSE

:NETWORK_INFO
cls
echo ==========================================
echo Network Configuration Information
echo ==========================================
echo.
python get-network-info.py
echo.
echo Press any key to return to main menu...
pause >nul
goto MAIN_MENU

:CENTRAL_ONLY
cls
echo ==========================================
echo Starting Central Server Only
echo ==========================================
echo.
cd /d "%~dp0central-server"
echo Central Server will auto-detect network IP...
echo.
python main.py
goto END_PAUSE

:FRONTEND_ONLY
cls
echo ==========================================
echo Starting Frontend Dashboard Only
echo ==========================================
echo.
cd /d "%~dp0frontend"
echo Starting React development server...
echo Dashboard will be available at http://localhost:5173
echo.
npm run dev
goto END_PAUSE

:END_PAUSE
echo.
echo Press any key to return to main menu...
pause >nul
goto MAIN_MENU

:EXIT
cls
echo.
echo Goodbye!
echo.
exit /b 0
