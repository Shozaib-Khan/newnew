"use client";

import {
  AlertDialog,
  AlertDialogContent,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogDescription,
  AlertDialogFooter
} from '@/components/ui/alert-dialog';
import { Button } from '@/components/ui/button';
import { X } from 'lucide-react';
import type { GameState } from '@/lib/game-constants';

interface GameModalProps {
  gameState: GameState;
  score: number;
  highScore: number;
  onPlayAgain: () => void;
  onClose: () => void;
  playsLeft?: number; // Add this prop to check remaining plays
}

export const GameModal = ({ 
  gameState, 
  score, 
  highScore, 
  onPlayAgain, 
  onClose,
  playsLeft = 0
}: GameModalProps) => {
  const isOpen = gameState === 'win' || gameState === 'lose';
  const isNewHighScore = score > 0 && score === highScore;
  const hasReachedDailyLimit = playsLeft <= 0;

  // Helper function to format scores with max 1 decimal place
  const formatScore = (value: number) => {
    return Number(value.toFixed(1));
  };

  const messages = {
    win: {
      title: 'YOU WIN!',
      description: `Congratulations! You collected all the coins.`,
    },
    lose: {
      title: 'GAME OVER',
      description: 'The ghosts got you. Better luck next time!',
    },
  };

  if (!isOpen) return null;

  const { title, description } = messages[gameState as 'win' | 'lose'];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50" style={{ display: isOpen ? 'flex' : 'none' }}>
      <div className="relative bg-background border-2 border-border rounded-lg p-6 w-full max-w-md font-headline">
        {/* Close button */}
        <Button
          variant="ghost"
          size="icon"
          onClick={onClose}
          className="absolute right-4 top-4 opacity-70 hover:opacity-100 z-10 h-8 w-8"
        >
          <X className="h-4 w-4" />
          <span className="sr-only">Close</span>
        </Button>

        {/* Header */}
        <div className="pt-2">
          <h2 className="text-primary text-2xl text-center pr-10">
            {title}
          </h2>
          <p className="text-center text-sm text-foreground/80 pt-4">
            {description}
          </p>
          {isNewHighScore && (
            <p className="text-center text-primary text-lg animate-pulse pt-4">
              New High Score!
            </p>
          )}
          <p className="text-center text-xl pt-4 font-bold">
            Final Score: <span className="text-accent">{formatScore(score)}</span>
          </p>

          {/* Daily limit reached message */}
          {hasReachedDailyLimit && (
            <div className="text-center pt-6 border-t border-border mt-4">
              <p className="text-destructive text-lg font-bold">
                Daily Limit Reached
              </p>
              <p className="text-muted-foreground text-sm pt-2">
                Try again tomorrow!
              </p>
            </div>
          )}
        </div>
        
        {/* Footer */}
        <div className="mt-6">
          {hasReachedDailyLimit ? (
            <Button 
              onClick={onClose} 
              variant="ghost"
              className="w-full text-lg py-4 text-primary"
            >
              Close Game
            </Button>
          ) : (
            <Button 
              onClick={onPlayAgain} 
              variant="ghost"
              className="w-full text-lg py-4 text-primary animate-pulse"
            >
              Play Again
            </Button>
          )}
        </div>
      </div>
    </div>
  );
};
