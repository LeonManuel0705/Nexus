import { Navigation } from "@/components/navigation"
import { Footer } from "@/components/footer"
import { PlatformCard } from "@/components/ui/platform-card"
import { ArrowRight } from "lucide-react"
import Link from "next/link"
import type { Metadata } from "next"

export const metadata: Metadata = {
  title: "Download - Nexus",
  description: "Lade Nexus herunter für Android, iOS, macOS oder Linux. Kostenlos, privat und offline nutzbar.",
}

const platforms = [
  {
    iconName: "Smartphone" as const,
    name: "Android",
    description: "Native APK für maximale Performance",
    downloadLabel: "APK herunterladen",
    downloadUrl: "#android",
    badge: "Empfohlen",
    features: ["Native Performance", "Alle Features", "Offline-Modus"]
  },
  {
    iconName: "Globe" as const,
    name: "iOS / iPadOS",
    description: "Progressive Web App für Apple-Geräte",
    downloadLabel: "PWA installieren",
    downloadUrl: "#ios",
    badge: null,
    features: ["Safari öffnen", "Teilen antippen", "Zum Home-Bildschirm"]
  },
  {
    iconName: "Monitor" as const,
    name: "macOS",
    description: "Desktop-App für den Mac",
    downloadLabel: "Für Mac laden",
    downloadUrl: "#macos",
    badge: null,
    features: ["Native App", "Menübar-Integration", "Tastenkürzel"]
  },
  {
    iconName: "Monitor" as const,
    name: "Linux",
    description: "AppImage für alle Distributionen",
    downloadLabel: "AppImage laden",
    downloadUrl: "#linux",
    badge: null,
    features: ["AppImage Format", "Keine Installation", "Alle Distros"]
  },
]

const requirements = [
  { platform: "Android", requirement: "Android 8.0 oder höher" },
  { platform: "iOS/iPadOS", requirement: "iOS 14.0 / iPadOS 14.0 oder höher" },
  { platform: "macOS", requirement: "macOS 11 Big Sur oder höher" },
  { platform: "Linux", requirement: "64-bit Linux mit GLIBC 2.17+" },
]

export default function DownloadPage() {
  return (
    <>
      <Navigation />
      <main className="pt-24">
        {}
        <section className="py-16 md:py-24">
          <div className="mx-auto max-w-4xl px-6 text-center">
            <h1 className="text-4xl md:text-5xl font-semibold tracking-tight mb-6">
              <span className="gradient-text">Nexus</span>
              <span className="text-foreground"> herunterladen</span>
            </h1>
            <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
              Wähle deine Plattform und starte in unter 5 Minuten. 
              Dein System aufzubauen war noch nie so einfach.
            </p>
          </div>
        </section>

        {}
        <section className="py-8 md:py-16">
          <div className="mx-auto max-w-6xl px-6">
            <div className="grid sm:grid-cols-2 gap-6">
              {platforms.map((platform) => (
                <PlatformCard key={platform.name} {...platform} />
              ))}
            </div>
          </div>
        </section>

        {}
        <section className="py-16 md:py-24 bg-gradient-to-b from-background to-[oklch(0.12_0.02_280)]">
          <div className="mx-auto max-w-4xl px-6">
            <div className="text-center mb-12">
              <h2 className="text-3xl md:text-4xl font-semibold tracking-tight mb-4 text-foreground">
                In 3 Schritten starten
              </h2>
              <p className="text-lg text-muted-foreground">
                Dein System steht schneller, als du denkst.
              </p>
            </div>

            <div className="grid md:grid-cols-3 gap-8">
              <div className="text-center">
                <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center mx-auto mb-4">
                  <span className="text-xl font-semibold text-primary">1</span>
                </div>
                <h3 className="font-medium text-foreground mb-2">Herunterladen</h3>
                <p className="text-sm text-muted-foreground">
                  Wähle deine Plattform und installiere Nexus.
                </p>
              </div>

              <div className="text-center">
                <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center mx-auto mb-4">
                  <span className="text-xl font-semibold text-primary">2</span>
                </div>
                <h3 className="font-medium text-foreground mb-2">Einrichten</h3>
                <p className="text-sm text-muted-foreground">
                  Verbinde deinen Kalender und IServ (optional).
                </p>
              </div>

              <div className="text-center">
                <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center mx-auto mb-4">
                  <span className="text-xl font-semibold text-primary">3</span>
                </div>
                <h3 className="font-medium text-foreground mb-2">Loslegen</h3>
                <p className="text-sm text-muted-foreground">
                  Erstelle deine erste Aufgabe und beginne.
                </p>
              </div>
            </div>

            <div className="mt-12 p-6 rounded-xl border border-border/50 bg-card/30 text-center">
              <p className="text-muted-foreground mb-2">
                Dein System muss nicht perfekt sein. Es muss nur existieren.
              </p>
              <p className="text-sm text-muted-foreground">
                Starte chaotisch. Ende klar.
              </p>
            </div>
          </div>
        </section>

        {}
        <section className="py-16 md:py-24">
          <div className="mx-auto max-w-4xl px-6">
            <h2 className="text-2xl font-semibold text-foreground mb-8 text-center">
              Systemanforderungen
            </h2>
            
            <div className="grid sm:grid-cols-2 gap-4">
              {requirements.map((req) => (
                <div
                  key={req.platform}
                  className="flex items-center justify-between p-4 rounded-lg border border-border/50 bg-card/30"
                >
                  <span className="font-medium text-foreground">{req.platform}</span>
                  <span className="text-sm text-muted-foreground">{req.requirement}</span>
                </div>
              ))}
            </div>
          </div>
        </section>

        {}
        <section className="py-16 md:py-24 bg-gradient-to-b from-background to-[oklch(0.12_0.02_280)]">
          <div className="mx-auto max-w-4xl px-6 text-center">
            <h2 className="text-2xl font-semibold text-foreground mb-4">
              Probleme bei der Installation?
            </h2>
            <p className="text-muted-foreground mb-6">
              Als früher Nutzer bekommst du direkten Support.
            </p>
            <Link
              href="mailto:leon.m.toepper@gmail.com?subject=Nexus%20-%20Installation"
              className="inline-flex items-center gap-2 text-primary hover:underline underline-offset-4 font-medium"
            >
              Schreib uns eine E-Mail
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </section>
      </main>
      <Footer />
    </>
  )
}
