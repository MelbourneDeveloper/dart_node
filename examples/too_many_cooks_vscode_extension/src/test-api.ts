/**
 * Test API exposed for integration tests.
 * This allows tests to inspect internal state and trigger actions.
 */

import {
  agents,
  locks,
  messages,
  plans,
  connectionStatus,
  agentCount,
  lockCount,
  messageCount,
  unreadMessageCount,
  agentDetails,
} from './state/signals';
import type { Store } from './state/store';
import type {
  AgentIdentity,
  FileLock,
  Message,
  AgentPlan,
} from './mcp/types';
import type { AgentDetails as AgentDetailsType } from './state/signals';
import type { AgentsTreeProvider } from './ui/tree/agentsTreeProvider';
import type { LocksTreeProvider } from './ui/tree/locksTreeProvider';
import type { MessagesTreeProvider } from './ui/tree/messagesTreeProvider';

/** Serializable tree item for test assertions - proves what appears in UI */
export interface TreeItemSnapshot {
  label: string;
  description?: string;
  children?: TreeItemSnapshot[];
}

export interface TestAPI {
  // State getters
  getAgents(): AgentIdentity[];
  getLocks(): FileLock[];
  getMessages(): Message[];
  getPlans(): AgentPlan[];
  getConnectionStatus(): string;

  // Computed getters
  getAgentCount(): number;
  getLockCount(): number;
  getMessageCount(): number;
  getUnreadMessageCount(): number;
  getAgentDetails(): AgentDetailsType[];

  // Store actions
  connect(): Promise<void>;
  disconnect(): Promise<void>;
  refreshStatus(): Promise<void>;
  isConnected(): boolean;
  callTool(name: string, args: Record<string, unknown>): Promise<string>;
  forceReleaseLock(filePath: string): Promise<void>;
  deleteAgent(agentName: string): Promise<void>;
  sendMessage(fromAgent: string, toAgent: string, content: string): Promise<void>;

  // Tree view queries
  getLockTreeItemCount(): number;
  getMessageTreeItemCount(): number;

  // Full tree snapshots
  getAgentsTreeSnapshot(): TreeItemSnapshot[];
  getLocksTreeSnapshot(): TreeItemSnapshot[];
  getMessagesTreeSnapshot(): TreeItemSnapshot[];

  // Find specific items in trees
  findAgentInTree(agentName: string): TreeItemSnapshot | undefined;
  findLockInTree(filePath: string): TreeItemSnapshot | undefined;
  findMessageInTree(content: string): TreeItemSnapshot | undefined;

  // Logging
  getLogMessages(): string[];
}

export interface TreeProviders {
  agents: AgentsTreeProvider;
  locks: LocksTreeProvider;
  messages: MessagesTreeProvider;
}

// Global log storage for testing
const logMessages: string[] = [];

export function addLogMessage(message: string): void {
  logMessages.push(message);
}

export function getLogMessages(): string[] {
  return [...logMessages];
}

/** Convert a VSCode TreeItem to a serializable snapshot */
function toSnapshot(
  item: { label?: string | { label: string }; description?: string | boolean },
  getChildren?: () => TreeItemSnapshot[]
): TreeItemSnapshot {
  const labelStr = typeof item.label === 'string' ? item.label : item.label?.label ?? '';
  const descStr = typeof item.description === 'string' ? item.description : undefined;
  const snapshot: TreeItemSnapshot = { label: labelStr };
  if (descStr) snapshot.description = descStr;
  if (getChildren) {
    const children = getChildren();
    if (children.length > 0) snapshot.children = children;
  }
  return snapshot;
}

/** Build agent tree snapshot */
function buildAgentsSnapshot(providers: TreeProviders): TreeItemSnapshot[] {
  const items = providers.agents.getChildren() ?? [];
  return items.map(item =>
    toSnapshot(item, () => {
      const children = providers.agents.getChildren(item) ?? [];
      return children.map(child => toSnapshot(child));
    })
  );
}

/** Build locks tree snapshot */
function buildLocksSnapshot(providers: TreeProviders): TreeItemSnapshot[] {
  const categories = providers.locks.getChildren() ?? [];
  return categories.map(cat =>
    toSnapshot(cat, () => {
      const children = providers.locks.getChildren(cat) ?? [];
      return children.map(child => toSnapshot(child));
    })
  );
}

/** Build messages tree snapshot */
function buildMessagesSnapshot(providers: TreeProviders): TreeItemSnapshot[] {
  const items = providers.messages.getChildren() ?? [];
  return items.map(item => toSnapshot(item));
}

/** Search tree items recursively for a label match */
function findInTree(
  items: TreeItemSnapshot[],
  predicate: (item: TreeItemSnapshot) => boolean
): TreeItemSnapshot | undefined {
  for (const item of items) {
    if (predicate(item)) return item;
    if (item.children) {
      const found = findInTree(item.children, predicate);
      if (found) return found;
    }
  }
  return undefined;
}

export function createTestAPI(store: Store, providers: TreeProviders): TestAPI {
  return {
    getAgents: () => agents.value,
    getLocks: () => locks.value,
    getMessages: () => messages.value,
    getPlans: () => plans.value,
    getConnectionStatus: () => connectionStatus.value,

    getAgentCount: () => agentCount.value,
    getLockCount: () => lockCount.value,
    getMessageCount: () => messageCount.value,
    getUnreadMessageCount: () => unreadMessageCount.value,
    getAgentDetails: () => agentDetails.value,

    connect: () => store.connect(),
    disconnect: () => store.disconnect(),
    refreshStatus: () => store.refreshStatus(),
    isConnected: () => store.isConnected(),
    callTool: (name, args) => store.callTool(name, args),
    forceReleaseLock: filePath => store.forceReleaseLock(filePath),
    deleteAgent: agentName => store.deleteAgent(agentName),
    sendMessage: (fromAgent, toAgent, content) => store.sendMessage(fromAgent, toAgent, content),

    getLockTreeItemCount: () => {
      const categories = providers.locks.getChildren() ?? [];
      return categories.reduce((sum, cat) => {
        const children = providers.locks.getChildren(cat) ?? [];
        return sum + children.length;
      }, 0);
    },
    getMessageTreeItemCount: () => {
      const items = providers.messages.getChildren() ?? [];
      return items.filter(item => item.message !== undefined).length;
    },

    getAgentsTreeSnapshot: () => buildAgentsSnapshot(providers),
    getLocksTreeSnapshot: () => buildLocksSnapshot(providers),
    getMessagesTreeSnapshot: () => buildMessagesSnapshot(providers),

    findAgentInTree: (agentName: string) => {
      const snapshot = buildAgentsSnapshot(providers);
      return findInTree(snapshot, item => item.label === agentName);
    },
    findLockInTree: (filePath: string) => {
      const snapshot = buildLocksSnapshot(providers);
      return findInTree(snapshot, item => item.label === filePath);
    },
    findMessageInTree: (content: string) => {
      const snapshot = buildMessagesSnapshot(providers);
      return findInTree(snapshot, item => item.description?.includes(content) ?? false);
    },

    getLogMessages: () => getLogMessages(),
  };
}
