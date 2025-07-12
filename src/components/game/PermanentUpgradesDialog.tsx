
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
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import type { Translations } from "@/lib/translations"
import { Sparkles } from "lucide-react"

export type PermanentUpgradeId =
  | 'maxHp'
  | 'baseDamage'
  | 'powerupFreq'
  | 'attackTimer'
  | 'xpBonus'
  | 'startGold'
  | 'overcrowdingResist'
  | 'unlockSword'
  | 'unlockTorch'
  | 'unlockShield'
  | 'unlockPoison'
  | 'unlockFireScroll'
  | 'unlockRope'
  | 'unlockHealthPotion';

export type PermanentUpgrade = {
  id: PermanentUpgradeId;
  cost: number;
  maxLevel: number;
};

export const PERMANENT_UPGRADES: PermanentUpgrade[] = [
  { id: 'maxHp', cost: 200, maxLevel: 4 },
  { id: 'baseDamage', cost: 500, maxLevel: 3 },
  { id: 'powerupFreq', cost: 400, maxLevel: 2 },
  { id: 'attackTimer', cost: 800, maxLevel: 2 },
  { id: 'xpBonus', cost: 1000, maxLevel: 1 },
  { id: 'startGold', cost: 600, maxLevel: 3 },
  { id: 'overcrowdingResist', cost: 700, maxLevel: 1 },
  { id: 'unlockSword', cost: 300, maxLevel: 1 },
  { id: 'unlockTorch', cost: 300, maxLevel: 1 },
  { id: 'unlockShield', cost: 300, maxLevel: 1 },
  { id: 'unlockHealthPotion', cost: 600, maxLevel: 1 },
  { id: 'unlockPoison', cost: 600, maxLevel: 1 },
  { id: 'unlockRope', cost: 600, maxLevel: 1 },
  { id: 'unlockFireScroll', cost: 1200, maxLevel: 1 },
];

type PermanentUpgradesDialogProps = {
  totalXp: number;
  upgrades: { [key in PermanentUpgradeId]?: number };
  onClose: () => void;
  onBuy: (id: PermanentUpgradeId, cost: number) => void;
  t: Translations;
};

export function PermanentUpgradesDialog({ totalXp, upgrades, onClose, onBuy, t }: PermanentUpgradesDialogProps) {
  const getUpgradeLevel = (id: PermanentUpgradeId) => upgrades[id] || 0;

  return (
    <div className="absolute inset-0 bg-black/70 flex items-center justify-center rounded-lg z-30 animate-in fade-in-0 duration-500">
      <AlertDialog open={true} onOpenChange={onClose}>
        <AlertDialogContent className="max-w-md">
          <AlertDialogHeader>
            <AlertDialogTitle className="font-headline text-3xl text-primary flex items-center gap-2">
              <Sparkles className="w-8 h-8"/> {t.permUpgradesTitle}
            </AlertDialogTitle>
            <AlertDialogDescription className="text-base flex justify-between">
              <span>{t.permUpgradesDesc}</span>
              <span className="font-bold text-accent">{t.totalXpLabel} {totalXp}</span>
            </AlertDialogDescription>
          </AlertDialogHeader>
          
          <Card className="border-none shadow-none -mx-2">
            <CardContent className="p-2 max-h-80 overflow-y-auto flex flex-col gap-2">
              {PERMANENT_UPGRADES.map(item => {
                const currentLevel = getUpgradeLevel(item.id);
                const isMaxLevel = currentLevel >= item.maxLevel;
                const isDisabled = totalXp < item.cost || isMaxLevel;

                const name = t[`${item.id}_name` as keyof Translations]
                const description = t[`${item.id}_desc` as keyof Translations]

                return (
                  <div key={item.id} className="flex justify-between items-center p-2 bg-background/50 rounded-lg border">
                    <div>
                      <h3 className="font-bold text-sm">{name}</h3>
                      <p className="text-xs text-muted-foreground">{description}</p>
                    </div>
                    <div className="flex flex-col items-end gap-1">
                      <Button 
                        onClick={() => onBuy(item.id, item.cost)}
                        disabled={isDisabled}
                        variant="secondary"
                        className="w-28 text-xs h-8"
                      >
                        {isMaxLevel ? t.maxLevel : `${item.cost} XP`}
                      </Button>
                      <p className="text-xs text-muted-foreground">
                        {t.level}: {currentLevel} / {item.maxLevel}
                      </p>
                    </div>
                  </div>
                );
              })}
            </CardContent>
          </Card>

          <AlertDialogFooter>
            <AlertDialogAction onClick={onClose} className="w-full">
              {t.close}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
