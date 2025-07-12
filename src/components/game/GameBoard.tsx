"use client";

import React, { useRef } from 'react';
import { GoblinTile } from './GoblinTile';
import type { Grid } from '@/app/page';
import { cn } from '@/lib/utils';

type GameBoardProps = {
  grid: Grid;
  onSwipe: (direction: 'up' | 'down' | 'left' | 'right') => void;
  isTorchActive: boolean;
  isRopeModeActive: boolean;
  onBoardClick: (r: number, c: number) => void;
  selectedTileForRope: { r: number, c: number } | null;
};

const GRID_SIZE = 4;

export function GameBoard({ grid, onSwipe, isTorchActive, isRopeModeActive, onBoardClick, selectedTileForRope }: GameBoardProps) {
  const touchStartRef = useRef<{ x: number, y: number } | null>(null);
  const boardRef = useRef<HTMLDivElement>(null);

  const handleTouchStart = (e: React.TouchEvent<HTMLDivElement>) => {
    if (isRopeModeActive) return;
    touchStartRef.current = { x: e.touches[0].clientX, y: e.touches[0].clientY };
  };

  const handleTouchEnd = (e: React.TouchEvent<HTMLDivElement>) => {
    if (isRopeModeActive || !touchStartRef.current) return;

    const touchEndX = e.changedTouches[0].clientX;
    const touchEndY = e.changedTouches[0].clientY;

    const dx = touchEndX - touchStartRef.current.x;
    const dy = touchEndY - touchStartRef.current.y;

    if (Math.abs(dx) > Math.abs(dy)) {
      if (Math.abs(dx) > 30) { 
        onSwipe(dx > 0 ? 'right' : 'left');
      }
    } else {
      if (Math.abs(dy) > 30) {
        onSwipe(dy > 0 ? 'down' : 'up');
      }
    }

    touchStartRef.current = null;
  };

  const handleBoardClick = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!boardRef.current) return;
    
    const rect = boardRef.current.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;

    const cellSize = rect.width / GRID_SIZE;
    const col = Math.floor(x / cellSize);
    const row = Math.floor(y / cellSize);
    
    if (row >= 0 && row < GRID_SIZE && col >= 0 && col < GRID_SIZE) {
      onBoardClick(row, col);
    }
  };

  return (
    <div
      ref={boardRef}
      className={cn(
        "bg-card p-1 rounded-lg shadow-inner aspect-square touch-none select-none",
        isRopeModeActive && "rope-mode-active"
      )}
      onTouchStart={handleTouchStart}
      onTouchEnd={handleTouchEnd}
      onClick={handleBoardClick}
    >
      <div className="relative h-full w-full">
        {/* Background Cells */}
        <div className="grid grid-cols-4 grid-rows-4 gap-1 h-full w-full">
          {Array.from({ length: GRID_SIZE * GRID_SIZE }).map((_, i) => {
             const r = Math.floor(i / GRID_SIZE);
             const c = i % GRID_SIZE;
             const isEmpty = grid[r][c] === null;
            return (
              <div 
                key={i} 
                className={cn(
                  "bg-background/50 rounded-md aspect-square",
                  isRopeModeActive && isEmpty && "empty-cell-rope-hover"
                )} 
              />
            )
          })}
        </div>

        {/* Tiles */}
        <div className="absolute inset-0">
          {grid.map((row, r) =>
            row.map((tile, c) =>
              tile ? (
                <GoblinTile 
                  key={tile.id} 
                  tile={tile} 
                  row={r} 
                  col={c} 
                  isTorchActive={isTorchActive}
                  isSelectedForRope={selectedTileForRope?.r === r && selectedTileForRope?.c === c}
                />
              ) : null
            )
          )}
        </div>
      </div>
    </div>
  );
}
