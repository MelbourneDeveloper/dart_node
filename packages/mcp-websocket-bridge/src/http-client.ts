import type { HttpClient, HttpRequestOptions, HttpResponse, HttpEndpointConfig } from './types.js';

const buildUrl = (baseUrl: string, path: string, params?: Record<string, string | number | boolean>): string => {
  const url = new URL(path, baseUrl);
  if (params) {
    Object.entries(params).forEach(([key, value]) => url.searchParams.set(key, String(value)));
  }
  return url.toString();
};

const buildHeaders = (
  configHeaders?: Record<string, string>,
  optionHeaders?: Record<string, string>
): Record<string, string> => ({
  'Content-Type': 'application/json',
  ...configHeaders,
  ...optionHeaders,
});

const makeRequest = async <T>(
  config: HttpEndpointConfig,
  method: string,
  path: string,
  body?: unknown,
  options?: HttpRequestOptions
): Promise<HttpResponse<T>> => {
  const url = buildUrl(config.baseUrl, path, options?.params);
  const headers = buildHeaders(config.headers, options?.headers);

  const response = await fetch(url, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  const responseHeaders: Record<string, string> = {};
  response.headers.forEach((value, key) => {
    responseHeaders[key] = value;
  });

  const data = await response.json() as T;
  return { data, status: response.status, headers: responseHeaders };
};

export const createHttpClient = (config: HttpEndpointConfig): HttpClient => ({
  get: <T>(path: string, options?: HttpRequestOptions) =>
    makeRequest<T>(config, 'GET', path, undefined, options),
  post: <T>(path: string, body?: unknown, options?: HttpRequestOptions) =>
    makeRequest<T>(config, 'POST', path, body, options),
  put: <T>(path: string, body?: unknown, options?: HttpRequestOptions) =>
    makeRequest<T>(config, 'PUT', path, body, options),
  delete: <T>(path: string, options?: HttpRequestOptions) =>
    makeRequest<T>(config, 'DELETE', path, undefined, options),
});
