import React from "react";
import {
  interpolate,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { COLORS, GRADIENTS, FONTS } from "../theme";

interface AnimatedTextProps {
  text: string;
  delay?: number;
  fontSize?: number;
  gradient?: boolean;
  color?: string;
  style?: React.CSSProperties;
  letterByLetter?: boolean;
  weight?: number;
}

export const AnimatedText: React.FC<AnimatedTextProps> = ({
  text,
  delay = 0,
  fontSize = 72,
  gradient = false,
  color = COLORS.white,
  style = {},
  letterByLetter = false,
  weight = 700,
}) => {
  const frame = useCurrentFrame();

  if (letterByLetter) {
    return (
      <div
        style={{
          display: "flex",
          justifyContent: "center",
          flexWrap: "wrap",
          ...style,
        }}
      >
        {text.split("").map((char, i) => {
          const charDelay = delay + i * 2;
          const charOpacity = interpolate(
            frame - charDelay,
            [0, 12],
            [0, 1],
            { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
          );
          const y = interpolate(frame - charDelay, [0, 12], [30, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          });

          return (
            <span
              key={i}
              style={{
                display: "inline-block",
                fontSize,
                fontFamily: FONTS.display,
                fontWeight: weight,
                color,
                opacity: charOpacity,
                transform: `translateY(${y}px)`,
                ...(gradient
                  ? {
                      background: GRADIENTS.brand,
                      WebkitBackgroundClip: "text",
                      WebkitTextFillColor: "transparent",
                    }
                  : {}),
                whiteSpace: char === " " ? "pre" : undefined,
                letterSpacing: fontSize > 60 ? -2 : -0.5,
              }}
            >
              {char}
            </span>
          );
        })}
      </div>
    );
  }

  const opacity = interpolate(frame - delay, [0, 20], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const translateY = interpolate(frame - delay, [0, 20], [25, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <div
      style={{
        fontSize,
        fontFamily: FONTS.display,
        fontWeight: weight,
        color,
        opacity,
        transform: `translateY(${translateY}px)`,
        textAlign: "center",
        lineHeight: 1.15,
        letterSpacing: fontSize > 60 ? -2 : -0.5,
        ...(gradient
          ? {
              background: GRADIENTS.brand,
              WebkitBackgroundClip: "text",
              WebkitTextFillColor: "transparent",
            }
          : {}),
        ...style,
      }}
    >
      {text}
    </div>
  );
};
