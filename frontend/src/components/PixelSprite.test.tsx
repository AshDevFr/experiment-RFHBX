import { cleanup, render, screen } from '@testing-library/react';
import { afterEach, describe, expect, it } from 'vitest';
import { PixelSprite } from './PixelSprite';

describe('PixelSprite', () => {
  afterEach(() => {
    cleanup();
  });

  it('renders with the correct accessible role and label', () => {
    render(<PixelSprite name="ring" size={32} />);
    expect(screen.getByRole('img', { name: 'ring' })).toBeInTheDocument();
  });

  it('renders the placeholder sprite', () => {
    render(<PixelSprite name="placeholder" />);
    expect(screen.getByRole('img', { name: 'placeholder' })).toBeInTheDocument();
  });

  it('renders all sprite names without throwing', () => {
    const names = ['ring', 'eye', 'sword', 'shield', 'placeholder'] as const;
    for (const name of names) {
      const { unmount } = render(<PixelSprite name={name} />);
      expect(screen.getByRole('img', { name })).toBeInTheDocument();
      unmount();
    }
  });
});
