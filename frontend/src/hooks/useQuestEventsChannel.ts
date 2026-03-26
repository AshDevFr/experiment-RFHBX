import type { ChannelNameWithParams } from '@rails/actioncable';
import { useEffect, useRef, useState } from 'react';
import { useActionCable } from './useActionCable';

export type ConnectionStatus = 'connecting' | 'connected' | 'disconnected' | 'reconnecting';

export interface QuestEvent {
  event_type: string;
  quest_id?: number;
  quest_name?: string;
  region?: string;
  message?: string;
  data?: Record<string, unknown>;
  occurred_at?: string;
  // biome-ignore lint/suspicious/noExplicitAny: mirrors Action Cable's BaseMixin.received signature
  [key: string]: any;
}

export interface UseQuestEventsChannelResult {
  latestEvent: QuestEvent | null;
  connectionStatus: ConnectionStatus;
}

/**
 * Subscribes to the QuestEventsChannel (quest_events stream).
 * Optionally filters to a specific quest by quest_id.
 *
 * Progress-event ordering: ActionCable does not guarantee delivery order when
 * multiple tick broadcasts are in-flight. To prevent stale progress broadcasts
 * from causing the bar to jump backward, we track the ISO-8601 timestamp of
 * the most recently accepted `progress` event and silently discard any incoming
 * `progress` event whose `occurred_at` is not strictly newer. Status-transition
 * events (started / completed / failed / restarted) always pass through so that
 * quest lifecycle changes are never suppressed.
 */
export function useQuestEventsChannel(questId?: number): UseQuestEventsChannelResult {
  const consumer = useActionCable();
  const [latestEvent, setLatestEvent] = useState<QuestEvent | null>(null);
  const [connectionStatus, setConnectionStatus] = useState<ConnectionStatus>('connecting');
  const subscriptionRef = useRef<ReturnType<typeof consumer.subscriptions.create> | null>(null);
  // Tracks the occurred_at of the last accepted progress event so we can drop
  // any broadcast that arrives out of order (stale tick).
  const lastProgressTimestampRef = useRef<string | null>(null);

  useEffect(() => {
    // Reset ordering state whenever the subscription changes (quest switch or
    // reconnect) to avoid comparing timestamps across different quest sessions.
    lastProgressTimestampRef.current = null;

    const params: ChannelNameWithParams = { channel: 'QuestEventsChannel' };
    if (questId !== undefined) {
      params.quest_id = questId;
    }

    subscriptionRef.current = consumer.subscriptions.create(params, {
      connected() {
        setConnectionStatus('connected');
      },
      disconnected() {
        setConnectionStatus('disconnected');
      },
      rejected() {
        setConnectionStatus('disconnected');
      },
      received(data: QuestEvent) {
        // For progress events, enforce ordering by occurred_at timestamp.
        // If the incoming event is older than (or the same age as) the last
        // accepted one, it is a stale broadcast arriving out of order — discard.
        if (data.event_type === 'progress' && data.occurred_at) {
          if (
            lastProgressTimestampRef.current !== null &&
            data.occurred_at <= lastProgressTimestampRef.current
          ) {
            // Stale progress broadcast — ignore to prevent backward flicker.
            return;
          }
          lastProgressTimestampRef.current = data.occurred_at;
        }
        setLatestEvent(data);
      },
    });

    return () => {
      try {
        subscriptionRef.current?.unsubscribe();
      } catch {
        // Subscription may already be removed if the consumer was disconnected
        // (e.g. token refresh) before this cleanup ran.
      }
      subscriptionRef.current = null;
      lastProgressTimestampRef.current = null;
    };
  }, [consumer, questId]);

  return { latestEvent, connectionStatus };
}
