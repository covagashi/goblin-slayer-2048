
"use client"

import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogContent,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Coins } from "lucide-react"
import type { ShopItem } from "@/app/page";
import Image from "next/image";
import type { Translations } from "@/lib/translations"

type ShopDialogProps = {
  gold: number
  onClose: () => void
  onBuy: (cost: number, name: string, id: string) => void
  purchasedItems: string[]
  items: ShopItem[]
  unlockedItems: string[]
  t: Translations
}

export function ShopDialog({ gold, onClose, onBuy, purchasedItems, items, unlockedItems, t }: ShopDialogProps) {
  
  return (
    <div className="absolute inset-0 bg-black/70 flex items-center justify-center rounded-lg z-20 animate-in fade-in-0 duration-500">
      <AlertDialog open={true} onOpenChange={(open) => !open && onClose()}>
        <AlertDialogContent className="max-w-xs">
          <AlertDialogHeader>
            <AlertDialogTitle className="font-headline text-3xl text-primary">{t.shopTitle}</AlertDialogTitle>
            <div className="text-base text-muted-foreground flex justify-between items-center pt-1">
              <span>{t.shopDesc}</span>
              <span className="font-bold text-accent flex items-center gap-1">
                <Coins className="w-4 h-4" />
                {gold}
              </span>
            </div>
          </AlertDialogHeader>
          
          <Card className="border-none shadow-none -mx-2">
              <CardContent className="p-2 max-h-64 overflow-y-auto flex flex-col gap-2">
                {items.length > 0 ? items.map(item => {
                  const isPurchased = item.isUnique && purchasedItems.includes(item.id);
                  const isUnlocked = unlockedItems.includes(item.id);
                  const isDisabled = gold < item.cost || isPurchased || !isUnlocked;
                  const name = t[`${item.id}_name` as keyof Translations]
                  const description = t[`${item.id}_desc` as keyof Translations]

                  return (
                    <div key={item.id} className="flex justify-between items-center p-2 bg-background/50 rounded-lg border">
                      <div className="flex items-center gap-3 flex-1">
                        <Image src={item.spriteUrl} alt={name} width={40} height={40} data-ai-hint={item.dataAiHint} className="bg-stone-800 rounded-md" />
                        <div>
                          <h3 className="font-bold text-sm">{name}</h3>
                          <p className="text-xs text-muted-foreground">{description}</p>
                        </div>
                      </div>
                      <Button 
                        onClick={() => onBuy(item.cost, name, item.id)}
                        disabled={isDisabled}
                        variant="secondary"
                        className="w-24 text-xs"
                      >
                        {isPurchased ? t.owned : !isUnlocked ? t.locked : `${item.cost} ${t.gold}`}
                      </Button>
                    </div>
                  )
                }) : (
                  <p className="text-center text-sm text-muted-foreground p-4">
                    {t.noItemsAvailable}
                  </p>
                )}
              </CardContent>
          </Card>

          <AlertDialogFooter>
            <AlertDialogAction onClick={onClose} className="w-full">
              {t.continueSlaying}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
