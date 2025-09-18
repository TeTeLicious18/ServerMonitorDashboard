@echo off
echo ========================================
echo Testing Agent Installation
echo ========================================
echo.

echo Current directory: %CD%
echo Script directory: %~dp0
echo.

echo Checking Python...
python --version
if %errorlevel% neq 0 (
    echo [ERROR] Python not found
    pause
    exit /b 1
)

echo.
echo Checking if main.py exists...
if exist "%~dp0main.py" (
    echo [OK] main.py found
) else (
    echo [ERROR] main.py not found in %~dp0
    pause
    exit /b 1
)

echo.
echo Testing Python dependencies...
python -c "import fastapi, uvicorn, psutil, websockets" 2>nul
if %errorlevel% neq 0 (
    echo [WARNING] Some dependencies missing, installing...
    pip install -r "%~dp0requirements.txt"
) else (
    echo [OK] All dependencies available
)

echo.
echo Creating startup script...
echo @echo off > "%~dp0start-agent.bat"
echo echo Starting Server Monitor Agent... >> "%~dp0start-agent.bat"
echo set CENTRAL_SERVER_URL=ws://192.168.1.52:8080 >> "%~dp0start-agent.bat"
echo cd /d "%~dp0" >> "%~dp0start-agent.bat"
echo python main.py >> "%~dp0start-agent.bat"
echo pause >> "%~dp0start-agent.bat"

if exist "%~dp0start-agent.bat" (
    echo [OK] start-agent.bat created successfully
) else (
    echo [ERROR] Failed to create start-agent.bat
)

echo.
echo ========================================
echo Installation Test Complete
echo ========================================
echo.
echo You can now run: start-agent.bat
echo Or use the manual version: start-agent-manual.bat
echo.
pause
