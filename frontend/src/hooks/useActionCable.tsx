import { createConsumer } from '@rails/actioncable';
import { createContext, type ReactNode, useContext, useEffect, useRef } from 'react';

type Consumer = ReturnType<typeof createConsumer>;

const ActionCableContext = createContext<Consumer | null>(null);

const CABLE_URL = import.meta.env.VITE_CABLE_URL ?? 'ws://localhost:3000/cable';

/** Provides a single shared Action Cable consumer for the whole app. */
export function ActionCableProvider({ children }: { children: ReactNode }) {
  const consumerRef = useRef<Consumer | null>(null);

  if (!consumerRef.current) {
    consumerRef.current = createConsumer(CABLE_URL);
  }

  useEffect(() => {
    const c = consumerRef.current;
    // Disconnect cleanly when the provider unmounts (page navigation / unmount).
    return () => {
      c?.disconnect();
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
