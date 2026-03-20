import { createConsumer } from '@rails/actioncable';

// Read the cable URL from env; fall back to the conventional Rails default.
const CABLE_URL = import.meta.env.VITE_CABLE_URL ?? 'ws://localhost:3000/cable';

/**
 * Shared Action Cable consumer.
 * Exported as a singleton so every hook gets the same underlying connection.
 * The consumer connects lazily on the first subscription.
 */
export const consumer = createConsumer(CABLE_URL);
