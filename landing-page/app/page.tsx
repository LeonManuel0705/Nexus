import { Navigation } from "@/components/navigation"
import { Footer } from "@/components/footer"
import { Hero } from "@/components/sections/hero"
import { FeaturesPreview } from "@/components/sections/features-preview"
import { Philosophy } from "@/components/sections/philosophy"
import { CTA } from "@/components/sections/cta"

export default function HomePage() {
  return (
    <>
      <Navigation />
      <main>
        <Hero />
        <FeaturesPreview />
        <Philosophy />
        <CTA />
      </main>
      <Footer />
    </>
  )
}
