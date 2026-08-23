import React, { useState } from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Trash2, Edit, AlertTriangle } from 'lucide-react';
import { useSwipe } from '@/hooks/useSwipe';
import { cn } from '@/lib/utils';

interface SwipeableCardProps {
  children: React.ReactNode;
  onDelete?: () => void;
  onEdit?: () => void;
  className?: string;
  disabled?: boolean;
}

export const SwipeableCard: React.FC<SwipeableCardProps> = ({
  children,
  onDelete,
  onEdit,
  className,
  disabled = false
}) => {
  const [showActions, setShowActions] = useState(false);
  const [swipeOffset, setSwipeOffset] = useState(0);

  const { swipeHandlers } = useSwipe({
    onSwipeLeft: () => {
      if (!disabled && onDelete) {
        setShowActions(true);
        setSwipeOffset(-80);
      }
    },
    onSwipeRight: () => {
      if (!disabled && onEdit) {
        setShowActions(true);
        setSwipeOffset(80);
      }
    }
  });

  const handleReset = () => {
    setShowActions(false);
    setSwipeOffset(0);
  };

  const handleDelete = () => {
    onDelete?.();
    handleReset();
  };

  const handleEdit = () => {
    onEdit?.();
    handleReset();
  };

  return (
    <div className="relative overflow-hidden">
      {/* Action Buttons */}
      <div className="absolute inset-0 flex items-center justify-between pointer-events-none">
        {/* Left Action (Delete) */}
        <div className={cn(
          "flex items-center justify-center w-20 h-full bg-destructive text-destructive-foreground transition-transform duration-300",
          showActions && swipeOffset < 0 ? "translate-x-0" : "-translate-x-full"
        )}>
          <Button
            variant="destructive"
            size="sm"
            onClick={handleDelete}
            className="h-full w-full rounded-none"
            disabled={disabled}
          >
            <Trash2 className="h-4 w-4" />
          </Button>
        </div>

        {/* Right Action (Edit) */}
        <div className={cn(
          "flex items-center justify-center w-20 h-full bg-primary text-primary-foreground transition-transform duration-300 ml-auto",
          showActions && swipeOffset > 0 ? "translate-x-0" : "translate-x-full"
        )}>
          <Button
            variant="default"
            size="sm"
            onClick={handleEdit}
            className="h-full w-full rounded-none"
            disabled={disabled}
          >
            <Edit className="h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Main Card */}
      <div
        className={cn(
          "transition-transform duration-300",
          showActions && "transform",
          swipeOffset < 0 && "translate-x-20",
          swipeOffset > 0 && "-translate-x-20"
        )}
        style={{
          transform: showActions ? `translateX(${swipeOffset}px)` : 'translateX(0)'
        }}
      >
        <Card
          className={cn(
            "bg-card border-border shadow-card transition-all duration-300",
            showActions && "shadow-lg",
            className
          )}
          {...swipeHandlers}
        >
          <CardContent className="p-4">
            {children}
          </CardContent>
        </Card>
      </div>

      {/* Swipe Hint (only on mobile) */}
      <div className="hidden sm:block absolute inset-0 flex items-center justify-center pointer-events-none">
        <div className="flex items-center gap-2 text-xs text-muted-foreground bg-background/80 px-2 py-1 rounded">
          <AlertTriangle className="h-3 w-3" />
          <span>Swipe for actions</span>
        </div>
      </div>
    </div>
  );
}; 