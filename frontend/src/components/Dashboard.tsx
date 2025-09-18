import React, { useState } from 'react';
import { Cpu, MemoryStick, HardDrive, Clock, Server, Activity, Folder, FileText, AlertTriangle, CheckCircle, Thermometer, Share2 } from 'lucide-react';
import { Agent } from '../types';
import MetricCard from './MetricCard';
import SystemChart from './SystemChart';
import DriveInfo from './DriveInfo';
import FileBrowser from './FileBrowser';
import TemperatureInfo from './TemperatureInfo';
import FileSharing from './FileSharing';

interface DashboardProps {
  agents: Agent[];
  selectedAgent: string | null;
  isLoading: boolean;
}

const Dashboard: React.FC<DashboardProps> = ({ agents, selectedAgent, isLoading }) => {
  const currentAgent = agents.find(agent => agent.agent_id === selectedAgent);
  const [activeTab, setActiveTab] = useState<'overview' | 'drives' | 'temperature' | 'files' | 'sharing'>('overview');

  if (isLoading) {
    return (
      <div className="p-8">
        <div className="animate-pulse space-y-6">
          <div className="h-8 bg-gray-700 rounded w-1/4"></div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="h-32 bg-gray-700 rounded-lg"></div>
            ))}
          </div>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div className="h-80 bg-gray-700 rounded-lg"></div>
            <div className="h-80 bg-gray-700 rounded-lg"></div>
          </div>
        </div>
      </div>
    );
  }

  if (!currentAgent) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="text-center">
          <Server className="w-16 h-16 text-gray-500 mx-auto mb-4" />
          <h2 className="text-xl font-semibold text-gray-300 mb-2">No Agent Selected</h2>
          <p className="text-gray-500">Select an agent from the sidebar to view its metrics</p>
        </div>
      </div>
    );
  }

  const { status_data } = currentAgent;

  const formatUptime = (seconds: number) => {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${days}d ${hours}h ${minutes}m`;
  };

  const formatBytes = (bytes: number) => {
    const gb = bytes / 1024;
    return `${gb.toFixed(1)} GB`;
  };

  return (
    <div className="p-8 space-y-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2">
            {currentAgent.hostname}
          </h1>
          <div className="flex items-center space-x-4 text-sm text-gray-400">
            <span className="flex items-center space-x-2">
              <div className={`w-2 h-2 rounded-full ${
                currentAgent.status === 'online' ? 'bg-green-400' : 'bg-red-400'
              }`} />
              <span className="capitalize">{currentAgent.status}</span>
            </span>
            <span>{currentAgent.ip}</span>
            <span>Last seen: {new Date(currentAgent.last_seen).toLocaleTimeString()}</span>
          </div>
        </div>
        <div className="flex items-center space-x-2 px-4 py-2 bg-gray-800 rounded-lg">
          <Activity className="w-5 h-5 text-green-400" />
          <span className="text-white font-medium">Live Monitoring</span>
        </div>
      </div>

      {/* Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <MetricCard
          title="CPU Usage"
          value={`${status_data?.cpu_percent?.toFixed(1) || 0}%`}
          icon={<Cpu className="w-6 h-6" />}
          color="blue"
          percentage={status_data?.cpu_percent || 0}
        />
        <MetricCard
          title="Memory Usage"
          value={`${status_data?.memory_percent?.toFixed(1) || 0}%`}
          subtitle={`${formatBytes(status_data?.memory_used_mb || 0)} / ${formatBytes(status_data?.memory_total_mb || 0)}`}
          icon={<MemoryStick className="w-6 h-6" />}
          color="green"
          percentage={status_data?.memory_percent || 0}
        />
        <MetricCard
          title="Disk Usage"
          value={`${status_data?.disk_percent?.toFixed(1) || 0}%`}
          subtitle={`${status_data?.disk_used_gb?.toFixed(1) || 0} GB / ${status_data?.disk_total_gb?.toFixed(1) || 0} GB`}
          icon={<HardDrive className="w-6 h-6" />}
          color="purple"
          percentage={status_data?.disk_percent || 0}
        />
        <MetricCard
          title="Uptime"
          value={formatUptime(status_data?.uptime_seconds || 0)}
          icon={<Clock className="w-6 h-6" />}
          color="yellow"
        />
      </div>

      {/* Tab Navigation */}
      <div className="flex space-x-1 bg-gray-800 p-1 rounded-lg border border-gray-700">
        <button
          onClick={() => setActiveTab('overview')}
          className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
            activeTab === 'overview'
              ? 'bg-blue-600 text-white'
              : 'text-gray-400 hover:text-white hover:bg-gray-700'
          }`}
        >
          Overview
        </button>
        <button
          onClick={() => setActiveTab('drives')}
          className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
            activeTab === 'drives'
              ? 'bg-blue-600 text-white'
              : 'text-gray-400 hover:text-white hover:bg-gray-700'
          }`}
        >
          <HardDrive className="w-4 h-4 mr-2 inline" />
          Drives
        </button>
        <button
          onClick={() => setActiveTab('temperature')}
          className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
            activeTab === 'temperature'
              ? 'bg-blue-600 text-white'
              : 'text-gray-400 hover:text-white hover:bg-gray-700'
          }`}
        >
          <Thermometer className="w-4 h-4 mr-2 inline" />
          Temperature
        </button>
        <button
          onClick={() => setActiveTab('files')}
          className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
            activeTab === 'files'
              ? 'bg-blue-600 text-white'
              : 'text-gray-400 hover:text-white hover:bg-gray-700'
          }`}
        >
          <Folder className="w-4 h-4 mr-2 inline" />
          Files
        </button>
        <button
          onClick={() => setActiveTab('sharing')}
          className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
            activeTab === 'sharing'
              ? 'bg-blue-600 text-white'
              : 'text-gray-400 hover:text-white hover:bg-gray-700'
          }`}
        >
          <Share2 className="w-4 h-4 mr-2 inline" />
          Sharing
        </button>
      </div>

      {/* Tab Content */}
      {activeTab === 'overview' && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <SystemChart
            title="System Performance"
            data={[
              { name: 'CPU', value: status_data?.cpu_percent || 0, color: '#3B82F6' },
              { name: 'Memory', value: status_data?.memory_percent || 0, color: '#10B981' },
              { name: 'Disk', value: status_data?.disk_percent || 0, color: '#8B5CF6' },
            ]}
          />
          <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
            <h3 className="text-lg font-semibold text-white mb-4">System Information</h3>
            <div className="space-y-4">
              <div className="flex justify-between">
                <span className="text-gray-400">Hostname</span>
                <span className="text-white font-medium">{currentAgent.hostname}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">IP Address</span>
                <span className="text-white font-medium">{currentAgent.ip}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Status</span>
                <span className={`font-medium capitalize ${
                  currentAgent.status === 'online' ? 'text-green-400' : 'text-red-400'
                }`}>
                  {currentAgent.status}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Total Memory</span>
                <span className="text-white font-medium">
                  {formatBytes(status_data?.memory_total_mb || 0)}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Total Disk</span>
                <span className="text-white font-medium">
                  {status_data?.disk_total_gb?.toFixed(1) || 0} GB
                </span>
              </div>
              {status_data?.drives && status_data.drives.length > 0 && (
                <div className="flex justify-between">
                  <span className="text-gray-400">Drive Count</span>
                  <span className="text-white font-medium">{status_data.drives.length}</span>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {activeTab === 'drives' && (
        <DriveInfo drives={status_data?.drives || []} />
      )}

      {activeTab === 'temperature' && (
        <TemperatureInfo temperatures={status_data?.temperatures || {}} />
      )}

      {activeTab === 'files' && (
        <FileBrowser agentId={currentAgent.agent_id} agentIp={currentAgent.ip} />
      )}

      {activeTab === 'sharing' && (
        <FileSharing agentId={currentAgent.agent_id} agentIp={currentAgent.ip} />
      )}
    </div>
  );
};

export default Dashboard;
