import React from "react";
import {
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
} from "remotion";
import { COLORS, FONTS, GRADIENTS } from "../theme";

const WifiOffIcon: React.FC<{ progress: number }> = ({ progress }) => {
  return (
    <svg width="180" height="180" viewBox="0 0 24 24" fill="none">
      <defs>
        <linearGradient id="wifiG" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor={COLORS.blue} />
          <stop offset="50%" stopColor={COLORS.purple} />
          <stop offset="100%" stopColor={COLORS.pink} />
        </linearGradient>
      </defs>
      <path
        d="M1 9l2 2c4.97-4.97 13.03-4.97 18 0l2-2C16.93 2.93 7.08 2.93 1 9z"
        stroke="url(#wifiG)"
        strokeWidth="1.2"
        strokeLinecap="round"
        fill="none"
        strokeDasharray={50}
        strokeDashoffset={interpolate(progress, [0, 0.4], [50, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        })}
      />
      <path
        d="M5 13l2 2c2.76-2.76 7.24-2.76 10 0l2-2C14.14 8.14 9.87 8.14 5 13z"
        stroke="url(#wifiG)"
        strokeWidth="1.2"
        strokeLinecap="round"
        fill="none"
        strokeDasharray={40}
        strokeDashoffset={interpolate(progress, [0.2, 0.6], [40, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        })}
      />
      <path
        d="M9 17l3 3 3-3c-1.65-1.66-4.34-1.66-6 0z"
        stroke="url(#wifiG)"
        strokeWidth="1.2"
        strokeLinecap="round"
        fill="none"
        strokeDasharray={20}
        strokeDashoffset={interpolate(progress, [0.4, 0.8], [20, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        })}
      />
      <path
        d="M2 2l20 20"
        stroke={COLORS.white}
        strokeWidth="1.5"
        strokeLinecap="round"
        fill="none"
        strokeDasharray={30}
        strokeDashoffset={interpolate(progress, [0.6, 1], [30, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        })}
      />
    </svg>
  );
};

export const OfflineSequence: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const iconProgress = spring({
    frame: frame - 10,
    fps,
    config: { damping: 20, stiffness: 40, mass: 1.5 },
  });

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

  const items = [
    "Alle Daten lokal gespeichert",
    "Kein Server nötig",
    "Sofort einsatzbereit",
  ];

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
      {/* Left — Icon */}
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
        <WifiOffIcon progress={iconProgress} />
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
          Funktioniert ohne Internet.
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
          Immer und überall.
        </div>

        {items.map((text, i) => {
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
                gap: 14,
                marginBottom: 22,
              }}
            >
              <div
                style={{
                  width: 6,
                  height: 6,
                  borderRadius: "50%",
                  background: COLORS.gray,
                  flexShrink: 0,
                }}
              />
              <span
                style={{
                  fontSize: 24,
                  fontFamily: FONTS.body,
                  fontWeight: 400,
                  color: COLORS.lightGray,
                }}
              >
                {text}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
};
