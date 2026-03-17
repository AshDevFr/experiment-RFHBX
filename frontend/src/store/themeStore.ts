import { create } from 'zustand'
import { persist } from 'zustand/middleware'

type ColorScheme = 'dark' | 'light'

interface ThemeState {
  colorScheme: ColorScheme
  toggle: () => void
}

export const useThemeStore = create<ThemeState>()(
  persist(
    (set) => ({
      colorScheme: 'dark',
      toggle: () =>
        set((state) => ({
          colorScheme: state.colorScheme === 'dark' ? 'light' : 'dark',
        })),
    }),
    { name: 'mordors-edge-theme' },
  ),
)
