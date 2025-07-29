"use client";

import { useState } from "react";
import type { TouchEventHandler } from "react";

interface SwipeConfig {
  onSwipedLeft?: () => void;
  onSwipedRight?: () => void;
  onSwipedUp?: () => void;
  onSwipedDown?: () => void;
}

const MIN_SWIPE_DISTANCE = 30;

export function useSwipe(config: SwipeConfig) {
  const [touchStartX, setTouchStartX] = useState<number | null>(null);
  const [touchEndX, setTouchEndX] = useState<number | null>(null);
  const [touchStartY, setTouchStartY] = useState<number | null>(null);
  const [touchEndY, setTouchEndY] = useState<number | null>(null);

  const onTouchStart: TouchEventHandler<HTMLElement> = (e) => {
    setTouchEndX(null);
    setTouchEndY(null);
    setTouchStartX(e.targetTouches[0].clientX);
    setTouchStartY(e.targetTouches[0].clientY);
  };

  const onTouchMove: TouchEventHandler<HTMLElement> = (e) => {
    setTouchEndX(e.targetTouches[0].clientX);
    setTouchEndY(e.targetTouches[0].clientY);
  };

  const onTouchEnd: TouchEventHandler<HTMLElement> = () => {
    if (!touchStartX || !touchEndX || !touchStartY || !touchEndY) return;

    const distanceX = touchStartX - touchEndX;
    const distanceY = touchStartY - touchEndY;
    const isLeftSwipe = distanceX > MIN_SWIPE_DISTANCE;
    const isRightSwipe = distanceX < -MIN_SWIPE_DISTANCE;
    const isUpSwipe = distanceY > MIN_SWIPE_DISTANCE;
    const isDownSwipe = distanceY < -MIN_SWIPE_DISTANCE;
    
    // Check for horizontal swipe
    if (Math.abs(distanceX) > Math.abs(distanceY)) {
      if (isLeftSwipe && config.onSwipedLeft) {
        config.onSwipedLeft();
      }
      if (isRightSwipe && config.onSwipedRight) {
        config.onSwipedRight();
      }
    } 
    // Check for vertical swipe
    else {
      if (isUpSwipe && config.onSwipedUp) {
        config.onSwipedUp();
      }
      if (isDownSwipe && config.onSwipedDown) {
        config.onSwipedDown();
      }
    }
    
    setTouchStartX(null);
    setTouchEndX(null);
    setTouchStartY(null);
    setTouchEndY(null);
  };

  return {
    onTouchStart,
    onTouchMove,
    onTouchEnd,
  };
}
