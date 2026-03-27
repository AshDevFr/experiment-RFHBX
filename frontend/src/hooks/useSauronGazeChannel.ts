import { useEffect, useRef, useState } from 'react';
import { useActionCable } from './useActionCable';
import type { ConnectionStatus } from './useQuestEventsChannel';

export interface SauronGaze {
  region: string;
  threat_level: number;
  message: string;
  watched_at: string;
}

export interface UseSauronGazeChannelResult {
  latestGaze: SauronGaze | null;
  connectionStatus: ConnectionStatus;
}

/**
 * Subscribes to the SauronGazeChannel (sauron_gaze stream).
 */
export function useSauronGazeChannel(): UseSauronGazeChannelResult {
  const consumer = useActionCable();
  const [latestGaze, setLatestGaze] = useState<SauronGaze | null>(null);
  const [connectionStatus, setConnectionStatus] = useState<ConnectionStatus>('connecting');
  const subscriptionRef = useRef<ReturnType<typeof consumer.subscriptions.create> | null>(null);

  useEffect(() => {
    subscriptionRef.current = consumer.subscriptions.create(
      { channel: 'SauronGazeChannel' },
      {
        connected() {
          setConnectionStatus('connected');
        },
        disconnected() {
          setConnectionStatus('disconnected');
        },
        rejected() {
          setConnectionStatus('disconnected');
        },
        received(data: SauronGaze) {
          setLatestGaze(data);
        },
      },
    );

    return () => {
      try {
        subscriptionRef.current?.unsubscribe();
      } catch {
        // Subscription may already be removed if not yet confirmed
        // or if the consumer was disconnected.
      }
      subscriptionRef.current = null;
    };
  }, [consumer]);

  return { latestGaze, connectionStatus };
}
