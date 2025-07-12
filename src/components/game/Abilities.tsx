
"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion"
import { CheckCircle, XCircle, Sword, Shield, Lasso } from "lucide-react"
import Image from "next/image"
import type { Translations } from "@/lib/translations"

type AbilitiesProps = {
  ropeCount: number
  onUseRope: () => void
  purchasedItems: string[]
  damageBonus: number
  damageReduction: number
  t: Translations
}

const passiveItems = [
  { id: 'sword', spriteUrl: "/sprites/item-sword.png", dataAiHint: "sword" },
  { id: 'torch', spriteUrl: "/sprites/item-torch.png", dataAiHint: "torch" },
  { id: 'shield', spriteUrl: "/sprites/item-shield.png", dataAiHint: "shield" },
  { id: 'poison', spriteUrl: "/sprites/item-poison.png", dataAiHint: "poison flask" },
  { id: 'fireScroll', spriteUrl: "/sprites/item-fire-scroll.png", dataAiHint: "fire scroll" },
];

export function Abilities({ ropeCount, onUseRope, purchasedItems, damageBonus, damageReduction, t }: AbilitiesProps) {
  const activePassiveItems = passiveItems.filter(item => purchasedItems.includes(item.id));
  const inactivePassiveItems = passiveItems.filter(item => !purchasedItems.includes(item.id));

  return (
    <Card className="shadow-lg">
      <CardHeader className="pb-2">
        <div className="flex justify-between items-center">
          <CardTitle className="font-headline text-base text-accent">{t.itemsAndUpgrades}</CardTitle>
          <div className="flex items-center gap-4 text-xs text-muted-foreground">
            {damageBonus > 0 && (
              <div className="flex items-center gap-1" title={t.combineDamageBonus}>
                <Sword className="w-4 h-4" />
                <span className="font-bold text-foreground">+{damageBonus}</span>
              </div>
            )}
            {damageReduction > 0 && (
              <div className="flex items-center gap-1" title={t.damageReduction}>
                <Shield className="w-4 h-4" />
                <span className="font-bold text-foreground">+{damageReduction}</span>
              </div>
            )}
          </div>
        </div>
      </CardHeader>
      <CardContent className="flex flex-col gap-2 pt-2">
        {/* Active Item: Rope */}
        <div className="flex justify-between items-center p-3 bg-background/50 rounded-lg border">
          <div>
            <h3 className="font-bold flex items-center gap-2 text-sm">
                <Lasso className="w-4 h-4" /> {t.useRope}
            </h3>
            <p className="text-xs text-muted-foreground">{t.moveGoblin}</p>
          </div>
          <Button 
            onClick={onUseRope}
            disabled={ropeCount <= 0} 
            variant="secondary"
            className="w-24 text-xs"
          >
            {t.use} ({ropeCount})
          </Button>
        </div>

        {/* Purchased Passive Items */}
        {activePassiveItems.map(item => {
          const name = t[`${item.id}_name` as keyof Translations]
          const description = t[`${item.id}_desc` as keyof Translations]
          return (
            <div key={item.id} className="flex justify-between items-center p-3 bg-background/50 rounded-lg border">
              <div className="flex items-center gap-3">
                <Image src={item.spriteUrl} alt={name} width={32} height={32} data-ai-hint={item.dataAiHint} className="bg-stone-800 rounded-md" />
                <div>
                  <h3 className="font-bold text-sm">{name}</h3>
                  <p className="text-xs text-muted-foreground">{description}</p>
                </div>
              </div>
              <div className="flex items-center gap-2 text-xs text-green-400 font-bold">
                <CheckCircle className="w-4 h-4" />
                <span>{t.active}</span>
              </div>
            </div>
          )
        })}

        {/* Inactive Items */}
        {inactivePassiveItems.length > 0 && (
          <Accordion type="single" collapsible className="w-full">
            <AccordionItem value="inactive-items" className="border-none">
              <AccordionTrigger className="text-xs text-muted-foreground justify-center py-2 hover:no-underline rounded-md hover:bg-muted/50">
                {t.showInactiveUpgrades}
              </AccordionTrigger>
              <AccordionContent className="flex flex-col gap-2 pt-2">
                {inactivePassiveItems.map(item => {
                    const name = t[`${item.id}_name` as keyof Translations]
                    const description = t[`${item.id}_desc` as keyof Translations]
                   return (
                     <div key={item.id} className="flex justify-between items-center p-3 bg-background/50 rounded-lg border opacity-60">
                       <div className="flex items-center gap-3">
                         <Image src={item.spriteUrl} alt={name} width={32} height={32} data-ai-hint={item.dataAiHint} className="bg-stone-800 rounded-md" />
                         <div>
                           <h3 className="font-bold text-sm">{name}</h3>
                           <p className="text-xs text-muted-foreground">{description}</p>
                         </div>
                       </div>
                       <div className="flex items-center gap-2 text-xs text-muted-foreground font-medium">
                         <XCircle className="w-4 h-4" />
                         <span>{t.inactive}</span>
                       </div>
                     </div>
                   )
                })}
              </AccordionContent>
            </AccordionItem>
          </Accordion>
        )}
      </CardContent>
    </Card>
  )
}
