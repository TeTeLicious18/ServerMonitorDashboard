# Server Monitor Agent PowerShell Installer
# Run with: powershell -ExecutionPolicy Bypass -File install-client.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Server Monitor Agent Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

# Check Python installation
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Python not found"
    }
    Write-Host "✓ Python found: $pythonVersion" -ForegroundColor Green
    
    # Check Python version
    $versionCheck = python -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Python 3.8+ required"
    }
    Write-Host "✓ Python version OK" -ForegroundColor Green
}
catch {
    Write-Host "✗ ERROR: Python 3.8+ is required" -ForegroundColor Red
    Write-Host "Please install Python from https://python.org" -ForegroundColor Yellow
    Write-Host "Make sure to check 'Add Python to PATH' during installation" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Create installation directory
$installDir = "$env:USERPROFILE\ServerMonitorAgent"
Write-Host "Creating installation directory: $installDir" -ForegroundColor Yellow

if (!(Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

# Copy agent files
Write-Host "Copying agent files..." -ForegroundColor Yellow
Copy-Item "agent\main.py" -Destination $installDir -Force
Copy-Item "agent\requirements.txt" -Destination $installDir -Force

# Copy utils if exists
if (Test-Path "utils") {
    $utilsDir = "$installDir\utils"
    if (!(Test-Path $utilsDir)) {
        New-Item -ItemType Directory -Path $utilsDir -Force | Out-Null
    }
    Copy-Item "utils\*" -Destination $utilsDir -Force -Recurse
    Write-Host "✓ Utils copied" -ForegroundColor Green
}

# Install Python dependencies
Write-Host ""
Write-Host "Installing Python dependencies..." -ForegroundColor Yellow
Set-Location $installDir

try {
    python -m pip install --user -r requirements.txt
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Dependencies installed successfully" -ForegroundColor Green
    } else {
        throw "Pip install failed"
    }
}
catch {
    Write-Host "✗ ERROR: Failed to install dependencies" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Create startup script
Write-Host "Creating startup scripts..." -ForegroundColor Yellow

$startScript = @"
@echo off
title Server Monitor Agent
echo Starting Server Monitor Agent...
cd /d "$installDir"
python main.py
if %errorlevel% neq 0 (
    echo.
    echo Agent stopped with error. Press any key to close.
    pause >nul
) else (
    echo.
    echo Agent stopped normally. Press any key to close.
    pause >nul
)
"@

$startScript | Out-File -FilePath "$installDir\start-agent.bat" -Encoding ASCII

# Create PowerShell startup script
$startPsScript = @"
Write-Host "Starting Server Monitor Agent..." -ForegroundColor Green
Set-Location "$installDir"
try {
    python main.py
} catch {
    Write-Host "Error starting agent: `$_" -ForegroundColor Red
}
Read-Host "Press Enter to close"
"@

$startPsScript | Out-File -FilePath "$installDir\start-agent.ps1" -Encoding UTF8

# Create service installer
$serviceScript = @"
@echo off
echo Installing Server Monitor Agent as Windows Service...
echo This requires administrator privileges.
echo.

:: Check if running as admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script must be run as Administrator
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

:: Create service using sc command
sc create "ServerMonitorAgent" binPath= "cmd /c `"$installDir\start-agent.bat`"" start= auto DisplayName= "Server Monitor Agent"
if %errorlevel% equ 0 (
    echo Service created successfully!
    echo Starting service...
    sc start ServerMonitorAgent
    echo.
    echo Service installed and started.
    echo You can manage it through Services.msc or with:
    echo   sc start ServerMonitorAgent
    echo   sc stop ServerMonitorAgent
) else (
    echo Failed to create service.
)
pause
"@

$serviceScript | Out-File -FilePath "$installDir\install-service.bat" -Encoding ASCII

# Create uninstaller
$uninstallScript = @"
@echo off
echo Uninstalling Server Monitor Agent...
echo.

:: Stop and remove service if exists
sc stop ServerMonitorAgent >nul 2>&1
sc delete ServerMonitorAgent >nul 2>&1

:: Remove desktop shortcut
del "%USERPROFILE%\Desktop\Start Server Monitor Agent.bat" >nul 2>&1

:: Remove files
echo Removing installation directory...
cd /d "%USERPROFILE%"
rmdir /s /q "$installDir"

echo.
echo ✓ Server Monitor Agent uninstalled successfully.
pause
"@

$uninstallScript | Out-File -FilePath "$installDir\uninstall.bat" -Encoding ASCII

# Create desktop shortcut
Write-Host "Creating desktop shortcut..." -ForegroundColor Yellow
$desktopPath = "$env:USERPROFILE\Desktop"
$shortcutScript = @"
@echo off
cd /d "$installDir"
start "" "$installDir\start-agent.bat"
"@

$shortcutScript | Out-File -FilePath "$desktopPath\Start Server Monitor Agent.bat" -Encoding ASCII

# Create configuration file
$configContent = @"
# Server Monitor Agent Configuration
# You can modify these settings as needed

# Central server settings (auto-detected by default)
# CENTRAL_SERVER_URL=ws://192.168.1.100:8080

# Agent settings
# AGENT_ID=MyComputer
# AGENT_PORT=3000

# Logging level (DEBUG, INFO, WARNING, ERROR)
LOG_LEVEL=INFO
"@

$configContent | Out-File -FilePath "$installDir\config.env" -Encoding UTF8

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installation directory: $installDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "To start the agent:" -ForegroundColor White
Write-Host "  1. Double-click 'Start Server Monitor Agent' on your desktop" -ForegroundColor Gray
Write-Host "  2. Or run: $installDir\start-agent.bat" -ForegroundColor Gray
Write-Host ""
Write-Host "To install as Windows service:" -ForegroundColor White
Write-Host "  - Run as administrator: $installDir\install-service.bat" -ForegroundColor Gray
Write-Host ""
Write-Host "To uninstall:" -ForegroundColor White
Write-Host "  - Run: $installDir\uninstall.bat" -ForegroundColor Gray
Write-Host ""
Write-Host "Configuration file: $installDir\config.env" -ForegroundColor White
Write-Host ""
Write-Host "The agent will automatically connect to the central server" -ForegroundColor Green
Write-Host "on your network. Make sure the central server is running!" -ForegroundColor Green
Write-Host ""

Read-Host "Press Enter to exit"
