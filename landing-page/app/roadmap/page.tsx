import { Navigation } from "@/components/navigation"
import { Footer } from "@/components/footer"
import { CTA } from "@/components/sections/cta"
import { CheckCircle2, Circle, Loader2 } from "lucide-react"
import type { Metadata } from "next"

export const metadata: Metadata = {
  title: "Roadmap - Nexus",
  description: "Sieh dir an, was ich als Nächstes baue. Die Nexus-Roadmap zeigt, wohin die Reise geht.",
}

type RoadmapItem = {
  title: string
  description: string
  status: "done" | "in-progress" | "planned"
}

type RoadmapPhase = {
  phase: string
  title: string
  items: RoadmapItem[]
}

const roadmap: RoadmapPhase[] = [
  {
    phase: "Phase 1",
    title: "Fundament",
    items: [
      {
        title: "Kern-Dashboard",
        description: "Personalisierter Startbildschirm mit Tagesübersicht",
        status: "done"
      },
      {
        title: "Task-Management",
        description: "Aufgaben erstellen, priorisieren und abhaken",
        status: "done"
      },
      {
        title: "Notizen-System",
        description: "Einfache Notizen mit Markdown-Unterstützung",
        status: "done"
      },
      {
        title: "IServ-Anbindung",
        description: "Stundenplan, Vertretungen und Hausaufgaben",
        status: "done"
      },
    ]
  },
  {
    phase: "Phase 2",
    title: "Erweiterung",
    items: [
      {
        title: "Training-Modul",
        description: "Workouts tracken und Fortschritt visualisieren",
        status: "done"
      },
      {
        title: "E-Mail-Integration",
        description: "Schul- und Arbeits-Mails direkt in Nexus",
        status: "in-progress"
      },
      {
        title: "Kalender-Integration",
        description: "Google Calendar und CalDAV Synchronisation",
        status: "in-progress"
      },
      {
        title: "Widget-Anpassung",
        description: "Dashboard nach deinen Wünschen gestalten",
        status: "planned"
      },
      {
        title: "ÖPNV-Kalender-Anbindung",
        description: "Automatische Nahverkehr-Verbindungen zu deinen Terminen",
        status: "planned"
      },
      {
        title: "ÖPNV-Training-Anbindung",
        description: "Automatische Anfahrt zu Trainingsorten finden",
        status: "planned"
      },
      {
        title: "Karten-Integration",
        description: "Navigation und Standort-Dienste direkt in Nexus",
        status: "planned"
      },
    ]
  },
  {
    phase: "Phase 3",
    title: "Optimierung",
    items: [
      {
        title: "Fokus-Modus",
        description: "Ablenkungsfreier Modus für konzentriertes Arbeiten",
        status: "planned"
      },
      {
        title: "Statistiken",
        description: "Einblicke in deine Produktivität und Gewohnheiten",
        status: "planned"
      },
      {
        title: "Vorlagen",
        description: "Vorgefertigte Strukturen für häufige Workflows",
        status: "planned"
      },
      {
        title: "Tastenkürzel",
        description: "Schnelle Navigation für Power-User",
        status: "planned"
      },
    ]
  },
  {
    phase: "Phase 4",
    title: "Zukunft",
    items: [
      {
        title: "Optionale Cloud-Sync",
        description: "Geräteübergreifende Synchronisation (opt-in)",
        status: "planned"
      },
      {
        title: "AI-Assistent",
        description: "Intelligenter Assistent für Planung und Produktivität",
        status: "planned"
      },
      {
        title: "Habit-Tracking",
        description: "Gewohnheiten aufbauen und verfolgen",
        status: "planned"
      },
      {
        title: "Pomodoro-Timer",
        description: "Integrierte Zeitmanagement-Technik",
        status: "planned"
      },
      {
        title: "API für Entwickler",
        description: "Nexus erweitern und integrieren",
        status: "planned"
      },
    ]
  },
]

function StatusIcon({ status }: { status: RoadmapItem["status"] }) {
  switch (status) {
    case "done":
      return <CheckCircle2 className="w-5 h-5 text-primary" />
    case "in-progress":
      return <Loader2 className="w-5 h-5 text-accent animate-spin" />
    case "planned":
      return <Circle className="w-5 h-5 text-muted-foreground/50" />
  }
}

function StatusLabel({ status }: { status: RoadmapItem["status"] }) {
  switch (status) {
    case "done":
      return <span className="text-xs text-primary">Fertig</span>
    case "in-progress":
      return <span className="text-xs text-accent">In Arbeit</span>
    case "planned":
      return <span className="text-xs text-muted-foreground">Geplant</span>
  }
}

