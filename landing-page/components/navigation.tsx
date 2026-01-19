"use client"

import Link from "next/link"
import Image from "next/image"
import { usePathname } from "next/navigation"
import { useState } from "react"
import { cn } from "@/lib/utils"
import { Menu, X } from "lucide-react"

const navItems = [
  { href: "/", label: "Start" },
  { href: "/features", label: "Features" },
  { href: "/about", label: "Über Nexus" },
  { href: "/roadmap", label: "Roadmap" },
  { href: "/download", label: "Download" },
]

export function Navigation() {
  const pathname = usePathname()
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

  return (
    <header className="fixed top-0 left-0 right-0 z-50 glass border-b border-border/50">
      <nav className="mx-auto max-w-6xl px-6 py-4">
        <div className="flex items-center justify-between">
          {}
          <Link href="/" className="flex items-center gap-3 group">
            <Image
              src="/nexus-logo.png"
              alt="Nexus"
              width={42}
              height={42}
              className="rounded-lg"
            />
            <span className="font-bold text-2xl gradient-text">
              Nexus
            </span>
          </Link>

          {}
          <div className="hidden md:flex items-center gap-1">
            {navItems.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                data-text={item.label}
                className={cn(
                  "px-4 py-2 rounded-md text-sm font-medium nav-link-gradient",
                  pathname === item.href
                    ? "text-primary bg-primary/10"
                    : "text-muted-foreground"
                )}
              >
                {item.label}
              </Link>
            ))}
          </div>

          {}
          <div className="hidden md:block">
            <Link
              href="/download"
              className="px-5 py-2.5 rounded-lg bg-primary text-primary-foreground text-sm font-medium hover:opacity-90 transition-opacity"
            >
              Jetzt starten
            </Link>
          </div>

          {}
          <button
            type="button"
            className="md:hidden p-2 text-muted-foreground hover:text-foreground transition-colors"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            aria-label="Menü öffnen"
          >
            {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>

        {}
        {mobileMenuOpen && (
          <div className="md:hidden mt-4 pb-4 border-t border-border/50 pt-4">
            <div className="flex flex-col gap-2">
              {navItems.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={() => setMobileMenuOpen(false)}
                  className={cn(
                    "px-4 py-3 rounded-md text-sm font-medium transition-colors",
                    pathname === item.href
                      ? "text-primary bg-primary/10"
                      : "text-muted-foreground hover:text-foreground hover:bg-secondary/50"
                  )}
                >
                  {item.label}
                </Link>
              ))}
              <Link
                href="/download"
                onClick={() => setMobileMenuOpen(false)}
                className="mt-2 px-4 py-3 rounded-lg bg-primary text-primary-foreground text-sm font-medium text-center hover:opacity-90 transition-opacity"
              >
                Jetzt starten
              </Link>
            </div>
          </div>
        )}
      </nav>
    </header>
  )
}
