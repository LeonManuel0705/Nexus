import { Navigation } from "@/components/navigation"
import { Footer } from "@/components/footer"
import { CTA } from "@/components/sections/cta"
import { ValueCard } from "@/components/ui/value-card"
import {
  Calendar,
  CheckSquare,
  GraduationCap,
  Dumbbell,
  Mail
} from "lucide-react"
import type { Metadata } from "next"
import { ImageLightbox } from "@/components/ui/image-lightbox"

export const metadata: Metadata = {
  title: "Features - Nexus",
  description: "Entdecke alle Features von Nexus: Dashboard, Kalender, Schul-Integration, Task-Management, Fitness-Tracking und mehr.",
}

const mainFeatures = [
  {
    icon: Calendar,
    title: "Kalender",
    description: "Alle deine Termine. Ein Kalender.",
    details: [
      "Google Calendar Synchronisation",
      "CalDAV-Server Unterstützung",
      "Mehrere Kalender verwalten",
      "Offline-Funktionalität"
    ],
    color: "accent",
    image: "/screenshots/calendar.png"
  },
  {
    icon: GraduationCap,
    title: "Schul-Modul",
    description: "Speziell für Schüler mit IServ entwickelt.",
    details: [
      "Automatischer Stundenplan-Import",
      "A/B-Wochen Unterstützung",
      "Vertretungsplan-Integration",
      "Hausaufgaben-Tracking"
    ],
    color: "primary",
    image: "/screenshots/school.png"
  },
  {
    icon: CheckSquare,
    title: "Aufgaben",
    description: "Fokussierte Task-Verwaltung ohne Ablenkung.",
    details: [
      "Einfache Prioritäten setzen",
      "Deadlines und Erinnerungen",
      "Projekte organisieren",
      "Wiederkehrende Aufgaben"
    ],
    color: "accent",
    image: "/screenshots/tasks.png"
  },
  {
    icon: Dumbbell,
    title: "Training",
    description: "Dein Fitness-Fortschritt, dokumentiert.",
    details: [
      "Workouts loggen",
      "Wöchentliche Trainingspläne",
      "Fortschritt visualisieren",
      "Übungsbibliothek"
    ],
    color: "primary",
    image: "/screenshots/training.png"
  },
  {
    icon: Mail,
    title: "E-Mail",
    description: "Schul- und Arbeits-Mails integriert.",
    details: [
      "Mehrere Accounts verwalten",
      "Push-Benachrichtigungen",
      "Schnelle Suche",
      "Anhänge verwalten"
    ],
    color: "accent",
    image: "/screenshots/email.png"
  },
]

const coreValues = [
  {
    iconName: "Shield" as const,
    title: "Privatsphäre zuerst",
    description: "Deine Daten werden lokal gespeichert. Externe Dienste nur bei Bedarf."
  },
  {
    iconName: "Lock" as const,
    title: "Komplett kostenlos",
    description: "Keine Premium-Tiers, keine Paywalls. Kostenlos für immer."
  },
  {
    iconName: "WifiOff" as const,
    title: "Offline nutzbar",
    description: "Volle Funktionalität auch ohne Internetverbindung."
  },
  {
    iconName: "Smartphone" as const,
    title: "Cross-Platform",
    description: "Android, iOS/iPadOS (PWA), macOS und Linux."
  },
]

export default function FeaturesPage() {
  return (
    <>
      <Navigation />
      <main className="pt-24">
        {}
        <section className="py-16 md:py-24">
          <div className="mx-auto max-w-4xl px-6 text-center">
            <h1 className="text-4xl md:text-5xl font-semibold tracking-tight mb-6">
              <span className="text-foreground">Features, die </span>
              <span className="gradient-text">Sinn machen</span>
            </h1>
            <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
              Nexus versucht nicht, alles zu sein. Ich baue ein ruhiges System — keine weitere laute App. 
              Features werden nur hinzugefügt, wenn sie Last reduzieren.
            </p>
          </div>
        </section>

        {}
        <section className="py-16 md:py-24 bg-gradient-to-b from-background to-[oklch(0.12_0.02_280)]">
          <div className="mx-auto max-w-6xl px-6">
            <div className="grid gap-8 md:gap-12">
              {mainFeatures.map((feature, index) => (
                <div
                  key={feature.title}
                  className={`grid md:grid-cols-2 gap-8 items-center ${
                    index % 2 === 1 ? "md:[direction:rtl]" : ""
                  }`}
                >
                  {}
                  <div className="md:[direction:ltr]">
                    <div className={`w-12 h-12 rounded-lg flex items-center justify-center mb-4 ${
                      feature.color === "primary" ? "bg-primary/10" : "bg-accent/10"
                    }`}>
                      <feature.icon className={`w-6 h-6 ${
                        feature.color === "primary" ? "text-primary" : "text-accent"
                      }`} />
                    </div>
                    <h2 className="text-2xl md:text-3xl font-semibold text-foreground mb-3">
                      {feature.title}
                    </h2>
                    <p className="text-lg text-muted-foreground mb-6">
                      {feature.description}
                    </p>
                    <ul className="space-y-3">
                      {feature.details.map((detail) => (
                        <li key={detail} className="flex items-center gap-3 text-foreground">
                          <span className={`w-1.5 h-1.5 rounded-full ${
                            feature.color === "primary" ? "bg-primary" : "bg-accent"
                          }`} />
                          {detail}
                        </li>
                      ))}
                    </ul>
                  </div>

                  {}
                  <div className="md:[direction:ltr]">
                    <div className="rounded-xl border border-border/50 bg-card/50 overflow-hidden shadow-lg">
                      <ImageLightbox
                        src={feature.image}
                        alt={`${feature.title} Screenshot`}
                        width={800}
                        height={600}
                      />
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {}
        <section className="py-16 md:py-24">
          <div className="mx-auto max-w-6xl px-6">
            <div className="text-center mb-12">
              <h2 className="text-3xl md:text-4xl font-semibold tracking-tight mb-4 text-foreground">
                Was Nexus anders macht
              </h2>
              <p className="text-lg text-muted-foreground">
                Die meisten Tools lösen ein Problem. Das Leben hat viele.
              </p>
            </div>

            <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-6">
              {coreValues.map((value) => (
                <ValueCard key={value.title} {...value} />
              ))}
            </div>
          </div>
        </section>

        <CTA />
      </main>
      <Footer />
    </>
  )
}
