import { Badge, type BadgeProps } from '@mantine/core';
import type { ConnectionStatus } from '../hooks/useQuestEventsChannel';

interface CableStatusProps {
  status: ConnectionStatus;
  size?: BadgeProps['size'];
}

const STATUS_CONFIG: Record<ConnectionStatus, { color: string; label: string }> = {
  connected: { color: 'green', label: 'CABLE: CONNECTED' },
  connecting: { color: 'yellow', label: 'CABLE: CONNECTING' },
  reconnecting: { color: 'orange', label: 'CABLE: RECONNECTING' },
  disconnected: { color: 'red', label: 'CABLE: DISCONNECTED' },
};

/**
 * Small badge indicating the current Action Cable connection status.
 * Renders in the app header (or wherever placed).
 */
export function CableStatus({ status, size = 'sm' }: CableStatusProps) {
  const { color, label } = STATUS_CONFIG[status];
  return (
    <Badge
      color={color}
      variant="filled"
      size={size}
      aria-label={`WebSocket status: ${status}`}
    >
      {label}
    </Badge>
  );
}
