// TestAPI interface and factory for integration tests.

import { AgentIdentity, FileLock, Message, AgentPlan, AgentDetails } from './state/types';
import { selectAgentDetails } from './state/selectors';
import { StoreManager } from './services/storeManager';
import { AgentsTreeProvider } from './ui/tree/agentsTreeProvider';
import { LocksTreeProvider } from './ui/tree/locksTreeProvider';
import { MessagesTreeProvider } from './ui/tree/messagesTreeProvider';
import { AgentTreeItem } from './ui/tree/treeItems';
import { LockTreeItem } from './ui/tree/treeItems';
import { MessageTreeItem } from './ui/tree/treeItems';

export interface TreeItemSnapshot {
  label: string;
  description?: string;
  children?: TreeItemSnapshot[];
}

export interface TestAPI {
  getAgents(): AgentIdentity[];
  getLocks(): FileLock[];
  getMessages(): Message[];
  getPlans(): AgentPlan[];
  getConnectionStatus(): string;
  getAgentCount(): number;
  getLockCount(): number;
  getMessageCount(): number;
  getUnreadMessageCount(): number;
  getAgentDetails(): AgentDetails[];
  connect(): Promise<void>;
  disconnect(): Promise<void>;
  refreshStatus(): Promise<void>;
  isConnected(): boolean;
  isConnecting(): boolean;
  callTool(name: string, args: Record<string, unknown>): Promise<string>;
  forceReleaseLock(filePath: string): Promise<void>;
  deleteAgent(agentName: string): Promise<void>;
  sendMessage(fromAgent: string, toAgent: string, content: string): Promise<void>;
  getLockTreeItemCount(): number;
  getMessageTreeItemCount(): number;
  getAgentsTreeSnapshot(): TreeItemSnapshot[];
  getLocksTreeSnapshot(): TreeItemSnapshot[];
  getMessagesTreeSnapshot(): TreeItemSnapshot[];
  findAgentInTree(agentName: string): TreeItemSnapshot | null;
  findLockInTree(filePath: string): TreeItemSnapshot | null;
  findMessageInTree(content: string): TreeItemSnapshot | null;
  getLogMessages(): string[];
}

export function createTestAPI(
  storeManager: StoreManager,
  agentsProvider: AgentsTreeProvider,
  locksProvider: LocksTreeProvider,
  messagesProvider: MessagesTreeProvider,
  logMessages: string[],
): TestAPI {
  function toAgentSnapshot(item: AgentTreeItem): TreeItemSnapshot {
    const label = typeof item.label === 'string' ? item.label : '';
    const snapshot: TreeItemSnapshot = { label };
    if (item.description) { snapshot.description = String(item.description); }
    const children = agentsProvider.getChildren(item);
    if (children.length > 0) {
      snapshot.children = children.map(toAgentSnapshot);
    }
    return snapshot;
  }

  function toLockSnapshot(item: LockTreeItem): TreeItemSnapshot {
    const label = typeof item.label === 'string' ? item.label : '';
    const snapshot: TreeItemSnapshot = { label };
    if (item.description) { snapshot.description = String(item.description); }
    const children = locksProvider.getChildren(item);
    if (children.length > 0) {
      snapshot.children = children.map(toLockSnapshot);
    }
    return snapshot;
  }

  function toMessageSnapshot(item: MessageTreeItem): TreeItemSnapshot {
    const label = typeof item.label === 'string' ? item.label : '';
    const snapshot: TreeItemSnapshot = { label };
    if (item.description) { snapshot.description = String(item.description); }
    return snapshot;
  }

  function findInTree(
    items: TreeItemSnapshot[],
    predicate: (item: TreeItemSnapshot) => boolean,
  ): TreeItemSnapshot | null {
    for (const item of items) {
      if (predicate(item)) { return item; }
      if (item.children) {
        const found = findInTree(item.children, predicate);
        if (found) { return found; }
      }
    }
    return null;
  }

  return {
    getAgents: () => storeManager.state.agents,
    getLocks: () => storeManager.state.locks,
    getMessages: () => storeManager.state.messages,
    getPlans: () => storeManager.state.plans,
    getConnectionStatus: () => storeManager.state.connectionStatus,
    getAgentCount: () => storeManager.state.agents.length,
    getLockCount: () => storeManager.state.locks.length,
    getMessageCount: () => storeManager.state.messages.length,
    getUnreadMessageCount: () =>
      storeManager.state.messages.filter(m => m.readAt === null).length,
    getAgentDetails: () => selectAgentDetails(storeManager.state),

    connect: () => storeManager.connect(),
    disconnect: () => storeManager.disconnect(),
    refreshStatus: async () => {
      try { await storeManager.refreshStatus(); } catch { /* swallow */ }
    },
    isConnected: () => storeManager.isConnected,
    isConnecting: () => storeManager.isConnecting,
    callTool: (name, args) => storeManager.callTool(name, args),
    forceReleaseLock: async (filePath) => { storeManager.forceReleaseLock(filePath); },
    deleteAgent: async (agentName) => { storeManager.deleteAgent(agentName); },
    sendMessage: async (fromAgent, toAgent, content) => {
      storeManager.sendMessage(fromAgent, toAgent, content);
    },

    getLockTreeItemCount: () => {
      const categories = locksProvider.getChildren();
      let count = 0;
      for (const cat of categories) {
        const children = locksProvider.getChildren(cat);
        count += children.length;
      }
      return count;
    },
    getMessageTreeItemCount: () => {
      const items = messagesProvider.getChildren();
      return items.filter(item => {
        const label = typeof item.label === 'string' ? item.label : '';
        return label !== 'No messages';
      }).length;
    },

    getAgentsTreeSnapshot: () =>
      agentsProvider.getChildren().map(toAgentSnapshot),
    getLocksTreeSnapshot: () =>
      locksProvider.getChildren().map(toLockSnapshot),
    getMessagesTreeSnapshot: () =>
      messagesProvider.getChildren().map(toMessageSnapshot),

    findAgentInTree: (agentName) =>
      findInTree(
        agentsProvider.getChildren().map(toAgentSnapshot),
        item => item.label === agentName,
      ),
    findLockInTree: (filePath) =>
      findInTree(
        locksProvider.getChildren().map(toLockSnapshot),
        item => item.label === filePath,
      ),
    findMessageInTree: (content) =>
      findInTree(
        messagesProvider.getChildren().map(toMessageSnapshot),
        item => item.description?.includes(content) ?? false,
      ),

    getLogMessages: () => [...logMessages],
  };
}
