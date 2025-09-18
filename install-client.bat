@echo off
echo ========================================
echo  Server Monitor Agent Installer
echo ========================================
echo.

:: Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.8+ from https://python.org
    echo Make sure to check "Add Python to PATH" during installation
    pause
    exit /b 1
)

echo Python found. Checking version...
python -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)"
if %errorlevel% neq 0 (
    echo ERROR: Python 3.8+ is required
    echo Please update Python from https://python.org
    pause
    exit /b 1
)

echo Python version OK.
echo.

:: Create installation directory
set INSTALL_DIR=%USERPROFILE%\ServerMonitorAgent
echo Creating installation directory: %INSTALL_DIR%
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

:: Copy agent files
echo Copying agent files...
copy /Y "agent\main.py" "%INSTALL_DIR%\"
copy /Y "agent\requirements.txt" "%INSTALL_DIR%\"

:: Copy utils if exists
if exist "utils" (
    if not exist "%INSTALL_DIR%\utils" mkdir "%INSTALL_DIR%\utils"
    copy /Y "utils\*" "%INSTALL_DIR%\utils\"
)

:: Install Python dependencies
echo.
echo Installing Python dependencies...
cd /d "%INSTALL_DIR%"
python -m pip install --user -r requirements.txt

if %errorlevel% neq 0 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

:: Create startup script
echo.
echo Creating startup script...
(
echo @echo off
echo echo Starting Server Monitor Agent...
echo cd /d "%INSTALL_DIR%"
echo python main.py
echo pause
) > "%INSTALL_DIR%\start-agent.bat"

:: Create service installer (optional)
echo.
echo Creating service installer...
(
echo @echo off
echo echo Installing Server Monitor Agent as Windows Service...
echo echo This requires administrator privileges.
echo echo.
echo pause
echo.
echo :: Install as service using nssm (if available)
echo nssm install ServerMonitorAgent "%INSTALL_DIR%\start-agent.bat" ^>nul 2^>^&1
echo if %%errorlevel%% equ 0 (
echo     echo Service installed successfully!
echo     echo You can start it with: net start ServerMonitorAgent
echo ^) else (
echo     echo NSSM not found. Manual service installation required.
echo     echo Run start-agent.bat manually or set up as scheduled task.
echo ^)
echo pause
) > "%INSTALL_DIR%\install-service.bat"

:: Create uninstaller
echo Creating uninstaller...
(
echo @echo off
echo echo Uninstalling Server Monitor Agent...
echo echo.
echo :: Stop service if running
echo net stop ServerMonitorAgent ^>nul 2^>^&1
echo nssm remove ServerMonitorAgent confirm ^>nul 2^>^&1
echo.
echo :: Remove files
echo cd /d "%%USERPROFILE%%"
echo rmdir /s /q "%INSTALL_DIR%"
echo echo Agent uninstalled successfully.
echo pause
) > "%INSTALL_DIR%\uninstall.bat"

:: Create desktop shortcut
echo Creating desktop shortcut...
set DESKTOP=%USERPROFILE%\Desktop
(
echo @echo off
echo cd /d "%INSTALL_DIR%"
echo start "" "%INSTALL_DIR%\start-agent.bat"
) > "%DESKTOP%\Start Server Monitor Agent.bat"

echo.
echo ========================================
echo  Installation Complete!
echo ========================================
echo.
echo Installation directory: %INSTALL_DIR%
echo.
echo To start the agent:
echo   1. Double-click "Start Server Monitor Agent" on your desktop
echo   2. Or run: %INSTALL_DIR%\start-agent.bat
echo.
echo To install as Windows service (optional):
echo   - Run as administrator: %INSTALL_DIR%\install-service.bat
echo.
echo To uninstall:
echo   - Run: %INSTALL_DIR%\uninstall.bat
echo.
echo The agent will automatically connect to the central server
echo on your network. Make sure the central server is running!
echo.
pause
