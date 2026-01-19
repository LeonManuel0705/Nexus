"use client"

import { AnimatedCard } from "@/components/ui/animated-card"
import { Shield, Lock, WifiOff, Smartphone } from "lucide-react"

const iconMap = {
  Shield,
  Lock,
  WifiOff,
  Smartphone,
} as const

interface ValueCardProps {
  iconName: keyof typeof iconMap
  title: string
  description: string
}

export function ValueCard({ iconName, title, description }: ValueCardProps) {
  const Icon = iconMap[iconName]

  return (
    <AnimatedCard className="p-6 bg-card/50 text-center">
      <div className="w-12 h-12 rounded-lg bg-primary/10 flex items-center justify-center mb-4 mx-auto relative z-10">
        <Icon className="w-6 h-6 text-primary" />
      </div>
      <h3 className="text-lg font-medium text-foreground mb-2 relative z-10">
        {title}
      </h3>
      <p className="text-sm text-muted-foreground relative z-10">
        {description}
      </p>
    </AnimatedCard>
  )
}
