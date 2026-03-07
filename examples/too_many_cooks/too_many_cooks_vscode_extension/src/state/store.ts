// Simple Redux-style store with EventEmitter pattern.

import { AppState, AppAction, initialState } from './types';

// Main reducer for the application state.
function appReducer(state: AppState, action: AppAction): AppState {
  switch (action.type) {
    case 'SetConnectionStatus':
      return { ...state, connectionStatus: action.status };
    case 'SetAgents':
      return { ...state, agents: action.agents };
    case 'AddAgent':
      return { ...state, agents: [...state.agents, action.agent] };
    case 'RemoveAgent':
      return {
        ...state,
        agents: state.agents.filter(a => a.agentName !== action.agentName),
        locks: state.locks.filter(l => l.agentName !== action.agentName),
        plans: state.plans.filter(p => p.agentName !== action.agentName),
      };
    case 'SetLocks':
      return { ...state, locks: action.locks };
    case 'UpsertLock':
      return {
        ...state,
        locks: [
          ...state.locks.filter(l => l.filePath !== action.lock.filePath),
          action.lock,
        ],
      };
    case 'RemoveLock':
      return {
        ...state,
        locks: state.locks.filter(l => l.filePath !== action.filePath),
      };
    case 'RenewLock':
      return {
        ...state,
        locks: state.locks.map(l =>
          l.filePath === action.filePath
            ? { ...l, expiresAt: action.expiresAt }
            : l
        ),
      };
    case 'SetMessages':
      return { ...state, messages: action.messages };
    case 'AddMessage':
      return { ...state, messages: [...state.messages, action.message] };
    case 'SetPlans':
      return { ...state, plans: action.plans };
    case 'UpsertPlan':
      return {
        ...state,
        plans: [
          ...state.plans.filter(p => p.agentName !== action.plan.agentName),
          action.plan,
        ],
      };
    case 'ResetState':
      return initialState;
  }
}

export class Store {
  private state: AppState = initialState;
  private listeners: Set<() => void> = new Set();

  getState(): AppState {
    return this.state;
  }

  dispatch(action: AppAction): void {
    this.state = appReducer(this.state, action);
    this.listeners.forEach(fn => fn());
  }

  subscribe(listener: () => void): () => void {
    this.listeners.add(listener);
    return () => { this.listeners.delete(listener); };
  }
}
