import React from "react";
import {
  interpolate,
  useCurrentFrame,
  spring,
  useVideoConfig,
  staticFile,
  Img,
} from "remotion";

interface ScreenshotShowcaseProps {
  src: string;
  delay?: number;
  style?: React.CSSProperties;
  perspective?: boolean;
  scale?: number;
  rotateY?: number;
  rotateX?: number;
}

export const ScreenshotShowcase: React.FC<ScreenshotShowcaseProps> = ({
  src,
  delay = 0,
  style = {},
  perspective = false,
  scale: targetScale = 1,
  rotateY: targetRotateY = 0,
  rotateX: targetRotateX = 0,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const enter = spring({
    frame: frame - delay,
    fps,
    config: { damping: 18, stiffness: 60, mass: 1 },
  });

  const opacity = interpolate(frame - delay, [0, 25], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const scale = interpolate(enter, [0, 1], [0.92, targetScale]);
  const translateY = interpolate(enter, [0, 1], [40, 0]);
  const rotateY = perspective
    ? interpolate(enter, [0, 1], [-8 + targetRotateY, targetRotateY])
    : targetRotateY;
  const rotateX = perspective
    ? interpolate(enter, [0, 1], [5 + targetRotateX, targetRotateX])
    : targetRotateX;

  return (
    <div
      style={{
        perspective: 2000,
        ...style,
      }}
    >
      <div
        style={{
          opacity,
          transform: `
            translateY(${translateY}px)
            scale(${scale})
            rotateY(${rotateY}deg)
            rotateX(${rotateX}deg)
          `,
          borderRadius: 12,
          overflow: "hidden",
          boxShadow: "0 30px 80px rgba(0,0,0,0.6)",
        }}
      >
        <Img
          src={staticFile(src)}
          style={{
            width: "100%",
            height: "100%",
            objectFit: "cover",
            display: "block",
          }}
        />
      </div>
    </div>
  );
};
