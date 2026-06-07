export type McpToolErrorData = {
  code: string;
  message: string;
  data?: Record<string, unknown>;
};

export const createMcpToolError = (errorData: McpToolErrorData): Error & McpToolErrorData => {
  const error = new Error(errorData.message) as Error & McpToolErrorData;
  error.name = 'McpToolError';
  error.code = errorData.code;
  error.data = errorData.data;
  return error;
};

export const isMcpToolError = (error: unknown): error is Error & McpToolErrorData =>
  error instanceof Error && 'code' in error;

export const createServiceConnectionError = (message: string, cause?: Error): Error => {
  const error = new Error(message);
  error.name = 'ServiceConnectionError';
  error.cause = cause;
  return error;
};

export const createSessionNotFoundError = (sessionId: string): Error => {
  const error = new Error(`Session not found: ${sessionId}`);
  error.name = 'SessionNotFoundError';
  return error;
};
