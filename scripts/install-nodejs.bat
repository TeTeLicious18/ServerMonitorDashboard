@echo off
echo ========================================
echo Node.js Installation Helper
echo ========================================
echo.

echo This script will help you install Node.js to run the React frontend.
echo.

echo Option 1: Download from Official Website (Recommended)
echo -------------------------------------------------
echo 1. Go to: https://nodejs.org/
echo 2. Download the LTS version (Long Term Support)
echo 3. Run the installer as Administrator
echo 4. Follow the installation wizard
echo 5. Make sure to check "Add to PATH" option
echo.

echo Option 2: Using Chocolatey (if installed)
echo ----------------------------------------
echo If you have Chocolatey package manager:
echo   choco install nodejs
echo.

echo Option 3: Using Winget (Windows 10/11)
echo -------------------------------------
echo If you have winget available:
echo   winget install OpenJS.NodeJS
echo.

echo After installation, restart your command prompt and run:
echo   node --version
echo   npm --version
echo.

echo Then navigate to the frontend folder and run:
echo   cd frontend
echo   npm install
echo   npm run dev
echo.

pause
echo.
echo Opening Node.js download page...
start https://nodejs.org/

echo.
echo After installing Node.js:
echo 1. Close this window
echo 2. Open a new command prompt
echo 3. Navigate to: %~dp0frontend
echo 4. Run: npm install
echo 5. Run: npm run dev
echo.
pause
