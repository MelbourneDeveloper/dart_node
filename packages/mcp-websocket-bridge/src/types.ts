import type WebSocket from 'ws';

export interface JSONSchema {
  type: string;
  properties?: Record<string, JSONSchema>;
  required?: string[];
  items?: JSONSchema;
  description?: string;
  format?: string;
  enum?: string[];
  additionalProperties?: boolean | JSONSchema;
}

export interface CorsOptions {
  origin?: string | string[] | boolean;
  methods?: string[];
  allowedHeaders?: string[];
  credentials?: boolean;
}

export interface HttpEndpointConfig {
  name: string;
  baseUrl: string;
  headers?: Record<string, string>;
}

export interface ServiceConnectionConfig {
  url: string;
  reconnect?: boolean;
  reconnectInterval?: number;
  headers?: Record<string, string>;
}

export interface McpServerConfig {
  port?: number;
  host?: string;
  cors?: CorsOptions;
}

export interface BridgeOptions {
  name: string;
  version: string;
  httpEndpoints?: HttpEndpointConfig[];
  serviceConnection?: ServiceConnectionConfig;
  mcpServer?: McpServerConfig;
}

export interface ToolDefinition {
  name: string;
  description: string;
  inputSchema: JSONSchema;
  asyncResponse?: boolean;
}

export interface NotificationDefinition {
  name: string;
  description: string;
  schema: JSONSchema;
}

export interface HttpClient {
  get<T = unknown>(path: string, options?: HttpRequestOptions): Promise<HttpResponse<T>>;
  post<T = unknown>(path: string, body?: unknown, options?: HttpRequestOptions): Promise<HttpResponse<T>>;
  put<T = unknown>(path: string, body?: unknown, options?: HttpRequestOptions): Promise<HttpResponse<T>>;
  delete<T = unknown>(path: string, options?: HttpRequestOptions): Promise<HttpResponse<T>>;
}

export interface HttpRequestOptions {
  params?: Record<string, string | number | boolean>;
  headers?: Record<string, string>;
}

export interface HttpResponse<T = unknown> {
  data: T;
  status: number;
  headers: Record<string, string>;
}

export interface ToolCallContext {
  requestId: string;
  sessionId: string;
  ws: WebSocket;
  http: HttpClient;
  notifyAgent: (payload: unknown) => Promise<void>;
}

export interface PendingRequest {
  requestId: string;
  toolName: string;
  timestamp: number;
  resolve: (value: unknown) => void;
  reject: (error: Error) => void;
}

export interface ServiceMessageContext {
  sessionId: string;
  notifyAgent: (payload: unknown) => Promise<void>;
  pendingRequests: Map<string, PendingRequest>;
}

export interface SessionContext {
  sessionId: string;
  ws: WebSocket;
  http: HttpClient;
  notifyAgent: (payload: unknown) => Promise<void>;
}

export interface ServiceEventConfig {
  pollUrl: string;
  interval: number;
  handler: (events: unknown[], context: ServiceMessageContext) => Promise<void>;
}

export type ToolCallHandler = (
  toolName: string,
  args: Record<string, unknown>,
  context: ToolCallContext
) => Promise<unknown>;

export type ServiceMessageHandler = (
  message: string | Buffer,
  context: ServiceMessageContext
) => Promise<void>;

export type SessionStartHandler = (
  sessionId: string,
  context: SessionContext
) => Promise<void>;

export type SessionEndHandler = (
  sessionId: string,
  context: SessionContext
) => Promise<void>;

export type ServiceErrorHandler = (
  error: Error,
  context: { notifyAgent: (payload: unknown) => Promise<void> }
) => Promise<void>;
