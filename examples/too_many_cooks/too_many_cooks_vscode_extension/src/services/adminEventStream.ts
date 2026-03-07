// Admin event stream client for real-time server-pushed notifications.

import { streamableHttpPost } from 'services/httpClient';

const ADMIN_EVENTS_PATH: string = '/admin/events';
const INITIALIZED_NOTIFICATION: string = 'notifications/initialized';
const MCP_VERSION: string = '2025-03-26';
const CLIENT_NAME: string = 'too-many-cooks-vsix-admin';
const CLIENT_VERSION: string = '1.0.0';

type LogFn = (msg: string) => void;

export interface AdminEventStreamConfig {
  readonly baseUrl: string;
  readonly log: LogFn;
  readonly onEvent: () => void;
}

async function initAdminSession(baseUrl: string): Promise<string> {
  const url: string = `${baseUrl}${ADMIN_EVENTS_PATH}`;
  const body: string = JSON.stringify({
    id: 1,
    jsonrpc: '2.0',
    method: 'initialize',
    params: {
      capabilities: {},
      clientInfo: { name: CLIENT_NAME, version: CLIENT_VERSION },
      protocolVersion: MCP_VERSION,
    },
  });
  const response: Response = await streamableHttpPost(url, body, null);
  const sessionId: string | null = response.headers.get('mcp-session-id');
  if (sessionId === null || sessionId === '') {
    throw new Error('No admin session ID in response');
  }
  const notifyBody: string = JSON.stringify({
    jsonrpc: '2.0',
    method: INITIALIZED_NOTIFICATION,
    params: {},
  });
  await streamableHttpPost(url, notifyBody, sessionId);
  return sessionId;
}

async function readEventStream(
  // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
  body: ReadableStream<Uint8Array>,
  onEvent: () => void,
): Promise<void> {
  const reader: ReadableStreamDefaultReader<Uint8Array> = body.getReader();
  const decoder: TextDecoder = new TextDecoder();
  let buffer: string = '';
  const dataPrefix: string = 'data: ';
  for (;;) {
    const result: ReadableStreamReadResult<Uint8Array> = await reader.read();
    if (result.done) {
      break;
    }
    buffer += decoder.decode(result.value, { stream: true });
    const lines: string[] = buffer.split('\n');
    buffer = lines.pop() ?? '';
    for (const line of lines) {
      if (line.startsWith(dataPrefix)) {
        const lineData: string = line.substring(dataPrefix.length).trim();
        if (lineData.length > 0) {
          onEvent();
        }
      }
    }
  }
}

function listenAdminEvents(
  sessionId: string,
  // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
  signal: AbortSignal,
  config: Readonly<AdminEventStreamConfig>,
): void {
  const headers: Headers = new Headers();
  headers.set('accept', 'application/json, text/event-stream');
  headers.set('mcp-session-id', sessionId);
  fetch(`${config.baseUrl}${ADMIN_EVENTS_PATH}`, {
    headers,
    method: 'GET',
    signal,
  }).then(
    // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
    async (response: Response): Promise<void> => {
      if (!response.ok || response.body === null) {
        config.log(`[AdminEventStream] GET failed: ${String(response.status)}`);
        return;
      }
      await readEventStream(response.body, config.onEvent);
      config.log('[AdminEventStream] Event stream ended');
    },
  ).catch((err: unknown): void => {
    if (!signal.aborted) {
      config.log(`[AdminEventStream] Stream error: ${String(err)}`);
    }
  });
}

export function startAdminEventStream(
  // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
  abortController: AbortController,
  config: Readonly<AdminEventStreamConfig>,
): void {
  const { signal }: { readonly signal: AbortSignal } = abortController;
  initAdminSession(config.baseUrl)
    .then((sessionId: string): void => {
      config.log(`[AdminEventStream] Session started: ${sessionId}`);
      listenAdminEvents(sessionId, signal, config);
    })
    .catch((err: unknown): void => {
      config.log(`[AdminEventStream] Session error: ${String(err)}`);
    });
}
