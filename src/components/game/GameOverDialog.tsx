
"use client"

import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog"
import type { Translations } from "@/lib/translations"

type GameOverDialogProps = {
  score: number;
  onBackToMenu: () => void;
  reason: string;
  runStats?: {
    kills: number;
    time: number;
    xp: number;
  } | null;
  t: Translations;
}

const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
}

export function GameOverDialog({ score, onBackToMenu, reason, runStats, t }: GameOverDialogProps) {
  return (
    <div className="absolute inset-0 bg-black/70 flex items-center justify-center rounded-lg z-10 animate-in fade-in-0 duration-500">
      <AlertDialog open={true}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle className="font-headline text-3xl text-primary">{runStats ? t.victory : t.gameOver}</AlertDialogTitle>
            <AlertDialogDescription className="text-base">
              {reason}
            </AlertDialogDescription>
            <AlertDialogDescription className="text-lg pt-2">
              {t.finalScore} <span className="font-bold text-accent">{score}</span>.
            </AlertDialogDescription>
            {runStats && (
                <div className="text-left text-sm text-muted-foreground pt-4 space-y-2 border-t mt-4">
                    <h4 className="font-bold text-base text-foreground">{t.runSummary}</h4>
                    <div className="flex justify-between"><span>{t.time}:</span> <span className="font-bold text-accent">{formatTime(runStats.time)}</span></div>
                    <div className="flex justify-between"><span>{t.goblinsSlain}:</span> <span className="font-bold text-accent">{runStats.kills}</span></div>
                    <div className="flex justify-between"><span>{t.xpEarned}:</span> <span className="font-bold text-accent">{runStats.xp}</span></div>
                </div>
            )}
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogAction onClick={onBackToMenu} className="w-full">
              {runStats ? t.playAgain : t.slayAgain}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
