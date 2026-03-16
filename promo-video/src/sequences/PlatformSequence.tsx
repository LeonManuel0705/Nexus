import React from "react";
import {
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
} from "remotion";
import { COLORS, FONTS, GRADIENTS } from "../theme";

// ─── SVG Device Outlines ───

const LaptopDevice: React.FC<{ drawProgress: number }> = ({ drawProgress }) => (
  <svg width="260" height="170" viewBox="0 0 260 170" fill="none">
    <defs>
      <linearGradient id="devG" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor={COLORS.blue} />
        <stop offset="50%" stopColor={COLORS.purple} />
        <stop offset="100%" stopColor={COLORS.pink} />
      </linearGradient>
    </defs>
    {/* Screen */}
    <rect
      x="30" y="8" width="200" height="125" rx="8"
      stroke="url(#devG)" strokeWidth="1.5" fill="none"
      strokeDasharray={650}
      strokeDashoffset={interpolate(drawProgress, [0, 1], [650, 0])}
    />
    {/* Screen glow */}
    <rect
      x="38" y="16" width="184" height="109" rx="4"
      fill="url(#devG)"
      opacity={interpolate(drawProgress, [0.5, 1], [0, 0.08], {
        extrapolateLeft: "clamp", extrapolateRight: "clamp",
      })}
    />
    {/* Base */}
    <path
      d="M10 145 L250 145 L240 138 L20 138 Z"
      stroke="url(#devG)" strokeWidth="1.2" fill="none"
      strokeDasharray={500}
      strokeDashoffset={interpolate(drawProgress, [0.3, 1], [500, 0], {
        extrapolateLeft: "clamp", extrapolateRight: "clamp",
      })}
    />
  </svg>
);

const PhoneDevice: React.FC<{ drawProgress: number }> = ({ drawProgress }) => (
  <svg width="90" height="170" viewBox="0 0 90 170" fill="none">
    <defs>
      <linearGradient id="devG2" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor={COLORS.blue} />
        <stop offset="50%" stopColor={COLORS.purple} />
        <stop offset="100%" stopColor={COLORS.pink} />
      </linearGradient>
    </defs>
    <rect
      x="5" y="5" width="80" height="160" rx="16"
      stroke="url(#devG2)" strokeWidth="1.5" fill="none"
      strokeDasharray={480}
      strokeDashoffset={interpolate(drawProgress, [0, 1], [480, 0])}
    />
    {/* Screen glow */}
    <rect
      x="11" y="20" width="68" height="130" rx="4"
      fill="url(#devG2)"
      opacity={interpolate(drawProgress, [0.5, 1], [0, 0.08], {
        extrapolateLeft: "clamp", extrapolateRight: "clamp",
      })}
    />
    {/* Notch */}
    <rect
      x="30" y="10" width="30" height="5" rx="2.5"
      stroke="url(#devG2)" strokeWidth="0.8" fill="none"
      opacity={interpolate(drawProgress, [0.7, 1], [0, 0.6], {
        extrapolateLeft: "clamp", extrapolateRight: "clamp",
      })}
    />
  </svg>
);

const TabletDevice: React.FC<{ drawProgress: number }> = ({ drawProgress }) => (
  <svg width="140" height="190" viewBox="0 0 140 190" fill="none">
    <defs>
      <linearGradient id="devG3" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor={COLORS.blue} />
        <stop offset="50%" stopColor={COLORS.purple} />
        <stop offset="100%" stopColor={COLORS.pink} />
      </linearGradient>
    </defs>
    <rect
      x="5" y="5" width="130" height="180" rx="14"
      stroke="url(#devG3)" strokeWidth="1.5" fill="none"
      strokeDasharray={620}
      strokeDashoffset={interpolate(drawProgress, [0, 1], [620, 0])}
    />
    {/* Screen glow */}
    <rect
      x="12" y="18" width="116" height="154" rx="4"
      fill="url(#devG3)"
      opacity={interpolate(drawProgress, [0.5, 1], [0, 0.08], {
        extrapolateLeft: "clamp", extrapolateRight: "clamp",
      })}
    />
  </svg>
);

