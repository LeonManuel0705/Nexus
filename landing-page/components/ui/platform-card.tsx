"use client"

import { AnimatedCard } from "@/components/ui/animated-card"
import { CheckCircle2, Download, Smartphone, Monitor, Globe } from "lucide-react"
import Link from "next/link"

const iconMap = {
  Smartphone,
  Monitor,
  Globe,
} as const

interface PlatformCardProps {
  iconName: keyof typeof iconMap
  name: string
  description: string
  downloadLabel: string
  downloadUrl?: string
  onClick?: () => void
  badge: string | null
  features: string[]
  isDownload?: boolean
}

export function PlatformCard({
  iconName,
  name,
  description,
  downloadLabel,
  downloadUrl,
  onClick,
  badge,
  features,
  isDownload = false,
}: PlatformCardProps) {
  const Icon = iconMap[iconName]

  const buttonContent = (
    <>
      <Download className="w-4 h-4" />
      {downloadLabel}
    </>
  )

  return (
    <AnimatedCard className="relative p-6 md:p-8 bg-card/50">
      {badge && (
        <div className="absolute top-4 right-4 px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-medium z-10">
          {badge}
        </div>
      )}

      <div className="flex items-start gap-4 relative z-10">
        <div className="w-12 h-12 rounded-lg bg-primary/10 flex items-center justify-center shrink-0">
          <Icon className="w-6 h-6 text-primary" />
        </div>
        <div className="flex-1">
          <h2 className="text-xl font-semibold text-foreground mb-1">
            {name}
          </h2>
          <p className="text-muted-foreground text-sm mb-4">
            {description}
          </p>

          <ul className="space-y-2 mb-6">
            {features.map((feature) => (
              <li key={feature} className="flex items-center gap-2 text-sm text-muted-foreground">
                <CheckCircle2 className="w-4 h-4 text-primary" />
                {feature}
              </li>
            ))}
          </ul>

          {onClick ? (
            <button
              onClick={onClick}
              className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-primary text-primary-foreground text-sm font-medium hover:opacity-90 transition-opacity"
            >
              {buttonContent}
            </button>
          ) : isDownload && downloadUrl ? (
            <a
              href={downloadUrl}
              download
              className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-primary text-primary-foreground text-sm font-medium hover:opacity-90 transition-opacity"
            >
              {buttonContent}
            </a>
          ) : downloadUrl ? (
            <Link
              href={downloadUrl}
              className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg bg-primary text-primary-foreground text-sm font-medium hover:opacity-90 transition-opacity"
            >
              {buttonContent}
            </Link>
          ) : null}
        </div>
      </div>
    </AnimatedCard>
  )
}
