import { edgeUrl } from "@/lib/edgeConfig";
import { supabase } from "@/lib/supabase";

export type EdgeApiError = {
  status: number;
  message: string;
  details?: unknown;
};

async function getAccessToken(): Promise<string | null> {
  try {
    const { data, error } = await supabase.auth.getSession();
    if (error) return null;
    return data.session?.access_token ?? null;
  } catch {
    return null;
  }
}

export async function edgeFetch<T>(
  path: string,
  options: RequestInit & { json?: unknown; auth?: boolean } = {}
): Promise<T> {
  const url = edgeUrl(path);
  const headers = new Headers(options.headers);
  headers.set("Accept", "application/json");

  if (!headers.has("Content-Type") && options.json !== undefined) {
    headers.set("Content-Type", "application/json");
  }

  if (options.auth !== false) {
    const token = await getAccessToken();
    if (token) headers.set("Authorization", `Bearer ${token}`);
  }

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



