import asyncio
import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Optional
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime
import uuid

# Add utils directory to path
sys.path.append(str(Path(__file__).parent.parent / "utils"))
from network_utils import get_local_ip, find_best_ip_for_network

# In-memory storage for agents
class Agent:
    def __init__(self, agent_id: str, hostname: str, ip: str):
        self.agent_id = agent_id
        self.hostname = hostname
        self.ip = ip
        self.last_seen = datetime.utcnow()
        self.status = "online"
        self.websocket = None
        self.status_data = {}

app = FastAPI(title="Server Monitor Central Server")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict this to your frontend's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory storage for connected agents
connected_agents: Dict[str, Agent] = {}

# WebSocket connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}

    async def connect(self, websocket: WebSocket, client_id: str):
        await websocket.accept()
        self.active_connections[client_id] = websocket

    def disconnect(self, client_id: str):
        if client_id in self.active_connections:
            del self.active_connections[client_id]

    async def send_personal_message(self, message: str, client_id: str):
        if client_id in self.active_connections:
            await self.active_connections[client_id].send_text(message)

    async def broadcast(self, message: str):
        for connection in self.active_connections.values():
            await connection.send_text(message)

manager = ConnectionManager()

# Routes
@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": "Server Monitor Central Server", "status": "running"}

@app.get("/api/agents")
async def list_agents():
    """List all connected agents."""
    return [
        {
            "agent_id": agent.agent_id,
            "hostname": agent.hostname,
            "ip": agent.ip,
            "status": agent.status,
            "last_seen": agent.last_seen.isoformat(),
            "status_data": agent.status_data
        }
        for agent in connected_agents.values()
    ]

@app.websocket("/ws/register")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket endpoint for agent registration and status updates."""
    agent_id = None
    try:
        await websocket.accept()
        
        # Wait for the agent to register
        data = await websocket.receive_text()
        message = json.loads(data)
        
        if message.get("type") == "register":
            agent_id = message.get("agent_id")
            hostname = message.get("hostname", "unknown")
            ip = message.get("ip", "unknown")
            
            # Register the agent
            if agent_id not in connected_agents:
                connected_agents[agent_id] = Agent(agent_id, hostname, ip)
            
            agent = connected_agents[agent_id]
            agent.websocket = websocket
            agent.status = "online"
            agent.last_seen = datetime.utcnow()
            
            print(f"Agent {agent_id} connected from {hostname} ({ip})")
            
            try:
                while True:
                    # Wait for status updates
                    data = await websocket.receive_text()
                    message = json.loads(data)
                    
                    if message.get("type") == "status_update":
                        agent.last_seen = datetime.utcnow()
                        agent.status_data = message.get("data", {})
                        print(f"Status update from {agent_id}")
                        
            except WebSocketDisconnect:
                print(f"Agent {agent_id} disconnected")
                if agent_id and agent_id in connected_agents:
                    connected_agents[agent_id].status = "offline"
                
    except Exception as e:
        print(f"WebSocket error: {e}")
    finally:
        if agent_id and agent_id in connected_agents:
            connected_agents[agent_id].status = "offline"

@app.on_event("startup")
async def startup_event():
    """Start background tasks when the application starts."""
    # Start a background task to clean up disconnected agents
    async def cleanup_disconnected_agents():
        while True:
            await asyncio.sleep(60)  # Check every minute
            current_time = datetime.utcnow()
            disconnected_agents = [
                agent_id for agent_id, agent in connected_agents.items()
                if (current_time - agent.last_seen).total_seconds() > 120  # 2 minutes
            ]
            for agent_id in disconnected_agents:
                connected_agents[agent_id].status = "offline"
                manager.disconnect(agent_id)
    
    asyncio.create_task(cleanup_disconnected_agents())

if __name__ == "__main__":
    import uvicorn
    
    # Get the best IP for network communication
    local_ip = get_local_ip()
    best_ip = find_best_ip_for_network()
    
    print(f"Central Server starting...")
    print(f"Local IP: {local_ip}")
    print(f"Best network IP: {best_ip}")
    print(f"Server will be accessible at:")
    print(f"  - Local: http://localhost:8080")
    print(f"  - Network: http://{best_ip}:8080")
    print(f"  - API: http://{best_ip}:8080/api/agents")
    
    uvicorn.run(app, host="0.0.0.0", port=8080)
