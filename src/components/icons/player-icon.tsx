"use client";

import type { Direction } from "@/lib/game-constants";

interface PlayerIconProps {
  direction: Direction;
  style: React.CSSProperties;
}

const directionToRotation: Record<Direction, string> = {
  up: "-90deg",
  down: "90deg",
  left: "180deg",
  right: "0deg",
  stop: "0deg",
};

export const PlayerIcon = ({ direction, style }: PlayerIconProps) => {
  // Simplified static mouth - no animation for better performance
  const mouthPath = "M12 12 L21 6 L21 18 Z";

  return (
    <svg
      viewBox="0 0 24 24"
      style={{
        ...style,
        transform: `rotate(${directionToRotation[direction]})`,
        transition: 'transform 100ms ease-in-out',
      }}
    >
      <circle cx="12" cy="12" r="11" fill="hsl(var(--primary))" />
      <path d={mouthPath} fill="hsl(var(--background))" />
      <circle cx="12" cy="7" r="1.5" fill="hsl(var(--background))" />
    </svg>
  );
};
