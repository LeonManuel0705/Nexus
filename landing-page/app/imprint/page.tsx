import { Navigation } from "@/components/navigation"
import { Footer } from "@/components/footer"
import type { Metadata } from "next"

export const metadata: Metadata = {
  title: "Impressum - Nexus",
  description: "Impressum und rechtliche Informationen zu Nexus.",
}

export default function ImprintPage() {
  return (
    <>
      <Navigation />
      <main className="pt-24">
        <section className="py-16 md:py-24">
          <div className="mx-auto max-w-3xl px-6">
            <h1 className="text-4xl md:text-5xl font-semibold tracking-tight mb-8 text-foreground">
              Impressum
            </h1>
            
            <div className="prose prose-invert max-w-none">
              <div className="space-y-8 text-muted-foreground">
                <section>
                  <h2 className="text-xl font-semibold text-foreground mb-4">
                    Angaben gemäß § 5 TMG
                  </h2>
                  <p className="leading-relaxed">
                    Leon [Nachname]<br />
                    [Straße und Hausnummer]<br />
                    [PLZ und Ort]<br />
                    Deutschland
                  </p>
                </section>

                <section>
                  <h2 className="text-xl font-semibold text-foreground mb-4">
                    Kontakt
                  </h2>
                  <p className="leading-relaxed">
                    E-Mail:{" "}
                    <a href="mailto:leon.m.toepper@gmail.com?subject=Nexus%20-%20Kontakt" className="text-primary hover:underline">
                      leon.m.toepper@gmail.com
                    </a>
                  </p>
                </section>

                <section>
                  <h2 className="text-xl font-semibold text-foreground mb-4">
                    Verantwortlich für den Inhalt nach § 55 Abs. 2 RStV
                  </h2>
                  <p className="leading-relaxed">
                    Leon [Nachname]<br />
                    [Adresse wie oben]
                  </p>
                </section>

                <section>
                  <h2 className="text-xl font-semibold text-foreground mb-4">
                    Haftungsausschluss
                  </h2>
                  
                  <h3 className="text-lg font-medium text-foreground mb-2 mt-6">
                    Haftung für Inhalte
                  </h3>
                  <p className="leading-relaxed mb-4">
                    Die Inhalte unserer Seiten wurden mit größter Sorgfalt erstellt. 
                    Für die Richtigkeit, Vollständigkeit und Aktualität der Inhalte 
                    können wir jedoch keine Gewähr übernehmen.
                  </p>

                  <h3 className="text-lg font-medium text-foreground mb-2">
                    Haftung für Links
                  </h3>
                  <p className="leading-relaxed">
                    Unser Angebot enthält Links zu externen Webseiten Dritter, auf deren 
                    Inhalte wir keinen Einfluss haben. Deshalb können wir für diese fremden 
                    Inhalte auch keine Gewähr übernehmen.
                  </p>
                </section>

                <section>
                  <h2 className="text-xl font-semibold text-foreground mb-4">
                    Urheberrecht
                  </h2>
                  <p className="leading-relaxed">
                    Die durch die Seitenbetreiber erstellten Inhalte und Werke auf diesen 
                    Seiten unterliegen dem deutschen Urheberrecht. Die Vervielfältigung, 
                    Bearbeitung, Verbreitung und jede Art der Verwertung außerhalb der 
                    Grenzen des Urheberrechtes bedürfen der schriftlichen Zustimmung des 
                    jeweiligen Autors bzw. Erstellers.
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
