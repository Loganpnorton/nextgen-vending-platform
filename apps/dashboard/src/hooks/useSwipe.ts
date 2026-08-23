import { useState, useRef, useEffect } from 'react';

interface SwipeConfig {
  minSwipeDistance?: number;
  maxSwipeTime?: number;
}

interface SwipeCallbacks {
  onSwipeLeft?: () => void;
  onSwipeRight?: () => void;
  onSwipeUp?: () => void;
  onSwipeDown?: () => void;
}

export const useSwipe = (callbacks: SwipeCallbacks, config: SwipeConfig = {}) => {
  const {
    minSwipeDistance = 50,
    maxSwipeTime = 300
  } = config;

  const [isSwiping, setIsSwiping] = useState(false);
  const [swipeDirection, setSwipeDirection] = useState<'left' | 'right' | 'up' | 'down' | null>(null);
  const touchStartRef = useRef<{ x: number; y: number; time: number } | null>(null);
  const touchEndRef = useRef<{ x: number; y: number; time: number } | null>(null);

  const onTouchStart = (e: React.TouchEvent) => {
    const touch = e.touches[0];
    touchStartRef.current = {
      x: touch.clientX,
      y: touch.clientY,
      time: Date.now()
    };
    setIsSwiping(false);
    setSwipeDirection(null);
  };

  const onTouchMove = (e: React.TouchEvent) => {
    if (!touchStartRef.current) return;

    const touch = e.touches[0];
    const deltaX = Math.abs(touch.clientX - touchStartRef.current.x);
    const deltaY = Math.abs(touch.clientY - touchStartRef.current.y);

    // Start swiping if we've moved enough distance
    if (deltaX > 10 || deltaY > 10) {
      setIsSwiping(true);
    }
  };

  const onTouchEnd = (e: React.TouchEvent) => {
    if (!touchStartRef.current) return;

    const touch = e.changedTouches[0];
    touchEndRef.current = {
      x: touch.clientX,
      y: touch.clientY,
      time: Date.now()
    };

    const deltaX = touchEndRef.current.x - touchStartRef.current.x;
    const deltaY = touchEndRef.current.y - touchStartRef.current.y;
    const deltaTime = touchEndRef.current.time - touchStartRef.current.time;

    // Check if swipe meets criteria
    if (deltaTime < maxSwipeTime) {
      const absDeltaX = Math.abs(deltaX);
      const absDeltaY = Math.abs(deltaY);

      if (absDeltaX > minSwipeDistance || absDeltaY > minSwipeDistance) {
        let direction: 'left' | 'right' | 'up' | 'down' | null = null;

        if (absDeltaX > absDeltaY) {
          // Horizontal swipe
          direction = deltaX > 0 ? 'right' : 'left';
        } else {
          // Vertical swipe
          direction = deltaY > 0 ? 'down' : 'up';
        }

        setSwipeDirection(direction);

        // Call appropriate callback
        switch (direction) {
          case 'left':
            callbacks.onSwipeLeft?.();
            break;
          case 'right':
            callbacks.onSwipeRight?.();
            break;
          case 'up':
            callbacks.onSwipeUp?.();
            break;
          case 'down':
            callbacks.onSwipeDown?.();
            break;
        }
      }
    }

    // Reset after a short delay
    setTimeout(() => {
      setIsSwiping(false);
      setSwipeDirection(null);
      touchStartRef.current = null;
      touchEndRef.current = null;
    }, 100);
  };

  const swipeHandlers = {
    onTouchStart,
    onTouchMove,
    onTouchEnd,
  };

  return {
    isSwiping,
    swipeDirection,
    swipeHandlers,
  };
}; 