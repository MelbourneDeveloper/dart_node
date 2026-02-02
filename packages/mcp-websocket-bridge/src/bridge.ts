import WebSocket from 'ws';
import { randomUUID } from 'crypto';
import type {
  BridgeOptions,
  ToolDefinition,
  NotificationDefinition,
  ToolCallHandler,
  ServiceMessageHandler,
  SessionStartHandler,
  SessionEndHandler,
  ServiceErrorHandler,
  ServiceEventConfig,
  ToolCallContext,
  ServiceMessageContext,
  HttpClient,
} from './types.js';
import {
  type SessionStore,
  type Session,
  createSessionStore,
  getOrCreateSession,
  deleteSession,
  setSessionWebSocket,
  setSessionHttpClient,
} from './session.js';
import { createHttpClient } from './http-client.js';
import { type Transport, type TransportConfig, createTransport } from './transport.js';
import { isMcpToolError } from './errors.js';

export type Bridge = {
  options: BridgeOptions;
  sessionStore: SessionStore;
  tools: Map<string, ToolDefinition>;
  notifications: Map<string, NotificationDefinition>;
  toolCallHandler: ToolCallHandler | null;
  serviceMessageHandler: ServiceMessageHandler | null;
  sessionStartHandler: SessionStartHandler | null;
  sessionEndHandler: SessionEndHandler | null;
  serviceErrorHandler: ServiceErrorHandler | null;
  serviceEventConfigs: ServiceEventConfig[];
  serviceWs: WebSocket | null;
  transport: Transport | null;
  pollingIntervals: NodeJS.Timeout[];
};

export const createBridge = (options: BridgeOptions): Bridge => ({
  options,
  sessionStore: createSessionStore(),
  tools: new Map(),
  notifications: new Map(),
  toolCallHandler: null,
  serviceMessageHandler: null,
  sessionStartHandler: null,
  sessionEndHandler: null,
  serviceErrorHandler: null,
  serviceEventConfigs: [],
  serviceWs: null,
  transport: null,
  pollingIntervals: [],
});

export const defineTool = (bridge: Bridge, tool: ToolDefinition): void => {
  bridge.tools.set(tool.name, tool);
};

export const defineNotification = (bridge: Bridge, notification: NotificationDefinition): void => {
  bridge.notifications.set(notification.name, notification);
};

export const onToolCall = (bridge: Bridge, handler: ToolCallHandler): void => {
  bridge.toolCallHandler = handler;
};

export const onServiceMessage = (bridge: Bridge, handler: ServiceMessageHandler): void => {
  bridge.serviceMessageHandler = handler;
};

export const onSessionStart = (bridge: Bridge, handler: SessionStartHandler): void => {
  bridge.sessionStartHandler = handler;
};

export const onSessionEnd = (bridge: Bridge, handler: SessionEndHandler): void => {
  bridge.sessionEndHandler = handler;
};

export const onServiceError = (bridge: Bridge, handler: ServiceErrorHandler): void => {
  bridge.serviceErrorHandler = handler;
};

export const onServiceEvent = (bridge: Bridge, config: ServiceEventConfig): void => {
  bridge.serviceEventConfigs.push(config);
};

const createNotifyAgent = (bridge: Bridge) => async (payload: unknown): Promise<void> => {
  bridge.transport?.send(JSON.stringify(payload));
};

const getHttpClientForSession = (bridge: Bridge): HttpClient | null => {
  const endpoint = bridge.options.httpEndpoints?.[0];
  return endpoint ? createHttpClient(endpoint) : null;
};

const buildToolCallContext = (
  bridge: Bridge,
  session: Session,
  requestId: string
): ToolCallContext | null => {
  if (!session.ws) return null;

  const http = session.http ?? getHttpClientForSession(bridge);
  if (!http) return null;

  return {
    requestId,
    sessionId: session.id,
    ws: session.ws,
    http,
    notifyAgent: createNotifyAgent(bridge),
  };
};

const buildServiceMessageContext = (bridge: Bridge, session: Session): ServiceMessageContext => ({
  sessionId: session.id,
  notifyAgent: createNotifyAgent(bridge),
  pendingRequests: session.pendingRequests,
});

const handleToolCall = async (
  bridge: Bridge,
  session: Session,
  toolName: string,
  args: Record<string, unknown>
): Promise<unknown> => {
  if (!bridge.toolCallHandler) {
    throw new Error('No tool call handler registered');
  }

  const requestId = randomUUID();
  const context = buildToolCallContext(bridge, session, requestId);

  if (!context) {
    throw new Error('Unable to create tool call context - missing WebSocket or HTTP client');
  }

  return bridge.toolCallHandler(toolName, args, context);
};

