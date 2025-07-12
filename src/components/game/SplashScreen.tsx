"use client";

import { useState, useRef, useEffect } from 'react';
import { GoblinSwiperIcon } from '@/components/icons/GoblinSwiperIcon';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import type { GameMode, Language, LeaderboardEntry, PermanentUpgradesState, PermanentUpgradeId } from '@/app/page';
import { Sparkles, BookOpen, Volume2, VolumeX } from 'lucide-react';
import { HowToPlayDialog } from './HowToPlayDialog';
import type { Translations } from '@/lib/translations';
import { PermanentUpgradesDialog } from './PermanentUpgradesDialog';
import { LeaderboardDialog } from './LeaderboardDialog';

const MENU_MUSIC_FILE = '/music/menu-theme.mp3';

type SplashScreenProps = {
  onModeSelect: (mode: GameMode) => void;
  onOpenPermShop: () => void;
  onLanguageChange: (lang: Language) => void;
  language: Language;
  t: Translations;
  isMusicEnabled: boolean;
  onMusicToggle: () => void;
  isPermShopOpen: boolean;
  isLeaderboardOpen: boolean;
  onOpenLeaderboard: () => void;
  onCloseLeaderboard: () => void;
  leaderboard: LeaderboardEntry[];
  onClosePermShop: () => void;
  totalXp: number;
  upgrades: PermanentUpgradesState;
  onBuyPermanentUpgrade: (id: PermanentUpgradeId, cost: number) => void;
};

export function SplashScreen({ 
  onModeSelect, 
  onOpenPermShop, 
  onLanguageChange, 
  language, 
  t,
  isMusicEnabled,
  onMusicToggle,
  isPermShopOpen,
  isLeaderboardOpen,
  onOpenLeaderboard,
  onCloseLeaderboard,
  leaderboard,
  onClosePermShop,
  totalXp,
  upgrades,
  onBuyPermanentUpgrade
}: SplashScreenProps) {
  const [isHowToPlayOpen, setIsHowToPlayOpen] = useState(false);
  const menuAudioRef = useRef<HTMLAudioElement>(null);
  const [isMenuAudioReady, setIsMenuAudioReady] = useState(false);

  useEffect(() => {
    if (menuAudioRef.current && isMenuAudioReady) {
        menuAudioRef.current.volume = 0.7; // Set volume to 70%
        if (isMusicEnabled) {
            menuAudioRef.current.play().catch(error => console.error("Menu audio play failed:", error));
        } else {
            menuAudioRef.current.pause();
        }
    }
  }, [isMusicEnabled, isMenuAudioReady]);

  return (
    <>
      <main className="relative flex items-center justify-center min-h-screen bg-background p-4">
        <audio ref={menuAudioRef} src={MENU_MUSIC_FILE} loop onCanPlay={() => setIsMenuAudioReady(true)} />
        <div className="w-full max-w-sm">
          <Card className="text-center shadow-lg border-primary/50">
            <CardHeader>
              <div className="flex flex-col items-center gap-4">
                  <GoblinSwiperIcon className="w-16 h-16 text-primary" />
                  <CardTitle className="font-headline text-4xl text-primary">{t.splashTitle}</CardTitle>
              </div>
              <CardDescription className="text-base pt-2">
                {t.splashDescription}
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-4">
               <Button
                  onClick={() => onModeSelect('story')}
                  size="lg"
                  className="w-full"
                >
                  <div className="text-left w-full">
                      <p className="font-bold">{t.storyMode}</p>
                      <p className="text-xs font-normal">{t.storyModeDesc}</p>
                  </div>
              </Button>
              <Button
                  onClick={() => onModeSelect('endless')}
                  variant="secondary"
                  size="lg"
                  className="w-full"
              >
                  <div className="text-left w-full">
                      <p className="font-bold">{t.endlessMode}</p>
                      <p className="text-xs font-normal">{t.endlessModeDesc}</p>
                  </div>
              </Button>
            </CardContent>
            <CardFooter className="flex-col gap-2 pt-4">
              <Button onClick={() => setIsHowToPlayOpen(true)} variant="outline" className="w-full">
                <BookOpen className="mr-2 h-4 w-4" />
                {t.howToPlay}
              </Button>
              <Button onClick={onOpenPermShop} variant="outline" className="w-full">
                <Sparkles className="mr-2 h-4 w-4" />
                {t.upgradesAndProgress}
              </Button>
              <p className="text-xs text-muted-foreground mx-auto pt-2">
                {t.poweredBy}
              </p>
            </CardFooter>
          </Card>
        </div>
        <div className="absolute bottom-4 right-4 flex gap-2">
           <Button onClick={onMusicToggle} variant="outline" size="sm" className="w-10">
                {isMusicEnabled ? <Volume2 className="h-4 w-4" /> : <VolumeX className="h-4 w-4" />}
                <span className="sr-only">Toggle Music</span>
            </Button>
          <Button variant={language === 'en' ? 'default' : 'outline'} size="sm" onClick={() => onLanguageChange('en')}>EN</Button>
          <Button variant={language === 'es' ? 'default' : 'outline'} size="sm" onClick={() => onLanguageChange('es')}>ES</Button>
        </div>
      </main>
      <HowToPlayDialog isOpen={isHowToPlayOpen} onClose={() => setIsHowToPlayOpen(false)} t={t} />
      {isPermShopOpen && (
          <PermanentUpgradesDialog
            totalXp={totalXp}
            upgrades={upgrades}
            onClose={onClosePermShop}
            onBuy={onBuyPermanentUpgrade}
            t={t}
          />
        )}
        {isLeaderboardOpen && (
          <LeaderboardDialog 
            leaderboard={leaderboard}
            onClose={onCloseLeaderboard}
            t={t}
          />
        )}
    </>
  );
}
