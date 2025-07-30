// src/lib/game-constants.ts

export const MAX_POINTS = 100;          // Hard cap per play-through
export const TILE_SIZE = 20;

// GAME_SPEED: base interval in milliseconds per game tick update (move attempts).
export const GAME_SPEED = 120;          // ~120ms - controls update frequency

// Player moves every tick (divider 1) → faster movement.
export const PLAYER_SPEED_DIVISOR = 1;

// Ghosts move every 2 ticks → slower movement (half speed player).
export const GHOST_SPEED_MULTIPLIER = 2;

export const GHOST_FRIGHTENED_DURATION = 7000;

/* raw values – score clamped to MAX_POINTS in engine */
export const GHOST_POINTS = 0.5;
export const AARNA_COIN_POINTS = 5;
export const NORMAL_COIN_POINTS = 0.2;

/* fixed locations from which one will be chosen for the Aarna coin */
export const AARNA_COIN_FIXED_POSITIONS = [
  { x: 1, y: 10 },
  { x: 10, y: 1 },
  { x: 17, y: 10 }
];

export const COIN_TYPES = ['btc', 'eth', 'sol'];

export type Direction = "up" | "down" | "left" | "right" | "stop";

export interface Position {
  x: number;
  y: number;
}

export interface Character extends Position {
  id: string;
  direction: Direction;
}

export interface Ghost extends Character {
  isFrightened: boolean;
  isEaten: boolean;
  spawnPoint: Position;
}

export type GameState = "pre-game" | "running" | "paused" | "win" | "lose";

// Maze legend:
// 0: Wall
// 1: Empty space
// 2: Coin
// 3: Power Pellet
// 4: Ghost spawn
// 7: Player spawn
// 9: Aarna Coin (placed randomly)
// prettier-ignore
export const INITIAL_MAZE_LAYOUT: number[][] = [
  [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
  [0,3,2,2,2,2,2,2,2,2,0,2,2,2,2,2,2,2,2,3,0],
  [0,2,0,0,2,0,0,0,0,2,0,2,0,0,0,0,2,0,0,2,0],
  [0,2,0,0,2,0,0,0,0,2,0,2,0,0,0,0,2,0,0,2,0],
  [0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0],
  [0,2,0,0,2,0,2,0,0,0,0,0,0,0,2,0,2,0,0,2,0],
  [0,2,2,2,2,0,2,2,2,2,0,2,2,2,2,0,2,2,2,2,0],
  [0,0,0,0,2,0,0,0,0,1,0,1,0,0,0,0,2,0,0,0,0],
  [0,1,1,0,2,0,1,1,1,1,1,1,1,1,1,0,2,0,1,1,0],
  [0,1,1,0,2,0,1,0,4,4,4,4,4,0,1,0,2,0,1,1,0],
  [1,1,1,1,2,1,1,0,1,1,1,1,1,0,1,1,2,1,1,1,1],
  [0,1,1,0,2,0,1,0,0,0,0,0,0,0,1,0,2,0,1,1,0],
  [0,1,1,0,2,0,1,1,1,1,1,1,1,1,1,0,2,0,1,1,0],
  [0,0,0,0,2,0,0,0,0,1,0,1,0,0,0,0,2,0,0,0,0],
  [0,2,2,2,2,2,2,2,2,2,0,2,2,2,2,2,2,2,2,2,0],
  [0,2,0,0,2,0,2,0,0,0,0,0,0,0,2,0,2,0,0,2,0],
  [0,2,2,2,2,0,2,1,1,7,1,1,2,2,2,0,2,2,2,2,0],
  [0,0,0,2,2,0,2,0,2,0,0,0,2,0,2,0,2,2,0,0,0],
  [0,3,2,2,2,2,2,0,2,2,2,2,2,0,2,2,2,2,2,3,0],
  [0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0],
  [0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0],
  [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
];

export const GHOST_START_POSITIONS: Position[] = [
  { x: 9, y: 9 },
  { x: 9, y: 10 },
  { x: 9, y: 11 },
  { x: 9, y: 12 },
];

export const PLAYER_START_POSITION: Position = { x: 16, y: 9 };