const DesktopDevice: React.FC<{ drawProgress: number }> = ({ drawProgress }) => (
  <svg width="220" height="190" viewBox="0 0 220 190" fill="none">
    <defs>
      <linearGradient id="devG4" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor={COLORS.blue} />
        <stop offset="50%" stopColor={COLORS.purple} />
        <stop offset="100%" stopColor={COLORS.pink} />
      </linearGradient>
    </defs>
    {/* Monitor */}
    <rect
      x="10" y="5" width="200" height="130" rx="8"
      stroke="url(#devG4)" strokeWidth="1.5" fill="none"
      strokeDasharray={660}
      strokeDashoffset={interpolate(drawProgress, [0, 1], [660, 0])}
    />
    {/* Screen glow */}
    <rect
      x="18" y="13" width="184" height="114" rx="4"
      fill="url(#devG4)"
      opacity={interpolate(drawProgress, [0.5, 1], [0, 0.08], {
        extrapolateLeft: "clamp", extrapolateRight: "clamp",
      })}
    />
    {/* Stand */}
    <path
      d="M95 140 L95 160 M75 165 L145 165"
      stroke="url(#devG4)" strokeWidth="1.5" strokeLinecap="round"
      strokeDasharray={60}
      strokeDashoffset={interpolate(drawProgress, [0.6, 1], [60, 0], {
        extrapolateLeft: "clamp", extrapolateRight: "clamp",
      })}
    />
  </svg>
);

// ─── Device data ───

const DEVICES = [
  { name: "Desktop", label: "Windows · Linux", Component: DesktopDevice },
  { name: "iPhone", label: "iOS", Component: PhoneDevice },
  { name: "MacBook", label: "macOS", Component: LaptopDevice },
  { name: "iPad", label: "iPadOS", Component: TabletDevice },
  { name: "Android", label: "Android", Component: PhoneDevice },
];

export const PlatformSequence: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Title animation
  const titleOpacity = interpolate(frame, [0, 40], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const titleY = interpolate(frame, [0, 40], [30, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Subtitle
  const subOpacity = interpolate(frame, [20, 60], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const subY = interpolate(frame, [20, 60], [20, 0], {
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
        position: "relative",
      }}
    >
      {/* Title */}
      <div
        style={{
          opacity: titleOpacity,
          transform: `translateY(${titleY}px)`,
          fontSize: 68,
          fontFamily: FONTS.display,
          fontWeight: 600,
          letterSpacing: -2.5,
          lineHeight: 1.1,
          background: "linear-gradient(180deg, #ffffff 0%, #808085 100%)",
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
          textAlign: "center",
          marginBottom: 6,
        }}
      >
        Ein Erlebnis.
      </div>

      {/* Subtitle */}
      <div
        style={{
          opacity: subOpacity,
          transform: `translateY(${subY}px)`,
          fontSize: 68,
          fontFamily: FONTS.display,
          fontWeight: 600,
          letterSpacing: -2.5,
          lineHeight: 1.1,
          background: GRADIENTS.brand,
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
          textAlign: "center",
          marginBottom: 80,
        }}
      >
        Jedes Gerät.
      </div>

      {/* Devices row */}
      <div
        style={{
          display: "flex",
          alignItems: "flex-end",
          justifyContent: "center",
          gap: 60,
        }}
      >
        {DEVICES.map((device, i) => {
          const stagger = 50 + i * 25; // staggered entrance
          const drawProgress = spring({
            frame: frame - stagger,
            fps,
            config: { damping: 22, stiffness: 35, mass: 1.2 },
          });

          const deviceOpacity = interpolate(
            frame - stagger,
            [0, 30],
            [0, 1],
            { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
          );
          const deviceY = interpolate(
            frame - stagger,
            [0, 40],
            [40, 0],
            { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
          );

          // Label appears after device is drawn
          const labelOpacity = interpolate(
            frame - stagger - 40,
            [0, 20],
            [0, 0.7],
            { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
          );

          const { Component } = device;

          return (
            <div
              key={device.name}
              style={{
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                opacity: deviceOpacity,
                transform: `translateY(${deviceY}px)`,
              }}
            >
              <Component drawProgress={drawProgress} />
              <div
                style={{
                  marginTop: 16,
                  fontSize: 13,
                  fontFamily: FONTS.body,
                  color: COLORS.gray,
                  letterSpacing: 2,
                  textTransform: "uppercase",
                  opacity: labelOpacity,
                }}
              >
                {device.label}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
