import React, { useState, useEffect } from 'react';
import { Upload, Download, Share2, Trash2, File, Clock, User, HardDrive } from 'lucide-react';

interface SharedFile {
  file_id: string;
  filename: string;
  size: number;
  created_at: number;
  shared_by: string;
}

interface FileSharingProps {
  agentId: string;
  agentIp: string;
}

const FileSharing: React.FC<FileSharingProps> = ({ agentId, agentIp }) => {
  const [sharedFiles, setSharedFiles] = useState<SharedFile[]>([]);
  const [isUploading, setIsUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);

  const fetchSharedFiles = async () => {
    try {
      const response = await fetch(`http://${agentIp}:3000/api/shared-files`);
      if (response.ok) {
        const data = await response.json();
        setSharedFiles(data.files || []);
      }
    } catch (error) {
      console.error('Error fetching shared files:', error);
    }
  };

  useEffect(() => {
    fetchSharedFiles();
    const interval = setInterval(fetchSharedFiles, 10000); // Refresh every 10 seconds
    return () => clearInterval(interval);
  }, [agentIp]);

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      setSelectedFile(file);
    }
  };

  const handleUpload = async () => {
    if (!selectedFile) return;

    setIsUploading(true);
    setUploadProgress(0);

    try {
      const formData = new FormData();
      formData.append('file', selectedFile);

      const response = await fetch(`http://${agentIp}:3000/api/upload`, {
        method: 'POST',
        body: formData,
      });

      if (response.ok) {
        const result = await response.json();
        console.log('Upload successful:', result);
        setSelectedFile(null);
        fetchSharedFiles(); // Refresh the file list
        
        // Reset file input
        const fileInput = document.getElementById('file-input') as HTMLInputElement;
        if (fileInput) fileInput.value = '';
      } else {
        console.error('Upload failed:', response.statusText);
      }
    } catch (error) {
      console.error('Upload error:', error);
    } finally {
      setIsUploading(false);
      setUploadProgress(0);
    }
  };

  const handleDownload = async (fileId: string, filename: string) => {
    try {
      const response = await fetch(`http://${agentIp}:3000/api/download/${fileId}`);
      if (response.ok) {
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
      }
    } catch (error) {
      console.error('Download error:', error);
    }
  };

  const handleDelete = async (fileId: string) => {
    try {
      const response = await fetch(`http://${agentIp}:3000/api/shared-files/${fileId}`, {
        method: 'DELETE',
      });
      if (response.ok) {
        fetchSharedFiles(); // Refresh the file list
      }
    } catch (error) {
      console.error('Delete error:', error);
    }
  };

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const formatDate = (timestamp: number) => {
    return new Date(timestamp * 1000).toLocaleString();
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold text-white">File Sharing</h3>
        <div className="flex items-center space-x-2 text-sm text-gray-400">
          <Share2 className="w-4 h-4" />
          <span>Share files between computers</span>
        </div>
      </div>

      {/* Upload Section */}
      <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
        <h4 className="text-md font-medium text-white mb-4 flex items-center">
          <Upload className="w-5 h-5 mr-2" />
          Upload File
        </h4>
        
        <div className="space-y-4">
          <div className="flex items-center space-x-4">
            <input
              id="file-input"
              type="file"
              onChange={handleFileSelect}
              className="block w-full text-sm text-gray-400 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-medium file:bg-blue-600 file:text-white hover:file:bg-blue-700"
            />
            <button
              onClick={handleUpload}
              disabled={!selectedFile || isUploading}
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-gray-600 disabled:cursor-not-allowed flex items-center space-x-2"
            >
              <Upload className="w-4 h-4" />
              <span>{isUploading ? 'Uploading...' : 'Upload'}</span>
            </button>
          </div>
          
          {selectedFile && (
            <div className="text-sm text-gray-400">
              Selected: {selectedFile.name} ({formatFileSize(selectedFile.size)})
            </div>
          )}
          
          {isUploading && (
            <div className="w-full bg-gray-700 rounded-full h-2">
              <div 
                className="bg-blue-600 h-2 rounded-full transition-all duration-300"
                style={{ width: `${uploadProgress}%` }}
              ></div>
            </div>
          )}
        </div>
      </div>

      {/* Shared Files List */}
      <div className="bg-gray-800 rounded-lg p-6 border border-gray-700">
        <h4 className="text-md font-medium text-white mb-4 flex items-center">
          <HardDrive className="w-5 h-5 mr-2" />
          Shared Files ({sharedFiles.length})
        </h4>
        
        {sharedFiles.length === 0 ? (
          <div className="text-center py-8 text-gray-400">
            <File className="w-12 h-12 mx-auto mb-3 opacity-50" />
            <p>No shared files available</p>
            <p className="text-sm">Upload a file to start sharing</p>
          </div>
        ) : (
          <div className="space-y-3">
            {sharedFiles.map((file) => (
              <div
                key={file.file_id}
                className="flex items-center justify-between p-4 bg-gray-700 rounded-lg hover:bg-gray-600 transition-colors"
              >
                <div className="flex items-center space-x-3 flex-1">
                  <File className="w-5 h-5 text-blue-400" />
                  <div className="flex-1 min-w-0">
                    <p className="text-white font-medium truncate">{file.filename}</p>
                    <div className="flex items-center space-x-4 text-sm text-gray-400">
                      <span className="flex items-center space-x-1">
                        <HardDrive className="w-3 h-3" />
                        <span>{formatFileSize(file.size)}</span>
                      </span>
                      <span className="flex items-center space-x-1">
                        <User className="w-3 h-3" />
                        <span>{file.shared_by}</span>
                      </span>
                      <span className="flex items-center space-x-1">
                        <Clock className="w-3 h-3" />
                        <span>{formatDate(file.created_at)}</span>
                      </span>
                    </div>
                  </div>
                </div>
                
                <div className="flex items-center space-x-2">
                  <button
                    onClick={() => handleDownload(file.file_id, file.filename)}
                    className="p-2 text-green-400 hover:text-green-300 hover:bg-gray-600 rounded-md transition-colors"
                    title="Download"
                  >
                    <Download className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => handleDelete(file.file_id)}
                    className="p-2 text-red-400 hover:text-red-300 hover:bg-gray-600 rounded-md transition-colors"
                    title="Delete"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default FileSharing;
