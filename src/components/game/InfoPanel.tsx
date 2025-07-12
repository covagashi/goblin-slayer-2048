
"use client"

import { Card, CardContent } from "@/components/ui/card"
import { Trophy, Coins, Heart, Star, Sparkles, Zap, Crosshair } from "lucide-react"
import { Progress } from "@/components/ui/progress"
import type { GameMode } from "@/app/page"
import type { Translations } from "@/lib/translations"

type InfoPanelProps = {
  score: number;
  gold: number;
  playerHP: number;
  maxPlayerHP: number;
  movesUntilAttack: number;
  level: number;
  killsToNextLevel: number;
  totalXp: number;
  gameMode: GameMode;
  t: Translations;
}

export function InfoPanel({ score, gold, playerHP, maxPlayerHP, movesUntilAttack, level, killsToNextLevel, totalXp, gameMode, t }: InfoPanelProps) {
  const hpPercentage = maxPlayerHP > 0 ? (playerHP / maxPlayerHP) * 100 : 0;

  return (
    <div className="flex flex-col gap-3 rounded-lg bg-card p-3 shadow-lg border">
      {/* Player HP */}
      <div className="flex items-center gap-3">
        <Heart className="w-5 h-5 text-primary shrink-0" />
        <div className="w-full">
            <Progress value={hpPercentage} className="h-2.5" />
        </div>
        <div className="font-bold text-sm text-primary w-20 text-right shrink-0">{playerHP} / {maxPlayerHP}</div>
      </div>
      
      {/* Main Stats */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-sm text-center">
          <div className="flex items-center justify-center gap-1.5 p-1.5 bg-background/50 rounded-md" title={t.score}>
            <Trophy className="w-4 h-4 text-accent" />
            <span className="font-bold">{score}</span>
          </div>
          <div className="flex items-center justify-center gap-1.5 p-1.5 bg-background/50 rounded-md" title={t.gold}>
            <Coins className="w-4 h-4 text-accent" />
            <span className="font-bold">{gold}</span>
          </div>
          <div className="flex items-center justify-center gap-1.5 p-1.5 bg-background/50 rounded-md" title={t.level}>
            <Star className="w-4 h-4 text-accent" />
            <span className="font-bold">{level}</span>
          </div>
          <div className="flex items-center justify-center gap-1.5 p-1.5 bg-background/50 rounded-md" title={t.totalXp}>
            <Sparkles className="w-4 h-4 text-accent" />
            <span className="font-bold">{totalXp}</span>
          </div>
      </div>
      
      {/* Level Progress & Horde Attack Timer */}
      <div className="grid grid-cols-2 gap-2 text-sm text-center">
        <div className="flex items-center justify-center gap-1.5 p-1.5 bg-background/50 rounded-md" title="Kills to next level">
            <Crosshair className="w-4 h-4 text-accent" />
            <span className="font-bold">{killsToNextLevel} {t.killsToLevel}</span>
        </div>
        <div className="flex items-center justify-center gap-1.5 p-1.5 bg-background/50 rounded-md" title="Moves until horde attack">
            <Zap className="w-4 h-4 text-accent" />
            <span className="font-bold">{movesUntilAttack} {t.movesUntilAttack}</span>
        </div>
      </div>
    </div>
  )
}
