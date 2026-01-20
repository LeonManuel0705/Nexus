import React from "react"
import type { Metadata, Viewport } from 'next'
import { Inter, Geist_Mono } from 'next/font/google'
import { Analytics } from '@vercel/analytics/next'
import { PageTransition } from '@/components/page-transition'
import { IOSInstallBanner } from '@/components/ios-install-banner'
import './globals.css'

const inter = Inter({ 
  subsets: ["latin"],
  variable: '--font-inter',
})

const geistMono = Geist_Mono({ 
  subsets: ["latin"],
  variable: '--font-geist-mono',
})

export const metadata: Metadata = {
  title: 'Nexus - Dein ruhiges System für alles',
  description: 'Nexus ist eine kostenlose, datenschutzfreundliche Produktivitäts-App, die Tasks, Kalender, Schule und Fitness in einem ruhigen System vereint.',
  keywords: ['Produktivität', 'App', 'Studenten', 'Tasks', 'Kalender', 'Schule', 'IServ', 'Datenschutz', 'Kostenlos'],
  authors: [{ name: 'Leon Manuel Töpper' }],
  generator: 'Next.js',
  openGraph: {
    title: 'Nexus - Dein ruhiges System für alles',
    description: 'Eine App. Alles an einem Ort. Kostenlos und privat.',
    type: 'website',
    locale: 'de_DE',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Nexus - Dein ruhiges System für alles',
    description: 'Eine App. Alles an einem Ort. Kostenlos und privat.',
  },
}

export const viewport: Viewport = {
  themeColor: '#1a1625',
  width: 'device-width',
  initialScale: 1,
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="de" className={`${inter.variable} ${geistMono.variable}`}>
      <body className="font-sans antialiased">
        <PageTransition>
          {children}
        </PageTransition>
        <IOSInstallBanner />
        <Analytics />
      </body>
    </html>
  )
}
