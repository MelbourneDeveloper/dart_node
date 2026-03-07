// State types for Too Many Cooks VSCode extension.

// Agent identity (public info only - no key).
export interface AgentIdentity {
  readonly agentName: string;
  readonly lastActive: number;
  readonly registeredAt: number;
}

// File lock info.
export interface FileLock {
  readonly acquiredAt: number;
  readonly agentName: string;
  readonly expiresAt: number;
  readonly filePath: string;
  readonly reason: string | null;
  readonly version: number;
}

// Inter-agent message.
export interface Message {
  readonly content: string;
  readonly createdAt: number;
  readonly fromAgent: string;
  readonly id: string;
  readonly readAt: number | null;
  readonly toAgent: string;
}

// Agent plan (what they're doing and why).
export interface AgentPlan {
  readonly agentName: string;
  readonly currentTask: string;
  readonly goal: string;
  readonly updatedAt: number;
}

// Connection status to the MCP server.
export type ConnectionStatus = 'connected' | 'connecting' | 'disconnected';

// Agent with their associated data (computed/derived state).
export interface AgentDetails {
  readonly agent: AgentIdentity;
  readonly locks: readonly FileLock[];
  readonly plan: AgentPlan | null;
  readonly receivedMessages: readonly Message[];
  readonly sentMessages: readonly Message[];
}

// The complete application state.
export interface AppState {
  readonly agents: readonly AgentIdentity[];
  readonly connectionStatus: ConnectionStatus;
  readonly locks: readonly FileLock[];
  readonly messages: readonly Message[];
  readonly plans: readonly AgentPlan[];
}

// Initial state.
export const initialState: AppState = {
  agents: [],
  connectionStatus: 'disconnected',
  locks: [],
  messages: [],
  plans: [],
};

// Actions - discriminated union.
export type AppAction =
  { readonly agent: AgentIdentity; readonly type: 'AddAgent' } | { readonly agentName: string; readonly type: 'RemoveAgent' } | { readonly agents: readonly AgentIdentity[]; readonly type: 'SetAgents' } | { readonly expiresAt: number; readonly filePath: string; readonly type: 'RenewLock' } | { readonly filePath: string; readonly type: 'RemoveLock' } | { readonly lock: FileLock; readonly type: 'UpsertLock' } | { readonly locks: readonly FileLock[]; readonly type: 'SetLocks' } | { readonly message: Message; readonly type: 'AddMessage' } | { readonly messages: readonly Message[]; readonly type: 'SetMessages' } | { readonly plan: AgentPlan; readonly type: 'UpsertPlan' } | { readonly plans: readonly AgentPlan[]; readonly type: 'SetPlans' } | { readonly status: ConnectionStatus; readonly type: 'SetConnectionStatus' } | { readonly type: 'ResetState' };
