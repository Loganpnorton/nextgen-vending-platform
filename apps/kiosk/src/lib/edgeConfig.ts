import { EDGE_BASE_URL } from "@/lib/env";

export const edgeConfig = {
  /**
   * Local Flask service on the edge box.
   * In production, this runs on the kiosk itself (localhost).
   */
  baseUrl: (import.meta.env.VITE_EDGE_BASE_URL as string | undefined) || EDGE_BASE_URL || "http://127.0.0.1:5000",

  inventoryPath: (import.meta.env.VITE_EDGE_INVENTORY_PATH as string | undefined) || "/inventory",
  mjpegPath: (import.meta.env.VITE_EDGE_MJPEG_PATH as string | undefined) || "/video_feed/0",
  eventsPath: (import.meta.env.VITE_EDGE_EVENTS_PATH as string | undefined) || "/events",
  salePath: (import.meta.env.VITE_EDGE_SALE_PATH as string | undefined) || "/sale",
  unlockPath: (import.meta.env.VITE_EDGE_UNLOCK_PATH as string | undefined) || "/unlock",
  healthPath: (import.meta.env.VITE_EDGE_HEALTH_PATH as string | undefined) || "/health",
} as const;

export function getEdgeBaseUrl(): string {
  const raw = edgeConfig.baseUrl || "";
  return raw.endsWith("/") ? raw.slice(0, -1) : raw;
}

export function edgeUrl(path: string): string {
  const base = getEdgeBaseUrl();
  const p = path.startsWith("/") ? path : `/${path}`;
  return `${base}${p}`;
}

export function getEdgeMjpegUrl(): string {
  return edgeUrl(edgeConfig.mjpegPath);
}


