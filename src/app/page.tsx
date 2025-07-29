"use client";

import { useCallback, useEffect, useState } from "react";
import { GameBoard } from "@/components/game/game-board";
import { GameUI } from "@/components/game/game-ui";
import { GameModal } from "@/components/game/game-modal";
import { useGameEngine } from "@/hooks/use-game-engine";
import { useSwipe } from "@/hooks/use-swipe";
import { useIsMobile } from "@/hooks/use-mobile";
import { Button } from "@/components/ui/button";

const MAX_TRIES_PER_DAY = 34;
const STORAGE_KEY_COUNT = "coinChasePlays";
const STORAGE_KEY_DATE = "coinChaseLastPlay";

export default function Home() {
  const {
    gameState,
    setGameState,
    score,
    highScore,
    maze,
    player,
    ghosts,
    handleStartGame,
    handleSetDirection
  } = useGameEngine();

  const isMobile = useIsMobile();

  // Daily play-limit
  const [playsLeft, setPlaysLeft] = useState<number>(MAX_TRIES_PER_DAY);

  const refreshPlayState = useCallback(() => {
    const last = localStorage.getItem(STORAGE_KEY_DATE);
    const count = parseInt(localStorage.getItem(STORAGE_KEY_COUNT) || "0", 10);

    if (!last || Date.now() - parseInt(last, 10) > 24 * 60 * 60 * 1000) {
      // New day
      localStorage.setItem(STORAGE_KEY_DATE, Date.now().toString());
      localStorage.setItem(STORAGE_KEY_COUNT, "0");
      setPlaysLeft(MAX_TRIES_PER_DAY);
    } else {
      setPlaysLeft(Math.max(0, MAX_TRIES_PER_DAY - count));
    }
  }, []);

  useEffect(refreshPlayState, [refreshPlayState]);

  const startGameIfAllowed = () => {
    if (playsLeft <= 0) return;
    // Increment stored counter
    const newCount = MAX_TRIES_PER_DAY - playsLeft + 1;
    localStorage.setItem(STORAGE_KEY_COUNT, newCount.toString());
    handleStartGame();
    setPlaysLeft(playsLeft - 1);
  };

  // Keyboard + swipe controls
  useEffect(() => {
    if (isMobile) return;

    const down = (e: KeyboardEvent) => {
      switch (e.key) {
        case "ArrowUp":
          handleSetDirection("up");
          break;
        case "ArrowDown":
          handleSetDirection("down");
          break;
        case "ArrowLeft":
          handleSetDirection("left");
          break;
        case "ArrowRight":
          handleSetDirection("right");
          break;
      }
    };
    window.addEventListener("keydown", down);
    return () => window.removeEventListener("keydown", down);
  }, [handleSetDirection, isMobile]);

  const swipeHandlers = useSwipe({
    onSwipedLeft: () => handleSetDirection("left"),
    onSwipedRight: () => handleSetDirection("right"),
    onSwipedUp: () => handleSetDirection("up"),
    onSwipedDown: () => handleSetDirection("down")
  });

  // Modal close
  const handleCloseModal = useCallback(() => {
    setGameState('pre-game');
    refreshPlayState(); // Re-evaluate remaining tries
  }, [setGameState, refreshPlayState]);

  return (
    <main
      {...swipeHandlers}
      className="flex min-h-screen w-full flex-col items-center justify-center bg-background p-2 sm:p-4 touch-none"
    >
      <h1 className="text-3xl sm:text-4xl font-headline text-primary mb-4 text-center">
        Coin Chase
      </h1>

      <GameUI score={score} highScore={highScore} playsLeft={playsLeft} />

      <div className="relative w-full max-w-lg aspect-[21/22] sm:max-w-xl mt-4">
        <GameBoard maze={maze} player={player} ghosts={ghosts} gameState={gameState} />

        {gameState === "pre-game" && (
          <div className="absolute inset-0 flex items-center justify-center bg-black/50">
            <Button
              onClick={startGameIfAllowed}
              variant="ghost"
              disabled={playsLeft <= 0}
              className="text-primary text-2xl animate-pulse disabled:opacity-40"
            >
              {playsLeft > 0 ? "Start Game" : "Daily Limit Reached"}
            </Button>
          </div>
        )}
      </div>

      <GameModal
        gameState={gameState}
        score={score}
        highScore={highScore}
        onPlayAgain={startGameIfAllowed}
        onClose={handleCloseModal}
        playsLeft={playsLeft}
      />
    </main>
  );
}
