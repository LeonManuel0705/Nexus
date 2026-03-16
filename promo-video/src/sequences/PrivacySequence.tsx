import React from "react";
import {
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
} from "remotion";
import { COLORS, FONTS, GRADIENTS } from "../theme";
import { FeatureIcon } from "../components/FeatureIcon";

const ShieldIcon: React.FC<{ progress: number }> = ({ progress }) => {
  return (
    <svg width="180" height="220" viewBox="0 0 120 150" fill="none">
      <defs>
        <linearGradient id="shieldG" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor={COLORS.blue} />
          <stop offset="50%" stopColor={COLORS.purple} />
          <stop offset="100%" stopColor={COLORS.pink} />
        </linearGradient>
      </defs>
      <path
        d="M60 8 L112 38 L112 82 C112 116 90 135 60 146 C30 135 8 116 8 82 L8 38 Z"
        fill="none"
        stroke="url(#shieldG)"
        strokeWidth="1.5"
        strokeDasharray={400}
        strokeDashoffset={interpolate(progress, [0, 1], [400, 0])}
      />
      <path
        d="M42 78 L55 91 L82 58"
        stroke={COLORS.white}
        strokeWidth="3"
        strokeLinecap="round"
        strokeLinejoin="round"
        fill="none"
        strokeDasharray={80}
        strokeDashoffset={interpolate(progress, [0.5, 1], [80, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        })}
      />
    </svg>
  );
};

export const PrivacySequence: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const shieldProgress = spring({
    frame: frame - 10,
    fps,
    config: { damping: 20, stiffness: 40, mass: 1.5 },
  });

  const items = [
    { text: "Ende-zu-Ende-Verschlüsselung", icon: "privacy" },
    { text: "Kein Tracking. Keine Analyse.", icon: "crossplatform" },
    { text: "Deine Daten bleiben bei dir.", icon: "dashboard" },
  ];

  const title1Opacity = interpolate(frame, [10, 50], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const title1Y = interpolate(frame, [10, 50], [20, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const title2Opacity = interpolate(frame, [30, 70], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const title2Y = interpolate(frame, [30, 70], [20, 0], {
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
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      {/* Left — Shield */}
      <div
        style={{
          flex: 1,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          opacity: interpolate(frame, [0, 40], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      >
        <ShieldIcon progress={shieldProgress} />
      </div>

      {/* Right — Content */}
      <div style={{ flex: 1, paddingRight: 100 }}>
        <div
          style={{
            opacity: title1Opacity,
            transform: `translateY(${title1Y}px)`,
            fontSize: 62,
            fontFamily: FONTS.display,
            fontWeight: 600,
            letterSpacing: -2,
            lineHeight: 1.12,
            background: "linear-gradient(180deg, #ffffff 0%, #808085 100%)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            marginBottom: 6,
          }}
        >
          Privatsphäre ist kein Feature.
        </div>
        <div
          style={{
            opacity: title2Opacity,
            transform: `translateY(${title2Y}px)`,
            fontSize: 62,
            fontFamily: FONTS.display,
            fontWeight: 600,
            letterSpacing: -2,
            lineHeight: 1.12,
            background: GRADIENTS.brand,
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            marginBottom: 50,
          }}
        >
          Es ist das Fundament.
        </div>

        {items.map((item, i) => {
          const itemDelay = 60 + i * 20;
          const itemOpacity = interpolate(
            frame - itemDelay,
            [0, 30],
            [0, 1],
            { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
          );
          const itemX = interpolate(frame - itemDelay, [0, 30], [20, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          });

          return (
            <div
              key={i}
              style={{
                opacity: itemOpacity,
                transform: `translateX(${itemX}px)`,
                display: "flex",
                alignItems: "center",
                gap: 18,
                marginBottom: 22,
              }}
            >
              <FeatureIcon
                name={item.icon}
                size={24}
                color={COLORS.gray}
                strokeWidth={1.5}
              />
              <span
                style={{
                  fontSize: 24,
                  fontFamily: FONTS.body,
                  fontWeight: 400,
                  color: COLORS.lightGray,
                }}
              >
                {item.text}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
};
