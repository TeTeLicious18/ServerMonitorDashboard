@echo off
echo ====================================
echo Creating Agent Deployment Package
echo ====================================
echo.

REM Create a deployment folder with timestamp
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "datestamp=%YYYY%%MM%%DD%_%HH%%Min%%Sec%"

set DEPLOY_FOLDER=agent-deployment-%datestamp%
echo Creating deployment package: %DEPLOY_FOLDER%
mkdir "%DEPLOY_FOLDER%"

echo.
echo Copying agent files...
copy "agent-installer\main.py" "%DEPLOY_FOLDER%\"
copy "agent-installer\requirements.txt" "%DEPLOY_FOLDER%\"
copy "agent-installer\install-agent.bat" "%DEPLOY_FOLDER%\"
copy "agent-installer\README.txt" "%DEPLOY_FOLDER%\"

echo.
echo Creating quick-start script...
echo @echo off > "%DEPLOY_FOLDER%\QUICK-START.bat"
echo echo ========================================== >> "%DEPLOY_FOLDER%\QUICK-START.bat"
echo echo Server Monitor Agent - Quick Installation >> "%DEPLOY_FOLDER%\QUICK-START.bat"
echo echo ========================================== >> "%DEPLOY_FOLDER%\QUICK-START.bat"
echo echo. >> "%DEPLOY_FOLDER%\QUICK-START.bat"
echo echo This will install the Server Monitor Agent on this computer. >> "%DEPLOY_FOLDER%\QUICK-START.bat"
echo echo It will connect to the central server at 192.168.1.52:8080 >> "%DEPLOY_FOLDER%\QUICK-START.bat"
echo echo. >> "%DEPLOY_FOLDER%\QUICK-START.bat"
echo echo Requirements: >> "%DEPLOY_FOLDER%\QUICK-START.bat"
echo echo - Python 3.8+ installed >> "%DEPLOY_FOLDER%\QUICK-START.bat"
echo echo - Internet connection >> "%DEPLOY_FOLDER%\QUICK-START.bat"
echo echo - Network access to 192.168.1.52 >> "%DEPLOY_FOLDER%\QUICK-START.bat"
echo echo. >> "%DEPLOY_FOLDER%\QUICK-START.bat"
echo pause >> "%DEPLOY_FOLDER%\QUICK-START.bat"
echo echo. >> "%DEPLOY_FOLDER%\QUICK-START.bat"
echo echo Starting installation... >> "%DEPLOY_FOLDER%\QUICK-START.bat"
echo call install-agent.bat >> "%DEPLOY_FOLDER%\QUICK-START.bat"

echo.
echo Creating network test script...
echo @echo off > "%DEPLOY_FOLDER%\test-network.bat"
echo echo Testing network connection to central server... >> "%DEPLOY_FOLDER%\test-network.bat"
echo echo. >> "%DEPLOY_FOLDER%\test-network.bat"
echo echo Central Server: 192.168.1.52:8080 >> "%DEPLOY_FOLDER%\test-network.bat"
echo echo Dashboard: http://192.168.1.52:5173 >> "%DEPLOY_FOLDER%\test-network.bat"
echo echo. >> "%DEPLOY_FOLDER%\test-network.bat"
echo powershell -Command "Test-NetConnection -ComputerName 192.168.1.52 -Port 8080" >> "%DEPLOY_FOLDER%\test-network.bat"
echo echo. >> "%DEPLOY_FOLDER%\test-network.bat"
echo powershell -Command "try { Invoke-WebRequest -Uri http://192.168.1.52:8080/api/agents -UseBasicParsing -TimeoutSec 5 | Select-Object StatusCode, StatusDescription } catch { Write-Host 'API Test Failed:' $_.Exception.Message }" >> "%DEPLOY_FOLDER%\test-network.bat"
echo pause >> "%DEPLOY_FOLDER%\test-network.bat"

echo.
echo Creating deployment instructions...
echo ========================================== > "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo Server Monitor Agent - Deployment Package >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo ========================================== >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo. >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo CENTRAL SERVER: 192.168.1.52:8080 >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo DASHBOARD: http://192.168.1.52:5173 >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo. >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo DEPLOYMENT STEPS: >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo 1. Copy this entire folder to the target computer >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo 2. Double-click QUICK-START.bat to install >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo 3. After installation, double-click start-agent.bat >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo 4. Check dashboard at http://192.168.1.52:5173 >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo. >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo TROUBLESHOOTING: >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo - Run test-network.bat to check connectivity >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo - Ensure Python 3.8+ is installed >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo - Check Windows Firewall settings >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo - Verify both computers are on same network >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo. >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo FILES INCLUDED: >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo - QUICK-START.bat: One-click installation >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo - install-agent.bat: Main installer >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo - main.py: Agent application >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo - requirements.txt: Python dependencies >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo - test-network.bat: Network connectivity test >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"
echo - README.txt: Detailed instructions >> "%DEPLOY_FOLDER%\DEPLOYMENT-INSTRUCTIONS.txt"

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
