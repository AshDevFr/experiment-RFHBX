import { useEffect, useRef, useState } from 'react';
import { useActionCable } from './useActionCable';

export type ConnectionStatus = 'connecting' | 'connected' | 'disconnected' | 'reconnecting';

export interface QuestEvent {
  type: string;
  quest_id?: number;
  [key: string]: unknown;
}

export interface UseQuestEventsChannelResult {
  latestEvent: QuestEvent | null;
  connectionStatus: ConnectionStatus;
}

/**
 * Subscribes to the QuestEventsChannel (quest_events stream).
 * Optionally filters to a specific quest by quest_id.
 */
export function useQuestEventsChannel(questId?: number): UseQuestEventsChannelResult {
  const consumer = useActionCable();
  const [latestEvent, setLatestEvent] = useState<QuestEvent | null>(null);
  const [connectionStatus, setConnectionStatus] = useState<ConnectionStatus>('connecting');
  const subscriptionRef = useRef<ReturnType<typeof consumer.subscriptions.create> | null>(null);

  useEffect(() => {
    const params: Record<string, unknown> = { channel: 'QuestEventsChannel' };
    if (questId !== undefined) {
      params['quest_id'] = questId;
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
        setLatestEvent(data);
      },
    });

    return () => {
      subscriptionRef.current?.unsubscribe();
      subscriptionRef.current = null;
    };
  }, [consumer, questId]);

  return { latestEvent, connectionStatus };
}
