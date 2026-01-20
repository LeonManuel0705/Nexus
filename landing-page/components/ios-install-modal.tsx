"use client"

import { X, Share, PlusSquare, CheckCircle2 } from "lucide-react"
import { useEffect } from "react"

interface IOSInstallModalProps {
  isOpen: boolean
  onClose: () => void
}

const steps = [
  {
    icon: (
      <svg className="w-8 h-8" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M12 2C6.477 2 2 6.477 2 12s4.477 10 10 10 10-4.477 10-10S17.523 2 12 2z" fill="url(#safari-gradient)"/>
        <path d="M12 4.5L8.5 12l3.5 7.5 3.5-7.5L12 4.5z" fill="white"/>
        <path d="M12 12l3.5-7.5-7 7 3.5.5z" fill="#FF3B30"/>
        <defs>
          <linearGradient id="safari-gradient" x1="2" y1="2" x2="22" y2="22">
            <stop stopColor="#00D4FF"/>
            <stop offset="1" stopColor="#0066FF"/>
          </linearGradient>
        </defs>
      </svg>
    ),
    title: "Safari öffnen",
    description: "Öffne diese Webseite in Safari. Andere Browser unterstützen kein 'Zum Home-Bildschirm'."
  },
  {
    icon: <Share className="w-8 h-8 text-[#007AFF]" />,
    title: "Teilen antippen",
    description: "Tippe auf das Teilen-Symbol unten in der Mitte (Quadrat mit Pfeil nach oben)."
  },
  {
    icon: <PlusSquare className="w-8 h-8 text-[#007AFF]" />,
    title: "'Zum Home-Bildschirm'",
    description: "Scrolle nach unten und wähle 'Zum Home-Bildschirm' aus."
  },
  {
    icon: <CheckCircle2 className="w-8 h-8 text-[#34C759]" />,
    title: "Hinzufügen",
    description: "Tippe oben rechts auf 'Hinzufügen'. Nexus erscheint als App auf deinem Home-Bildschirm."
  },
]

export function IOSInstallModal({ isOpen, onClose }: IOSInstallModalProps) {
  // Close on escape key
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose()
    }
    if (isOpen) {
      document.addEventListener("keydown", handleEscape)
      document.body.style.overflow = "hidden"
    }
    return () => {
      document.removeEventListener("keydown", handleEscape)
      document.body.style.overflow = ""
    }
  }, [isOpen, onClose])

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/70 backdrop-blur-sm"
        onClick={onClose}
      />

      {/* Modal */}
      <div className="relative w-full max-w-md bg-gradient-to-b from-card to-background rounded-2xl border border-border/50 shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="relative p-6 pb-4 bg-gradient-to-br from-primary/10 via-transparent to-accent/5">
          <button
            onClick={onClose}
            className="absolute top-4 right-4 p-2 rounded-full hover:bg-white/10 transition-colors"
          >
            <X className="w-5 h-5 text-muted-foreground" />
          </button>

          <div className="flex items-center gap-3 mb-2">
            <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-primary to-accent flex items-center justify-center shadow-lg shadow-primary/25">
              <svg className="w-7 h-7 text-white" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M12 2L2 7l10 5 10-5-10-5z" fill="currentColor"/>
                <path d="M2 17l10 5 10-5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                <path d="M2 12l10 5 10-5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            </div>
            <div>
              <h2 className="text-xl font-semibold text-foreground">
                Nexus installieren
              </h2>
              <p className="text-sm text-muted-foreground">
                iOS / iPadOS
              </p>
            </div>
          </div>
        </div>

        {/* Steps */}
        <div className="p-6 pt-2 space-y-4">
          {steps.map((step, index) => (
            <div
              key={index}
              className="flex gap-4 p-4 rounded-xl bg-card/50 border border-border/30 hover:border-primary/30 transition-colors"
            >
              <div className="shrink-0 w-12 h-12 rounded-lg bg-white/5 flex items-center justify-center">
                {step.icon}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <span className="w-5 h-5 rounded-full bg-primary/20 text-primary text-xs font-bold flex items-center justify-center">
                    {index + 1}
                  </span>
                  <h3 className="font-medium text-foreground">{step.title}</h3>
                </div>
                <p className="text-sm text-muted-foreground leading-relaxed">
                  {step.description}
                </p>
              </div>
            </div>
          ))}
        </div>

        {/* Footer */}
        <div className="p-6 pt-2 border-t border-border/30">
          <div className="flex items-center gap-3 p-3 rounded-lg bg-primary/5 border border-primary/20">
            <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
              <svg className="w-4 h-4 text-primary" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10z" stroke="currentColor" strokeWidth="2"/>
                <path d="M12 16v-4m0-4h.01" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
              </svg>
            </div>
            <p className="text-xs text-muted-foreground">
              <span className="text-foreground font-medium">Wichtig:</span> Nur Safari unterstützt PWAs auf iOS. Chrome und andere Browser funktionieren nicht.
            </p>
          </div>

          <button
            onClick={onClose}
            className="w-full mt-4 px-5 py-3 rounded-xl bg-primary text-primary-foreground font-medium hover:opacity-90 transition-opacity"
          >
            Verstanden
          </button>
        </div>
      </div>
    </div>
  )
}
