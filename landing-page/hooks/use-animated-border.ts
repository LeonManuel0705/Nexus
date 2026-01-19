"use client"

import { useCallback, useRef } from "react"

interface AnimatedBorderOptions {
  speed?: number
}

export function useAnimatedBorder(options: AnimatedBorderOptions = {}) {
  const { speed = 0.008 } = options
  const animationRef = useRef<number | null>(null)
  const progressRef = useRef(0)
  const isHoveringRef = useRef(false)

  const handleMouseEnter = useCallback((e: React.MouseEvent<HTMLElement>) => {
    const element = e.currentTarget
    const rect = element.getBoundingClientRect()
    const x = e.clientX - rect.left
    const y = e.clientY - rect.top
    const centerX = rect.width / 2
    const centerY = rect.height / 2

    const cursorAngle = Math.atan2(y - centerY, x - centerX) * (180 / Math.PI) + 90

    const startAngle = ((cursorAngle - 180) % 360 + 360) % 360

    element.style.setProperty('--border-angle', `${startAngle}deg`)
    element.classList.add('animating')

    isHoveringRef.current = true
    const targetProgress = 1

    const animate = () => {
      const animSpeed = isHoveringRef.current ? speed : speed * 2
      const diff = targetProgress - progressRef.current

      if (Math.abs(diff) > 0.001) {
        progressRef.current += diff * animSpeed * 60 / 16.67
        element.style.setProperty('--border-progress', String(progressRef.current))
        animationRef.current = requestAnimationFrame(animate)
      } else {
        progressRef.current = targetProgress
        element.style.setProperty('--border-progress', String(progressRef.current))
      }
    }

    if (animationRef.current) cancelAnimationFrame(animationRef.current)
    animate()
  }, [speed])

  const handleMouseLeave = useCallback((e: React.MouseEvent<HTMLElement>) => {
    const element = e.currentTarget
    isHoveringRef.current = false
    const targetProgress = 0

    const animate = () => {
      const animSpeed = speed * 2
      const diff = targetProgress - progressRef.current

      if (Math.abs(diff) > 0.001) {
        progressRef.current += diff * animSpeed * 60 / 16.67
        element.style.setProperty('--border-progress', String(progressRef.current))
        animationRef.current = requestAnimationFrame(animate)
      } else {
        progressRef.current = targetProgress
        element.style.setProperty('--border-progress', String(progressRef.current))
        element.classList.remove('animating')
      }
    }

    if (animationRef.current) cancelAnimationFrame(animationRef.current)
    animate()
  }, [speed])

  return {
    onMouseEnter: handleMouseEnter,
    onMouseLeave: handleMouseLeave,
  }
}
