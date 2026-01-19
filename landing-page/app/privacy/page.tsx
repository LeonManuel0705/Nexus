import { Navigation } from "@/components/navigation"
import { Footer } from "@/components/footer"
import type { Metadata } from "next"

export const metadata: Metadata = {
  title: "Datenschutz - Nexus",
  description: "Datenschutzerklärung für Nexus. 100% privat - alle Daten bleiben auf deinem Gerät.",
}

export default function PrivacyPage() {
  return (
    <>
      <Navigation />
      <main className="pt-24">
        <section className="py-16 md:py-24">
          <div className="mx-auto max-w-3xl px-6">
            <h1 className="text-4xl md:text-5xl font-semibold tracking-tight mb-8 text-foreground">
              Datenschutz
            </h1>
            
            <div className="prose prose-invert max-w-none">
              <div className="space-y-8 text-muted-foreground">
                <section>
                  <h2 className="text-xl font-semibold text-foreground mb-4">
                    Meine Philosophie
                  </h2>
                  <p className="leading-relaxed">
                    Nexus wurde mit Privatsphäre als Grundprinzip entwickelt. 
                    Alle deine Daten bleiben auf deinem Gerät. Ich habe keinen Zugriff 
                    auf deine Tasks, Termine, Notizen oder andere persönliche Informationen.
                  </p>
                </section>

                <section>
                  <h2 className="text-xl font-semibold text-foreground mb-4">
                    Welche Daten werden gespeichert?
                  </h2>
                  <p className="leading-relaxed mb-4">
                    Nexus speichert alle Daten ausschließlich lokal auf deinem Gerät:
                  </p>
                  <ul className="list-disc pl-6 space-y-2">
                    <li>Tasks und Aufgaben</li>
                    <li>Kalendereinträge (synchronisiert mit deinen Kalendern)</li>
                    <li>Schulinformationen (IServ-Daten)</li>
                    <li>Trainingseinheiten</li>
                    <li>App-Einstellungen</li>
                  </ul>
                </section>

                <section>
                  <h2 className="text-xl font-semibold text-foreground mb-4">
                    Cloud-Dienste
                  </h2>
                  <p className="leading-relaxed">
                    Wenn du externe Dienste wie Google Calendar oder IServ verbindest, 
                    kommuniziert Nexus direkt mit diesen Diensten. Ich agiere nicht als 
                    Vermittler und speichere keine Kopien dieser Daten auf meinen Servern.
                  </p>
                </section>

                <section>
                  <h2 className="text-xl font-semibold text-foreground mb-4">
                    Website-Analyse
                  </h2>
                  <p className="leading-relaxed">
                    Diese Website verwendet Vercel Analytics für anonymisierte Nutzungsstatistiken. 
                    Es werden keine persönlichen Daten erfasst oder gespeichert.
                  </p>
                </section>

                <section>
                  <h2 className="text-xl font-semibold text-foreground mb-4">
                    Kontakt
                  </h2>
                  <p className="leading-relaxed">
                    Bei Fragen zum Datenschutz erreichst du mich unter:{" "}
                    <a href="mailto:leon.m.toepper@gmail.com?subject=Nexus%20-%20Datenschutz" className="text-primary hover:underline">
                      leon.m.toepper@gmail.com
                    </a>
                  </p>
                </section>

                <p className="text-sm text-muted-foreground/70">
                  Stand: Januar 2026
                </p>
              </div>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  )
}
