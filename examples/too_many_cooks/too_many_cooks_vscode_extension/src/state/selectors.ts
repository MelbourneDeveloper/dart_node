// Derived state selectors.

import { AppState, AgentIdentity, FileLock, Message, AgentPlan, AgentDetails, ConnectionStatus } from './types';

export const selectConnectionStatus = (state: AppState): ConnectionStatus =>
  state.connectionStatus;

export const selectAgents = (state: AppState): AgentIdentity[] =>
  state.agents;

export const selectLocks = (state: AppState): FileLock[] =>
  state.locks;

export const selectMessages = (state: AppState): Message[] =>
  state.messages;

export const selectPlans = (state: AppState): AgentPlan[] =>
  state.plans;

export const selectAgentCount = (state: AppState): number =>
  state.agents.length;

export const selectLockCount = (state: AppState): number =>
  state.locks.length;

export const selectMessageCount = (state: AppState): number =>
  state.messages.length;

export const selectUnreadMessageCount = (state: AppState): number =>
  state.messages.filter(m => m.readAt === null).length;

export const selectActiveLocks = (state: AppState): FileLock[] => {
  const now = Date.now();
  return state.locks.filter(l => l.expiresAt > now);
};

export const selectExpiredLocks = (state: AppState): FileLock[] => {
  const now = Date.now();
  return state.locks.filter(l => l.expiresAt <= now);
};

export const selectAgentDetails = (state: AppState): AgentDetails[] =>
  state.agents.map(agent => ({
    agent,
    locks: state.locks.filter(l => l.agentName === agent.agentName),
    plan: state.plans.find(p => p.agentName === agent.agentName) ?? null,
    sentMessages: state.messages.filter(m => m.fromAgent === agent.agentName),
    receivedMessages: state.messages.filter(
      m => m.toAgent === agent.agentName || m.toAgent === '*'
    ),
  }));
