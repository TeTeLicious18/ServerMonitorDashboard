import React, { useState, useEffect } from 'react';
import { Folder, FileText, ArrowLeft, RefreshCw, Download } from 'lucide-react';

interface FileItem {
  name: string;
  path: string;
  is_directory: boolean;
  size: number;
  modified: number;
  type: string;
}

interface FileBrowserProps {
  agentId: string;
  agentIp: string;
}

const FileBrowser: React.FC<FileBrowserProps> = ({ agentId, agentIp }) => {
  const [currentPath, setCurrentPath] = useState('C:\\');
  const [files, setFiles] = useState<FileItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchFiles = async (path: string) => {
    setLoading(true);
    setError(null);
    
    try {
      const response = await fetch(`http://${agentIp}:3000/api/files?path=${encodeURIComponent(path)}`);
      if (!response.ok) {
        throw new Error(`Failed to fetch files: ${response.statusText}`);
      }
      
      const data = await response.json();
      setFiles(data.items || []);
      setCurrentPath(data.path || path);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load files');
      setFiles([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchFiles(currentPath);
  }, [agentId, agentIp]);

  const handleItemClick = (item: FileItem) => {
    if (item.is_directory) {
      fetchFiles(item.path);
    }
  };

  const handleBack = () => {
    const parentPath = currentPath.split('\\').slice(0, -1).join('\\');
    if (parentPath && parentPath !== currentPath) {
      fetchFiles(parentPath || 'C:\\');
    }
  };

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  };

  const formatDate = (timestamp: number) => {
    return new Date(timestamp * 1000).toLocaleDateString();
  };

  const getFileIcon = (item: FileItem) => {
    if (item.is_directory) {
      return <Folder className="w-5 h-5 text-blue-400" />;
    }
    return <FileText className="w-5 h-5 text-gray-400" />;
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold text-white">File Browser</h3>
        <button
          onClick={() => fetchFiles(currentPath)}
          disabled={loading}
          className="p-2 bg-gray-700 hover:bg-gray-600 rounded-lg transition-colors disabled:opacity-50"
        >
          <RefreshCw className={`w-4 h-4 text-white ${loading ? 'animate-spin' : ''}`} />
        </button>
      </div>

      <div className="bg-gray-800 rounded-lg border border-gray-700">
        {/* Path bar */}
        <div className="flex items-center p-4 border-b border-gray-700">
          <button
            onClick={handleBack}
            disabled={loading || currentPath === 'C:\\'}
            className="p-2 mr-3 bg-gray-700 hover:bg-gray-600 rounded disabled:opacity-50 transition-colors"
          >
            <ArrowLeft className="w-4 h-4 text-white" />
          </button>
          <span className="text-white font-mono text-sm bg-gray-700 px-3 py-1 rounded">
            {currentPath}
          </span>
        </div>

        {/* File list */}
        <div className="p-4">
          {loading ? (
            <div className="flex items-center justify-center py-8">
              <RefreshCw className="w-6 h-6 text-gray-400 animate-spin mr-2" />
              <span className="text-gray-400">Loading...</span>
            </div>
          ) : error ? (
            <div className="text-center py-8">
              <p className="text-red-400 mb-2">{error}</p>
              <button
                onClick={() => fetchFiles(currentPath)}
                className="px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white rounded transition-colors"
              >
                Retry
              </button>
            </div>
          ) : files.length === 0 ? (
            <div className="text-center py-8">
              <Folder className="w-12 h-12 text-gray-500 mx-auto mb-3" />
              <p className="text-gray-400">No files found</p>
            </div>
          ) : (
            <div className="space-y-1">
              {files.map((item, index) => (
                <div
                  key={index}
                  onClick={() => handleItemClick(item)}
                  className={`flex items-center p-3 rounded-lg transition-colors ${
                    item.is_directory 
                      ? 'hover:bg-gray-700 cursor-pointer' 
                      : 'hover:bg-gray-750'
                  }`}
                >
                  <div className="flex items-center flex-1 min-w-0">
                    {getFileIcon(item)}
                    <span className="ml-3 text-white truncate">{item.name}</span>
                  </div>
                  <div className="flex items-center space-x-4 text-sm text-gray-400">
                    {!item.is_directory && (
                      <span className="w-20 text-right">{formatFileSize(item.size)}</span>
                    )}
                    <span className="w-24 text-right">{formatDate(item.modified)}</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default FileBrowser;
