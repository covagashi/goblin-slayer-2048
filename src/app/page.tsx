
"use client";

import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { GameBoard } from '@/components/game/GameBoard';
import { InfoPanel } from '@/components/game/InfoPanel';
import { Abilities } from '@/components/game/Abilities';
import { GoblinSwiperIcon } from '@/components/icons/GoblinSwiperIcon';
import { Button } from '@/components/ui/button';
import { GameOverDialog } from '@/components/game/GameOverDialog';
import { useToast } from "@/hooks/use-toast";
import { SplashScreen } from '@/components/game/SplashScreen';
import { ShopDialog } from '@/components/game/ShopDialog';
import { Menu, Trophy, Volume2, VolumeX } from 'lucide-react';
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger, SheetDescription } from "@/components/ui/sheet";
import { PermanentUpgradesDialog, PERMANENT_UPGRADES, type PermanentUpgradeId } from '@/components/game/PermanentUpgradesDialog';
import { LeaderboardDialog, type LeaderboardEntry } from '@/components/game/LeaderboardDialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { translations, formatString, type Translations } from '@/lib/translations';

const GRID_SIZE = 4;
const GAME_MUSIC_FILE = '/music/background-theme.mp3';

export type TileData = {
  id: number;
  value: number;
  hp: number;
  maxHp: number;
  type?: 'goblin' | 'chest' | 'shop';
  poisoned?: number;
};

export type Grid = (TileData | null)[][];
export type GameMode = 'story' | 'endless';
export type Language = 'en' | 'es';

export type PermanentUpgradesState = {
  [key in PermanentUpgradeId]?: number;
};

const DEFAULT_PERMANENT_UPGRADES: PermanentUpgradesState = {
  maxHp: 0,
  baseDamage: 0,
  powerupFreq: 0,
  attackTimer: 0,
  xpBonus: 0,
  startGold: 0,
  overcrowdingResist: 0,
  unlockSword: 0,
  unlockTorch: 0,
  unlockShield: 0,
  unlockPoison: 0,
  unlockFireScroll: 0,
  unlockRope: 0,
  unlockHealthPotion: 0,
};

const GOBLIN_STATS: { [key: number]: { hp: number; gold: number; damage: number } } = {
  2: { hp: 1, gold: 2, damage: 1 },
  4: { hp: 2, gold: 4, damage: 1 },
  8: { hp: 4, gold: 8, damage: 2 },
  16: { hp: 8, gold: 15, damage: 2 },
  32: { hp: 15, gold: 25, damage: 3 },
  64: { hp: 25, gold: 40, damage: 3 },
  128: { hp: 40, gold: 60, damage: 4 },
  256: { hp: 60, gold: 100, damage: 4 },
};

const GOBLIN_XP: { [key: number]: number } = {
  2: 1,
  4: 3,
  8: 8,
  16: 20,
  32: 50,
  64: 125,
  128: 300,
  256: 750,
};

export const allShopItems: {
  id: string;
  cost: number;
  spriteUrl: string;
  dataAiHint: string;
  isUnique: boolean;
}[] = [
  { id: "healthPotion", cost: 60, spriteUrl: "/sprites/item-health-potion.png", dataAiHint: "health potion", isUnique: false },
  { id: "torch", cost: 50, spriteUrl: "/sprites/item-torch.png", dataAiHint: "torch", isUnique: true },
  { id: "sword", cost: 120, spriteUrl: "/sprites/item-sword.png", dataAiHint: "sword", isUnique: true },
  { id: "shield", cost: 150, spriteUrl: "/sprites/item-shield.png", dataAiHint: "shield", isUnique: true },
  { id: "poison", cost: 180, spriteUrl: "/sprites/item-poison.png", dataAiHint: "poison flask", isUnique: true },
  { id: "rope", cost: 200, spriteUrl: "/sprites/item-rope.png", dataAiHint: "rope", isUnique: false },
  { id: "fireScroll", cost: 250, spriteUrl: "/sprites/item-fire-scroll.png", dataAiHint: "fire scroll", isUnique: true },
];

export type ShopItem = (typeof allShopItems)[number];

const INITIAL_PLAYER_HP = 20;
const INITIAL_GOLD = 10;
const COMBINE_BASE_DAMAGE = 2;
const OVERCROWDING_DAMAGE = 1;
const CHEST_SPAWN_CHANCE = 0.05;
const POWERUP_DROP_CHANCE = 0.15;
const CHEST_GOLD_REWARD = 20;
const DROP_GOLD_REWARD = 10;
const MILESTONE_REWARDS: { [key: number]: number } = {
  32: 50,
  128: 200,
};

const createEmptyGrid = (): Grid => Array(GRID_SIZE).fill(null).map(() => Array(GRID_SIZE).fill(null));

const getHpBonus = (level: number, gameMode: GameMode): number => {
    if (gameMode !== 'endless') return 0;
    if (level >= 21) return 4;
    if (level >= 16) return 3;
    if (level >= 11) return 2;
    if (level >= 6) return 1;
    return 0;
};

const getMovesPerAttack = (level: number, gameMode: GameMode, upgrades: PermanentUpgradesState): number => {
    let baseMoves: number;
    if (gameMode === 'story') {
        const base = 15;
        return base + ((upgrades.attackTimer || 0) * 2);
    } else { // endless
        if (level >= 21) baseMoves = 11;
        else if (level >= 16) baseMoves = 12;
        else if (level >= 11) baseMoves = 13;
        else if (level >= 6) baseMoves = 14;
        else baseMoves = 15;
        return baseMoves + ((upgrades.attackTimer || 0) * 2);
    }
};

