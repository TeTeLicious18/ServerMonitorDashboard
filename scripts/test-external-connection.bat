@echo off
echo Testing external connectivity to Server Monitor...
echo.

echo 1. Testing local connection (localhost:8080)...
powershell -Command "try { $response = Invoke-WebRequest -Uri http://localhost:8080/api/agents -UseBasicParsing -TimeoutSec 5; Write-Host 'SUCCESS: Local connection works'; Write-Host $response.Content } catch { Write-Host 'FAILED: Local connection failed -' $_.Exception.Message }"
echo.

echo 2. Testing network IP connection (192.168.1.52:8080)...
powershell -Command "try { $response = Invoke-WebRequest -Uri http://192.168.1.52:8080/api/agents -UseBasicParsing -TimeoutSec 5; Write-Host 'SUCCESS: Network IP connection works'; Write-Host $response.Content } catch { Write-Host 'FAILED: Network IP connection failed -' $_.Exception.Message }"
echo.

echo 3. Testing port connectivity...
powershell -Command "Test-NetConnection -ComputerName 192.168.1.52 -Port 8080"
echo.

echo 4. Checking firewall rules...
netsh advfirewall firewall show rule name="Server Monitor - Central Server"
echo.

echo 5. Checking what's listening on port 8080...
netstat -an | findstr ":8080"
echo.

echo Test complete. If tests 1-3 pass, other computers should be able to connect.
pause
