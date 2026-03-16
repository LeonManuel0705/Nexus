import React from "react";
import {
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
} from "remotion";
import { COLORS, FONTS, GRADIENTS } from "../theme";
import { ScreenshotShowcase } from "../components/ScreenshotShowcase";

const AnimatedCounter: React.FC<{
  value: number;
  suffix?: string;
  delay: number;
  label: string;
}> = ({ value, suffix = "", delay, label }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const progress = spring({
    frame: frame - delay,
    fps,
    config: { damping: 20, stiffness: 40, mass: 1.5 },
  });

  const displayValue = Math.round(value * progress);
  const opacity = interpolate(frame - delay, [0, 30], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <div style={{ textAlign: "center", opacity }}>
      <div
        style={{
          fontSize: 64,
          fontFamily: FONTS.display,
          fontWeight: 600,
          background: "linear-gradient(180deg, #ffffff 0%, #808085 100%)",
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
          letterSpacing: -2,
        }}
      >
        {displayValue}
        {suffix}
      </div>
      <div
        style={{
          fontSize: 16,
          fontFamily: FONTS.body,
          color: COLORS.gray,
          marginTop: 8,
          textTransform: "uppercase",
          letterSpacing: 3,
        }}
      >
        {label}
      </div>
    </div>
  );
};

export const DashboardSequence: React.FC = () => {
  const frame = useCurrentFrame();

  const headlineOpacity = interpolate(frame, [0, 40], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const headlineY = interpolate(frame, [0, 40], [20, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        background: COLORS.black,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      {/* Headline */}
      <div
        style={{
          opacity: headlineOpacity,
          transform: `translateY(${headlineY}px)`,
          fontSize: 72,
          fontFamily: FONTS.display,
          fontWeight: 600,
          letterSpacing: -3,
          textAlign: "center",
          lineHeight: 1.1,
          background: "linear-gradient(180deg, #ffffff 0%, #808085 100%)",
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
          marginBottom: 50,
        }}
      >
        Alles an einem Ort.
      </div>

      {/* Dashboard screenshot */}
      <div style={{ width: "65%", maxWidth: 850 }}>
        <ScreenshotShowcase src="screenshots/dashboard.png" delay={20} />
      </div>

      {/* Stats */}
      <div style={{ display: "flex", gap: 120, marginTop: 50 }}>
        <AnimatedCounter value={12} suffix="+" delay={70} label="Funktionen" />
        <AnimatedCounter value={100} suffix="%" delay={84} label="Privat" />
        <AnimatedCounter value={5} delay={98} label="Plattformen" />
      </div>
    </div>
  );
};
