import Link from "next/link"
import Image from "next/image"

const footerLinks = {
  product: [
    { href: "/features", label: "Features" },
    { href: "/download", label: "Download" },
    { href: "/roadmap", label: "Roadmap" },
  ],
  resources: [
    { href: "/about", label: "Über Nexus" },
    { href: "https://github.com/LeonManuel0705/", label: "GitHub", external: true },
    { href: "mailto:leon.m.toepper@gmail.com?subject=Nexus%20-%20Anfrage", label: "Kontakt", external: true },
  ],
  legal: [
    { href: "/privacy", label: "Datenschutz" },
    
  ],
}

export function Footer() {
  return (
    <footer className="border-t border-border/50 bg-background">
      <div className="mx-auto max-w-6xl px-6 py-16">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
          {}
          <div className="col-span-2 md:col-span-1">
            <Link href="/" className="flex items-center gap-3 mb-4">
              <Image
                src="/nexus-logo.png"
                alt="Nexus"
                width={32}
                height={32}
                className="rounded-lg"
              />
              <span className="font-semibold text-lg gradient-text">Nexus</span>
            </Link>
            <p className="text-sm text-muted-foreground leading-relaxed">
              Ein ruhiges System für Menschen, die ihr Leben nicht improvisieren wollen.
            </p>
          </div>

          {}
          <div>
            <h4 className="font-medium text-foreground mb-4">Produkt</h4>
            <ul className="space-y-3">
              {footerLinks.product.map((link) => (
                <li key={link.href}>
                  <Link
                    href={link.href}
                    className="text-sm text-muted-foreground hover:text-foreground transition-colors"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {}
          <div>
            <h4 className="font-medium text-foreground mb-4">Ressourcen</h4>
            <ul className="space-y-3">
              {footerLinks.resources.map((link) => (
                <li key={link.href}>
                  <Link
                    href={link.href}
                    className="text-sm text-muted-foreground hover:text-foreground transition-colors"
                    {...(link.external ? { target: "_blank", rel: "noopener noreferrer" } : {})}
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {}
          <div>
            <h4 className="font-medium text-foreground mb-4">Rechtliches</h4>
            <ul className="space-y-3">
              {footerLinks.legal.map((link) => (
                <li key={link.href}>
                  <Link
                    href={link.href}
                    className="text-sm text-muted-foreground hover:text-foreground transition-colors"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        </div>

        {}
        <div className="mt-12 pt-8 border-t border-border/50 flex flex-col md:flex-row justify-between items-center gap-4">
          <p className="text-sm text-muted-foreground">
            © {new Date().getFullYear()} Leon Manuel Töpper. Alle Rechte vorbehalten.
          </p>
          <p className="text-sm text-muted-foreground">
            100% kostenlos. 100% privat.
          </p>
        </div>
      </div>
    </footer>
  )
}
