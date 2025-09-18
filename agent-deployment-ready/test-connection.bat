@echo off
echo ====================================
echo Server Monitor - Connection Test
echo ====================================
echo.

echo Testing connection to central server...
echo Server IP: 192.168.1.52
echo Server Port: 8080
echo.

REM Test basic network connectivity
echo [1/3] Testing network connectivity...
ping -n 1 192.168.1.52 >nul 2>&1
if errorlevel 1 (
    echo ❌ FAILED: Cannot reach server 192.168.1.52
    echo Check network connection and server IP
    goto :error
) else (
    echo ✅ SUCCESS: Can reach server 192.168.1.52
)

REM Test HTTP port
echo [2/3] Testing HTTP port 8080...
powershell -Command "try { Invoke-WebRequest -Uri http://192.168.1.52:8080/api/agents -UseBasicParsing -TimeoutSec 5 | Out-Null; Write-Host '✅ SUCCESS: Port 8080 accessible' } catch { Write-Host '❌ FAILED: Port 8080 not accessible' }"

REM Test WebSocket endpoint
echo [3/3] Testing WebSocket connection...
powershell -Command "try { $response = Invoke-WebRequest -Uri http://192.168.1.52:8080 -UseBasicParsing -TimeoutSec 5; Write-Host '✅ SUCCESS: Central server is running' } catch { Write-Host '❌ FAILED: Central server not responding' }"

echo.
echo ====================================
echo Connection Test Complete
echo ====================================
echo.
echo If all tests passed, you can run: start-agent.bat
echo Dashboard will be available at: http://192.168.1.52:5173
echo.
goto :end

:error
echo.
echo ====================================
echo Connection Test Failed
echo ====================================
echo.
echo Troubleshooting:
echo 1. Ensure both computers are on same network
echo 2. Check if central server is running on 192.168.1.52
echo 3. Verify firewall allows port 8080 on main server
echo.

:end
pause
