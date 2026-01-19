import { Navigation } from "@/components/navigation"
import { Footer } from "@/components/footer"
import { CTA } from "@/components/sections/cta"
import { TextCard } from "@/components/ui/text-card"
import Link from "next/link"
import type { Metadata } from "next"

export const metadata: Metadata = {
  title: "Über Nexus - Die Geschichte hinter der App",
  description: "Erfahre, warum Nexus existiert und welche Vision dahinter steht. Gebaut von einem Studenten für Studenten.",
}

const values = [
  {
    title: "Klarheit vor Features",
    description: "Ich füge nur Features hinzu, wenn sie die Last reduzieren. Nicht, weil ich es kann."
  },
  {
    title: "Privatsphäre ist Standard",
    description: "Deine Daten gehören dir. Keine Cloud, kein Tracking, keine Kompromisse."
  },
  {
    title: "Ehrlichkeit",
    description: "Ich verspreche nicht, was ich nicht halten kann. Nexus ist jung — und das ist okay."
  },
  {
    title: "Für echte Menschen",
    description: "Nexus wird im echten Alltag getestet, nicht in Pitch-Decks."
  },
]

export default function AboutPage() {
  return (
    <>
      <Navigation />
      <main className="pt-24">
        {}
        <section className="py-16 md:py-24">
          <div className="mx-auto max-w-4xl px-6">
            <h1 className="text-4xl md:text-5xl font-semibold tracking-tight mb-6 text-center">
              <span className="text-foreground">Warum </span>
              <span className="gradient-text">Nexus</span>
              <span className="text-foreground"> existiert</span>
            </h1>
            <p className="text-lg text-muted-foreground max-w-2xl mx-auto text-center">
              Eine Geschichte über das Chaos, die Frustration — und den Wunsch nach Klarheit.
            </p>
          </div>
        </section>

        {}
        <section className="py-16 md:py-24 bg-gradient-to-b from-background to-[oklch(0.12_0.02_280)]">
          <div className="mx-auto max-w-3xl px-6">
            <div className="prose prose-invert prose-lg max-w-none">
              <div className="space-y-8 text-foreground">
                <p className="text-xl leading-relaxed">
                  Es begann mit einer einfachen Frage: Warum brauche ich 6 verschiedene Apps, 
                  um meinen Tag zu organisieren?
                </p>

                <p className="text-muted-foreground leading-relaxed">
                  Eine App für Aufgaben. Eine für den Kalender. Eine für die Schule. 
                  Eine für Notizen. Eine für Fitness. Und irgendwo dazwischen verlor ich 
                  jeden Tag Zeit — nicht mit produktiver Arbeit, sondern mit dem Wechseln 
                  zwischen Apps, dem Suchen nach Informationen, dem Zusammensetzen eines 
                  Gesamtbildes, das nie vollständig war.
                </p>

                <p className="text-muted-foreground leading-relaxed">
                  Das Schlimmste? Jede einzelne App war gut. Aber zusammen fühlten sie sich 
                  an wie ein fragmentiertes System, das mehr Energie kostete als es sparte.
                </p>

                <div className="py-8 border-y border-border/50">
                  <blockquote className="text-xl text-foreground italic">
                    {'"'}Ich wollte nicht noch eine App. Ich wollte ein System.{'"'}
                  </blockquote>
                </div>

                <p className="text-muted-foreground leading-relaxed">
                  Also begann ich, Nexus zu bauen. Nicht als Startup, nicht für Investoren — 
                  sondern für mich selbst. Ein ruhiger Ort, an dem alles zusammenkommt. 
                  Wo ich morgens aufwache, eine App öffne und sofort weiß, was heute wichtig ist.
                </p>

                <p className="text-muted-foreground leading-relaxed">
                  Nexus ist keine Revolution. Es ist eine Rückkehr zur Einfachheit. 
                  Ein System für Menschen, die ihr Leben nicht mehr improvisieren wollen.
                </p>

                <p className="text-foreground font-medium">
                  — Leon Töpper, Entwickler von Nexus
                </p>
              </div>
            </div>
          </div>
        </section>

        {}
        <section className="py-16 md:py-24">
          <div className="mx-auto max-w-6xl px-6">
            <div className="text-center mb-12">
              <h2 className="text-3xl md:text-4xl font-semibold tracking-tight mb-4 text-foreground">
                Meine Werte
              </h2>
              <p className="text-lg text-muted-foreground">
                Was ich glaube und wie ich baue.
              </p>
            </div>

            <div className="grid sm:grid-cols-2 gap-6">
              {values.map((value) => (
                <TextCard key={value.title} {...value} />
              ))}
            </div>
          </div>
        </section>

        {}
        <section className="py-16 md:py-24 bg-gradient-to-b from-background to-[oklch(0.12_0.02_280)]">
          <div className="mx-auto max-w-4xl px-6">
            <div className="p-8 md:p-12 rounded-2xl border border-primary/30 bg-primary/5">
              <h2 className="text-2xl md:text-3xl font-semibold text-foreground mb-4 text-center">
                Nexus ist noch jung
              </h2>
              <p className="text-lg text-muted-foreground text-center mb-8">
                Ich bin ehrlich: Nexus ist Version 0.2. Es gibt noch Ecken und Kanten. 
                Aber das ist auch eine Chance.
              </p>

              <div className="grid sm:grid-cols-3 gap-6 text-center">
                <div>
                  <div className="text-3xl font-semibold text-primary mb-2">v0.2</div>
                  <div className="text-sm text-muted-foreground">Aktuelle Version</div>
                </div>
                <div>
                  <div className="text-3xl font-semibold text-primary mb-2">1</div>
                  <div className="text-sm text-muted-foreground">Entwickler</div>
                </div>
                <div>
                  <div className="text-3xl font-semibold text-primary mb-2">100%</div>
                  <div className="text-sm text-muted-foreground">Kostenlos</div>
                </div>
              </div>

              <p className="mt-8 text-center text-muted-foreground">
                Als früher Nutzer hast du direkten Einfluss darauf, was Nexus wird. 
                Dein Feedback formt die Zukunft.
              </p>

              <div className="mt-8 text-center">
                <Link
                  href="/roadmap"
                  className="text-primary hover:underline underline-offset-4 font-medium"
                >
                  Sieh dir an, was ich als Nächstes baue
                </Link>
              </div>
            </div>
          </div>
        </section>

        <CTA />
      </main>
      <Footer />
    </>
  )
}