export default function RoadmapPage() {
  return (
    <>
      <Navigation />
      <main className="pt-24">
        {}
        <section className="py-16 md:py-24">
          <div className="mx-auto max-w-4xl px-6 text-center">
            <h1 className="text-4xl md:text-5xl font-semibold tracking-tight mb-6">
              <span className="text-foreground">Die </span>
              <span className="gradient-text">Roadmap</span>
            </h1>
            <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
              Dies ist Nexus v0.2 — und es wird nur besser.
              Was Nexus wird, hängt von seinen frühen Nutzern ab.
            </p>
          </div>
        </section>

        {}
        <section className="py-8">
          <div className="mx-auto max-w-4xl px-6">
            <div className="flex flex-wrap justify-center gap-6 md:gap-12 p-6 rounded-xl border border-border/50 bg-card/30">
              <div className="text-center">
                <div className="text-3xl font-semibold text-primary mb-1">
                  {roadmap.flatMap(p => p.items).filter(i => i.status === "done").length}
                </div>
                <div className="text-sm text-muted-foreground">Fertig</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-semibold text-accent mb-1">
                  {roadmap.flatMap(p => p.items).filter(i => i.status === "in-progress").length}
                </div>
                <div className="text-sm text-muted-foreground">In Arbeit</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-semibold text-muted-foreground mb-1">
                  {roadmap.flatMap(p => p.items).filter(i => i.status === "planned").length}
                </div>
                <div className="text-sm text-muted-foreground">Geplant</div>
              </div>
            </div>
          </div>
        </section>

        {}
        <section className="py-16 md:py-24">
          <div className="mx-auto max-w-4xl px-6">
            <div className="space-y-16">
              {roadmap.map((phase, phaseIndex) => (
                <div key={phase.phase} className="relative">
                  {/* Phase Header */}
                  <div className="flex items-center gap-4 mb-6">
                    <div className="relative group">
                      {/* Outer glow ring */}
                      <div className="absolute -inset-1 bg-gradient-to-br from-primary/40 via-accent/30 to-primary/20 rounded-2xl blur-md opacity-60 group-hover:opacity-100 transition-opacity" />
                      {/* Main container */}
                      <div className="relative w-14 h-14 rounded-xl bg-gradient-to-br from-background via-card to-background border border-primary/30 flex items-center justify-center shadow-lg shadow-primary/10">
                        {/* Inner gradient accent */}
                        <div className="absolute inset-[3px] rounded-[10px] bg-gradient-to-br from-primary/10 via-transparent to-accent/10" />
                        {/* Number */}
                        <span className="relative text-xl font-bold bg-gradient-to-br from-primary via-accent to-primary bg-clip-text text-transparent">
                          {phaseIndex + 1}
                        </span>
                      </div>
                    </div>
                    <div>
                      <div className="text-sm text-muted-foreground">{phase.phase}</div>
                      <h2 className="text-xl font-semibold text-foreground">{phase.title}</h2>
                    </div>
                  </div>

                  {}
                  <div className="ml-6 pl-10 border-l border-border/50 space-y-4">
                    {phase.items.map((item) => (
                      <div
                        key={item.title}
                        className="relative p-4 rounded-lg border border-border/50 bg-card/30 hover:bg-card/50 transition-colors"
                      >
                        {}
                        <div className="absolute -left-[calc(2.5rem+1px)] top-1/2 -translate-y-1/2 w-3 h-3 rounded-full border-2 border-border bg-background" />
                        
                        <div className="flex items-start justify-between gap-4">
                          <div className="flex-1">
                            <div className="flex items-center gap-2 mb-1">
                              <StatusIcon status={item.status} />
                              <h3 className="font-medium text-foreground">{item.title}</h3>
                            </div>
                            <p className="text-sm text-muted-foreground ml-7">
                              {item.description}
                            </p>
                          </div>
                          <StatusLabel status={item.status} />
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {}
        <section className="py-16 md:py-24 bg-gradient-to-b from-background to-[oklch(0.12_0.02_280)]">
          <div className="mx-auto max-w-4xl px-6">
            <div className="p-8 md:p-12 rounded-2xl border border-primary/30 bg-primary/5 text-center">
              <h2 className="text-2xl md:text-3xl font-semibold text-foreground mb-4">
                Du bestimmst mit
              </h2>
              <p className="text-lg text-muted-foreground mb-6">
                Frühe Nutzer beeinflussen direkt, was Nexus wird. 
                Dein Feedback formt Features, Prioritäten und Richtung.
              </p>
              <a
                href="mailto:leon.m.toepper@gmail.com?subject=Nexus%20-%20Feedback"
                className="inline-flex items-center gap-2 text-primary hover:underline underline-offset-4 font-medium"
              >
                Schreib uns an
              </a>
            </div>
          </div>
        </section>

        <CTA />
      </main>
      <Footer />
    </>
  )
}
