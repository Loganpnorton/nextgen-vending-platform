import { createClient } from '@supabase/supabase-js';
import { config } from './env';
import type { Database } from '@/integrations/supabase/types';

// Create a single instance to prevent multiple GoTrueClient instances
let supabaseInstance: ReturnType<typeof createClient<Database>> | null = null;

export const supabase = (() => {
  if (!supabaseInstance) {
    supabaseInstance = createClient<Database>(config.supabase.url, config.supabase.anonKey, {
      auth: {
        storage: localStorage,
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
        flowType: 'pkce',
      },
      global: {
        headers: {
          'X-Client-Info': 'kiosk-vibe'
        }
      }
    });

    // Add error handling for token refresh
    supabaseInstance.auth.onAuthStateChange((event, session) => {
      if (event === 'TOKEN_REFRESHED') {
        console.log('Token refreshed successfully');
      } else if (event === 'TOKEN_REFRESH_FAILED') {
        console.error('Token refresh failed');
        // Clear invalid session (project ref may differ per environment)
        try {
          const keys = Object.keys(localStorage);
          keys.forEach((k) => {
            if (k.startsWith("sb-")) localStorage.removeItem(k);
          });
        } catch {
          // ignore
        }
      }
    });
  }

  return supabaseInstance;
})();

export default supabase;
