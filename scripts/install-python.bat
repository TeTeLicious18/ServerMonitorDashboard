@echo off
echo Server Monitor Dashboard - Python Installation Helper
echo.

echo This script will help you install Python if it's not already installed.
echo.

python --version >nul 2>&1
if %errorlevel% equ 0 (
    echo Python is already installed!
    python --version
    pip --version
    echo.
    echo You can now run setup.bat to install project dependencies.
    pause
    exit /b 0
)

echo Python is not installed or not in PATH.
echo.
echo Please follow these steps:
echo 1. Go to https://www.python.org/downloads/
echo 2. Download Python 3.8 or later for Windows
echo 3. During installation, CHECK the box "Add Python to PATH"
echo 4. Complete the installation
echo 5. Restart this command prompt
echo 6. Run this script again to verify
echo.

echo Would you like to open the Python download page now? (Y/N)
set /p choice=
if /i "%choice%"=="Y" (
    start https://www.python.org/downloads/
)

pause
