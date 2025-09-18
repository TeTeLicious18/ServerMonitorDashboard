@echo off
echo Setting up Server Monitor Dashboard...
echo.

echo Checking Python installation...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python from https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation
    pause
    exit /b 1
)

echo Checking pip installation...
pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: pip is not installed or not in PATH
    pause
    exit /b 1
)

echo.
echo Installing Agent dependencies...
cd agent
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo ERROR: Failed to install agent dependencies
    pause
    exit /b 1
)
cd ..

echo.
echo Installing Central Server dependencies...
cd central-server
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo ERROR: Failed to install central server dependencies
    pause
    exit /b 1
)
cd ..

echo.
echo Checking Node.js installation...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: Node.js is not installed
    echo To set up the frontend, install Node.js from https://nodejs.org/
    echo Then run: npm create vite@latest frontend -- --template react-ts
) else (
    echo Node.js found. Setting up frontend...
    npm create vite@latest frontend -- --template react-ts
    if %errorlevel% equ 0 (
        cd frontend
        npm install
        cd ..
    )
)

echo.
echo Setup complete!
echo.
echo To start the services:
echo 1. Agent: cd agent && python main.py
echo 2. Central Server: cd central-server && python main.py
echo 3. Frontend (if installed): cd frontend && npm run dev
echo.
pause
