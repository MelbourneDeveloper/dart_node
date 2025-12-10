/**
 * TypeScript types matching the Dart MCP server types.
 */

/** Agent identity (public info only - no key). */
export interface AgentIdentity {
  agentName: string;
  registeredAt: number;
  lastActive: number;
}

/** File lock info. */
export interface FileLock {
  filePath: string;
  agentName: string;
  acquiredAt: number;
  expiresAt: number;
  reason?: string;
  version: number;
}

/** Inter-agent message. */
export interface Message {
  id: string;
  fromAgent: string;
  toAgent: string;
  content: string;
  createdAt: number;
  readAt?: number;
}

/** Agent plan. */
export interface AgentPlan {
  agentName: string;
  goal: string;
  currentTask: string;
  updatedAt: number;
}

/** Status response from MCP server. */
export interface StatusResponse {
  agents: Array<{
    agent_name: string;
    registered_at: number;
    last_active: number;
  }>;
  locks: Array<{
    file_path: string;
    agent_name: string;
    acquired_at: number;
    expires_at: number;
    reason?: string;
  }>;
  plans: Array<{
    agent_name: string;
    goal: string;
    current_task: string;
    updated_at: number;
  }>;
  messages: Array<{
    id: string;
    from_agent: string;
    to_agent: string;
    content: string;
    created_at: number;
    read_at?: number;
  }>;
}

/** Notification event from server. */
export interface NotificationEvent {
  event:
    | 'agent_registered'
    | 'lock_acquired'
    | 'lock_released'
    | 'lock_renewed'
    | 'message_sent'
    | 'plan_updated';
  timestamp: number;
  payload: Record<string, unknown>;
}

/** MCP tool call content item. */
export interface ContentItem {
  type: string;
  text: string;
}

/** MCP tool call result. */
export interface ToolCallResult {
  content: ContentItem[];
  isError?: boolean;
}

/** JSON-RPC message. */
export interface JsonRpcMessage {
  jsonrpc: '2.0';
  id?: number;
  method?: string;
  params?: Record<string, unknown>;
  result?: unknown;
  error?: { code: number; message: string };
}
