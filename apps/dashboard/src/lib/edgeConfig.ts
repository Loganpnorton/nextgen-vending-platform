export const edgeConfig = {
  /**
   * Cloudflare tunnel URL (recommended) or direct LAN URL to the edge box.
   * Example: https://kiosk.example.com
   */
  baseUrl:
    (import.meta.env.VITE_EDGE_BASE_URL as string | undefined) ||
    (import.meta.env.VITE_TUNNEL_URL as string | undefined) ||
    "http://127.0.0.1:5000",

  /**
   * Default MJPEG endpoint (Flask).
   * Override by setting VITE_EDGE_MJPEG_PATH if your backend differs.
   */
  mjpegPath: (import.meta.env.VITE_EDGE_MJPEG_PATH as string | undefined) || "/video_feed/0",
} as const;

export function getEdgeBaseUrl(): string {
  const raw = edgeConfig.baseUrl || "";
  return raw.endsWith("/") ? raw.slice(0, -1) : raw;
}

export function getEdgeMjpegUrl(): string {
  const base = getEdgeBaseUrl();
  const path = edgeConfig.mjpegPath.startsWith("/")
    ? edgeConfig.mjpegPath
    : `/${edgeConfig.mjpegPath}`;
  return `${base}${path}`;
}

