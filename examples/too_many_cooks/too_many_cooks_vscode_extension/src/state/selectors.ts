// Derived state selectors.

import type { AgentDetails, AgentIdentity, AgentPlan, AppState, ConnectionStatus, FileLock, Message } from './types';

export const selectConnectionStatus = (state: AppState): ConnectionStatus =>
  {return state.connectionStatus};

export const selectAgents = (state: AppState): AgentIdentity[] =>
  {return state.agents};

export const selectLocks = (state: AppState): FileLock[] =>
  {return state.locks};

export const selectMessages = (state: AppState): Message[] =>
  {return state.messages};

export const selectPlans = (state: AppState): AgentPlan[] =>
  {return state.plans};

export const selectAgentCount = (state: AppState): number =>
  {return state.agents.length};

export const selectLockCount = (state: AppState): number =>
  {return state.locks.length};

export const selectMessageCount = (state: AppState): number =>
  {return state.messages.length};

export const selectUnreadMessageCount = (state: AppState): number =>
  {return state.messages.filter(m => {return m.readAt === null}).length};

export const selectActiveLocks = (state: AppState): FileLock[] => {
  const now = Date.now();
  return state.locks.filter(l => {return l.expiresAt > now});
};

export const selectExpiredLocks = (state: AppState): FileLock[] => {
  const now = Date.now();
  return state.locks.filter(l => {return l.expiresAt <= now});
};

export const selectAgentDetails = (state: AppState): AgentDetails[] =>
  {return state.agents.map(agent => {return {
    agent,
    locks: state.locks.filter(l => {return l.agentName === agent.agentName}),
    plan: state.plans.find(p => {return p.agentName === agent.agentName}) ?? null,
    sentMessages: state.messages.filter(m => {return m.fromAgent === agent.agentName}),
    receivedMessages: state.messages.filter(
      m => {return m.toAgent === agent.agentName || m.toAgent === '*'}
    ),
  }})};
