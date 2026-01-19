"use client"

import Link from "next/link"
import { ArrowRight } from "lucide-react"
import { AnimatedCard } from "@/components/ui/animated-card"

export function CTA() {
  return (
    <section className="py-24 md:py-32">
      <div className="mx-auto max-w-4xl px-6">
        <AnimatedCard className="relative rounded-2xl bg-card/50 p-8 md:p-12">
          {}
          <div className="absolute top-0 right-0 w-64 h-64 bg-primary/10 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2 z-0" />

          <div className="relative z-10 text-center">
            {}
            <h2 className="text-3xl md:text-4xl font-semibold tracking-tight mb-4 text-foreground text-balance">
              Bereit, das Chaos zu beenden?
            </h2>
            
            <p className="text-lg text-muted-foreground max-w-xl mx-auto mb-8 text-pretty">
              Nexus ist noch klein. Das ist der Vorteil. Werde einer der frühen Nutzer und gestalte mit, was Nexus wird.
            </p>

            {}
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
              <Link
                href="/download"
                className="group px-6 py-3 rounded-lg bg-primary text-primary-foreground font-medium hover:opacity-90 transition-all flex items-center gap-2"
              >
                Nexus ausprobieren
                <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
              </Link>
              <Link
                href="/roadmap"
                className="px-6 py-3 rounded-lg btn-premium text-foreground font-medium"
              >
                <span>Roadmap ansehen</span>
              </Link>
            </div>

            {}
            <p className="mt-8 text-sm text-muted-foreground">
              Kein Druck. Einfach ausprobieren.
            </p>
          </div>
        </AnimatedCard>
      </div>
    </section>
  )
}
