import React from 'react';
import { Thermometer, AlertTriangle, CheckCircle } from 'lucide-react';

interface Temperature {
  current: number;
  high?: number | null;
  critical?: number | null;
}

interface TemperatureInfoProps {
  temperatures: Record<string, Temperature>;
}

const TemperatureInfo: React.FC<TemperatureInfoProps> = ({ temperatures }) => {
  const getTemperatureStatus = (temp: Temperature) => {
    if (temp.critical && temp.current >= temp.critical) {
      return { status: 'critical', color: 'text-red-400', bgColor: 'bg-red-500' };
    }
    if (temp.high && temp.current >= temp.high) {
      return { status: 'warning', color: 'text-yellow-400', bgColor: 'bg-yellow-500' };
    }
    if (temp.current >= 80) {
      return { status: 'hot', color: 'text-orange-400', bgColor: 'bg-orange-500' };
    }
    if (temp.current >= 60) {
      return { status: 'warm', color: 'text-blue-400', bgColor: 'bg-blue-500' };
    }
    return { status: 'normal', color: 'text-green-400', bgColor: 'bg-green-500' };
  };

  const getTemperatureIcon = (temp: Temperature) => {
    const status = getTemperatureStatus(temp);
    switch (status.status) {
      case 'critical':
        return <AlertTriangle className="w-5 h-5 text-red-400" />;
      case 'warning':
        return <AlertTriangle className="w-5 h-5 text-yellow-400" />;
      default:
        return <Thermometer className={`w-5 h-5 ${status.color}`} />;
    }
  };

  const formatSensorName = (name: string) => {
    return name
      .replace(/_/g, ' ')
      .replace(/([A-Z])/g, ' $1')
      .replace(/\b\w/g, l => l.toUpperCase())
      .trim();
  };

  const getTemperaturePercentage = (temp: Temperature) => {
    const max = temp.critical || temp.high || 100;
    return Math.min((temp.current / max) * 100, 100);
  };

  return (
    <div className="space-y-4">
      <h3 className="text-lg font-semibold text-white mb-4">Temperature Monitoring</h3>
      {temperatures && Object.keys(temperatures).length > 0 ? (
        Object.entries(temperatures).map(([sensorName, temp]) => {
          const status = getTemperatureStatus(temp);
          return (
            <div key={sensorName} className="bg-gray-800 rounded-lg p-4 border border-gray-700">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center space-x-3">
                  {getTemperatureIcon(temp)}
                  <div>
                    <h4 className="text-white font-medium">{formatSensorName(sensorName)}</h4>
                    <p className="text-gray-400 text-sm">Temperature Sensor</p>
                  </div>
                </div>
                <div className="text-right">
                  <div className={`text-lg font-bold ${status.color}`}>
                    {temp.current.toFixed(1)}°C
                  </div>
                  <div className="text-xs text-gray-400 capitalize">
                    {status.status}
                  </div>
                </div>
              </div>
              
              <div className="space-y-2">
                <div className="w-full bg-gray-700 rounded-full h-2">
                  <div 
                    className={`h-2 rounded-full ${status.bgColor}`}
                    style={{ width: `${getTemperaturePercentage(temp)}%` }}
                  ></div>
                </div>
                
                <div className="flex justify-between text-xs text-gray-400">
                  <span>0°C</span>
                  <div className="flex space-x-4">
                    {temp.high && (
                      <span className="text-yellow-400">High: {temp.high}°C</span>
                    )}
                    {temp.critical && (
                      <span className="text-red-400">Critical: {temp.critical}°C</span>
                    )}
                  </div>
                  <span>{temp.critical || temp.high || 100}°C</span>
                </div>
              </div>
            </div>
          );
        })
      ) : (
        <div className="bg-gray-800 rounded-lg p-6 border border-gray-700 text-center">
          <Thermometer className="w-12 h-12 text-gray-500 mx-auto mb-3" />
          <p className="text-gray-400">No temperature sensors detected</p>
          <p className="text-gray-500 text-sm mt-1">
            Temperature monitoring may require additional drivers or administrative privileges
          </p>
        </div>
      )}
    </div>
  );
};

export default TemperatureInfo;
