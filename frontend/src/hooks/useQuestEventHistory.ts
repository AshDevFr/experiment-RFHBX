import { useCallback, useEffect, useReducer, useState } from 'react';
import { api } from '../lib/api';
import {
  type EventsMeta,
  type EventType,
  eventsResponseSchema,
  type QuestEvent,
} from '../schemas/questEvent';

export interface EventHistoryFilters {
  eventTypes: EventType[];
  questTitle: string;
  page: number;
  perPage: number;
}

export interface UseQuestEventHistoryResult {
  events: QuestEvent[];
  meta: EventsMeta | null;
  isLoading: boolean;
  error: string | null;
  filters: EventHistoryFilters;
  setEventTypes: (types: EventType[]) => void;
  setQuestTitle: (title: string) => void;
  setPage: (page: number) => void;
}

const DEFAULT_FILTERS: EventHistoryFilters = {
  eventTypes: [],
  questTitle: '',
  page: 1,
  perPage: 25,
};

/**
 * Fetches paginated quest event history from GET /api/v1/events.
 * Supports filtering by event type (multi-select) and quest title (free-text).
 */
export function useQuestEventHistory(): UseQuestEventHistoryResult {
  const [events, setEvents] = useState<QuestEvent[]>([]);
  const [meta, setMeta] = useState<EventsMeta | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filters, setFilters] = useState<EventHistoryFilters>(DEFAULT_FILTERS);
  const [tick, bump] = useReducer((n: number) => n + 1, 0);

  const setEventTypes = useCallback((types: EventType[]) => {
    setFilters((prev) => ({ ...prev, eventTypes: types, page: 1 }));
    bump();
  }, []);

  const setQuestTitle = useCallback((title: string) => {
    setFilters((prev) => ({ ...prev, questTitle: title, page: 1 }));
    bump();
  }, []);

  const setPage = useCallback((page: number) => {
    setFilters((prev) => ({ ...prev, page }));
    bump();
  }, []);

  // biome-ignore lint/correctness/useExhaustiveDependencies: tick is an intentional re-fetch trigger; filters is the dependency we want
  useEffect(() => {
    let cancelled = false;

    async function fetchEvents() {
      setIsLoading(true);
      setError(null);

      try {
        const params: Record<string, unknown> = {
          page: filters.page,
          per_page: filters.perPage,
        };

        // Send multiple event_type values as repeated params (event_type[]=...)
        if (filters.eventTypes.length === 1) {
          params.event_type = filters.eventTypes[0];
        } else if (filters.eventTypes.length > 1) {
          params['event_type[]'] = filters.eventTypes;
        }

        if (filters.questTitle.trim()) {
          params.quest_title = filters.questTitle.trim();
        }

        const response = await api.get<unknown>('/api/v1/events', { params });
        const parsed = eventsResponseSchema.parse(response.data);

        if (!cancelled) {
          setEvents(parsed.events);
          setMeta(parsed.meta);
        }
      } catch (err: unknown) {
        if (!cancelled) {
          const message = err instanceof Error ? err.message : 'Failed to load event history';
          setError(message);
        }
      } finally {
        if (!cancelled) {
          setIsLoading(false);
        }
      }
    }

    fetchEvents();

    return () => {
      cancelled = true;
    };
  }, [tick, filters]);

  return { events, meta, isLoading, error, filters, setEventTypes, setQuestTitle, setPage };
}
