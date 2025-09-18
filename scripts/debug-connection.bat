@echo off
echo ====================================
echo Server Monitor Connection Debug
echo ====================================
echo.

echo 1. Testing Central Server API (localhost)...
powershell -Command "try { $response = Invoke-WebRequest -Uri http://localhost:8080/api/agents -UseBasicParsing; Write-Host 'SUCCESS:' $response.StatusCode; Write-Host $response.Content } catch { Write-Host 'FAILED:' $_.Exception.Message }"
echo.

echo 2. Testing Central Server API (network IP)...
powershell -Command "try { $response = Invoke-WebRequest -Uri http://192.168.1.52:8080/api/agents -UseBasicParsing; Write-Host 'SUCCESS:' $response.StatusCode; Write-Host $response.Content } catch { Write-Host 'FAILED:' $_.Exception.Message }"
echo.

echo 3. Testing Dashboard...
powershell -Command "try { $response = Invoke-WebRequest -Uri http://localhost:5173 -UseBasicParsing; Write-Host 'Dashboard Status:' $response.StatusCode } catch { Write-Host 'Dashboard FAILED:' $_.Exception.Message }"
echo.

echo 4. Checking what's running on ports...
echo Port 8080:
netstat -an | findstr ":8080" | findstr LISTENING
echo Port 5173:
netstat -an | findstr ":5173" | findstr LISTENING
echo Port 3000:
netstat -an | findstr ":3000" | findstr LISTENING
echo.

echo 5. Checking Python processes...
tasklist /fi "imagename eq python.exe"
echo.

echo 6. Testing WebSocket connection...
powershell -Command "Test-NetConnection -ComputerName localhost -Port 8080"
echo.

pause
