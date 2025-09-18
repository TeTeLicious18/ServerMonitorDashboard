====================================
Server Monitor Agent - Deployment Package
====================================

QUICK INSTALLATION:
1. Right-click "QUICK-START.bat"
2. Select "Run as administrator"
3. Wait for installation (2-3 minutes)
4. Agent starts automatically

MANUAL INSTALLATION:
1. Run "install-agent.bat" as administrator
2. Run "start-agent.bat" to begin monitoring
3. Check dashboard at http://192.168.1.52:5173

FILES INCLUDED:
- QUICK-START.bat      → One-click install and start
- install-agent.bat    → Install dependencies only
- start-agent.bat      → Start monitoring agent
- stop-agent.bat       → Stop monitoring agent
- test-connection.bat  → Test network connectivity
- main.py              → Agent application code
- requirements.txt     → Python dependencies
- README.txt           → This file

REQUIREMENTS:
- Windows computer
- Python 3.8+ (will prompt to install if missing)
- Internet connection (for dependency installation)
- Same network as central server (192.168.1.x)
- Administrator access (for installation only)

CONFIGURATION:
- Central Server: ws://192.168.1.52:8080
- Dashboard URL: http://192.168.1.52:5173
- Agent Port: 3000 (local only)
- Update Interval: 30 seconds

TROUBLESHOOTING:
1. Run as administrator if installation fails
2. Check internet connection for pip installs
3. Run "test-connection.bat" to verify network
4. Ensure central server is running on main computer
5. Both computers must be on same network (192.168.1.x)

VERIFICATION:
- Agent window shows "Connected to central server"
- Computer appears in dashboard within 30 seconds
- Real-time metrics update every 30 seconds
- Status shows "online" with green indicator

SUPPORT:
- No firewall changes needed on agent computer
- Agent makes outbound connections only
- Survives network disconnections (auto-reconnect)
- Multiple agents can run simultaneously

For questions or issues, check the main server documentation.

Generated: 2025-09-10
Version: Production Ready
