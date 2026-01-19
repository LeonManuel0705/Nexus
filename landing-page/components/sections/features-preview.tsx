"use client"

import { Calendar, CheckSquare, GraduationCap, Dumbbell, Mail, LayoutDashboard } from "lucide-react"
import Link from "next/link"
import { AnimatedCard } from "@/components/ui/animated-card"

const features = [
  {
    icon: LayoutDashboard,
    title: "Dashboard",
    description: "Dein personalisierter Startpunkt. Alles Wichtige auf einen Blick.",
  },
  {
    icon: Calendar,
    title: "Kalender",
    description: "Google Calendar, CalDAV und mehr. Alle Termine an einem Ort.",
  },
  {
    icon: GraduationCap,
    title: "Schule",
    description: "IServ-Integration mit Stundenplan, Vertretungen und Hausaufgaben.",
  },
  {
    icon: CheckSquare,
    title: "Aufgaben",
    description: "Fokussierte Task-Verwaltung. Keine Ablenkung, nur Klarheit.",
  },
  {
    icon: Dumbbell,
    title: "Training",
    description: "Workouts tracken, Fortschritt sehen, Ziele erreichen.",
  },
  {
    icon: Mail,
    title: "E-Mail",
    description: "Schul- und Arbeits-Mails direkt in Nexus lesen und verwalten.",
  },
]

export function FeaturesPreview() {
  return (
    <section className="py-24 md:py-32">
      <div className="mx-auto max-w-6xl px-6">
        {}
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl font-semibold tracking-tight mb-4">
            <span className="text-foreground">Alles an </span>
            <span className="gradient-text">einem Ort</span>
          </h2>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            Notizen hier. Tasks dort. Deadlines irgendwo anders. 
            Nexus bringt alles zusammen.
          </p>
        </div>

        {}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((feature, index) => (
            <AnimatedCard
              key={feature.title}
              className="group p-6 cursor-pointer"
              style={{ animationDelay: `${index * 100}ms` }}
            >
              <div className="w-12 h-12 rounded-lg bg-primary/10 flex items-center justify-center mb-4 group-hover:bg-primary/20 transition-colors relative z-10">
                <feature.icon className="w-6 h-6 text-primary" />
              </div>
              <h3 className="text-lg font-medium text-foreground mb-2 relative z-10">
                {feature.title}
              </h3>
              <p className="text-muted-foreground text-sm leading-relaxed relative z-10">
                {feature.description}
              </p>
            </AnimatedCard>
          ))}
        </div>

        {}
        <div className="text-center mt-12">
          <Link
            href="/features"
            className="text-primary hover:underline underline-offset-4 text-sm font-medium"
          >
            Alle Features im Detail ansehen
          </Link>
        </div>
      </div>
    </section>
  )
}
