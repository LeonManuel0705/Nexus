import React from "react";
import {
  useCurrentFrame,
  useVideoConfig,
  interpolate,
} from "remotion";
import { COLORS, FONTS } from "../theme";
import { FeatureIcon } from "../components/FeatureIcon";

const FEATURES = [
  { title: "Kalender", icon: "calendar" },
  { title: "E-Mail", icon: "email" },
  { title: "Aufgaben", icon: "tasks" },
  { title: "Schule", icon: "school" },
  { title: "Training", icon: "training" },
  { title: "Notizen", icon: "notes" },
  { title: "Pomodoro", icon: "pomodoro" },
  { title: "Projekte", icon: "projects" },
  { title: "Transport", icon: "transit" },
  { title: "Lesezeichen", icon: "bookmarks" },
  { title: "Assistent", icon: "assistant" },
  { title: "Rückblick", icon: "dashboard" },
];

// Box dimensions
const BOX_W = 320;
const BOX_H = 90;
const BOX_GAP = 20;
const COLUMN_HEIGHT = FEATURES.length * (BOX_H + BOX_GAP) - BOX_GAP;
const SCROLL_TARGET = COLUMN_HEIGHT + 400;

// Exponential acceleration: speed increases 10% every 0.2s (12 frames at 60fps)
const V0 = 1.5; // initial speed (px/frame)
const K = Math.log(1.1) / 12;

function scrollPos(f: number): number {
  if (f <= 0) return 0;
  return (V0 / K) * (Math.exp(K * f) - 1);
}

// Find frame where scroll reaches target
let SCROLL_FRAMES = 400;
for (let f = 1; f < 1000; f++) {
  if (scrollPos(f) >= SCROLL_TARGET) {
    SCROLL_FRAMES = f;
    break;
  }
}

// Heading shows for 100 frames (1.67s), then scroll starts
const HEADING_HOLD = 100;

export const FeaturesSequence: React.FC = () => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();

  // Heading fade-in
  const headingOpacity = interpolate(frame, [0, 40], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const headingY = interpolate(frame, [0, 40], [25, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Scroll starts after heading hold
  const scrollFrame = Math.max(0, frame - HEADING_HOLD);
  const sp = scrollPos(scrollFrame);

  // "Und vieles mehr" appears after scroll ends
  const scrollDoneFrame = HEADING_HOLD + SCROLL_FRAMES;
  const moreAppear = scrollDoneFrame + 40;
  const moreOpacity = interpolate(frame, [moreAppear, moreAppear + 24], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const moreScale = interpolate(frame, [moreAppear, moreAppear + 24], [0.88, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Fade out entire scene before sequence ends (smooth transition)
  const masterFadeOut = interpolate(
    frame,
    [durationInFrames - 50, durationInFrames - 10],
    [1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  // Fade out scrolling list as "Und vieles mehr" appears
  const listOpacity = interpolate(
    frame,
    [moreAppear - 10, moreAppear + 10],
    [1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

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
        overflow: "hidden",
        opacity: masterFadeOut,
      }}
    >
      {/* Top fade mask */}
      <div
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          height: 250,
          background: `linear-gradient(180deg, ${COLORS.black} 30%, transparent 100%)`,
          zIndex: 3,
          pointerEvents: "none",
        }}
      />
      {/* Bottom fade mask */}
      <div
        style={{
          position: "absolute",
          bottom: 0,
          left: 0,
          right: 0,
          height: 250,
          background: `linear-gradient(0deg, ${COLORS.black} 30%, transparent 100%)`,
          zIndex: 3,
          pointerEvents: "none",
        }}
      />

      {/* Heading — centered, fades in then scrolls away */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          opacity: headingOpacity * listOpacity,
          transform: `translateY(${headingY - sp}px)`,
          zIndex: 2,
        }}
      >
        <div
          style={{
            fontSize: 64,
            fontFamily: FONTS.display,
            fontWeight: 600,
            letterSpacing: -2,
            lineHeight: 1.15,
            textAlign: "center",
            background: "linear-gradient(180deg, #ffffff 0%, #808085 100%)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
          }}
        >
          Alles, was du im Alltag brauchst.
        </div>
      </div>

      {/* Vertical boxes — scrolling top to bottom */}
      <div
        style={{
          position: "absolute",
          top: 0,
          bottom: 0,
          left: 0,
          right: 0,
          overflow: "hidden",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        {FEATURES.map((f, i) => {
          const startY = 1080 + i * (BOX_H + BOX_GAP);
          const y = startY - sp;
          if (y < -BOX_H - 50 || y > 1200) return null;

          return (
            <div
              key={i}
              style={{
                position: "absolute",
                top: y,
                width: BOX_W,
                height: BOX_H,
                border: "1px solid rgba(255,255,255,0.1)",
                borderRadius: 18,
                background: "rgba(255,255,255,0.03)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                gap: 16,
                opacity: listOpacity,
              }}
            >
              <FeatureIcon
                name={f.icon}
                size={28}
                color={COLORS.lightGray}
                strokeWidth={1.5}
              />
              <span
                style={{
                  fontSize: 28,
                  fontFamily: FONTS.display,
                  fontWeight: 500,
                  letterSpacing: -0.5,
                  background:
                    "linear-gradient(180deg, #e0e0e5 0%, #808085 100%)",
                  WebkitBackgroundClip: "text",
                  WebkitTextFillColor: "transparent",
                }}
              >
                {f.title}
              </span>
            </div>
          );
        })}
      </div>

      {/* "Und vieles mehr." — appears after scroll completes */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          zIndex: 4,
          opacity: moreOpacity,
          transform: `scale(${moreScale})`,
        }}
      >
        <div
          style={{
            fontSize: 56,
            fontFamily: FONTS.display,
            fontWeight: 600,
            letterSpacing: -1.5,
            background: "linear-gradient(180deg, #ffffff 0%, #808085 100%)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
          }}
        >
          Und vieles mehr.
        </div>
      </div>
    </div>
  );
};
