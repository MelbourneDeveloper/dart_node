// Derived state selectors.

import type { AgentDetails, AgentIdentity, AgentPlan, AppState, ConnectionStatus, FileLock, Message } from 'state/types';

export function selectConnectionStatus(state: Readonly<AppState>): ConnectionStatus {
  return state.connectionStatus;
}

export function selectAgents(state: Readonly<AppState>): readonly AgentIdentity[] {
  return state.agents;
}

export function selectLocks(state: Readonly<AppState>): readonly FileLock[] {
  return state.locks;
}

export function selectMessages(state: Readonly<AppState>): readonly Message[] {
  return state.messages;
}

export function selectPlans(state: Readonly<AppState>): readonly AgentPlan[] {
  return state.plans;
}

export function selectAgentCount(state: Readonly<AppState>): number {
  return state.agents.length;
}

export function selectLockCount(state: Readonly<AppState>): number {
  return state.locks.length;
}

export function selectMessageCount(state: Readonly<AppState>): number {
  return state.messages.length;
}

export function selectUnreadMessageCount(state: Readonly<AppState>): number {
  return state.messages.filter((msg: Message): boolean => {
    return msg.readAt === null;
  }).length;
}

export function selectActiveLocks(state: Readonly<AppState>): readonly FileLock[] {
  const now: number = Date.now();
  return state.locks.filter((lock: FileLock): boolean => {
    return lock.expiresAt > now;
  });
}

export function selectExpiredLocks(state: Readonly<AppState>): readonly FileLock[] {
  const now: number = Date.now();
  return state.locks.filter((lock: FileLock): boolean => {
    return lock.expiresAt <= now;
  });
}

export function selectAgentDetails(state: Readonly<AppState>): AgentDetails[] {
  return state.agents.map((agent: AgentIdentity): AgentDetails => {
    return {
      agent,
      locks: state.locks.filter((lock: FileLock): boolean => {
        return lock.agentName === agent.agentName;
      }),
      plan: state.plans.find((plan: AgentPlan): boolean => {
        return plan.agentName === agent.agentName;
      }) ?? null,
      receivedMessages: state.messages.filter(
        (msg: Message): boolean => {
          return msg.toAgent === agent.agentName || msg.toAgent === '*';
        },
      ),
      sentMessages: state.messages.filter((msg: Message): boolean => {
        return msg.fromAgent === agent.agentName;
      }),
    };
  });
}
