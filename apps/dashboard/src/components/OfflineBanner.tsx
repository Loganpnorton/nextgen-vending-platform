import React, { useState, useEffect } from 'react';
import { Wifi, WifiOff } from 'lucide-react';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { cn } from '@/lib/utils';

export const OfflineBanner: React.FC = () => {
  const [isOnline, setIsOnline] = useState(navigator.onLine);

  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  if (isOnline) return null;

  return (
    <Alert className={cn(
      "fixed top-0 left-0 right-0 z-50 border-destructive bg-destructive/10 text-destructive",
      "animate-slide-down"
    )}>
      <WifiOff className="h-4 w-4" />
      <AlertDescription>
        You're offline. Changes will sync once reconnected.
      </AlertDescription>
    </Alert>
  );
}; 