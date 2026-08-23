import { useState, useEffect, useRef } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useToast } from '@/hooks/use-toast';

interface SessionTimeoutConfig {
  warningTime?: number; // Time in minutes before showing warning
  logoutTime?: number; // Time in minutes before auto logout
  checkInterval?: number; // How often to check (in seconds)
}

export const useSessionTimeout = (config: SessionTimeoutConfig = {}) => {
  const {
    warningTime = 55, // 55 minutes
    logoutTime = 60, // 60 minutes
    checkInterval = 60 // Check every 60 seconds
  } = config;

  const { signOut } = useAuth();
  const { toast } = useToast();
  const [showWarning, setShowWarning] = useState(false);
  const [timeRemaining, setTimeRemaining] = useState<number>(0);
  const lastActivityRef = useRef<number>(Date.now());
  const warningShownRef = useRef<boolean>(false);

  // Update last activity on user interaction
  const updateActivity = () => {
    lastActivityRef.current = Date.now();
    if (warningShownRef.current) {
      setShowWarning(false);
      warningShownRef.current = false;
      toast({
        title: "Session Extended",
        description: "Your session has been extended due to activity",
      });
    }
  };

  // Check session timeout
  const checkSessionTimeout = () => {
    const now = Date.now();
    const idleTime = now - lastActivityRef.current;
    const idleMinutes = idleTime / (1000 * 60);

    if (idleMinutes >= logoutTime) {
      // Auto logout
      toast({
        title: "Session Expired",
        description: "You have been logged out due to inactivity",
        variant: "destructive",
      });
      signOut();
    } else if (idleMinutes >= warningTime && !warningShownRef.current) {
      // Show warning
      const remainingMinutes = Math.ceil(logoutTime - idleMinutes);
      setTimeRemaining(remainingMinutes);
      setShowWarning(true);
      warningShownRef.current = true;
      
      toast({
        title: "Session Expiring Soon",
        description: `Your session will expire in ${remainingMinutes} minutes. Click anywhere to extend.`,
        variant: "destructive",
      });
    }
  };

  // Set up activity listeners
  useEffect(() => {
    const events = ['mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart', 'click'];
    
    const handleActivity = () => {
      updateActivity();
    };

    events.forEach(event => {
      document.addEventListener(event, handleActivity, true);
    });

    // Set up interval to check session timeout
    const interval = setInterval(checkSessionTimeout, checkInterval * 1000);

    return () => {
      events.forEach(event => {
        document.removeEventListener(event, handleActivity, true);
      });
      clearInterval(interval);
    };
  }, [signOut, toast, warningTime, logoutTime, checkInterval]);

  // Update time remaining in warning
  useEffect(() => {
    if (!showWarning) return;

    const interval = setInterval(() => {
      const now = Date.now();
      const idleTime = now - lastActivityRef.current;
      const idleMinutes = idleTime / (1000 * 60);
      const remainingMinutes = Math.ceil(logoutTime - idleMinutes);

      if (remainingMinutes <= 0) {
        setShowWarning(false);
        signOut();
      } else {
        setTimeRemaining(remainingMinutes);
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [showWarning, logoutTime, signOut]);

  const extendSession = () => {
    updateActivity();
  };

  const logoutNow = () => {
    signOut();
  };

  return {
    showWarning,
    timeRemaining,
    extendSession,
    logoutNow,
  };
}; 