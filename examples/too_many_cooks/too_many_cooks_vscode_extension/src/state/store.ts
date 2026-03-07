// Simple Redux-style store with EventEmitter pattern.

import type { AppAction, AppState, FileLock } from 'state/types';
import { initialState } from 'state/types';

// Reduce agent-related actions.
function reduceAgentAction(state: Readonly<AppState>, action: Readonly<AppAction>): AppState {
  switch (action.type) {
    case 'SetAgents':
      return { ...state, agents: action.agents };
    case 'AddAgent':
      return { ...state, agents: [...state.agents, action.agent] };
    case 'RemoveAgent':
      return {
        ...state,
        agents: state.agents.filter((agent: Readonly<{ agentName: string }>): boolean => {
          return agent.agentName !== action.agentName;
        }),
        locks: state.locks.filter((lock: Readonly<{ agentName: string }>): boolean => {
          return lock.agentName !== action.agentName;
        }),
        plans: state.plans.filter((plan: Readonly<{ agentName: string }>): boolean => {
          return plan.agentName !== action.agentName;
        }),
      };
    default:
      return state;
  }
}

// Reduce lock-related actions.
function reduceLockAction(state: Readonly<AppState>, action: Readonly<AppAction>): AppState {
  switch (action.type) {
    case 'SetLocks':
      return { ...state, locks: action.locks };
    case 'UpsertLock':
      return {
        ...state,
        locks: [
          ...state.locks.filter((lock: Readonly<{ filePath: string }>): boolean => {
            return lock.filePath !== action.lock.filePath;
          }),
          action.lock,
        ],
      };
    case 'RemoveLock':
      return {
        ...state,
        locks: state.locks.filter((lock: Readonly<{ filePath: string }>): boolean => {
          return lock.filePath !== action.filePath;
        }),
      };
    case 'RenewLock':
      return {
        ...state,
        locks: state.locks.map(
          (lock: Readonly<FileLock>): FileLock => {
            if (lock.filePath === action.filePath) {
              return { ...lock, expiresAt: action.expiresAt };
            }
            return lock;
          },
        ),
      };
    default:
      return state;
  }
}

// Reduce message and plan actions.
function reduceDataAction(state: Readonly<AppState>, action: Readonly<AppAction>): AppState {
  switch (action.type) {
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
          ...state.plans.filter((plan: Readonly<{ agentName: string }>): boolean => {
            return plan.agentName !== action.plan.agentName;
          }),
          action.plan,
        ],
      };
    default:
      return state;
  }
}

const AGENT_ACTIONS: ReadonlySet<string> = new Set(['AddAgent', 'RemoveAgent', 'SetAgents']);
const LOCK_ACTIONS: ReadonlySet<string> = new Set(['RemoveLock', 'RenewLock', 'SetLocks', 'UpsertLock']);
const DATA_ACTIONS: ReadonlySet<string> = new Set(['AddMessage', 'SetMessages', 'SetPlans', 'UpsertPlan']);

// Main reducer for the application state.
function appReducer(state: Readonly<AppState>, action: Readonly<AppAction>): AppState {
  if (action.type === 'SetConnectionStatus') {
    return { ...state, connectionStatus: action.status };
  }
  if (action.type === 'ResetState') {
    return initialState;
  }
  if (AGENT_ACTIONS.has(action.type)) {
    return reduceAgentAction(state, action);
  }
  if (LOCK_ACTIONS.has(action.type)) {
    return reduceLockAction(state, action);
  }
  if (DATA_ACTIONS.has(action.type)) {
    return reduceDataAction(state, action);
  }
  return state;
}

export class Store {
  private state: AppState = initialState;
  private readonly listeners: Set<() => void> = new Set<() => void>();

  public getState(): AppState {
    return this.state;
  }

  public dispatch(action: Readonly<AppAction>): void {
    this.state = appReducer(this.state, action);
    this.listeners.forEach((fn: () => void): void => { fn(); });
  }

  public subscribe(listener: () => void): () => void {
    this.listeners.add(listener);
    return (): void => { this.listeners.delete(listener); };
  }
}
