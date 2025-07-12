"use client"

import { ScrollArea } from "@/components/ui/scroll-area"

type EventLogProps = {
  logs: string[]
}

export function EventLog({ logs }: EventLogProps) {
  return (
    <ScrollArea className="h-full w-full rounded-md border p-3 bg-background/50">
      <div className="flex flex-col-reverse gap-2">
        {logs.map((log, index) => (
          <p key={index} className="text-sm text-muted-foreground animate-in fade-in-0 slide-in-from-top-2 duration-300">
            {log}
          </p>
        ))}
      </div>
    </ScrollArea>
  )
}
