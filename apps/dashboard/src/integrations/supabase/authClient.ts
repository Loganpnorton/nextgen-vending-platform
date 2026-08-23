import { createClient, type SupabaseClient } from "@supabase/supabase-js";

/**
 * Supabase is retained for **Auth only** (session + JWT).
 * Do not use Supabase DB / Storage / Realtime in this repo going forward.
 */

function getRequiredEnvVar(name: string): string {
  const value = import.meta.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

const SUPABASE_URL = getRequiredEnvVar("VITE_SUPABASE_URL");
const SUPABASE_ANON_KEY = getRequiredEnvVar("VITE_SUPABASE_ANON_KEY");

// Auth UI needs a real SupabaseClient instance. We keep the instance private-ish
// and only export `auth` separately for most of the app.
export const supabaseClient: SupabaseClient = createClient(
  SUPABASE_URL,
  SUPABASE_ANON_KEY,
  {
    auth: {
      storage: localStorage,
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
      flowType: "pkce",
    },
    global: {
      headers: {
        "X-Client-Info": "new-nextgen-auth-only",
      },
    },
  }
);

export const supabaseAuth = {
  auth: supabaseClient.auth,
} as const;

export function assertSupabaseAuthConfigured() {
  // Configuration is validated when this module is loaded.
  return true;
}

