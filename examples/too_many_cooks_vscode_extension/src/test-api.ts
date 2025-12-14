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
import type { AgentsTreeProvider, AgentTreeItem } from './ui/tree/agentsTreeProvider';
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

  // Admin operations (for coverage of store.ts methods)
  forceReleaseLock(filePath: string): Promise<void>;
  deleteAgent(agentName: string): Promise<void>;
  sendMessage(fromAgent: string, toAgent: string, content: string): Promise<void>;

  // Tree view queries - these prove what APPEARS in the UI
  getAgentTreeItems(): AgentTreeItem[];
  getAgentTreeChildren(agentName: string): AgentTreeItem[];
  getLockTreeItemCount(): number;
  getMessageTreeItemCount(): number;
  getPlanTreeItemCount(): number;

  // Full tree snapshots - serializable proof of what's displayed
  getAgentsTreeSnapshot(): TreeItemSnapshot[];
  getLocksTreeSnapshot(): TreeItemSnapshot[];
  getMessagesTreeSnapshot(): TreeItemSnapshot[];
  getPlansTreeSnapshot(): TreeItemSnapshot[];

  // Find specific items in trees
  findAgentInTree(agentName: string): TreeItemSnapshot | undefined;
  findLockInTree(filePath: string): TreeItemSnapshot | undefined;
  findMessageInTree(content: string): TreeItemSnapshot | undefined;
  findPlanInTree(agentName: string): TreeItemSnapshot | undefined;

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

export function clearLogMessages(): void {
  logMessages.length = 0;
}

/** Convert a VSCode TreeItem to a serializable snapshot */
function toSnapshot(item: { label?: string | { label: string }; description?: string | boolean }, getChildren?: () => TreeItemSnapshot[]): TreeItemSnapshot {
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
  return items.map(item => toSnapshot(item, () => {
    const children = providers.agents.getChildren(item) ?? [];
    return children.map(child => toSnapshot(child));
  }));
}

/** Build locks tree snapshot */
function buildLocksSnapshot(providers: TreeProviders): TreeItemSnapshot[] {
  const categories = providers.locks.getChildren() ?? [];
  return categories.map(cat => toSnapshot(cat, () => {
    const children = providers.locks.getChildren(cat) ?? [];
    return children.map(child => toSnapshot(child));
  }));
}

/** Build messages tree snapshot */
function buildMessagesSnapshot(providers: TreeProviders): TreeItemSnapshot[] {
  const items = providers.messages.getChildren() ?? [];
  return items.map(item => toSnapshot(item));
}

/** Build plans tree snapshot - plans are shown as children under agents */
function buildPlansSnapshot(providers: TreeProviders): TreeItemSnapshot[] {
  // Plans now appear as children under agents, not in a separate tree
  // Return a flat list of plan items found under agents
  const plansFromAgents: TreeItemSnapshot[] = [];
  const agentItems = providers.agents.getChildren() ?? [];
  for (const agent of agentItems) {
    const children = providers.agents.getChildren(agent) ?? [];
    for (const child of children) {
      // Plan items have label starting with "Goal:"
      if (typeof child.label === 'string' && child.label.startsWith('Goal:')) {
        // Create a plan snapshot with agent name as label and task as description
        const desc = typeof child.description === 'string' ? child.description : undefined;
        plansFromAgents.push({
          label: agent.agentName ?? '',
          description: desc,
          children: [
            { label: child.label as string },
            ...(desc ? [{ label: desc }] : []),
          ],
        });
      }
    }
  }
  if (plansFromAgents.length === 0) {
    return [{ label: 'No plans' }];
  }
  return plansFromAgents;
}

/** Search tree items recursively for a label match */
function findInTree(items: TreeItemSnapshot[], predicate: (item: TreeItemSnapshot) => boolean): TreeItemSnapshot | undefined {
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

    // Admin operations (for coverage)
    forceReleaseLock: (filePath) => store.forceReleaseLock(filePath),
    deleteAgent: (agentName) => store.deleteAgent(agentName),
    sendMessage: (fromAgent, toAgent, content) => store.sendMessage(fromAgent, toAgent, content),

    // Tree view queries - these query the ACTUAL tree provider state
    getAgentTreeItems: () => providers.agents.getChildren() ?? [],
    getAgentTreeChildren: (agentName: string) => {
      const agentItems = providers.agents.getChildren() ?? [];
      const agentItem = agentItems.find((item) => item.agentName === agentName);
      return agentItem ? providers.agents.getChildren(agentItem) ?? [] : [];
    },
    getLockTreeItemCount: () => {
      // Sum lock items across all categories (Active, Expired)
      const categories = providers.locks.getChildren() ?? [];
      return categories.reduce((sum, cat) => {
        const children = providers.locks.getChildren(cat) ?? [];
        return sum + children.length;
      }, 0);
    },
    getMessageTreeItemCount: () => {
      // Count only items with actual messages (not "No messages" placeholder)
      const items = providers.messages.getChildren() ?? [];
      return items.filter((item) => item.message !== undefined).length;
    },
    getPlanTreeItemCount: () => {
      // Count plans shown as children under agents (Goal: items)
      let count = 0;
      const agentItems = providers.agents.getChildren() ?? [];
      for (const agent of agentItems) {
        const children = providers.agents.getChildren(agent) ?? [];
        for (const child of children) {
          if (typeof child.label === 'string' && child.label.startsWith('Goal:')) {
            count++;
          }
        }
      }
      return count;
    },

    // Full tree snapshots - PROOF of what's displayed in UI
    getAgentsTreeSnapshot: () => buildAgentsSnapshot(providers),
    getLocksTreeSnapshot: () => buildLocksSnapshot(providers),
    getMessagesTreeSnapshot: () => buildMessagesSnapshot(providers),
    getPlansTreeSnapshot: () => buildPlansSnapshot(providers),

    // Find specific items - search the tree for exact content
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
      return findInTree(snapshot, item =>
        item.description?.includes(content) ?? false
      );
    },
    findPlanInTree: (agentName: string) => {
      const snapshot = buildPlansSnapshot(providers);
      return findInTree(snapshot, item => item.label === agentName);
    },

    // Logging
    getLogMessages: () => getLogMessages(),
  };
}
