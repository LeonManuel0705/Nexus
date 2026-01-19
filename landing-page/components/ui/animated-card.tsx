"use client"

import { useAnimatedBorder } from "@/hooks/use-animated-border"
import { cn } from "@/lib/utils"
import { forwardRef } from "react"

interface AnimatedCardProps extends React.HTMLAttributes<HTMLDivElement> {
  speed?: number
}

export const AnimatedCard = forwardRef<HTMLDivElement, AnimatedCardProps>(
  ({ className, speed = 0.008, children, ...props }, ref) => {
    const { onMouseEnter, onMouseLeave } = useAnimatedBorder({ speed })

    return (
      <div
        ref={ref}
        className={cn("card-hover-bar", className)}
        onMouseEnter={onMouseEnter}
        onMouseLeave={onMouseLeave}
        {...props}
      >
        {children}
      </div>
    )
  }
)

AnimatedCard.displayName = "AnimatedCard"
