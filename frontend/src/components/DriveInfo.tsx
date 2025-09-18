import React from 'react';
import { HardDrive, AlertTriangle, CheckCircle } from 'lucide-react';

interface Drive {
  device: string;
  mountpoint: string;
  fstype: string;
  total_gb: number;
  used_gb: number;
  free_gb: number;
  percent_used: number;
  health_status: string;
  smart_available: boolean;
}

interface DriveInfoProps {
  drives: Drive[];
}

const DriveInfo: React.FC<DriveInfoProps> = ({ drives }) => {
  const getHealthIcon = (status: string) => {
    switch (status.toLowerCase()) {
      case 'ok':
      case 'good':
        return <CheckCircle className="w-5 h-5 text-green-400" />;
      case 'warning':
        return <AlertTriangle className="w-5 h-5 text-yellow-400" />;
      case 'error':
      case 'critical':
        return <AlertTriangle className="w-5 h-5 text-red-400" />;
      default:
        return <HardDrive className="w-5 h-5 text-gray-400" />;
    }
  };

  const getUsageColor = (percentage: number) => {
    if (percentage >= 90) return 'bg-red-500';
    if (percentage >= 75) return 'bg-yellow-500';
    return 'bg-blue-500';
  };

  return (
    <div className="space-y-4">
      <h3 className="text-lg font-semibold text-white mb-4">Drive Information</h3>
      {drives && drives.length > 0 ? (
        drives.map((drive, index) => (
          <div key={index} className="bg-gray-800 rounded-lg p-4 border border-gray-700">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center space-x-3">
                <HardDrive className="w-6 h-6 text-blue-400" />
                <div>
                  <h4 className="text-white font-medium">{drive.device}</h4>
                  <p className="text-gray-400 text-sm">{drive.mountpoint} ({drive.fstype})</p>
                </div>
              </div>
              <div className="flex items-center space-x-2">
                {getHealthIcon(drive.health_status)}
                <span className={`text-sm font-medium ${
                  drive.health_status.toLowerCase() === 'ok' ? 'text-green-400' : 
                  drive.health_status.toLowerCase() === 'warning' ? 'text-yellow-400' : 
                  'text-gray-400'
                }`}>
                  {drive.health_status}
                </span>
              </div>
            </div>
            
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">Used</span>
                <span className="text-white">{drive.used_gb.toFixed(1)} GB / {drive.total_gb.toFixed(1)} GB</span>
              </div>
              
              <div className="w-full bg-gray-700 rounded-full h-2">
                <div 
                  className={`h-2 rounded-full ${getUsageColor(drive.percent_used)}`}
                  style={{ width: `${Math.min(drive.percent_used, 100)}%` }}
                ></div>
              </div>
              
              <div className="flex justify-between text-sm">
                <span className="text-gray-400">Free Space</span>
                <span className="text-white">{drive.free_gb.toFixed(1)} GB ({(100 - drive.percent_used).toFixed(1)}%)</span>
              </div>
              
              {drive.smart_available && (
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">SMART Status</span>
                  <span className="text-green-400">Available</span>
                </div>
              )}
            </div>
          </div>
        ))
      ) : (
        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700 text-center">
          <HardDrive className="w-12 h-12 text-gray-500 mx-auto mb-3" />
          <p className="text-gray-400">No drive information available</p>
        </div>
      )}
    </div>
  );
};

export default DriveInfo;
