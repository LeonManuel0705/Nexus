"use client"

import { AnimatedCard } from "@/components/ui/animated-card"

interface TextCardProps {
  title: string
  description: string
}

export function TextCard({ title, description }: TextCardProps) {
  return (
    <AnimatedCard className="p-6 bg-card/50">
      <h3 className="text-lg font-medium text-foreground mb-2 relative z-10">
        {title}
      </h3>
      <p className="text-muted-foreground relative z-10">
        {description}
      </p>
    </AnimatedCard>
  )
}
