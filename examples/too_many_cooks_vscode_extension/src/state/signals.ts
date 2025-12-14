/**
 * Signal-based state management using @preact/signals-core.
 */

import { signal, computed } from '@preact/signals-core';
import type {
  AgentIdentity,
  FileLock,
  Message,
  AgentPlan,
} from '../mcp/types';

// Connection state
export type ConnectionStatus = 'disconnected' | 'connecting' | 'connected';
export const connectionStatus = signal<ConnectionStatus>('disconnected');

// Core data signals
export const agents = signal<AgentIdentity[]>([]);
export const locks = signal<FileLock[]>([]);
export const messages = signal<Message[]>([]);
export const plans = signal<AgentPlan[]>([]);

// Computed values
export const agentCount = computed(() => agents.value.length);
export const lockCount = computed(() => locks.value.length);
export const messageCount = computed(() => messages.value.length);

export const unreadMessageCount = computed(
  () => messages.value.filter((m) => m.readAt === undefined).length
);

export const activeLocks = computed(() =>
  locks.value.filter((l) => l.expiresAt > Date.now())
);

export const expiredLocks = computed(() =>
  locks.value.filter((l) => l.expiresAt <= Date.now())
);

/** Agent with their associated data. */
export interface AgentDetails {
  agent: AgentIdentity;
  locks: FileLock[];
  plan?: AgentPlan;
  sentMessages: Message[];
  receivedMessages: Message[];
}

export const agentDetails = computed<AgentDetails[]>(() =>
  agents.value.map((agent) => ({
    agent,
    locks: locks.value.filter((l) => l.agentName === agent.agentName),
    plan: plans.value.find((p) => p.agentName === agent.agentName),
    sentMessages: messages.value.filter(
      (m) => m.fromAgent === agent.agentName
    ),
    receivedMessages: messages.value.filter(
      (m) => m.toAgent === agent.agentName || m.toAgent === '*'
    ),
  }))
);

/** Reset all state. */
export function resetState(): void {
  connectionStatus.value = 'disconnected';
  agents.value = [];
  locks.value = [];
  messages.value = [];
  plans.value = [];
}
