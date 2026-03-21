import { Box, RingProgress, Stack, Text } from '@mantine/core';

interface ThreatLevelIndicatorProps {
  level: number;
  region: string;
  message: string;
}

/**
 * Maps threat level (0–10) to a colour that transitions from
 * calm green → amber → urgent red as the Eye focuses.
 */
function threatColor(level: number): string {
  if (level <= 2) return 'green';
  if (level <= 4) return 'yellow';
  if (level <= 6) return 'orange';
  return 'red';
}

/**
 * A large, colour-coded ring showing the current threat level
 * broadcast by the Eye of Sauron.
 */
export function ThreatLevelIndicator({ level, region, message }: ThreatLevelIndicatorProps) {
  const color = threatColor(level);
  const pct = Math.min(level, 10) * 10; // 0-100 scale for the ring

  return (
    <Stack align="center" gap="xs" data-testid="threat-indicator">
      <RingProgress
        size={200}
        thickness={16}
        roundCaps
        sections={[{ value: pct, color }]}
        label={
          <Box ta="center">
            <Text size="xl" fw={700} data-testid="threat-level-value">
              {level}
            </Text>
            <Text size="xs" c="dimmed">
              / 10
            </Text>
          </Box>
        }
      />

      <Text size="lg" fw={600} data-testid="threat-region">
        {region}
      </Text>
      <Text size="sm" c="dimmed" ta="center" maw={360} data-testid="threat-message">
        {message}
      </Text>
    </Stack>
  );
}
