"use client"

import { useState, useEffect } from "react"
import { X } from "lucide-react"
import { IOSInstallModal } from "./ios-install-modal"

const STORAGE_KEY = "nexus-ios-banner-dismissed"

export function IOSInstallBanner() {
  const [isVisible, setIsVisible] = useState(false)
  const [isModalOpen, setIsModalOpen] = useState(false)

  useEffect(() => {
    // Check if we should show the banner
    const checkVisibility = () => {
      // Check if iOS/iPadOS
      const isIOS =
        /iPad|iPhone|iPod/.test(navigator.userAgent) ||
        (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)

      if (!isIOS) return false

      // Check if already running as PWA
      const isPWA =
        window.matchMedia("(display-mode: standalone)").matches ||
        (window.navigator as any).standalone === true

      if (isPWA) return false

      // Check if user dismissed the banner
      const isDismissed = localStorage.getItem(STORAGE_KEY) === "true"
      if (isDismissed) return false

      return true
    }

    // Small delay to let page load
    const timer = setTimeout(() => {
      setIsVisible(checkVisibility())
    }, 1000)

    return () => clearTimeout(timer)
  }, [])

  const handleDismiss = () => {
    localStorage.setItem(STORAGE_KEY, "true")
    setIsVisible(false)
  }

  const handleShowInstructions = () => {
    setIsModalOpen(true)
  }

  if (!isVisible) return null

  return (
    <>
      {/* Banner */}
      <div className="fixed bottom-0 left-0 right-0 z-40 p-4 pb-safe animate-slide-up">
        <div className="mx-auto max-w-lg">
          <div className="relative overflow-hidden rounded-2xl border border-primary/30 bg-gradient-to-r from-card via-card to-card shadow-2xl shadow-primary/10">
            {/* Gradient accent line */}
            <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-primary via-accent to-primary" />

            <div className="p-4 flex items-center gap-4">
              {/* App icon */}
              <div className="shrink-0 w-14 h-14 rounded-xl bg-gradient-to-br from-primary to-accent flex items-center justify-center shadow-lg shadow-primary/25">
                <svg className="w-8 h-8 text-white" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M12 2L2 7l10 5 10-5-10-5z" fill="currentColor"/>
                  <path d="M2 17l10 5 10-5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  <path d="M2 12l10 5 10-5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              </div>

              {/* Text */}
              <div className="flex-1 min-w-0">
                <h3 className="font-semibold text-foreground text-sm">
                  Nexus als App installieren
                </h3>
                <p className="text-xs text-muted-foreground mt-0.5">
                  Vollbild-Erlebnis auf deinem Home-Bildschirm
                </p>
              </div>

              {/* Actions */}
              <div className="shrink-0 flex items-center gap-2">
                <button
                  onClick={handleShowInstructions}
                  className="px-4 py-2 rounded-lg bg-primary text-primary-foreground text-sm font-medium hover:opacity-90 transition-opacity whitespace-nowrap"
                >
                  So geht's
                </button>
                <button
                  onClick={handleDismiss}
                  className="p-2 rounded-lg hover:bg-white/10 transition-colors"
                  aria-label="Schließen"
                >
                  <X className="w-5 h-5 text-muted-foreground" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Modal */}
      <IOSInstallModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} />

      {/* Animation styles */}
      <style jsx>{`
        @keyframes slide-up {
          from {
            transform: translateY(100%);
            opacity: 0;
          }
          to {
            transform: translateY(0);
            opacity: 1;
          }
        }
        .animate-slide-up {
          animation: slide-up 0.4s ease-out;
        }
        .pb-safe {
          padding-bottom: max(1rem, env(safe-area-inset-bottom));
        }
      `}</style>
    </>
  )
}
