"use client";

import { useState, useEffect, useCallback, useRef } from 'react';
import {
  INITIAL_MAZE_LAYOUT,
  GHOST_START_POSITIONS,
  PLAYER_START_POSITION,
  AARNA_COIN_POINTS,
  NORMAL_COIN_POINTS,
  GHOST_POINTS,
  GAME_SPEED,
  GHOST_FRIGHTENED_DURATION,
  GHOST_SPEED_MULTIPLIER,
  COIN_TYPES,
  MAX_POINTS,
  AARNA_COIN_FIXED_POSITIONS,
  PLAYER_SPEED_DIVISOR,
  type GameState,
  type Direction,
  type Position,
  type Character,
  type Ghost
} from '@/lib/game-constants';
import { useToast } from './use-toast';

// Helper to safely add score without breaching the 80-point cap and format to 1 decimal
const clampAdd = (setter: (cb: (n: number) => number) => void) =>
  (points: number) =>
    setter(s => Number(Math.min(MAX_POINTS, s + points).toFixed(1)));

export const useGameEngine = () => {
    const [gameState, setGameState] = useState<GameState>('pre-game');
    const [score, setScore] = useState(0);
    const [highScore, setHighScore] = useState(0);
    const [maze, setMaze] = useState(INITIAL_MAZE_LAYOUT.map(row => row.map(cell => ({ type: cell }))));
    const [player, setPlayer] = useState<Character>({ 
        ...PLAYER_START_POSITION, 
        id: 'player', 
        direction: 'stop'
    });
    const [ghosts, setGhosts] = useState<Ghost[]>([]);
    const [remainingCoins, setRemainingCoins] = useState(0);
    
    const desiredDirectionRef = useRef<Direction>('stop');
    const playerRef = useRef(player);
    const gameTickRef = useRef(0);
    const frightenedTimerRef = useRef<NodeJS.Timeout>();
    const lastFrightenUpdateRef = useRef(0);
    const { toast } = useToast();

    const addScore = clampAdd(setScore);

    useEffect(() => {
        const storedHighScore = localStorage.getItem('coinChaseHighScore');
        if (storedHighScore) {
            setHighScore(parseFloat(storedHighScore));
        }
    }, []);

    useEffect(() => {
      if (score > highScore) {
        const formattedScore = Number(score.toFixed(1));
        setHighScore(formattedScore);
        localStorage.setItem('coinChaseHighScore', String(formattedScore));
      }
    }, [score, highScore]);

    useEffect(() => {
        playerRef.current = player;
    }, [player]);

    const isWall = useCallback((pos: Position, mazeLayout: typeof maze) => {
        const cell = mazeLayout[pos.x]?.[pos.y];
        return !cell || cell.type === 0;
    }, []);

    const resetCharactersToStart = useCallback(() => {
        setPlayer({ 
            ...PLAYER_START_POSITION, 
            id: 'player', 
            direction: 'stop'
        });
        desiredDirectionRef.current = 'stop';
        setGhosts(GHOST_START_POSITIONS.map((pos, i) => ({
            ...pos,
            id: String(i),
            direction: 'up',
            isFrightened: false,
            isEaten: false,
            spawnPoint: pos
        })));
    }, []);

    const handleStartGame = useCallback(() => {
        // Build maze without warp tiles and with coins
        const newMaze = INITIAL_MAZE_LAYOUT.map(row => row.map(cell => {
          const coinType = cell === 2 ? COIN_TYPES[Math.floor(Math.random() * COIN_TYPES.length)] : undefined;
          return { type: cell, coin: coinType };
        }));

        // Place Aarna coin in one pre-defined spot
        const pos = AARNA_COIN_FIXED_POSITIONS[
          Math.floor(Math.random() * AARNA_COIN_FIXED_POSITIONS.length)
        ];
        newMaze[pos.x][pos.y].type = 9;

        // Count coins/pellets
        let totalCoins = 0;
        newMaze.forEach(row => {
            row.forEach(cell => {
                if (cell.type === 2 || cell.type === 3 || cell.type === 9) {
                    totalCoins++;
                }
            });
        });

        setMaze(newMaze);
        setRemainingCoins(totalCoins);
        setScore(0);
        resetCharactersToStart();
        setGameState('running');
    }, [resetCharactersToStart]);

    const handleSetDirection = useCallback((dir: Direction) => {
        if (gameState === 'running') {
            desiredDirectionRef.current = dir;
        }
    }, [gameState]);

    const gameLoop = useCallback(() => {
      gameTickRef.current++;
  
      // Player Movement (controlled by PLAYER_SPEED_DIVISOR)
      if (gameTickRef.current % PLAYER_SPEED_DIVISOR === 0) {
        setPlayer(p => {
            const getNextPosition = (pos: Position, dir: Direction) => {
                let newPos = { ...pos };
                if (dir === 'up') newPos.x--;
                if (dir === 'down') newPos.x++;
                if (dir === 'left') newPos.y--;
                if (dir === 'right') newPos.y++;
                return newPos;
            };

            let newDirection = p.direction;
            let nextPos = { ...p };
            
            // Try desired direction first
            if (desiredDirectionRef.current !== 'stop') {
                const desiredNextPos = getNextPosition(p, desiredDirectionRef.current);
                if (!isWall(desiredNextPos, maze)) {
                    nextPos = { ...p, ...desiredNextPos };
                    newDirection = desiredDirectionRef.current;
                }
            }
            
            // If desired direction not possible, continue current direction
            if (nextPos.x === p.x && nextPos.y === p.y && p.direction !== 'stop') {
                const currentNextPos = getNextPosition(p, p.direction);
                if (!isWall(currentNextPos, maze)) {
                    nextPos = { ...p, ...currentNextPos };
                } else {
                    newDirection = 'stop';
                }
            }
            
            // Handle tunnel wrapping
            const mazeWidth = maze[0].length;
            if (nextPos.y < 0) nextPos.y = mazeWidth - 1;
            if (nextPos.y >= mazeWidth) nextPos.y = 0;

            return { ...p, ...nextPos, direction: newDirection };
        });
      }
  
      // Ghost Movement (controlled by multiplier)
      if (gameTickRef.current % GHOST_SPEED_MULTIPLIER === 0) {
          setGhosts(gs => {
              const currentPlayerPos = playerRef.current;
              
              return gs.map(ghost => {
                  const getNextPosition = (pos: Position, dir: Direction): Position => {
                      const newPos = { ...pos };
                      if (dir === 'up') newPos.x--;
                      if (dir === 'down') newPos.x++;
                      if (dir === 'left') newPos.y--;
                      if (dir === 'right') newPos.y++;
                      return newPos;
                  };

                  if (ghost.isEaten) {
                    if(ghost.x === ghost.spawnPoint.x && ghost.y === ghost.spawnPoint.y) {
                      return {...ghost, isEaten: false, isFrightened: false }
                    }
                    // Pathfind back to spawn
                    const directions: Direction[] = ['up', 'down', 'left', 'right'];
                    let bestDir: Direction = 'stop';
                    let minDistance = Infinity;
                    for(const dir of directions) {
                      const nextPos = getNextPosition(ghost, dir);
                      if(!isWall(nextPos, maze)) {
                        const distance = Math.hypot(nextPos.x - ghost.spawnPoint.x, nextPos.y - ghost.spawnPoint.y);
                        if(distance < minDistance) {
                          minDistance = distance;
                          bestDir = dir;
                        }
                      }
                    }
                    return {...ghost, ...getNextPosition(ghost, bestDir), direction: bestDir};
                  }

                  const directions: Direction[] = ['up', 'down', 'left', 'right'];
                  const oppositeDirection: Record<Direction, Direction> = { 
                    'up': 'down', 'down': 'up', 'left': 'right', 'right': 'left', 'stop': 'stop' 
                  };

                  let possibleMoves = directions.filter(dir => {
                      const nextPos = getNextPosition(ghost, dir);
                      return !isWall(nextPos, maze) && dir !== oppositeDirection[ghost.direction];
                  });

                  if (possibleMoves.length === 0) {
                      possibleMoves = directions.filter(dir => !isWall(getNextPosition(ghost, dir), maze));
                      if (possibleMoves.length === 0) return ghost;
                  }
                  
                  let bestDir: Direction;

                  if (ghost.isFrightened) {
                      bestDir = possibleMoves[Math.floor(Math.random() * possibleMoves.length)];
                  } else {
                      let minDistance = Infinity;
                      bestDir = possibleMoves[0];
                      for (const dir of possibleMoves) {
                          const nextPos = getNextPosition(ghost, dir);
                          const distance = Math.hypot(nextPos.x - currentPlayerPos.x, nextPos.y - currentPlayerPos.y);
                          if (distance < minDistance) {
                              minDistance = distance;
                              bestDir = dir;
                          }
                      }
                  }

                  const finalNextPos = getNextPosition(ghost, bestDir);
                  return { ...ghost, ...finalNextPos, direction: bestDir };
              });
          });
      }
  }, [isWall, maze]);

    // Effect for collisions and game rules
    useEffect(() => {
        if (gameState !== 'running') return;

        const p = player;
        const cell = maze[p.x]?.[p.y];
        if (!cell) return;
          
        let eaten = false;

        if (cell.type === 2) { // Coin
            addScore(NORMAL_COIN_POINTS);
            eaten = true;
        } else if (cell.type === 9) { // Aarna Coin
            addScore(AARNA_COIN_POINTS);
            eaten = true;
            toast({ title: `+${AARNA_COIN_POINTS} Points!`, description: "You found the Aarna Coin!" });
        } else if (cell.type === 3) { // Power Pellet
            eaten = true;
            
            // Debounce frighten updates to prevent rapid state changes
            const now = Date.now();
            if (now - lastFrightenUpdateRef.current > 500) { // 500ms cooldown
                lastFrightenUpdateRef.current = now;
                
                // Batch ghost state update
                setGhosts(gs => gs.map(g => ({ ...g, isFrightened: true, isEaten: false })));
                
                clearTimeout(frightenedTimerRef.current);
                frightenedTimerRef.current = setTimeout(() => {
                    setGhosts(gs => gs.map(g => ({ ...g, isFrightened: false })));
                }, GHOST_FRIGHTENED_DURATION);
                
                // Single toast notification
                toast({ title: "Power Up!", description: "Ghosts are vulnerable!" });
            }
        }

        if (eaten) {
            setRemainingCoins(rc => rc - 1);
            setMaze(m => {
                const newMaze = m.map(r => r.slice());
                newMaze[p.x][p.y] = { type: 1 };
                return newMaze;
            });
        }
          
        // Ghost collision
        ghosts.forEach(ghost => {
            if (ghost.x === p.x && ghost.y === p.y) {
                if (ghost.isFrightened && !ghost.isEaten) {
                    addScore(GHOST_POINTS);
                    toast({ title: `+${GHOST_POINTS} Points!` });
                    setGhosts(gs => gs.map(g => g.id === ghost.id ? { ...g, isEaten: true } : g));
                } else if (!ghost.isEaten && !ghost.isFrightened) {
                    setGameState('lose');
                }
            }
        });

    }, [player, gameState, ghosts, maze, toast, addScore]);

    // Effect for win condition
    useEffect(() => {
        if (remainingCoins === 0 && gameState === 'running') {
            setGameState('win');
        }
    }, [remainingCoins, gameState]);

    // Main game loop interval
    useEffect(() => {
      let interval: NodeJS.Timeout;
      if (gameState === 'running') {
        interval = setInterval(gameLoop, GAME_SPEED);
      }
      return () => clearInterval(interval);
    }, [gameState, gameLoop]);

    return {
        gameState,
        setGameState,
        score,
        highScore,
        remainingCoins,
        maze,
        player,
        ghosts,
        handleStartGame,
        handleSetDirection
    };
};
