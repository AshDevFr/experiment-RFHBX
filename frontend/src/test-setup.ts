import '@testing-library/jest-dom/vitest';

// Mantine's color-scheme detection calls window.matchMedia which does not
// exist in jsdom.  Provide a minimal stub so components that use MantineProvider
// (e.g. UserInfo, AppShell) can render in tests without errors.
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: (query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: () => {},
    removeListener: () => {},
    addEventListener: () => {},
    removeEventListener: () => {},
    dispatchEvent: () => false,
  }),
});

// Mantine's ScrollArea (used internally by MultiSelect, Select, etc.) requires
// ResizeObserver which is not available in jsdom.  Provide a minimal stub.
if (typeof globalThis.ResizeObserver === 'undefined') {
  globalThis.ResizeObserver = class ResizeObserver {
    observe() {}
    unobserve() {}
    disconnect() {}
  };
}
