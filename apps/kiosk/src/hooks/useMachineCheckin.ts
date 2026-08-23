import { useCallback, useEffect, useState } from "react";
import { edgeFetch } from "@/lib/edgeApi";
import { edgeConfig } from "@/lib/edgeConfig";

export function useMachineCheckin(
  machineId?: string,
  machineCode?: string,
  machineToken?: string,
  products: any[] = [],
  cameraInfo?: {
    has_camera: boolean;
    permission: 'granted' | 'denied' | 'prompt' | 'unknown';
    facing: 'environment' | 'user' | 'unknown';
    device_label: string;
    device_id_hash: string;
    resolution: string;
    fps: number | null;
    last_error: string | null;
    snapshot_url: string | null;
    snapshot_at: string | null;
  }
) {
  const [online, setOnline] = useState(true);
  const [lastSync, setLastSync] = useState<Date | null>(null);
  const [batteryPct, setBatteryPct] = useState(85);

  const performCheckin = useCallback(async () => {
    try {
      await edgeFetch(edgeConfig.healthPath, { method: "GET", auth: false });
      const now = new Date();
      setLastSync(now);
      setOnline(true);
    } catch (error) {
      console.error("❌ Local edge health check failed:", error);
      setOnline(false);
    }
  }, []);

  // Initial checkin
  useEffect(() => {
    performCheckin();
  }, [performCheckin]);

  // Periodic health check every 5 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      performCheckin();
    }, 5000);

    return () => clearInterval(interval);
  }, [performCheckin]);

  const lastSyncText = lastSync 
    ? `${Math.max(0, Math.floor((Date.now() - lastSync.getTime()) / 60000))} min ago`
    : 'Never';

  return {
    online,
    lastSync,
    lastSyncText,
    batteryPct,
    performCheckin,
  };
}
