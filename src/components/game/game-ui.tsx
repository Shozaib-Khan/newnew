"use client";

interface GameUIProps {
  score: number;
  highScore: number;
  playsLeft?: number; // Add this prop for daily lives
}

export const GameUI = ({ score, highScore, playsLeft = 3 }: GameUIProps) => {
  // Helper function to format scores with max 1 decimal place
  const formatScore = (value: number) => {
    return Number(value.toFixed(1));
  };

  return (
    <div className="w-full max-w-lg sm:max-w-xl">
      {/* Main score display - centered */}
      <div className="flex justify-center items-center gap-8 text-primary font-headline text-base mb-4">
        <div className="text-center">
          <span className="uppercase text-muted-foreground text-xs sm:text-sm block text-white">Current Round</span>
          <p className="font-bold text-lg sm:text-xl text-primary">{formatScore(score)}</p>
        </div>
        <div className="text-center">
          <span className="uppercase text-muted-foreground text-xs sm:text-sm text-white block">Total Points</span>
          <p className="font-bold text-lg sm:text-xl text-primary">{formatScore(highScore)}</p>
        </div>
      </div>
      
      {/* Daily lives counter - centered */}
      <div className="flex justify-center items-center">
        <div className="text-center bg-background/20 rounded-lg px-4 py-2 border border-border">
          <span className="uppercase text-muted-foreground text-xs block text-white">Daily Lives</span>
          <p className="font-bold text-sm text-primary">{playsLeft}/3</p>
        </div>
      </div>
    </div>
  );
};
