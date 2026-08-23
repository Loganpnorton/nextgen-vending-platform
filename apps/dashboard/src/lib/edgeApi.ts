import { supabaseAuth } from "@/integrations/supabase/authClient";
import { getEdgeBaseUrl } from "@/lib/edgeConfig";

export type EdgeApiError = {
  status: number;
  message: string;
  details?: unknown;
};

async function getAccessToken(): Promise<string | null> {
  const { data, error } = await supabaseAuth.auth.getSession();
  if (error) return null;
  return data.session?.access_token ?? null;
}

export async function edgeFetch<T>(
  path: string,
  options: RequestInit & { json?: unknown } = {}
): Promise<T> {
  const base = getEdgeBaseUrl();
  if (!base) {
    throw {
      status: 0,
      message:
        "Edge base URL not configured. Set VITE_EDGE_BASE_URL (Cloudflare tunnel URL).",
    } satisfies EdgeApiError;
  }

  const token = await getAccessToken();
  const urlPath = path.startsWith("/") ? path : `/${path}`;
  const url = `${base}${urlPath}`;

  const headers = new Headers(options.headers);
  headers.set("Accept", "application/json");
  if (!headers.has("Content-Type") && options.json !== undefined) {
    headers.set("Content-Type", "application/json");
  }
  if (token) headers.set("Authorization", `Bearer ${token}`);

  const res = await fetch(url, {
    ...options,
    headers,
    body: options.json !== undefined ? JSON.stringify(options.json) : options.body,
  });

  const contentType = res.headers.get("content-type") || "";
  const isJson = contentType.includes("application/json");
  const body = isJson ? await res.json().catch(() => null) : await res.text().catch(() => "");

  if (!res.ok) {
    throw {
      status: res.status,
      message:
        (typeof body === "object" && body && "error" in body && (body as any).error) ||
        res.statusText ||
        "Edge API request failed",
      details: body,
    } satisfies EdgeApiError;
  }

  return body as T;
}



