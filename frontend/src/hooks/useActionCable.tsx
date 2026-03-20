import { createConsumer } from '@rails/actioncable';
import { createContext, type ReactNode, useContext, useEffect, useRef } from 'react';
import { useAuth } from '../auth/AuthProvider';

type Consumer = ReturnType<typeof createConsumer>;

const ActionCableContext = createContext<Consumer | null>(null);

const CABLE_URL = import.meta.env.VITE_CABLE_URL ?? 'ws://localhost:3000/cable';

function buildCableUrl(token: string | null): string {
  if (!token) return CABLE_URL;
  const separator = CABLE_URL.includes('?') ? '&' : '?';
  return `${CABLE_URL}${separator}token=${encodeURIComponent(token)}`;
}

/** Provides a single shared Action Cable consumer for the whole app. */
export function ActionCableProvider({ children }: { children: ReactNode }) {
  const { getAccessToken } = useAuth();
  const token = getAccessToken();
  const consumerRef = useRef<Consumer | null>(null);
  const tokenRef = useRef<string | null>(token);

  // Create or recreate consumer when token changes.
  if (tokenRef.current !== token) {
    // Token has changed — disconnect the old consumer before replacing it.
    consumerRef.current?.disconnect();
    consumerRef.current = null;
    tokenRef.current = token;
  }

  if (!consumerRef.current) {
    consumerRef.current = createConsumer(buildCableUrl(token));
  }

  useEffect(() => {
    const c = consumerRef.current;
    // Disconnect cleanly and clear the ref when the provider unmounts.
    // Clearing the ref is critical for React StrictMode: after the simulated
    // cleanup the next render's `if (!consumerRef.current)` guard will create
    // a fresh consumer instead of reusing the stale, disconnected instance.
    return () => {
      c?.disconnect();
      consumerRef.current = null;
    };
  }, []);

  return (
    <ActionCableContext.Provider value={consumerRef.current}>
      {children}
    </ActionCableContext.Provider>
  );
}

/**
 * Returns the shared Action Cable consumer.
 * Must be called inside an <ActionCableProvider> tree.
 */
export function useActionCable(): Consumer {
  const consumer = useContext(ActionCableContext);
  if (!consumer) {
    throw new Error('useActionCable must be used inside <ActionCableProvider>');
  }
  return consumer;
}
