import { createTheme } from '@mantine/core';

export const theme = createTheme({
  fontFamily: '"Press Start 2P", monospace',
  headings: {
    fontFamily: '"Press Start 2P", monospace',
  },
  primaryColor: 'retro',
  defaultRadius: 0,
  colors: {
    // Retro terminal green
    retro: [
      '#e8ffe8',
      '#c8f5c8',
      '#a0e8a0',
      '#70d870',
      '#40c040',
      '#20a020',
      '#108010',
      '#086008',
      '#044004',
      '#022002',
    ],
    // CRT amber
    amber: [
      '#fff8e1',
      '#ffecb3',
      '#ffe082',
      '#ffd54f',
      '#ffca28',
      '#ffc107',
      '#ffb300',
      '#ffa000',
      '#ff8f00',
      '#ff6f00',
    ],
  },
  components: {
    Button: {
      styles: {
        root: {
          border: '2px solid',
          boxShadow: '4px 4px 0px rgba(0,0,0,0.5)',
          textTransform: 'uppercase' as const,
          letterSpacing: '0.05em',
        },
      },
    },
    Paper: {
      styles: {
        root: {
          border: '2px solid',
          boxShadow: '4px 4px 0px rgba(0,0,0,0.4)',
        },
      },
    },
    Card: {
      styles: {
        root: {
          border: '2px solid',
          boxShadow: '4px 4px 0px rgba(0,0,0,0.4)',
        },
      },
    },
  },
});
