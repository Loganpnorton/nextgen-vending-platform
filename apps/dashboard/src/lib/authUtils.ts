import { supabaseAuth } from "@/integrations/supabase/authClient";

/**
 * Clear all authentication data from localStorage
 */
export const clearAuthData = () => {
  try {
    // Clear any Supabase / auth-related items (project ref changes per Supabase project)
    const keys = Object.keys(localStorage);
    keys.forEach(key => {
      if (key.startsWith("sb-") || key.includes('supabase') || key.includes('auth')) {
        localStorage.removeItem(key);
      }
    });
    
    console.log('Auth data cleared successfully');
  } catch (error) {
    console.error('Error clearing auth data:', error);
  }
};

/**
 * Check if the current session is valid
 */
export const isSessionValid = async (): Promise<boolean> => {
  try {
    const { data: { session }, error } = await supabaseAuth.auth.getSession();
    
    if (error) {
      console.error('Session validation error:', error);
      return false;
    }
    
    return !!session && !!session.access_token;
  } catch (error) {
    console.error('Error checking session validity:', error);
    return false;
  }
};

/**
 * Force refresh the current session
 */
export const refreshSession = async (): Promise<boolean> => {
  try {
    const { data: { session }, error } = await supabaseAuth.auth.refreshSession();
    
    if (error) {
      console.error('Session refresh error:', error);
      return false;
    }
    
    return !!session;
  } catch (error) {
    console.error('Error refreshing session:', error);
    return false;
  }
};

/**
 * Handle authentication errors and attempt recovery
 */
export const handleAuthError = async (error: any): Promise<void> => {
  console.error('Auth error detected:', error);
  
  // If it's a token refresh error, clear the session
  if (error?.message?.includes('refresh') || error?.status === 400) {
    console.log('Token refresh error detected, clearing session...');
    clearAuthData();
    
    // Try to refresh the session
    const refreshed = await refreshSession();
    if (!refreshed) {
      // If refresh fails, redirect to login
      window.location.href = '/login';
    }
  }
}; 