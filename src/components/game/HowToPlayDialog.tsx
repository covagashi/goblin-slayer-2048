
"use client"

import Image from "next/image"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
  DialogClose,
} from "@/components/ui/dialog"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Button } from "@/components/ui/button"
import { Heart, Coins, Sparkles, BookOpen } from "lucide-react"
import { allShopItems } from "@/app/page"
import { formatString, type Translations } from "@/lib/translations"

type HowToPlayDialogProps = {
  isOpen: boolean
  onClose: () => void
  t: Translations
}

const goblinProgression = [
  { value: 2, name: 'Goblin' },
  { value: 4, name: 'Goblin' },
  { value: 8, name: 'Goblin' },
  { value: 16, name: 'Goblin' },
  { value: 32, name: 'Hobgoblin' },
  { value: 64, name: 'Shaman' },
  { value: 128, name: 'Lord' },
  { value: 256, name: 'King' },
];


export function HowToPlayDialog({ isOpen, onClose, t }: HowToPlayDialogProps) {
  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle className="font-headline text-3xl text-primary flex items-center gap-2">
            <BookOpen className="w-8 h-8" /> {t.h2pTitle}
          </DialogTitle>
          <DialogDescription>
            {t.h2pDesc}
          </DialogDescription>
        </DialogHeader>

        <Tabs defaultValue="basico" className="w-full pt-2">
          <TabsList className="grid w-full grid-cols-5 h-auto">
            <TabsTrigger value="basico" className="text-xs px-1">{t.h2pBasics}</TabsTrigger>
            <TabsTrigger value="combate" className="text-xs px-1">{t.h2pCombat}</TabsTrigger>
            <TabsTrigger value="powerups" className="text-xs px-1">{t.h2pPowerups}</TabsTrigger>
            <TabsTrigger value="progresion" className="text-xs px-1">{t.h2pProgression}</TabsTrigger>
            <TabsTrigger value="modos" className="text-xs px-1">{t.h2pModes}</TabsTrigger>
          </TabsList>
          
          <div className="mt-4 p-4 border rounded-md min-h-[250px] bg-background/50 text-sm">
            <TabsContent value="basico" className="m-0">
              <h3 className="font-bold text-accent mb-2">{t.h2pBasics}</h3>
              <ul className="list-disc list-inside space-y-2">
                <li>{t.basicsL1}</li>
                <li>{t.basicsL2}</li>
                <li>{t.basicsL3}</li>
                <li>{t.basicsL4}</li>
              </ul>
            </TabsContent>
            
            <TabsContent value="combate" className="m-0">
                <h3 className="font-bold text-accent mb-2">{t.combatTitle}</h3>
                <p className="mb-2">{formatString(t.combatL1, {hp: 20})}</p>
                
                <div className="space-y-2 mt-4">
                  <p className="text-sm text-muted-foreground">{t.combatL2}</p>
                  <div className="grid grid-cols-4 gap-2 text-center">
                    {goblinProgression.map(goblin => (
                      <div key={goblin.value} className="p-1 bg-muted/50 rounded-md flex flex-col items-center justify-center">
                        <Image 
                          src={`/sprites/goblin-${goblin.value}.png`}
                          alt={goblin.name}
                          width={40}
                          height={40}
                          className="bg-stone-800 rounded"
                          data-ai-hint="goblin"
                          onError={(e) => {
                            e.currentTarget.src = `https://placehold.co/40x40/171212/8B0000.png`;
                            e.currentTarget.srcset = "";
                          }}
                        />
                        <span className="text-xs font-bold mt-1">{goblin.value}</span>
                      </div>
                    ))}
                  </div>
                </div>

                <p className="mt-4">{t.combatL3}</p>
            </TabsContent>
            
            <TabsContent value="powerups" className="m-0">
              <h3 className="font-bold text-accent mb-2">{t.powerupsTitle}</h3>
              <p className="mb-3">{t.powerupsL1}</p>
              <div className="space-y-2">
                  {allShopItems.map(item => {
                      const name = t[`${item.id}_name` as keyof Translations]
                      const description = t[`${item.id}_desc` as keyof Translations]
                      return (
                      <div key={item.id} className="flex items-center justify-between">
                          <div className="flex items-center gap-3">
                              <Image src={item.spriteUrl} alt={name} width={32} height={32} data-ai-hint={item.dataAiHint} className="bg-stone-800 rounded-md"/>
                              <div className="flex flex-col">
                                <span className="font-medium">{name}</span>
                                <span className="text-xs text-muted-foreground">{description}</span>
                              </div>
                          </div>
                          <div className="flex items-center gap-1 text-accent font-bold text-xs">
                              <Coins className="w-3 h-3" />
                              {item.cost}
                          </div>
                      </div>
                      )
                  })}
              </div>
            </TabsContent>
            
            <TabsContent value="progresion" className="m-0">
                <h3 className="font-bold text-accent mb-2">{t.progressionTitle}</h3>
                <ul className="list-disc list-inside space-y-2">
                    <li>{t.progressionL1}</li>
                    <li>{t.progressionL2}</li>
                    <li>{t.progressionL3}</li>
                    <li>{t.progressionL4}</li>
                </ul>
            </TabsContent>

            <TabsContent value="modos" className="m-0">
                <h3 className="font-bold text-accent mb-2">{t.modesTitle}</h3>
                 <div className="space-y-3">
                    <div>
                        <h4 className="font-bold">{t.storyModeTitle}</h4>
                        <p className="text-muted-foreground">{t.storyModeDesc}</p>
                    </div>
                     <div>
                        <h4 className="font-bold">{t.endlessModeTitle}</h4>
                        <p className="text-muted-foreground">{t.endlessModeDesc}</p>
                    </div>
                </div>
            </TabsContent>
          </div>
        </Tabs>
        
        <DialogFooter className="pt-2">
            <DialogClose asChild>
                <Button className="w-full">{t.h2pGotIt}</Button>
            </DialogClose>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
