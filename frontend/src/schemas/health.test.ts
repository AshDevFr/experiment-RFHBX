import { describe, expect, it } from 'vitest';
import { healthSchema } from './health';

describe('healthSchema', () => {
  it('parses a valid health response', () => {
    const result = healthSchema.safeParse({
      status: 'ok',
      version: '1.0.0',
      environment: 'test',
    });
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.status).toBe('ok');
      expect(result.data.version).toBe('1.0.0');
      expect(result.data.environment).toBe('test');
    }
  });

  it('rejects a response missing required fields', () => {
    const result = healthSchema.safeParse({ status: 'ok' });
    expect(result.success).toBe(false);
  });

  it('rejects a non-object value', () => {
    const result = healthSchema.safeParse(null);
    expect(result.success).toBe(false);
  });
});
