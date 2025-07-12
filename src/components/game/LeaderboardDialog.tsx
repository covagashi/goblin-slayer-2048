
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
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import type { Translations } from "@/lib/translations"
import { Trophy } from "lucide-react"

export type LeaderboardEntry = {
  id: string;
  score: number;
  kills: number;
  xp: number;
  time: number; // in seconds
  date: string;
};

type LeaderboardDialogProps = {
  leaderboard: LeaderboardEntry[];
  onClose: () => void;
  t: Translations;
};

const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
}

export function LeaderboardDialog({ leaderboard, onClose, t }: LeaderboardDialogProps) {
  return (
    <div className="absolute inset-0 bg-black/70 flex items-center justify-center rounded-lg z-30 animate-in fade-in-0 duration-500">
      <AlertDialog open={true} onOpenChange={onClose}>
        <AlertDialogContent className="max-w-xl">
          <AlertDialogHeader>
            <AlertDialogTitle className="font-headline text-3xl text-primary flex items-center gap-2">
              <Trophy className="w-8 h-8"/> {t.leaderboardTitle}
            </AlertDialogTitle>
            <AlertDialogDescription className="text-base">
              {t.leaderboardDesc}
            </AlertDialogDescription>
          </AlertDialogHeader>
          
          <div className="border rounded-md max-h-80 overflow-y-auto">
            <Table>
                <TableHeader>
                    <TableRow>
                        <TableHead className="w-[50px]">{t.rank}</TableHead>
                        <TableHead>{t.time}</TableHead>
                        <TableHead>{t.score}</TableHead>
                        <TableHead>{t.goblinsSlain}</TableHead>
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