const getSpawnConfig = (level: number): { value: number, weight: number }[] => {
    if (level >= 16) return [ { value: 2, weight: 0.30 }, { value: 4, weight: 0.30 }, { value: 8, weight: 0.25 }, { value: 16, weight: 0.10 }, { value: 32, weight: 0.05 }];
    if (level >= 11) return [ { value: 2, weight: 0.50 }, { value: 4, weight: 0.30 }, { value: 8, weight: 0.15 }, { value: 16, weight: 0.05 }];
    if (level >= 6) return [ { value: 2, weight: 0.70 }, { value: 4, weight: 0.25 }, { value: 8, weight: 0.05 }];
    return [{ value: 2, weight: 0.85 }, { value: 4, weight: 0.15 }];
};

const getNewTileValue = (level: number): number => {
    const config = getSpawnConfig(level);
    const totalWeight = config.reduce((sum, item) => sum + item.weight, 0);
    let random = Math.random() * totalWeight;

    for (const item of config) {
        if (random < item.weight) {
            return item.value;
        }
        random -= item.weight;
    }
    return 2;
};

const getGoblinStats = (value: number, level: number, gameMode: GameMode) => {
  const baseStats = GOBLIN_STATS[value] || { hp: 1, gold: 1, damage: 1 };
  const hpBonus = getHpBonus(level, gameMode);
  const finalHp = baseStats.hp + hpBonus;
  return {
    ...baseStats,
    hp: finalHp,
    maxHp: finalHp
  };
};

const getEmptyCells = (currentGrid: Grid): [number, number][] => {
  const cells: [number, number][] = [];
  for (let r = 0; r < GRID_SIZE; r++) {
    for (let c = 0; c < GRID_SIZE; c++) {
      if (currentGrid[r][c] === null) {
        cells.push([r, c]);
      }
    }
  }
  return cells;
};

const isBoardLocked = (grid: Grid): boolean => {
  if (getEmptyCells(grid).length > 0) return false;

  for (let r = 0; r < GRID_SIZE; r++) {
    for (let c = 0; c < GRID_SIZE; c++) {
      const tile = grid[r][c];
      if (!tile) continue;

      if (c < GRID_SIZE - 1) {
        const rightTile = grid[r][c+1];
        if (!rightTile || (rightTile.type === 'goblin' && tile.type === 'goblin' && rightTile.value === tile.value && tile.value < 256)) return false;
      }
      
      if (r < GRID_SIZE - 1) {
        const downTile = grid[r+1][c];
        if (!downTile || (downTile.type === 'goblin' && tile.type === 'goblin' && downTile.value === tile.value && tile.value < 256)) return false;
      }
    }
  }
  return true;
};

const calculateHordeDamage = (currentGrid: Grid, level: number, gameMode: GameMode): number => {
    let totalDamage = 0;
    for (const row of currentGrid) {
      for (const tile of row) {
        if (tile && tile.type === 'goblin') {
          totalDamage += getGoblinStats(tile.value, level, gameMode).damage;
        }
      }
    }
    return Math.min(totalDamage, 8);
}

const transpose = (grid: Grid): Grid => grid[0].map((_, colIndex) => grid.map(row => row[colIndex]));
const reverse = (grid: Grid): Grid => grid.map(row => [...row].reverse());

const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
}

