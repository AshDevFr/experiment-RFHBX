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
    // Track whether the server has confirmed this subscription.
    // ActionCable raises RuntimeError if `unsubscribe` is called before
    // confirmation arrives, so we only call it once `connected()` has fired.
    let isConnected = false;
    // Track whether the component unmounted before confirmation so we can
    // issue a deferred unsubscribe from inside the connected() callback.
    let unmounted = false;

    subscriptionRef.current = consumer.subscriptions.create(
      { channel: 'SauronGazeChannel' },
      {
        connected() {
          isConnected = true;
          if (unmounted) {
            // Component unmounted while confirmation was in flight.
            // Issue the deferred unsubscribe now that the server has confirmed.
            try {
              subscriptionRef.current?.unsubscribe();
            } catch {
              // already removed
            }
            subscriptionRef.current = null;
            return;
          }
          setConnectionStatus('connected');
        },
        disconnected() {
          isConnected = false;
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
      unmounted = true;
      if (isConnected) {
        // Subscription is confirmed — safe to unsubscribe immediately.
        try {
          subscriptionRef.current?.unsubscribe();
        } catch {
          // Subscription may already be removed if the consumer was disconnected
          // (e.g. token refresh) before this cleanup ran.
        }
        subscriptionRef.current = null;
      }
      // If !isConnected: connected() hasn't fired yet.
      // Setting unmounted=true above causes the connected() callback to issue
      // the deferred unsubscribe once the server confirms the subscription.
    };
  }, [consumer]);

  return { latestGaze, connectionStatus };
}
