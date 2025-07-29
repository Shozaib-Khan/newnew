"use client";

import { memo } from 'react';
import Image from 'next/image';
import { TILE_SIZE, type Position, type Ghost, type GameState, type Direction } from '@/lib/game-constants';
import { PlayerIcon } from '../icons/player-icon';
import { GhostIcon } from '../icons/ghost-icon';
import { PowerPelletIcon } from '../icons/collectible-icons';
import { cn } from '@/lib/utils';

interface GameBoardProps {
  maze: { type: number; coin?: string }[][];
  player: { x: number; y: number; direction: Direction };
  ghosts: Ghost[];
  gameState: GameState;
}

const renderCellContent = (cell: { type: number, coin?: string }, key: string) => {
  switch (cell.type) {
    case 2: // Coin
      if (cell.coin) {
        return <Image src={`/icons/${cell.coin}.ico`} alt={`${cell.coin} coin`} width={TILE_SIZE * 1.3} height={TILE_SIZE * 1.3} key={key} className="p-1" />;
      }
      return <div key={key} className="w-1.5 h-1.5 bg-primary/80 rounded-full" />;
    case 3: // Power Pellet
      return <PowerPelletIcon key={key} className="w-full h-full p-0.5 animate-pulse" />;
    case 9: // Aarna Coin
      return <Image src="/icons/aarna.ico" alt="Aarna coin" width={TILE_SIZE * 1.3} height={TILE_SIZE * 1.3} key={key} className="p-1" />;
    default:
      return null;
  }
};

export const GameBoard = memo(({ maze, player, ghosts, gameState }: GameBoardProps) => {
  return (
    <div
      className="border-2 border-border overflow-hidden"
      style={{
        display: 'grid',
        gridTemplateColumns: `repeat(${maze[0].length}, 1fr)`,
        gridTemplateRows: `repeat(${maze.length}, 1fr)`,
        position: 'relative',
      }}
    >
      {/* Maze rendering */}
      {maze.map((row, rowIndex) =>
        row.map((cell, colIndex) => {
          const isWall = cell.type === 0;
          return (
            <div
              key={`${rowIndex}-${colIndex}`}
              className={cn(
                'flex items-center justify-center',
                isWall ? 'bg-border' : ''
              )}
              style={{
                width: '100%',
                height: '100%',
              }}
            >
              {!isWall && renderCellContent(cell, `${rowIndex}-${colIndex}-content`)}
            </div>
          );
        })
      )}

      {gameState === 'running' && (
        <>
          {/* Player rendering with fast, smooth CSS transitions */}
          <PlayerIcon
            style={{
              position: 'absolute',
              width: TILE_SIZE,
              height: TILE_SIZE,
              top: `${(player.x / maze.length) * 100}%`,
              left: `${(player.y / maze[0].length) * 100}%`,
              transition: 'top 200ms linear, left 200ms linear', // Slightly slower transitions to match PLAYER_SPEED_DIVISOR
              zIndex: 10,
            }}
            direction={player.direction}
          />

          {/* Ghost rendering */}
          {ghosts.map((ghost) => (
            <GhostIcon
              key={ghost.id}
              ghost={ghost}
              style={{
                position: 'absolute',
                width: TILE_SIZE,
                height: TILE_SIZE,
                top: `${(ghost.x / maze.length) * 100}%`,
                left: `${(ghost.y / maze[0].length) * 100}%`,
                transition: 'top 150ms linear, left 150ms linear', // Slightly slower for ghosts
                zIndex: 5,
              }}
            />
          ))}
        </>
      )}
    </div>
  );
});

GameBoard.displayName = 'GameBoard';