export default function Home() {
  const [gameState, setGameState] = useState<'splash' | 'playing' | 'shop'>('splash');
  const [gameMode, setGameMode] = useState<GameMode>('story');
  const [language, setLanguage] = useState<Language>('es');
  const [grid, setGrid] = useState<Grid>(createEmptyGrid());
  const [score, setScore] = useState(0);
  const [gold, setGold] = useState(INITIAL_GOLD);
  const [playerHP, setPlayerHP] = useState(INITIAL_PLAYER_HP);
  const [maxPlayerHP, setMaxPlayerHP] = useState(INITIAL_PLAYER_HP);
  const [movesCount, setMovesCount] = useState(0);
  const [level, setLevel] = useState(1);
  const [kills, setKills] = useState(0);
  const [killsSinceLastLevel, setKillsSinceLastLevel] = useState(0);
  const [totalXp, setTotalXp] = useState(0);
  const [runXp, setRunXp] = useState(0);
  const [eventLog, setEventLog] = useState<string[]>([]);
  const [isGameOver, setIsGameOver] = useState(false);
  const [gameOverReason, setGameOverReason] = useState("");
  const [milestonesReached, setMilestonesReached] = useState(new Set<number>());
  const [purchasedItems, setPurchasedItems] = useState<string[]>([]);
  const [shopItems, setShopItems] = useState<ShopItem[]>([]);
  const [finalRunStats, setFinalRunStats] = useState<{kills: number; time: number; xp: number} | null>(null);
  const [activeShopTile, setActiveShopTile] = useState<{ r: number; c: number } | null>(null);
  const [shopPurchaseMade, setShopPurchaseMade] = useState(false);

  // Power-up states
  const [damageBonus, setDamageBonus] = useState(0);
  const [damageReduction, setDamageReduction] = useState(0);
  const [isTorchActive, setIsTorchActive] = useState(false);
  const [isPoisonActive, setIsPoisonActive] = useState(false);
  const [isFireScrollActive, setIsFireScrollActive] = useState(false);
  const [ropeCount, setRopeCount] = useState(0);
  const [isRopeModeActive, setIsRopeModeActive] = useState(false);
  const [selectedTileForRope, setSelectedTileForRope] = useState<{ r: number; c: number } | null>(null);

  // Permanent Upgrades
  const [permanentUpgrades, setPermanentUpgrades] = useState<PermanentUpgradesState>(DEFAULT_PERMANENT_UPGRADES);
  const [isPermShopOpen, setIsPermShopOpen] = useState(false);

  // Leaderboard
  const [leaderboard, setLeaderboard] = useState<LeaderboardEntry[]>([]);
  const [isLeaderboardOpen, setIsLeaderboardOpen] = useState(false);
  const [startTime, setStartTime] = useState<number | null>(null);

  // Audio
  const [isMusicEnabled, setIsMusicEnabled] = useState(true);
  const gameAudioRef = useRef<HTMLAudioElement>(null);
  const [isGameAudioReady, setIsGameAudioReady] = useState(false);

  const tileIdCounter = useRef(0);
  const { toast } = useToast();

  const prevGameStateRef = useRef<string>();
  useEffect(() => {
    prevGameStateRef.current = gameState;
  });
  const prevGameState = prevGameStateRef.current;
  
  const t = useMemo(() => translations[language], [language]);

  const logEvent = useCallback((message: string) => {
    setEventLog(prev => [message, ...prev].slice(0, 50));
  }, []);
  
  const addNewTile = useCallback((currentGrid: Grid, currentLevel: number): Grid => {
    const newGrid = currentGrid.map(row => row ? [...row] : []);
    const emptyCells = getEmptyCells(newGrid);
    if (emptyCells.length === 0) return newGrid;

    const [r, c] = emptyCells[Math.floor(Math.random() * emptyCells.length)];
    const isChest = Math.random() < CHEST_SPAWN_CHANCE;
    
    if (isChest) {
      newGrid[r][c] = {
        id: tileIdCounter.current++,
        type: 'chest',
        value: 0,
        hp: 1,
        maxHp: 1,
      };
      logEvent(t.log_chest_appeared);
    } else {
      const value = getNewTileValue(currentLevel);
      const stats = getGoblinStats(value, currentLevel, gameMode);
      
      newGrid[r][c] = {
        id: tileIdCounter.current++,
        type: 'goblin',
        value,
        hp: stats.hp,
        maxHp: stats.maxHp,
      };
      logEvent(formatString(t.log_new_goblin, { value }));
    }

    return newGrid;
  }, [logEvent, gameMode, t]);

  const resetGame = useCallback(() => {
    tileIdCounter.current = 0;
    let newGrid = createEmptyGrid();
    newGrid = addNewTile(newGrid, 1);
    newGrid = addNewTile(newGrid, 1);
    setGrid(newGrid);
    setScore(0);
    setRunXp(0);
    setStartTime(Date.now());
    
    const startingGold = INITIAL_GOLD + (permanentUpgrades.startGold || 0) * 100;
    setGold(startingGold);
    
    const startingHp = INITIAL_PLAYER_HP + (permanentUpgrades.maxHp || 0) * 5;
    setPlayerHP(startingHp);
    setMaxPlayerHP(startingHp);
    
    setMovesCount(0);
    setLevel(1);
    setKills(0);
    setKillsSinceLastLevel(0);
    setMilestonesReached(new Set());
    setPurchasedItems([]);
    setShopItems([]);
    setIsGameOver(false);
    setGameOverReason("");
    setFinalRunStats(null);
    setActiveShopTile(null);
    setShopPurchaseMade(false);

    // Reset power-ups
    setDamageBonus(0);
    setDamageReduction(0);
    setIsTorchActive(false);
    setIsPoisonActive(false);
    setIsFireScrollActive(false);
    setRopeCount(0);
    setIsRopeModeActive(false);
    setSelectedTileForRope(null);

    setEventLog([formatString(t.log_game_start, { gameMode })]);
  }, [addNewTile, gameMode, permanentUpgrades, t]);
  
  useEffect(() => {
    if (gameState === 'playing' && prevGameState === 'splash') {
        resetGame();
    }
  }, [gameState, prevGameState, resetGame]);

  useEffect(() => {
    try {
      const storedXp = localStorage.getItem('goblinSwiperTotalXp');
      if (storedXp) {
        setTotalXp(parseInt(storedXp, 10));
      }
      const storedUpgrades = localStorage.getItem('goblinSwiperPermanentUpgrades');
      if (storedUpgrades) {
        setPermanentUpgrades(JSON.parse(storedUpgrades));
      }
      const storedLeaderboard = localStorage.getItem('goblinSwiperLeaderboard');
      if (storedLeaderboard) {
        setLeaderboard(JSON.parse(storedLeaderboard));
      }
      const storedLanguage = localStorage.getItem('goblinSwiperLanguage');
      if (storedLanguage && (storedLanguage === 'en' || storedLanguage === 'es')) {
        setLanguage(storedLanguage as Language);
      }
      const storedMusic = localStorage.getItem('goblinSwiperMusic');
      if (storedMusic) {
        setIsMusicEnabled(JSON.parse(storedMusic));
      }
    } catch (error) {
      console.error("Failed to load data from localStorage", error);
    }
  }, []);

  useEffect(() => {
    if (gameAudioRef.current && isGameAudioReady) {
        if (isMusicEnabled && (gameState === 'playing' || gameState === 'shop')) {
            gameAudioRef.current.play().catch(error => console.error("Game audio play failed:", error));
        } else {
            gameAudioRef.current.pause();
        }
    }
  }, [isMusicEnabled, gameState, isGameAudioReady]);

  useEffect(() => {
    try {
      localStorage.setItem('goblinSwiperTotalXp', totalXp.toString());
    } catch (error) {
      console.error("Failed to save XP to localStorage", error);
    }
  }, [totalXp]);

  useEffect(() => {
    try {
      localStorage.setItem('goblinSwiperLanguage', language);
    } catch (error) {
      console.error("Failed to save language to localStorage", error);
    }
  }, [language]);
  
  const checkGameOver = useCallback((reason: string) => {
      setGameOverReason(reason);
      logEvent(reason);
      setIsGameOver(true);
  }, [logEvent]);

  const spawnShopTile = (currentGrid: Grid): Grid => {
      const newGrid = currentGrid.map(row => row ? [...row] : []);
      const emptyCells = getEmptyCells(newGrid);
      if (emptyCells.length === 0) {
          logEvent(t.log_no_room_for_shop);
          return newGrid;
      }
      const [r, c] = emptyCells[Math.floor(Math.random() * emptyCells.length)];
      newGrid[r][c] = {
        id: tileIdCounter.current++,
        type: 'shop',
        value: 0,
        hp: 1,
        maxHp: 1
      };
      logEvent(t.log_shop_appeared);
      return newGrid;
    }

  const removeShopTile = useCallback((currentGrid: Grid): { grid: Grid, shopRemoved: boolean } => {
      let shopRemoved = false;
      const newGrid = currentGrid.map(row => row.map(tile => {
          if (tile && tile.type === 'shop') {
              shopRemoved = true;
              return null;
          }
          return tile;
      }));
      if (shopRemoved) {
          logEvent(t.log_shop_disappeared);
      }
      return { grid: newGrid, shopRemoved };
  }, [logEvent, t]);
  
  const slideAndCombine = (row: (TileData | null)[], currentLevel: number): { newRow: (TileData | null)[], points: number, earnedGold: number, slainGoblins: number, mergeIndices: number[], earnedXp: number, gameWon: boolean, levelsGained: {level: number, value: number}[], chestOpened: boolean } => {
    const filteredRow = row.filter(tile => tile !== null) as TileData[];
    const newArr: (TileData | null)[] = [];
    let points = 0;
    let earnedGold = 0;
    let slainGoblins = 0;
    let earnedXp = 0;
    let gameWon = false;
    let skip = false;
    let mergeIndices: number[] = [];
    let levelsGained: {level: number, value: number}[] = [];
    let chestOpened = false;
    const xpMultiplier = (permanentUpgrades.xpBonus || 0) > 0 ? 1.25 : 1;
    const effectiveDropChance = POWERUP_DROP_CHANCE + (permanentUpgrades.powerupFreq || 0) * 0.15;

    for (let i = 0; i < filteredRow.length; i++) {
      if (skip) {
        skip = false;
        continue;
      }
      const currentTile = filteredRow[i];
      const nextTile = filteredRow[i+1];

      if (currentTile.type === 'chest' || currentTile.type === 'shop') {
        newArr.push(currentTile);
        continue;
      }

      if (nextTile && nextTile.type === 'chest') {
        earnedGold += CHEST_GOLD_REWARD;
        logEvent(formatString(t.log_chest_opened, { gold: CHEST_GOLD_REWARD }));
        newArr.push(currentTile);
        skip = true;
        chestOpened = true;
      } else if (nextTile && nextTile.type === 'goblin' && currentTile.value === nextTile.value && currentTile.value < 256) {
        const newValue = currentTile.value * 2;
        
        let newLevels = 0;
        switch(newValue) {
          case 8: newLevels = 1; break;
          case 16: newLevels = 2; break;
          case 32: newLevels = 3; break;
        }
        if (newLevels > 0) {
          levelsGained.push({level: newLevels, value: newValue});
        }
        
        if (gameMode === 'story' && newValue === 256) {
          gameWon = true;
        }

        const newStats = getGoblinStats(newValue, currentLevel, gameMode);
        let totalDamage = COMBINE_BASE_DAMAGE + damageBonus + (permanentUpgrades.baseDamage || 0);

        if (newValue >= 8) {
          totalDamage = Math.min(totalDamage, newStats.hp - 1);
        }
        
        let newHp = newStats.hp - totalDamage;

        logEvent(formatString(t.log_goblin_combine_damage, { value: currentTile.value, damage: totalDamage }));
        
        mergeIndices.push(newArr.length);

        if (newHp <= 0) {
          points += newValue;
          earnedGold += newStats.gold;
          earnedXp += Math.round((GOBLIN_XP[newValue] || 0) * xpMultiplier);
          slainGoblins++;
          logEvent(formatString(t.log_goblin_slain, { value: newValue, score: newValue, gold: newStats.gold }));

          if (Math.random() < effectiveDropChance) {
            const dropGold = DROP_GOLD_REWARD;
            earnedGold += dropGold;
            logEvent(formatString(t.log_goblin_drop, { gold: dropGold }));
          }
        } else {
          const newGoblin: TileData = {
            id: tileIdCounter.current++,
            type: 'goblin',
            value: newValue,
            hp: newHp,
            maxHp: newStats.maxHp
          };

          if (isPoisonActive) {
            newGoblin.poisoned = 3;
            logEvent(formatString(t.log_goblin_poisoned, { value: newValue }));
          }

          newArr.push(newGoblin);
          points += newValue / 2;
          logEvent(formatString(t.log_goblin_survived, { value: newValue, hp: newHp }));
        }

        if (MILESTONE_REWARDS[newValue] && !milestonesReached.has(newValue)) {
            const rewardGold = MILESTONE_REWARDS[newValue];
            earnedGold += rewardGold;
            setMilestonesReached(prev => new Set(prev).add(newValue));
            logEvent(formatString(t.log_milestone, { value: newValue, gold: rewardGold }));
        }

        skip = true;
      } else {
        newArr.push(currentTile);
      }
    }
    
    return {
      newRow: [...newArr, ...Array(row.length - newArr.length).fill(null)],
      points,
      earnedGold,
      slainGoblins,
      mergeIndices,
      earnedXp,
      gameWon,
      levelsGained,
      chestOpened,
    };
  };

  const applyPoisonDamage = useCallback((currentGrid: Grid): { newGrid: Grid; kills: number; gold: number; score: number; xp: number } => {
      const newGrid = currentGrid.map(row => row.map(tile => tile ? {...tile} : null));
      let kills = 0;
      let gold = 0;
      let score = 0;
      let xp = 0;
      const xpMultiplier = (permanentUpgrades.xpBonus || 0) > 0 ? 1.25 : 1;

      for(let r = 0; r < GRID_SIZE; r++) {
          for(let c = 0; c < GRID_SIZE; c++) {
              const tile = newGrid[r][c];
              if (tile && tile.type === 'goblin' && tile.poisoned && tile.poisoned > 0) {
                  tile.hp -= 1;
                  tile.poisoned -= 1;
                  logEvent(formatString(t.log_poison_damage, { value: tile.value }));
                  if (tile.hp <= 0) {
                      const stats = getGoblinStats(tile.value, level, gameMode);
                      kills++;
                      gold += stats.gold;
                      score += tile.value;
                      xp += Math.round((GOBLIN_XP[tile.value] || 0) * xpMultiplier);
                      logEvent(formatString(t.log_poison_death, { value: tile.value }));
                      newGrid[r][c] = null;
                  }
              }
          }
      }
      return { newGrid, kills, gold, score, xp };
  }, [level, logEvent, gameMode, permanentUpgrades.xpBonus, t]);

  const applyFireScrollDamage = useCallback((currentGrid: Grid, mergeCoords: {r: number, c: number}[]): { newGrid: Grid; kills: number; gold: number; score: number; xp: number } => {
    const newGrid = currentGrid.map(row => row.map(tile => tile ? {...tile} : null));
    let kills = 0;
    let gold = 0;
    let score = 0;
    let xp = 0;
    const xpMultiplier = (permanentUpgrades.xpBonus || 0) > 0 ? 1.25 : 1;
    
    if (!isFireScrollActive) return { newGrid, kills, gold, score, xp };

    logEvent(t.log_fire_scroll_trigger);

    for (const coord of mergeCoords) {
      for(let dr = -1; dr <= 1; dr++) {
        for(let dc = -1; dc <= 1; dc++) {
          const r = coord.r + dr;
          const c = coord.c + dc;
          
          if (r >= 0 && r < GRID_SIZE && c >= 0 && c < GRID_SIZE) {
            const tile = newGrid[r][c];
            if (tile && tile.type === 'goblin') {
              tile.hp -= 1;
              logEvent(formatString(t.log_splash_damage, { value: tile.value }));
              if (tile.hp <= 0) {
                const stats = getGoblinStats(tile.value, level, gameMode);
                kills++;
                gold += stats.gold;
                score += tile.value;
                xp += Math.round((GOBLIN_XP[tile.value] || 0) * xpMultiplier);
                logEvent(formatString(t.log_splash_death, { value: tile.value }));
                newGrid[r][c] = null;
              }
            }
          }
        }
      }
    }
    return { newGrid, kills, gold, score, xp };
  }, [isFireScrollActive, level, logEvent, gameMode, permanentUpgrades.xpBonus, t]);

  const move = useCallback((direction: 'left' | 'right' | 'up' | 'down') => {
    if (isGameOver || gameState === 'shop' || isRopeModeActive) return;

    let { grid: gridWithoutShop } = removeShopTile(grid);
    let preMoveGrid = gridWithoutShop;
    
    const { newGrid: gridAfterPoison, kills: poisonKills, gold: poisonGold, score: poisonScore, xp: poisonXp } = applyPoisonDamage(preMoveGrid);
    
    let tempGrid: Grid = gridAfterPoison;
    if (direction === 'right') tempGrid = reverse(tempGrid);
    else if (direction === 'up') tempGrid = transpose(tempGrid);
    else if (direction === 'down') tempGrid = reverse(transpose(tempGrid));

    let moved = false;
    let combinePoints = 0;
    let combineGold = 0;
    let combineKills = 0;
    let combineXp = 0;
    let hasWon = false;
    let allMergeCoords: {r: number, c: number}[] = [];
    let totalLevelsGained: { level: number; value: number }[] = [];
    let anyChestOpened = false;

    const processedGrid = tempGrid.map((row, r) => {
      const { newRow, points, earnedGold, slainGoblins, mergeIndices, earnedXp, gameWon, levelsGained, chestOpened } = slideAndCombine(row, level);
      if (chestOpened) anyChestOpened = true;
      if (JSON.stringify(newRow) !== JSON.stringify(row)) moved = true;
      combinePoints += points;
      combineGold += earnedGold;
      combineKills += slainGoblins;
      combineXp += earnedXp;
      if (gameWon) hasWon = true;
      
      if (levelsGained.length > 0) {
        totalLevelsGained.push(...levelsGained);
      }

      if (mergeIndices.length > 0) {
        if (direction === 'left' || direction === 'right') {
          mergeIndices.forEach(c => allMergeCoords.push({ r, c }));
        } else { // up or down
          mergeIndices.forEach(c => allMergeCoords.push({ r: c, c: r }));
        }
      }
      return newRow;
    });
    
    if (!moved) {
        if (isBoardLocked(grid)) {
            const damage = Math.max(0, OVERCROWDING_DAMAGE - (permanentUpgrades.overcrowdingResist || 0));
            if (damage > 0) {
                const newHp = playerHP - damage;
                setPlayerHP(newHp);
                if (newHp <= 0) {
                    checkGameOver(t.reason_crushed);
                } else {
                    logEvent(formatString(t.log_overcrowding_damage, { damage }));
                }
            } else {
                logEvent(t.log_overcrowding_resist);
            }
        }
        return;
    }
    
    let gridAfterAoe = processedGrid;
    let aoeKills = 0;
    let aoeGold = 0;
    let aoeScore = 0;
    let aoeXp = 0;

    if (isFireScrollActive && allMergeCoords.length > 0) {
      let transformedCoords = allMergeCoords;
      if (direction === 'right') transformedCoords = allMergeCoords.map(({r, c}) => ({r, c: GRID_SIZE - 1 - c}));

      const { newGrid, kills, gold, score, xp } = applyFireScrollDamage(processedGrid, transformedCoords);
      gridAfterAoe = newGrid;
      aoeKills = kills;
      aoeGold = gold;
      aoeScore = score;
      aoeXp = xp;
    }

    if (direction === 'right') tempGrid = reverse(gridAfterAoe);
    else if (direction === 'up') tempGrid = transpose(gridAfterAoe);
    else if (direction === 'down') tempGrid = transpose(reverse(gridAfterAoe));
    else tempGrid = gridAfterAoe;

    let gridBeforeNewTile = tempGrid;
    if (moved) {
        let chestRemoved = false;
        gridBeforeNewTile = tempGrid.map(row => row.map(tile => {
            if (tile && tile.type === 'chest') {
                chestRemoved = true;
                return null;
            }
            return tile;
        }));
        if (chestRemoved && !anyChestOpened) {
            logEvent(t.log_chest_vanished);
        }
    }

    let finalGrid = addNewTile(gridBeforeNewTile, level);
    
    const scoreDelta = combinePoints + aoeScore + poisonScore;
    const goldDelta = combineGold + aoeGold + poisonGold;
    const killsDelta = combineKills + aoeKills + poisonKills;
    const xpDelta = combineXp + aoeXp + poisonXp;
    
    const newScore = score + scoreDelta;
    const newKills = kills + killsDelta;
    const newRunXp = runXp + xpDelta;
    
    if(scoreDelta > 0) setScore(newScore);
    if(goldDelta > 0) setGold(g => g + goldDelta);
    if(killsDelta > 0) setKills(newKills);
    if(xpDelta > 0) {
        setTotalXp(xp => xp + xpDelta);
        setRunXp(newRunXp);
    }
    
    let levelUpCount = 0;
    if (totalLevelsGained.length > 0) {
        totalLevelsGained.forEach(lu => {
            levelUpCount += lu.level;
            logEvent(formatString(t.log_level_up_combine, { levels: lu.level, value: lu.value }));
        });
    }
    if (killsDelta > 0) {
      const newKillsCount = killsSinceLastLevel + killsDelta;
      const levelUpsFromKills = Math.floor(newKillsCount / 10);
      if (levelUpsFromKills > 0) {
        levelUpCount += levelUpsFromKills;
        const remainingKills = newKillsCount % 10;
        setKillsSinceLastLevel(remainingKills);
        logEvent(formatString(t.log_level_up_kills, { levels: levelUpsFromKills }));
      } else {
        setKillsSinceLastLevel(newKillsCount);
      }
    }

    let finalLevel = level;
    if (levelUpCount > 0) {
        const oldLevel = level;
        finalLevel = oldLevel + levelUpCount;
        setLevel(finalLevel);
        
        let shouldSpawnShop = false;
        for (let i = oldLevel + 1; i <= finalLevel; i++) {
            if (i > 1 && i % 5 === 0) {
                shouldSpawnShop = true;
                break;
            }
        }
        if (shouldSpawnShop) {
            finalGrid = spawnShopTile(finalGrid);
        }
    }

    const newMovesCount = movesCount + 1;
    setMovesCount(newMovesCount);
    
    let hpAfterAttack = playerHP;
    const movesPerAttack = getMovesPerAttack(finalLevel, gameMode, permanentUpgrades);

    if (newMovesCount % movesPerAttack === 0 && newMovesCount > 0) {
      const attackDamage = calculateHordeDamage(finalGrid, finalLevel, gameMode);
      const finalDamage = Math.max(0, attackDamage - damageReduction);
      
      if (finalDamage > 0) {
          logEvent(formatString(t.log_horde_attack, { damage: finalDamage }));
          hpAfterAttack -= finalDamage;
      } else if (attackDamage > 0) {
          logEvent(t.log_horde_blocked);
      }
    }
    
    setGrid(finalGrid);
    setPlayerHP(hpAfterAttack);
    
    if (hpAfterAttack <= 0) {
        checkGameOver(t.reason_slain);
        return;
    }

    if (hasWon) {
      logEvent(formatString(t.log_milestone, { value: 256, gold: 750 }));
      const finalRunXpWithBonus = newRunXp + 750;
      setTotalXp(xp => xp + 750);
      
      const timeTaken = startTime ? Math.floor((Date.now() - startTime) / 1000) : 0;
      const finalStats = { kills: newKills, time: timeTaken, xp: finalRunXpWithBonus };
      setFinalRunStats(finalStats);

      const newEntry: LeaderboardEntry = {
          id: new Date().toISOString(),
          score: newScore,
          kills: finalStats.kills,
          xp: finalStats.xp,
          time: finalStats.time,
          date: new Date().toLocaleDateString(),
      };

      const updatedLeaderboard = [...leaderboard, newEntry]
          .sort((a, b) => a.time - b.time)
          .slice(0, 10);

      setLeaderboard(updatedLeaderboard);
      try {
        localStorage.setItem('goblinSwiperLeaderboard', JSON.stringify(updatedLeaderboard));
      } catch (error) {
        console.error("Failed to save leaderboard to localStorage", error);
      }
      
      checkGameOver(t.reason_victory);
    }

  }, [grid, isGameOver, gameState, gameMode, level, playerHP, movesCount, score, gold, kills, runXp, startTime, leaderboard, damageBonus, damageReduction, isPoisonActive, isFireScrollActive, isRopeModeActive, milestonesReached, logEvent, addNewTile, checkGameOver, applyPoisonDamage, applyFireScrollDamage, permanentUpgrades, killsSinceLastLevel, removeShopTile, t]);

  const handleKeyDown = useCallback((e: KeyboardEvent) => {
    if (e.repeat || isGameOver || gameState === 'shop' || isPermShopOpen) return;
    switch(e.key) {
      case 'ArrowUp': e.preventDefault(); move('up'); break;
      case 'ArrowDown': e.preventDefault(); move('down'); break;
      case 'ArrowLeft': e.preventDefault(); move('left'); break;
      case 'ArrowRight': e.preventDefault(); move('right'); break;
      case 'Escape': 
        if(isRopeModeActive) {
          setIsRopeModeActive(false);
          setSelectedTileForRope(null);
          logEvent(t.log_rope_cancelled);
        }
        break;
    }
  }, [move, isGameOver, gameState, isRopeModeActive, logEvent, isPermShopOpen, t]);
  
  const handleSwipe = useCallback((direction: 'up' | 'down' | 'left' | 'right') => {
    move(direction);
  }, [move]);
  
  const activateRopeMode = useCallback(() => {
    if (ropeCount <= 0) {
      toast({ title: t.toast_no_ropes, variant: "destructive" });
      return;
    }
    if (isRopeModeActive) {
      setIsRopeModeActive(false);
      setSelectedTileForRope(null);
      logEvent(t.log_rope_cancelled);
    } else {
      setIsRopeModeActive(true);
      logEvent(t.log_rope_activated);
    }
  }, [ropeCount, isRopeModeActive, logEvent, toast, t]);

  const handleBoardClick = useCallback((r: number, c: number) => {
    if (isRopeModeActive) {
      const clickedTile = grid[r][c];
      if (!selectedTileForRope) {
        if (clickedTile && clickedTile.type === 'goblin') {
          setSelectedTileForRope({ r, c });
          logEvent(formatString(t.log_rope_selected, { value: clickedTile.value }));
        }
      } else {
        if (clickedTile === null) {
          const newGrid = grid.map(row => [...row]);
          const tileToMove = newGrid[selectedTileForRope.r][selectedTileForRope.c];
          newGrid[selectedTileForRope.r][selectedTileForRope.c] = null;
          newGrid[r][c] = tileToMove;
          
          setGrid(newGrid);
          setRopeCount(rc => rc - 1);
          setIsRopeModeActive(false);
          setSelectedTileForRope(null);
          logEvent(t.log_rope_used);
        } else {
          setSelectedTileForRope(null);
          logEvent(t.log_rope_cancelled_selection);
        }
      }
      return;
    }

    const clickedTile = grid[r][c];
    if (clickedTile && clickedTile.type === 'shop') {
      setActiveShopTile({ r, c });
      setShopPurchaseMade(false);
      const shuffled = [...allShopItems].sort(() => 0.5 - Math.random());
      setShopItems(shuffled.slice(0, 3));
      setGameState('shop');
      logEvent(t.log_enter_shop);
    }
  }, [isRopeModeActive, selectedTileForRope, grid, logEvent, t]);

  useEffect(() => {
    window.addEventListener('keydown', handleKeyDown);
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [handleKeyDown]);
  
  const handleModeSelect = (mode: GameMode) => {
    setGameMode(mode);
    setGameState('playing');
  };

  const handleLanguageChange = (lang: Language) => {
    setLanguage(lang);
  };

  const handleBackToMenu = () => {
    setGameState('splash');
  };

  const handleCloseShop = useCallback(() => {
    if (shopPurchaseMade && activeShopTile) {
        const newGrid = grid.map(row => [...row]);
        newGrid[activeShopTile.r][activeShopTile.c] = null;
        setGrid(newGrid);
        logEvent(t.log_shop_purchase_leaves);
    } else if (activeShopTile) {
        logEvent(t.log_leave_shop);
    }
    setGameState('playing');
    setActiveShopTile(null);
    setShopPurchaseMade(false);
  }, [shopPurchaseMade, activeShopTile, grid, logEvent, t]);

  const handleBuyItem = useCallback((cost: number, itemName: string, itemId: string) => {
    if (gold >= cost) {
      setGold(g => g - cost);
      setPurchasedItems(prev => [...prev, itemId]);
      logEvent(formatString(t.log_purchase, { item: itemName, cost: cost }));
      setShopPurchaseMade(true);
      
      switch (itemId) {
        case "healthPotion":
          setPlayerHP(hp => Math.min(maxPlayerHP, hp + 5));
          logEvent(formatString(t.log_heal, { hp: 5 }));
          break;
        case "sword":
          setDamageBonus(prev => prev + 1);
          break;
        case "torch":
          setIsTorchActive(true);
          break;
        case "shield":
          setDamageReduction(prev => prev + 1);
          break;
        case "poison":
          setIsPoisonActive(true);
          break;
        case "fireScroll":
          setIsFireScrollActive(true);
          break;
        case "rope":
          setRopeCount(prev => prev + 1);
          break;
      }

    } else {
      toast({
        title: t.toast_not_enough_gold,
        description: formatString(t.toast_not_enough_gold_desc, { cost, item: itemName }),
        variant: "destructive",
      });
    }
  }, [gold, maxPlayerHP, toast, logEvent, t]);

  const handleBuyPermanentUpgrade = (id: PermanentUpgradeId, cost: number) => {
    if (totalXp < cost) {
        toast({ title: t.toast_not_enough_xp, variant: "destructive" });
        return;
    }

    const upgradeInfo = PERMANENT_UPGRADES.find(u => u.id === id);
    if (!upgradeInfo) return;

    const currentLevel = permanentUpgrades[id] || 0;
    if (currentLevel >= upgradeInfo.maxLevel) {
        toast({ title: t.toast_max_level, variant: "destructive" });
        return;
    }

    const newTotalXp = totalXp - cost;
    setTotalXp(newTotalXp);

    const newUpgrades = {
        ...permanentUpgrades,
        [id]: (permanentUpgrades[id] || 0) + 1
    };
    setPermanentUpgrades(newUpgrades);
    
    try {
      localStorage.setItem('goblinSwiperPermanentUpgrades', JSON.stringify(newUpgrades));
      localStorage.setItem('goblinSwiperTotalXp', newTotalXp.toString());
    } catch (error) {
       console.error("Failed to save upgrades to localStorage", error);
       toast({ title: t.toast_error_saving, variant: "destructive" });
    }
    const upgradeName = t[`${id}_name` as keyof Translations] || upgradeInfo.id;
    logEvent(formatString(t.log_perm_upgrade_purchased, { name: upgradeName }));
    toast({ title: t.toast_upgrade_purchased, description: formatString(t.toast_upgrade_purchased_desc, { name: upgradeName }) });
  };

  const unlockedItems = useMemo(() => {
    const unlocked: string[] = [];
    if ((permanentUpgrades.unlockHealthPotion || 0) > 0) unlocked.push("healthPotion");
    if ((permanentUpgrades.unlockSword || 0) > 0) unlocked.push("sword");
    if ((permanentUpgrades.unlockTorch || 0) > 0) unlocked.push("torch");
    if ((permanentUpgrades.unlockShield || 0) > 0) unlocked.push("shield");
    if ((permanentUpgrades.unlockPoison || 0) > 0) unlocked.push("poison");
    if ((permanentUpgrades.unlockFireScroll || 0) > 0) unlocked.push("fireScroll");
    if ((permanentUpgrades.unlockRope || 0) > 0) unlocked.push("rope");
    return unlocked;
  }, [permanentUpgrades]);
  
  if (gameState === 'splash') {
    return (
      <SplashScreen 
        onModeSelect={handleModeSelect} 
        onOpenPermShop={() => setIsPermShopOpen(true)}
        onLanguageChange={handleLanguageChange}
        language={language}
        t={t}
        isMusicEnabled={isMusicEnabled}
        onMusicToggle={() => {
          const newMusicState = !isMusicEnabled;
          setIsMusicEnabled(newMusicState);
          try {
            localStorage.setItem('goblinSwiperMusic', JSON.stringify(newMusicState));
          } catch (error) {
            console.error("Failed to save music preference to localStorage", error);
          }
        }}
        isPermShopOpen={isPermShopOpen}
        isLeaderboardOpen={isLeaderboardOpen}
        onOpenLeaderboard={() => setIsLeaderboardOpen(true)}
        onCloseLeaderboard={() => setIsLeaderboardOpen(false)}
        leaderboard={leaderboard}
        onClosePermShop={() => setIsPermShopOpen(false)}
        totalXp={totalXp}
        upgrades={permanentUpgrades}
        onBuyPermanentUpgrade={handleBuyPermanentUpgrade}
      />
    );
  }
  
  const movesPerAttack = getMovesPerAttack(level, gameMode, permanentUpgrades);
  const movesUntilAttack = movesPerAttack - (movesCount % movesPerAttack);
  const killsToNextLevel = 10 - killsSinceLastLevel;

  return (
    <main className="flex flex-col items-center justify-start min-h-screen p-4 bg-background">
      <audio ref={gameAudioRef} src={GAME_MUSIC_FILE} loop onCanPlay={() => setIsGameAudioReady(true)} />
      <div className="w-full max-w-[350px] sm:max-w-sm mx-auto flex flex-col gap-4">
        <header className="flex flex-row justify-between items-center">
          <div className="flex items-center gap-2">
            <GoblinSwiperIcon className="w-8 h-8 text-primary" />
            <div>
              <h1 className="text-lg sm:text-xl font-headline font-bold text-primary">{t.headerTitle}</h1>
              <p className="text-xs text-muted-foreground">{t.headerSubtitle}</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Button onClick={handleBackToMenu} size="sm" className="shadow-md">{t.newGame}</Button>
            <Sheet>
              <SheetTrigger asChild>
                <Button variant="outline" size="icon" className="w-9 h-9 shadow-md">
                  <Menu className="h-4 w-4" />
                  <span className="sr-only">{t.openMenu}</span>
                </Button>
              </SheetTrigger>
              <SheetContent>
                <SheetHeader>
                  <SheetTitle className="font-headline text-accent flex items-center gap-2">
                    <Trophy className="w-6 h-6"/> {t.leaderboardTitle}
                  </SheetTitle>
                  <SheetDescription>
                    {t.leaderboardDesc}
                  </SheetDescription>
                </SheetHeader>
                <div className="py-4 h-[calc(100%-4rem)]">
                  <div className="border rounded-md h-full overflow-y-auto">
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead className="w-[50px]">{t.rank}</TableHead>
                                <TableHead>{t.time}</TableHead>
                                <TableHead>{t.score}</TableHead>
                                <TableHead>{t.kills}</TableHead>
                                <TableHead>XP</TableHead>
                                <TableHead>{t.date}</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {leaderboard.length > 0 ? leaderboard.map((entry, index) => (
                                <TableRow key={entry.id}>
                                    <TableCell>{index + 1}</TableCell>
                                    <TableCell className="font-medium text-accent">{formatTime(entry.time)}</TableCell>
                                    <TableCell>{entry.score}</TableCell>
                                    <TableCell>{entry.kills}</TableCell>
                                    <TableCell>{entry.xp}</TableCell>
                                    <TableCell>{entry.date}</TableCell>
                                </TableRow>
                            )) : (
                                <TableRow>
                                    <TableCell colSpan={6} className="text-center h-24 text-muted-foreground">
                                        {t.noVictories}
                                    </TableCell>
                                </TableRow>
                            )}
                        </TableBody>
                    </Table>
                  </div>
                </div>
              </SheetContent>
            </Sheet>
          </div>
        </header>

        <InfoPanel 
          score={score}
          gold={gold}
          playerHP={playerHP}
          maxPlayerHP={maxPlayerHP}
          movesUntilAttack={movesUntilAttack}
          level={level}
          killsToNextLevel={killsToNextLevel}
          totalXp={totalXp}
          gameMode={gameMode}
          t={t}
        />

        <div className="relative">
            <GameBoard 
              grid={grid} 
              onSwipe={handleSwipe} 
              isTorchActive={isTorchActive}
              isRopeModeActive={isRopeModeActive}
              onBoardClick={handleBoardClick}
              selectedTileForRope={selectedTileForRope}
            />
            {isGameOver && <GameOverDialog 
              score={score} 
              onBackToMenu={handleBackToMenu} 
              reason={gameOverReason}
              runStats={finalRunStats}
              t={t}
            />}
            {gameState === 'shop' && (
              <ShopDialog 
                gold={gold}
                onClose={handleCloseShop}
                onBuy={handleBuyItem}
                purchasedItems={purchasedItems}
                items={shopItems}
                unlockedItems={unlockedItems}
                t={t}
              />
            )}
        </div>
        
        <Abilities 
          ropeCount={ropeCount}
          onUseRope={activateRopeMode}
          purchasedItems={purchasedItems}
          damageBonus={damageBonus + (permanentUpgrades.baseDamage || 0)}
          damageReduction={damageReduction}
          t={t}
        />
        
      </div>
    </main>
  );
}
