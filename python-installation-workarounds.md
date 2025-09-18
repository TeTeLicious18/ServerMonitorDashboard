# Python Installation Workarounds for Policy Restrictions

## Error 0x80070659 Solutions

This error occurs when Windows blocks the installation due to security policies. Here are several workarounds:

### Method 1: Microsoft Store Installation (Recommended)
1. Open Microsoft Store
2. Search for "Python 3.11" or "Python 3.12"
3. Install the official Python app from Microsoft
4. This bypasses most policy restrictions

### Method 2: Portable Python Installation
1. Download Python embeddable package:
   - Go to https://www.python.org/downloads/windows/
   - Scroll to "Windows embeddable package (64-bit)" or (32-bit)
   - Download the ZIP file (e.g., python-3.11.x-embed-amd64.zip)

2. Extract to a folder (e.g., `C:\Python311-portable\`)

3. Add pip to portable Python:
   - Download get-pip.py from https://bootstrap.pypa.io/get-pip.py
   - Place it in your Python folder
   - Open Command Prompt as Administrator
   - Navigate to Python folder: `cd C:\Python311-portable`
   - Run: `python get-pip.py`

4. Add to PATH manually:
   - Press Win+R, type `sysdm.cpl`, press Enter
   - Click "Environment Variables"
   - Under "User variables", select "Path" and click "Edit"
   - Click "New" and add your Python folder path
   - Click "New" again and add the Scripts folder path

### Method 3: Run as Administrator
1. Right-click on the Python installer
2. Select "Run as administrator"
3. Try the installation again

### Method 4: Alternative Python Distributions
- **Anaconda**: Download from https://www.anaconda.com/products/distribution
- **Miniconda**: Lighter version from https://docs.conda.io/en/latest/miniconda.html
- **WinPython**: Portable distribution from https://winpython.github.io/

### Method 5: Use Windows Subsystem for Linux (WSL)
1. Enable WSL in Windows Features
2. Install Ubuntu from Microsoft Store
3. Install Python in Ubuntu: `sudo apt update && sudo apt install python3 python3-pip`

## Verification Steps

After installation, verify Python works:
```cmd
python --version
pip --version
```

If using portable Python, you may need to use full paths:
```cmd
C:\Python311-portable\python.exe --version
C:\Python311-portable\Scripts\pip.exe --version
```

## Next Steps

Once Python is working:
1. Run our setup script: `setup.bat`
2. Or manually install dependencies:
   ```cmd
   cd agent
   pip install -r requirements.txt
   cd ../central-server
   pip install -r requirements.txt
   ```

## Troubleshooting

- If PATH issues persist, use full paths to python.exe and pip.exe
- For corporate environments, contact IT support for policy exceptions
- Consider using virtual environments: `python -m venv venv`
