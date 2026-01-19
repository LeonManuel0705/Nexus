import Link from "next/link"
import { ArrowRight, ChevronDown } from "lucide-react"

export function Hero() {
  return (
    <section className="relative min-h-screen flex flex-col items-center justify-center overflow-hidden">
      {}
      <div className="absolute inset-0 bg-gradient-to-b from-background via-background to-[oklch(0.12_0.02_280)]" />

      {}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-[800px] h-[500px] bg-[oklch(0.55_0.18_280_/_0.08)] rounded-full blur-[100px] animate-pulse" style={{ animationDuration: '4s' }} />
      <div className="absolute top-1/3 left-1/4 w-[400px] h-[300px] bg-[oklch(0.50_0.16_310_/_0.06)] rounded-full blur-[80px]" />
      <div className="absolute top-1/3 right-1/4 w-[300px] h-[200px] bg-[oklch(0.70_0.15_330_/_0.05)] rounded-full blur-[60px]" />

      <div className="relative z-10 mx-auto max-w-4xl px-6 text-center pt-24">
        {}
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full border border-border/50 bg-secondary/30 mb-8 animate-fade-in-up">
          <span className="w-2 h-2 rounded-full bg-primary animate-pulse" />
          <span className="text-sm text-muted-foreground">
            Version 0.2 — Werde Teil der frühen Nutzer
          </span>
        </div>

        {}
        <h1 className="text-4xl sm:text-5xl md:text-6xl lg:text-7xl font-bold tracking-tight leading-[1.05] mb-6 animate-fade-in-up animation-delay-100">
          <span className="text-foreground">Dein Alltag. </span>
          <span className="gradient-text">Organisiert.</span>
        </h1>

        {}
        <p className="text-lg sm:text-xl text-muted-foreground max-w-2xl mx-auto mb-10 leading-relaxed animate-fade-in-up animation-delay-200">
          Nexus ist ein ruhiges System für alle, die aufhören wollen zu improvisieren.
          Tasks, Kalender, Schule – alles an einem Ort.
        </p>

        {}
        <div className="flex flex-col sm:flex-row items-center justify-center gap-4 animate-fade-in-up animation-delay-300">
          <Link
            href="/download"
            className="group px-8 py-4 rounded-lg bg-primary text-primary-foreground font-semibold hover:opacity-90 transition-all flex items-center gap-2 text-lg"
          >
            Nexus ausprobieren
            <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
          </Link>
          <Link
            href="/features"
            className="px-8 py-4 rounded-lg btn-premium text-foreground font-medium text-lg"
          >
            <span>Features entdecken</span>
          </Link>
        </div>

        {}
        <div className="mt-16 flex flex-wrap items-center justify-center gap-8 text-sm text-muted-foreground animate-fade-in-up animation-delay-400">
          <div className="flex items-center gap-2">
            <div className="w-5 h-5 rounded-full bg-primary/20 flex items-center justify-center">
              <div className="w-2 h-2 rounded-full bg-primary" />
            </div>
            <span>100% kostenlos</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-5 h-5 rounded-full bg-accent/20 flex items-center justify-center">
              <div className="w-2 h-2 rounded-full bg-accent" />
            </div>
            <span>Daten bleiben lokal</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-5 h-5 rounded-full bg-primary/20 flex items-center justify-center">
              <div className="w-2 h-2 rounded-full bg-primary" />
            </div>
            <span>Offline nutzbar</span>
          </div>
        </div>
      </div>

      {}
      <div className="absolute bottom-8 left-1/2 -translate-x-1/2 animate-bounce">
        <div className="w-6 h-10 rounded-full border-2 border-border/50 flex justify-center pt-2">
          <div className="w-1 h-2 rounded-full bg-muted-foreground" />
        </div>
      </div>
    </section>
  )
}
