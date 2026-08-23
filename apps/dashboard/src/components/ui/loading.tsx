import React from 'react';
import { Loader2 } from 'lucide-react';
import { cn } from '@/lib/utils';

interface LoadingProps {
  message?: string;
  className?: string;
  size?: 'sm' | 'md' | 'lg';
  fullHeight?: boolean;
}

export const Loading: React.FC<LoadingProps> = ({ 
  message = "Loading...", 
  className,
  size = 'md',
  fullHeight = false 
}) => {
  const sizeClasses = {
    sm: 'h-4 w-4',
    md: 'h-6 w-6',
    lg: 'h-8 w-8'
  };

  const containerClasses = cn(
    'flex items-center justify-center',
    fullHeight ? 'min-h-[400px]' : '',
    className
  );

  return (
    <div className={containerClasses}>
      <div className="flex items-center gap-2">
        <Loader2 className={cn('animate-spin', sizeClasses[size])} />
        <span className="text-muted-foreground">{message}</span>
      </div>
    </div>
  );
};

// Full page loading component
export const FullPageLoading: React.FC<{ message?: string }> = ({ message = "Loading..." }) => {
  return (
    <div className="p-4 space-y-4 animate-fade-in">
      <Loading message={message} fullHeight />
    </div>
  );
};

// Error state component to match the loading pattern
export const ErrorState: React.FC<{ 
  message?: string; 
  onRetry?: () => void;
  className?: string;
}> = ({ 
  message = "Error loading data", 
  onRetry,
  className 
}) => {
  return (
    <div className={cn('flex items-center justify-center min-h-[400px]', className)}>
      <div className="text-center">
        <p className="text-destructive mb-2">{message}</p>
        {onRetry && (
          <button 
            onClick={onRetry} 
            className="px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90 transition-colors"
          >
            Try Again
          </button>
        )}
      </div>
    </div>
  );
};
