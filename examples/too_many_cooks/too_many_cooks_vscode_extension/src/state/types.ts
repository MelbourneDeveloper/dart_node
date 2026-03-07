// State types for Too Many Cooks VSCode extension.

// Agent identity (public info only - no key).
export interface AgentIdentity {
  agentName: string;
  registeredAt: number;
  lastActive: number;
}

// File lock info.
export interface FileLock {
  filePath: string;
  agentName: string;
  acquiredAt: number;
  expiresAt: number;
  reason: string | null;
  version: number;
}

// Inter-agent message.
export interface Message {
  id: string;
  fromAgent: string;
  toAgent: string;
  content: string;
  createdAt: number;
  readAt: number | null;
}

// Agent plan (what they're doing and why).
export interface AgentPlan {
  agentName: string;
  goal: string;
  currentTask: string;
  updatedAt: number;
}

// Connection status to the MCP server.
export type ConnectionStatus = 'disconnected' | 'connecting' | 'connected';

// Agent with their associated data (computed/derived state).
export interface AgentDetails {
  agent: AgentIdentity;
  locks: FileLock[];
  plan: AgentPlan | null;
  sentMessages: Message[];
  receivedMessages: Message[];
}

// The complete application state.
export interface AppState {
  connectionStatus: ConnectionStatus;
  agents: AgentIdentity[];
  locks: FileLock[];
  messages: Message[];
  plans: AgentPlan[];
}

// Initial state.
export const initialState: AppState = {
  connectionStatus: 'disconnected',
  agents: [],
  locks: [],
  messages: [],
  plans: [],
};

// Actions - discriminated union.
export type AppAction =
  | { type: 'SetConnectionStatus'; status: ConnectionStatus }
  | { type: 'SetAgents'; agents: AgentIdentity[] }
  | { type: 'AddAgent'; agent: AgentIdentity }
  | { type: 'RemoveAgent'; agentName: string }
  | { type: 'SetLocks'; locks: FileLock[] }
  | { type: 'UpsertLock'; lock: FileLock }
  | { type: 'RemoveLock'; filePath: string }
  | { type: 'RenewLock'; filePath: string; expiresAt: number }
  | { type: 'SetMessages'; messages: Message[] }
  | { type: 'AddMessage'; message: Message }
  | { type: 'SetPlans'; plans: AgentPlan[] }
  | { type: 'UpsertPlan'; plan: AgentPlan }
  | { type: 'ResetState' };
