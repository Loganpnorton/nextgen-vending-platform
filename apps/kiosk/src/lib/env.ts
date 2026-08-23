interface Config {
  supabase: {
    url: string;
    anonKey: string;
  };
}

function getRequiredEnvVar(name: string): string {
  const value = import.meta.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export const SUPABASE_URL = getRequiredEnvVar('VITE_SUPABASE_URL');
export const SUPABASE_ANON_KEY = getRequiredEnvVar('VITE_SUPABASE_ANON_KEY');
export const EDGE_BASE_URL =
  (import.meta.env.VITE_EDGE_BASE_URL as string | undefined) ??
  'http://127.0.0.1:5000';

/**
 * Kiosk app retains Supabase for **Auth only**.
 */
export const config: Config = {
  supabase: {
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  },
};

export default config;

