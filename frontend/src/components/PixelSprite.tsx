import type { CSSProperties } from 'react';

export type SpriteName = 'ring' | 'eye' | 'sword' | 'shield' | 'placeholder';

interface PixelSpriteProps {
  name: SpriteName;
  size?: number;
  style?: CSSProperties;
}

// Emoji-based pixel art sprite stubs.
// Replace with actual sprite sheets in a later phase.
const SPRITES: Record<SpriteName, string> = {
  ring: '\uD83D\uDC8D', // 💍
  eye: '\uD83D\uDC41', // 👁
  sword: '\u2694', // ⚔
  shield: '\uD83D\uDEE1', // 🛡
  placeholder: '\u25C8', // ◈
};

export function PixelSprite({ name, size = 32, style }: PixelSpriteProps) {
  return (
    <span
      role="img"
      aria-label={name}
      style={{
        fontSize: size,
        display: 'inline-block',
        imageRendering: 'pixelated',
        lineHeight: 1,
        userSelect: 'none',
        ...style,
      }}
    >
      {SPRITES[name]}
    </span>
  );
}