const handleMcpRequest = async (
  bridge: Bridge,
  sessionId: string,
  request: { method: string; params?: Record<string, unknown>; id?: string | number }
): Promise<unknown> => {
  const session = getOrCreateSession(bridge.sessionStore, sessionId);

  switch (request.method) {
    case 'initialize':
      return {
        protocolVersion: '2024-11-05',
        capabilities: { tools: {} },
        serverInfo: { name: bridge.options.name, version: bridge.options.version },
      };

    case 'tools/list':
      return {
        tools: Array.from(bridge.tools.values()).map(t => ({
          name: t.name,
          description: t.description,
          inputSchema: t.inputSchema,
        })),
      };

    case 'tools/call': {
      const params = request.params ?? {};
      const toolName = params.name as string;
      const args = (params.arguments ?? {}) as Record<string, unknown>;

      if (!bridge.tools.has(toolName)) {
        throw new Error(`Unknown tool: ${toolName}`);
      }

      try {
        const result = await handleToolCall(bridge, session, toolName, args);
        return { content: [{ type: 'text', text: JSON.stringify(result) }] };
      } catch (error) {
        if (isMcpToolError(error)) {
          return { isError: true, content: [{ type: 'text', text: JSON.stringify(error) }] };
        }
        throw error;
      }
    }

    default:
      throw new Error(`Unknown method: ${request.method}`);
  }
};

export const connectService = (
  bridge: Bridge,
  url: string,
  options?: { headers?: Record<string, string> }
): void => {
  const ws = new WebSocket(url, { headers: options?.headers });

  ws.on('open', () => {
    bridge.serviceWs = ws;
  });

  ws.on('message', async (data) => {
    if (!bridge.serviceMessageHandler) return;

    for (const session of bridge.sessionStore.sessions.values()) {
      const context = buildServiceMessageContext(bridge, session);
      await bridge.serviceMessageHandler(data.toString(), context);
    }
  });

  ws.on('error', async (error) => {
    if (bridge.serviceErrorHandler) {
      await bridge.serviceErrorHandler(error, { notifyAgent: createNotifyAgent(bridge) });
    }
  });

  ws.on('close', () => {
    bridge.serviceWs = null;
    const config = bridge.options.serviceConnection;
    if (config?.reconnect) {
      setTimeout(() => connectService(bridge, url, options), config.reconnectInterval ?? 5000);
    }
  });

  for (const session of bridge.sessionStore.sessions.values()) {
    setSessionWebSocket(session, ws);
  }
};

const startPolling = (bridge: Bridge): void => {
  for (const config of bridge.serviceEventConfigs) {
    const interval = setInterval(async () => {
      try {
        const response = await fetch(config.pollUrl);
        const events = await response.json() as unknown[];

        for (const session of bridge.sessionStore.sessions.values()) {
          const context = buildServiceMessageContext(bridge, session);
          await config.handler(events, context);
        }
      } catch {
        // Polling error - silently continue
      }
    }, config.interval);

    bridge.pollingIntervals.push(interval);
  }
};

export const start = (bridge: Bridge, config: TransportConfig): void => {
  const httpEndpoint = bridge.options.httpEndpoints?.[0];
  if (httpEndpoint) {
    const httpClient = createHttpClient(httpEndpoint);
    for (const session of bridge.sessionStore.sessions.values()) {
      setSessionHttpClient(session, httpClient);
    }
  }

  const transport = createTransport(config);
  bridge.transport = transport;

  transport.onMessage(async (msg) => {
    try {
      const request = JSON.parse(msg.data);
      const sessionId = request.sessionId ?? 'default';
      const result = await handleMcpRequest(bridge, sessionId, request);
      msg.respond(JSON.stringify({ jsonrpc: '2.0', id: request.id, result }));
    } catch (error) {
      msg.respond(JSON.stringify({
        jsonrpc: '2.0',
        id: null,
        error: { code: -32603, message: error instanceof Error ? error.message : 'Unknown error' },
      }));
    }
  });

  transport.start();
  startPolling(bridge);
};

// Backwards compat alias
export const listen = (bridge: Bridge, port: number, host?: string): void => {
  start(bridge, { type: 'http', port, host });
};

export const close = (bridge: Bridge): void => {
  bridge.transport?.stop();
  bridge.serviceWs?.close();

  for (const interval of bridge.pollingIntervals) {
    clearInterval(interval);
  }
  bridge.pollingIntervals = [];

  for (const [sessionId] of bridge.sessionStore.sessions) {
    deleteSession(bridge.sessionStore, sessionId);
  }
};
