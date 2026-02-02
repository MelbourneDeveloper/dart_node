export type {
  JSONSchema,
  CorsOptions,
  HttpEndpointConfig,
  ServiceConnectionConfig,
  McpServerConfig,
  BridgeOptions,
  ToolDefinition,
  NotificationDefinition,
  HttpClient,
  HttpRequestOptions,
  HttpResponse,
  ToolCallContext,
  PendingRequest,
  ServiceMessageContext,
  SessionContext,
  ServiceEventConfig,
  ToolCallHandler,
  ServiceMessageHandler,
  SessionStartHandler,
  SessionEndHandler,
  ServiceErrorHandler,
} from './types.js';

export type { McpToolErrorData } from './errors.js';
export { createMcpToolError, isMcpToolError, createServiceConnectionError, createSessionNotFoundError } from './errors.js';

export type { Session, SessionStore } from './session.js';
export {
  createSessionStore,
  createSession,
  getSession,
  getOrCreateSession,
  deleteSession,
  setSessionWebSocket,
  setSessionHttpClient,
  addSseWriter,
  removeSseWriter,
  notifySession,
  getAllSessions,
  getSessionCount,
} from './session.js';

export { createHttpClient } from './http-client.js';

export type { Bridge } from './bridge.js';
export {
  createBridge,
  defineTool,
  defineNotification,
  onToolCall,
  onServiceMessage,
  onSessionStart,
  onSessionEnd,
  onServiceError,
  onServiceEvent,
  connectService,
  listen,
  close,
} from './bridge.js';
