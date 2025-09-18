export interface Agent {
  agent_id: string;
  hostname: string;
  ip: string;
  status: 'online' | 'offline';
  last_seen: string;
  status_data: {
    cpu_percent: number;
    memory_percent: number;
    memory_used_mb: number;
    memory_total_mb: number;
    disk_percent: number;
    disk_used_gb: number;
    disk_total_gb: number;
    uptime_seconds: number;
  };
}

export interface SystemInfo {
  hostname: string;
  os: string;
  os_version: string;
  cpu_count: number;
  total_ram: number;
  disks: Array<{
    device: string;
    mountpoint: string;
    fstype: string;
    total_gb: number;
    used_gb: number;
    free_gb: number;
    percent_used: number;
  }>;
  last_updated: string;
}
