@echo off
echo Starting agent with central server connection...
cd /d "%~dp0\agent"
set CENTRAL_SERVER_URL=ws://192.168.1.52:8080
python main.py
