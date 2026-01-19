"use client"

import { AnimatedCard } from "@/components/ui/animated-card"

export function Philosophy() {
  return (
    <section className="py-24 md:py-32 bg-gradient-to-b from-background to-[oklch(0.12_0.02_280)]">
      <div className="mx-auto max-w-4xl px-6">
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl font-semibold tracking-tight mb-4 text-foreground">
            Warum Nexus existiert
          </h2>
        </div>

        {}
        <div className="relative">
          <div className="absolute -left-4 top-0 w-1 h-full bg-gradient-to-b from-primary via-[oklch(0.50_0.16_310)] to-[oklch(0.70_0.15_330)] rounded-full" />
          
          <blockquote className="pl-8 md:pl-12">
            <p className="text-xl md:text-2xl text-foreground leading-relaxed mb-6">
              {'"'}Ich habe Nexus gebaut, weil das Jonglieren zwischen 6 verschiedenen Apps für Tasks, Schule, Termine und Leben einfach falsch war.{'"'}
            </p>
            <footer className="text-muted-foreground">
              — Leon, Entwickler von Nexus
            </footer>
          </blockquote>
        </div>

        {}
        <div className="mt-20 grid md:grid-cols-2 gap-8">
          {}
          <AnimatedCard className="p-6 bg-card/30">
            <h3 className="text-lg font-medium text-muted-foreground mb-4 relative z-10">
              Große Apps sind...
            </h3>
            <ul className="space-y-3 relative z-10">
              <li className="flex items-center gap-3 text-muted-foreground">
                <span className="w-1.5 h-1.5 rounded-full bg-muted-foreground/50" />
                Langsam
              </li>
              <li className="flex items-center gap-3 text-muted-foreground">
                <span className="w-1.5 h-1.5 rounded-full bg-muted-foreground/50" />
                Überladen mit Features
              </li>
              <li className="flex items-center gap-3 text-muted-foreground">
                <span className="w-1.5 h-1.5 rounded-full bg-muted-foreground/50" />
                Unpersönlich
              </li>
            </ul>
          </AnimatedCard>

          {}
          <AnimatedCard className="p-6 bg-primary/5 glow">
            <h3 className="text-lg font-medium text-foreground mb-4 relative z-10">
              Nexus ist...
            </h3>
            <ul className="space-y-3 relative z-10">
              <li className="flex items-center gap-3 text-foreground">
                <span className="w-1.5 h-1.5 rounded-full bg-primary" />
                Schnell und fokussiert
              </li>
              <li className="flex items-center gap-3 text-foreground">
                <span className="w-1.5 h-1.5 rounded-full bg-primary" />
                Nur das Wesentliche
              </li>
              <li className="flex items-center gap-3 text-foreground">
                <span className="w-1.5 h-1.5 rounded-full bg-primary" />
                Gebaut für echte Menschen
              </li>
            </ul>
          </AnimatedCard>
        </div>

        {}
        <p className="mt-12 text-center text-lg text-muted-foreground">
          Nexus ist klein genug, um sich zu kümmern — und ambitioniert genug, um wichtig zu sein.
        </p>
      </div>
    </section>
  )
}
