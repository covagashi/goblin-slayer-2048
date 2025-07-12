import * as React from "react"

export function GoblinSwiperIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      {...props}
    >
      <path d="M12 2a10 10 0 0 0-8.53 15.1l-1.47 3.43 3.43-1.47A10 10 0 1 0 12 2Z" fill="hsl(var(--primary) / 0.2)" />
      <path d="M8 14s1.5 2 4 2 4-2 4-2" />
      <path d="M9 9h.01" />
      <path d="M15 9h.01" />
      <path d="M16.5 6.5l-3 3" />
      <path d="M7.5 6.5l3 3" />
      <path d="M4.5 12.5l-1.5 1" />
      <path d="M19.5 12.5l1.5 1" />
    </svg>
  )
}
