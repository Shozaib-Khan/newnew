"use client";

import { cn } from "@/lib/utils";
import { type Ghost } from "@/lib/game-constants";

const GHOST_COLORS = [
  '#FF4136', // Red
  '#FF851B', // Orange
  '#0074D9', // Blue
  '#B10DC9', // Purple
];

interface GhostIconProps {
  ghost: Ghost;
  style: React.CSSProperties;
}

export const GhostIcon = ({ ghost, style }: GhostIconProps) => {
  const color = GHOST_COLORS[parseInt(ghost.id) % GHOST_COLORS.length];

  if (ghost.isEaten) {
    return (
        <svg viewBox="0 0 24 24" style={style}>
            <circle cx="8" cy="12" r="2" fill="hsl(var(--foreground))" />
            <circle cx="16" cy="12" r="2" fill="hsl(var(--foreground))" />
        </svg>
    );
  }

  return (
    <svg
      viewBox="0 0 14 14"
      style={style}
      className={cn(ghost.isFrightened && "animate-pulse")}
    >
      <path
        d="M1,7.28v-.56A6,6,0,0,1,12.72,2.3l.16.14a6,6,0,0,1,1,4.84v.56a.5.5,0,0,0,.5.5h0a.5.5,0,0,1,.5.5v2a.5.5,0,0,1-.5.5h-1a.5.5,0,0,0-.5.5v1a.5.5,0,0,1-.5.5H2.28a.5.5,0,0,1-.5-.5v-1a.5.5,0,0,0-.5-.5H.5a.5.5,0,0,1-.5-.5v-2a.5.5,0,0,1,.5-.5h0A.5.5,0,0,0,1,7.28Z"
        fill={ghost.isFrightened ? '#60FFE9' : color}
        stroke="hsl(var(--background))"
        strokeWidth="0.5"
      />
      <circle cx="4.5" cy="6.5" r="1.5" fill="white" />
      <circle cx="9.5" cy="6.5" r="1.5" fill="white" />
      <circle cx="4.5" cy="6.5" r="0.75" fill="black" />
      <circle cx="9.5" cy="6.5" r="0.75" fill="black" />
    </svg>
  );
};
