
"use client"

import Image from 'next/image';
import { cn } from "@/lib/utils"
import type { TileData } from "@/app/page";
import { Box, Store } from 'lucide-react';

type GoblinTileProps = {
  tile: TileData;
  row: number;
  col: number;
  isTorchActive: boolean;
  isSelectedForRope?: boolean;
};

export function GoblinTile({ tile, row, col, isTorchActive, isSelectedForRope }: GoblinTileProps) {
  const animationClass = 'animate-tile-spawn'; 

  const style: React.CSSProperties = {
    position: 'absolute',
    width: 'calc(25% - 4px)',
    height: 'calc(25% - 4px)',
    top: `calc(${row * 25}% + 2px)`,
    left: `calc(${col * 25}% + 2px)`,
    transition: 'top 0.1s ease-in-out, left 0.1s ease-in-out',
  };
  
  const tileContainerClasses = cn(
    'relative w-full h-full rounded-md shadow-md overflow-hidden',
    isSelectedForRope && 'tile-selected-for-rope',
    'goblin-tile-container'
  );

  if (tile.type === 'chest') {
    return (
      <div style={style} className={cn('p-1', animationClass)}>
        <div className={cn(tileContainerClasses, "bg-yellow-900/50 border-2 border-yellow-600 flex items-center justify-center")}>
          <Box className="w-1/2 h-1/2 text-yellow-400" />
        </div>
      </div>
    );
  }

  if (tile.type === 'shop') {
    return (
      <div style={style} className={cn('p-1', animationClass)}>
        <div className={cn(tileContainerClasses, "bg-purple-900/50 border-2 border-purple-500 flex items-center justify-center cursor-pointer hover:bg-purple-900/80 transition-colors")}>
          <Store className="w-1/2 h-1/2 text-purple-300" />
        </div>
      </div>
    );
  }

  const { value, hp, maxHp, poisoned } = tile;
  const hpPercentage = (hp / maxHp) * 100;

  return (
    <div style={style} className={cn(animationClass, 'p-1')}>
      <div className={tileContainerClasses}>
        <Image
          src={`/sprites/goblin-${value}.png`}
          alt={`Goblin level ${value}`}
          width={100}
          height={100}
          className="w-full h-full object-cover bg-stone-800"
          data-ai-hint="goblin"
          onError={(e) => {
            e.currentTarget.src = `https://placehold.co/100x100/171212/8B0000.png`;
            e.currentTarget.srcset = "";
          }}
        />
        
        {isTorchActive && (
            <div className="absolute bottom-0 left-0 h-1.5 w-full bg-black/40">
              <div 
                  className="h-full bg-red-500 transition-all duration-300" 
                  style={{ width: `${hpPercentage}%` }}
              />
            </div>
        )}

        {poisoned && poisoned > 0 && (
          <div className="absolute top-0 right-0 p-0.5 bg-black/50 rounded-bl-md">
            <span className="text-xs">🤢</span>
          </div>
        )}
      </div>
    </div>
  );
}
