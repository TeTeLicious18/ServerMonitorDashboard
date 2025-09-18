@echo off
echo ====================================
echo Creating Agent Deployment Package
echo ====================================
echo.

set DEPLOY_FOLDER=agent-deployment-ready
echo Creating deployment package: %DEPLOY_FOLDER%

if exist "%DEPLOY_FOLDER%" rmdir /s /q "%DEPLOY_FOLDER%"
mkdir "%DEPLOY_FOLDER%"

echo.
echo Copying agent files...
copy "agent-installer\main.py" "%DEPLOY_FOLDER%\"
copy "agent-installer\requirements.txt" "%DEPLOY_FOLDER%\"
copy "agent-installer\install-agent.bat" "%DEPLOY_FOLDER%\"
copy "agent-installer\README.txt" "%DEPLOY_FOLDER%\"

echo.
echo Creating quick-start script...
(
echo @echo off
echo echo ==========================================
echo echo Server Monitor Agent - Quick Installation
echo echo ==========================================
echo echo.
echo echo This will install the Server Monitor Agent on this computer.
echo echo It will connect to the central server at 192.168.1.52:8080
echo echo.
echo echo Requirements:
echo echo - Python 3.8+ installed
echo echo - Internet connection
echo echo - Network access to 192.168.1.52
echo echo.
echo pause
echo echo.
echo echo Starting installation...
echo call install-agent.bat
) > "%DEPLOY_FOLDER%\QUICK-START.bat"

echo.
echo Creating network test script...
(
echo @echo off
echo echo Testing network connection to central server...
echo echo.
echo echo Central Server: 192.168.1.52:8080
echo echo Dashboard: http://192.168.1.52:5173
echo echo.
echo powershell -Command "Test-NetConnection -ComputerName 192.168.1.52 -Port 8080"
echo echo.
echo powershell -Command "try { Invoke-WebRequest -Uri http://192.168.1.52:8080/api/agents -UseBasicParsing -TimeoutSec 5 | Select-Object StatusCode, StatusDescription } catch { Write-Host 'API Test Failed:' $_.Exception.Message }"
echo pause
) > "%DEPLOY_FOLDER%\test-network.bat"

echo.
echo Creating deployment instructions...
(
echo ==========================================
echo Server Monitor Agent - Deployment Package
echo ==========================================
echo.
echo CENTRAL SERVER: 192.168.1.52:8080
echo DASHBOARD: http://192.168.1.52:5173
echo.
echo DEPLOYMENT STEPS:
echo 1. Copy this entire folder to the target computer
echo 2. Double-click QUICK-START.bat to install
echo 3. After installation, double-click start-agent.bat
echo 4. Check dashboard at http://192.168.1.52:5173
echo.
echo TROUBLESHOOTING:
echo - Run test-network.bat to check connectivity
echo - Ensure Python 3.8+ is installed
echo - Check Windows Firewall settings
echo - Verify both computers are on same network
echo.
echo FILES INCLUDED:
echo - QUICK-START.bat: One-click installation
echo - install-agent.bat: Main installer
echo - main.py: Agent application
echo - requirements.txt: Python dependencies
echo - test-network.bat: Network connectivity test
echo - README.txt: Detailed instructions
) > "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"

echo.
echo ====================================
echo Deployment Package Created!
echo ====================================
echo.
echo Package location: %CD%\%DEPLOY_FOLDER%
echo.
echo TO DEPLOY TO OTHER COMPUTERS:
echo 1. Copy the '%DEPLOY_FOLDER%' folder to a USB drive or network share
echo 2. On the target computer, copy the folder locally
echo 3. Double-click QUICK-START.bat to install
echo 4. After installation, double-click start-agent.bat
echo 5. Check your dashboard at http://192.168.1.52:5173
echo.
echo The new computer should appear in your dashboard within 30 seconds!
echo.
pause
