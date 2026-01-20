"use client"

import { useState, useCallback, useEffect } from "react"
import Image from "next/image"
import { X } from "lucide-react"

interface ImageLightboxProps {
  src: string
  alt: string
  width: number
  height: number
  className?: string
}

export function ImageLightbox({ src, alt, width, height, className }: ImageLightboxProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [isAnimating, setIsAnimating] = useState(false)

  const openLightbox = useCallback(() => {
    setIsOpen(true)
    requestAnimationFrame(() => {
      setIsAnimating(true)
    })
  }, [])

  const closeLightbox = useCallback(() => {
    setIsAnimating(false)
    setTimeout(() => {
      setIsOpen(false)
    }, 300)
  }, [])

  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === "Escape" && isOpen) {
        closeLightbox()
      }
    }

    if (isOpen) {
      document.body.style.overflow = "hidden"
      window.addEventListener("keydown", handleEscape)
    }

    return () => {
      document.body.style.overflow = ""
      window.removeEventListener("keydown", handleEscape)
    }
  }, [isOpen, closeLightbox])

  return (
    <>
      <div
        className={`cursor-zoom-in ${className || ""}`}
        onClick={openLightbox}
      >
        <Image
          src={src}
          alt={alt}
          width={width}
          height={height}
          className="w-full h-auto transition-transform duration-300 hover:scale-[1.02]"
        />
      </div>

      {isOpen && (
        <div
          className={`fixed inset-0 z-50 flex items-center justify-center p-4 md:p-10 cursor-zoom-out transition-all duration-300 ease-out ${
            isAnimating ? "bg-black/95" : "bg-black/0"
          }`}
          onClick={closeLightbox}
        >
          <button
            className={`absolute top-4 right-4 md:top-8 md:right-8 w-12 h-12 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center transition-all duration-300 ease-out ${
              isAnimating ? "opacity-100 rotate-0 scale-100" : "opacity-0 -rotate-90 scale-75"
            }`}
            onClick={(e) => {
              e.stopPropagation()
              closeLightbox()
            }}
          >
            <X className="w-6 h-6 text-white" />
          </button>

          <div
            className={`relative max-w-[94%] max-h-[94vh] transition-all duration-300 ease-out ${
              isAnimating ? "opacity-100 scale-100" : "opacity-0 scale-90"
            }`}
            onClick={(e) => e.stopPropagation()}
          >
            <Image
              src={src}
              alt={alt}
              width={width * 2}
              height={height * 2}
              className="w-auto h-auto max-w-full max-h-[94vh] rounded-2xl shadow-2xl"
              priority
            />
          </div>
        </div>
      )}
    </>
  )
}
