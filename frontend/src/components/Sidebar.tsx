import React from 'react';
import { Server, Wifi, WifiOff, Activity } from 'lucide-react';
import { Agent } from '../types';

interface SidebarProps {
  agents: Agent[];
  selectedAgent: string | null;
  onSelectAgent: (agentId: string) => void;
  isLoading: boolean;
}

const Sidebar: React.FC<SidebarProps> = ({ agents, selectedAgent, onSelectAgent, isLoading }) => {
  return (
    <div className="w-80 bg-gray-800 border-r border-gray-700 flex flex-col">
      {/* Header */}
      <div className="p-6 border-b border-gray-700">
        <div className="flex items-center space-x-3">
          <div className="p-2 bg-blue-600 rounded-lg">
            <Server className="w-6 h-6 text-white" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-white">Server Monitor</h1>
            <p className="text-sm text-gray-400">Dashboard</p>
          </div>
        </div>
      </div>

      {/* Stats Overview */}
      <div className="p-6 border-b border-gray-700">
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-gray-900 rounded-lg p-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-400">Total</span>
              <Activity className="w-4 h-4 text-blue-400" />
            </div>
            <div className="text-2xl font-bold text-white mt-1">{agents.length}</div>
          </div>
          <div className="bg-gray-900 rounded-lg p-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-400">Online</span>
              <Wifi className="w-4 h-4 text-green-400" />
            </div>
            <div className="text-2xl font-bold text-green-400 mt-1">
              {agents.filter(agent => agent.status === 'online').length}
            </div>
          </div>
        </div>
      </div>

      {/* Agents List */}
      <div className="flex-1 overflow-y-auto">
        <div className="p-4">
          <h2 className="text-sm font-semibold text-gray-400 uppercase tracking-wider mb-4">
            Connected Servers
          </h2>
          
          {isLoading ? (
            <div className="space-y-3">
              {[1, 2, 3].map((i) => (
                <div key={i} className="animate-pulse">
                  <div className="bg-gray-700 rounded-lg p-4 h-20"></div>
                </div>
              ))}
            </div>
          ) : agents.length === 0 ? (
            <div className="text-center py-8">
              <WifiOff className="w-12 h-12 text-gray-500 mx-auto mb-3" />
              <p className="text-gray-400">No agents connected</p>
              <p className="text-sm text-gray-500 mt-1">Start an agent to see it here</p>
            </div>
          ) : (
            <div className="space-y-2">
              {agents.map((agent) => (
                <button
                  key={agent.agent_id}
                  onClick={() => onSelectAgent(agent.agent_id)}
                  className={`w-full text-left p-4 rounded-lg border transition-all duration-200 ${
                    selectedAgent === agent.agent_id
                      ? 'bg-blue-600 border-blue-500 shadow-lg'
                      : 'bg-gray-700 border-gray-600 hover:bg-gray-600 hover:border-gray-500'
                  }`}
                >
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center space-x-2">
                      <div className={`w-2 h-2 rounded-full ${
                        agent.status === 'online' ? 'bg-green-400' : 'bg-red-400'
                      }`} />
                      <span className="font-medium text-white truncate">
                        {agent.hostname}
                      </span>
                    </div>
                    {agent.status === 'online' ? (
                      <Wifi className="w-4 h-4 text-green-400" />
                    ) : (
                      <WifiOff className="w-4 h-4 text-red-400" />
                    )}
                  </div>
                  
                  <div className="text-xs text-gray-300 mb-2">
                    {agent.ip}
                  </div>
                  
                  {agent.status === 'online' && agent.status_data && (
                    <div className="grid grid-cols-3 gap-2 text-xs">
                      <div>
                        <span className="text-gray-400">CPU</span>
                        <div className="text-white font-medium">
                          {agent.status_data.cpu_percent?.toFixed(1)}%
                        </div>
                      </div>
                      <div>
                        <span className="text-gray-400">RAM</span>
                        <div className="text-white font-medium">
                          {agent.status_data.memory_percent?.toFixed(1)}%
                        </div>
                      </div>
                      <div>
                        <span className="text-gray-400">Disk</span>
                        <div className="text-white font-medium">
                          {agent.status_data.disk_percent?.toFixed(1)}%
                        </div>
                      </div>
                    </div>
                  )}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Sidebar;
