import axios from 'axios';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { api, clearAuthTokenAccessor, setAuthTokenAccessor } from './api';

describe('Axios auth interceptor', () => {
  beforeEach(() => {
    clearAuthTokenAccessor();
  });

  afterEach(() => {
    clearAuthTokenAccessor();
    vi.restoreAllMocks();
  });

  it('does NOT add Authorization header when no token accessor is registered', async () => {
    // Mock the adapter so we never hit the network.
    const adapter = vi.fn().mockResolvedValue({
      data: {},
      status: 200,
      statusText: 'OK',
      headers: {},
      config: {},
    });

    const capturedConfigs: unknown[] = [];
    const instance = axios.create({ adapter });
    instance.interceptors.request.use((config) => {
      capturedConfigs.push({ ...config.headers });
      return config;
    });

    // Directly invoke the interceptor registered on `api`.
    // We test the interceptor logic by importing and calling the setter.
    clearAuthTokenAccessor();

    // Build a minimal config and run the interceptor.
    const { InternalAxiosRequestConfig } = await import('axios');
    const config = { headers: axios.defaults.headers } as typeof InternalAxiosRequestConfig.prototype;

    // The interceptor is the first one registered on `api`; retrieve it.
    // biome-ignore lint/suspicious/noExplicitAny: test internals
    const interceptors = (api.interceptors.request as any).handlers as Array<{
      fulfilled: (c: unknown) => unknown;
    } | null>;
    const interceptor = interceptors.find(Boolean);
    if (!interceptor) throw new Error('Interceptor not found');

    const result = await (interceptor.fulfilled(config) as Promise<typeof config>);
    expect((result as { headers?: Record<string, string> }).headers?.Authorization).toBeUndefined();
  });

  it('injects Authorization: Bearer <token> when a token accessor is registered', async () => {
    setAuthTokenAccessor(() => 'my-secret-token');

    const { InternalAxiosRequestConfig } = await import('axios');
    const config = {
      headers: {},
    } as typeof InternalAxiosRequestConfig.prototype;

    // biome-ignore lint/suspicious/noExplicitAny: test internals
    const interceptors = (api.interceptors.request as any).handlers as Array<{
      fulfilled: (c: unknown) => unknown;
    } | null>;
    const interceptor = interceptors.find(Boolean);
    if (!interceptor) throw new Error('Interceptor not found');

    const result = await (interceptor.fulfilled(config) as Promise<typeof config>);
    expect((result as { headers: Record<string, string> }).headers.Authorization).toBe(
      'Bearer my-secret-token',
    );
  });

  it('does NOT add Authorization header when accessor returns null', async () => {
    setAuthTokenAccessor(() => null);

    const { InternalAxiosRequestConfig } = await import('axios');
    const config = {
      headers: {},
    } as typeof InternalAxiosRequestConfig.prototype;

    // biome-ignore lint/suspicious/noExplicitAny: test internals
    const interceptors = (api.interceptors.request as any).handlers as Array<{
      fulfilled: (c: unknown) => unknown;
    } | null>;
    const interceptor = interceptors.find(Boolean);
    if (!interceptor) throw new Error('Interceptor not found');

    const result = await (interceptor.fulfilled(config) as Promise<typeof config>);
    expect((result as { headers: Record<string, string> }).headers.Authorization).toBeUndefined();
  });
});
