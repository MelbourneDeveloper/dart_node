// TestAPI interface and factory for integration tests.

import type * as vscode from 'vscode';
import type { AgentDetails, AgentIdentity, AgentPlan, FileLock, Message } from 'state/types';
import type { AgentTreeItem } from 'ui/tree/agentTreeItem';
import type { AgentsTreeProvider } from 'ui/tree/agentsTreeProvider';
import type { LockTreeItem } from 'ui/tree/lockTreeItem';
import type { LocksTreeProvider } from 'ui/tree/locksTreeProvider';
import type { MessageTreeItem } from 'ui/tree/messageTreeItem';
import type { MessagesTreeProvider } from 'ui/tree/messagesTreeProvider';
import type { StoreManager } from 'services/storeManager';
import { selectAgentDetails } from 'state/selectors';

export interface TreeItemSnapshot {
  readonly children?: readonly TreeItemSnapshot[];
  readonly description?: string;
  readonly label: string;
}

export interface TestAPIConfig {
  readonly agentsProvider: AgentsTreeProvider;
  readonly locksProvider: LocksTreeProvider;
  readonly logMessages: readonly string[];
  readonly messagesProvider: MessagesTreeProvider;
  readonly storeManager: StoreManager;
}

export interface TestAPI {
  readonly callTool: (name: string, args: Readonly<Record<string, unknown>>) => Promise<string>;
  readonly connect: () => Promise<void>;
  readonly deleteAgent: (agentName: string) => Promise<void>;
  readonly disconnect: () => Promise<void>;
  readonly findAgentInTree: (agentName: string) => TreeItemSnapshot | null;
  readonly findLockInTree: (filePath: string) => TreeItemSnapshot | null;
  readonly findMessageInTree: (content: string) => TreeItemSnapshot | null;
  readonly forceReleaseLock: (filePath: string) => Promise<void>;
  readonly getAgentCount: () => number;
  readonly getAgentDetails: () => AgentDetails[];
  readonly getAgents: () => readonly AgentIdentity[];
  readonly getAgentsTreeSnapshot: () => TreeItemSnapshot[];
  readonly getConnectionStatus: () => string;
  readonly getLockCount: () => number;
  readonly getLockTreeItemCount: () => number;
  readonly getLocks: () => readonly FileLock[];
  readonly getLocksTreeSnapshot: () => TreeItemSnapshot[];
  readonly getLogMessages: () => string[];
  readonly getMessageCount: () => number;
  readonly getMessageTreeItemCount: () => number;
  readonly getMessages: () => readonly Message[];
  readonly getMessagesTreeSnapshot: () => TreeItemSnapshot[];
  readonly getPlans: () => readonly AgentPlan[];
  readonly getUnreadMessageCount: () => number;
  readonly isConnected: () => boolean;
  readonly isConnecting: () => boolean;
  readonly refreshStatus: () => Promise<void>;
  readonly sendMessage: (fromAgent: string, toAgent: string, content: string) => Promise<void>;
}

// eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
function extractLabel(item: vscode.TreeItem): string {
  if (typeof item.label === 'string') {
    return item.label;
  }
  return '';
}

// eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
function extractDescription(item: vscode.TreeItem): string {
  if (typeof item.description === 'string') {
    return item.description;
  }
  return '';
}

// eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
function toAgentSnapshot(item: AgentTreeItem, provider: Readonly<AgentsTreeProvider>): TreeItemSnapshot {
  const label: string = extractLabel(item);
  const children: AgentTreeItem[] = provider.getChildren(item);
  const desc: string = extractDescription(item);
  if (children.length > 0) {
    const mapped: TreeItemSnapshot[] = children.map(
      // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
      (child: AgentTreeItem): TreeItemSnapshot => { return toAgentSnapshot(child, provider); },
    );
    if (desc.length > 0) { return { children: mapped, description: desc, label }; }
    return { children: mapped, label };
  }
  if (desc.length > 0) { return { description: desc, label }; }
  return { label };
}

// eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
function toLockSnapshot(item: LockTreeItem, provider: Readonly<LocksTreeProvider>): TreeItemSnapshot {
  const label: string = extractLabel(item);
  const children: LockTreeItem[] = provider.getChildren(item);
  const desc: string = extractDescription(item);
  if (children.length > 0) {
    const mapped: TreeItemSnapshot[] = children.map(
      // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
      (child: LockTreeItem): TreeItemSnapshot => { return toLockSnapshot(child, provider); },
    );
    if (desc.length > 0) { return { children: mapped, description: desc, label }; }
    return { children: mapped, label };
  }
  if (desc.length > 0) { return { description: desc, label }; }
  return { label };
}

// eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
function toMessageSnapshot(item: MessageTreeItem): TreeItemSnapshot {
  const label: string = extractLabel(item);
  const desc: string = extractDescription(item);
  if (desc.length > 0) {
    return { description: desc, label };
  }
  return { label };
}

function findByLabel(snapshots: readonly TreeItemSnapshot[], name: string): TreeItemSnapshot | null {
  return findInTree(
    snapshots,
    (item: Readonly<TreeItemSnapshot>): boolean => { return item.label === name; },
  );
}

function findByContent(snapshots: readonly TreeItemSnapshot[], content: string): TreeItemSnapshot | null {
  return findInTree(
    snapshots,
    (item: Readonly<TreeItemSnapshot>): boolean => {
      return item.description?.includes(content) ?? false;
    },
  );
}

function findInTree(
  items: readonly TreeItemSnapshot[],
  predicate: (item: Readonly<TreeItemSnapshot>) => boolean,
): TreeItemSnapshot | null {
  for (const item of items) {
    if (predicate(item)) { return item; }
    if (typeof item.children !== 'undefined') {
      const found: TreeItemSnapshot | null = findInTree(item.children, predicate);
      if (found !== null) { return found; }
    }
  }
  return null;
}

function countLockTreeItems(locksProvider: Readonly<LocksTreeProvider>): number {
  const categories: LockTreeItem[] = locksProvider.getChildren();
  // eslint-disable-next-line @typescript-eslint/no-inferrable-types
  let count: number = 0;
  for (const cat of categories) {
    count += locksProvider.getChildren(cat).length;
  }
  return count;
}

// eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
function countMessageTreeItems(messagesProvider: Readonly<MessagesTreeProvider>): number {
  return messagesProvider.getChildren().filter(
    // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
    (item: MessageTreeItem): boolean => { return extractLabel(item) !== 'No messages'; },
  ).length;
}

function mapAgentSnapshots(provider: Readonly<AgentsTreeProvider>): TreeItemSnapshot[] {
  return provider.getChildren().map(
    // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
    (item: AgentTreeItem): TreeItemSnapshot => { return toAgentSnapshot(item, provider); },
  );
}

function mapLockSnapshots(provider: Readonly<LocksTreeProvider>): TreeItemSnapshot[] {
  return provider.getChildren().map(
    // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
    (item: LockTreeItem): TreeItemSnapshot => { return toLockSnapshot(item, provider); },
  );
}

function countUnread(storeManager: Readonly<StoreManager>): number {
  return storeManager.state.messages.filter(
    (msg: Readonly<Message>): boolean => { return msg.readAt === null; },
  ).length;
}

async function safeRefresh(storeManager: Readonly<StoreManager>): Promise<void> {
  try {
    await storeManager.refreshStatus();
  } catch {
    // Swallow refresh errors in test API
  }
}

function createAsyncMethods(
  sm: Readonly<StoreManager>,
): Pick<TestAPI, 'callTool' | 'connect' | 'deleteAgent' | 'disconnect' | 'forceReleaseLock' | 'refreshStatus' | 'sendMessage'> {
  return {
    callTool: async (name: string, args: Readonly<Record<string, unknown>>): Promise<string> => {
      const result: string = await sm.callTool(name, args);
      return result;
    },
    connect: async (): Promise<void> => { await sm.connect(); },
    deleteAgent: async (agentName: string): Promise<void> => { await sm.deleteAgent(agentName); },
    disconnect: async (): Promise<void> => { await Promise.resolve(); sm.disconnect(); },
    forceReleaseLock: async (fp: string): Promise<void> => { await sm.forceReleaseLock(fp); },
    refreshStatus: async (): Promise<void> => { await safeRefresh(sm); },
    sendMessage: async (fromAgent: string, toAgent: string, content: string): Promise<void> => {
      await sm.sendMessage(fromAgent, toAgent, content);
    },
  };
}

function createTreeMethods(
  agentsProvider: Readonly<AgentsTreeProvider>,
  locksProvider: Readonly<LocksTreeProvider>,
  messagesProvider: Readonly<MessagesTreeProvider>,
): Pick<TestAPI, 'findAgentInTree' | 'findLockInTree' | 'findMessageInTree' | 'getAgentsTreeSnapshot' | 'getLocksTreeSnapshot' | 'getMessagesTreeSnapshot'> {
  return {
    findAgentInTree: (name: string): TreeItemSnapshot | null => {
      return findByLabel(mapAgentSnapshots(agentsProvider), name);
    },
    findLockInTree: (filePath: string): TreeItemSnapshot | null => {
      return findByLabel(mapLockSnapshots(locksProvider), filePath);
    },
    findMessageInTree: (content: string): TreeItemSnapshot | null => {
      return findByContent(messagesProvider.getChildren().map(toMessageSnapshot), content);
    },
    getAgentsTreeSnapshot: (): TreeItemSnapshot[] => { return mapAgentSnapshots(agentsProvider); },
    getLocksTreeSnapshot: (): TreeItemSnapshot[] => { return mapLockSnapshots(locksProvider); },
    getMessagesTreeSnapshot: (): TreeItemSnapshot[] => {
      return messagesProvider.getChildren().map(toMessageSnapshot);
    },
  };
}

interface StateMethodsConfig {
  readonly locksProvider: LocksTreeProvider;
  readonly logMessages: readonly string[];
  readonly messagesProvider: MessagesTreeProvider;
  readonly storeManager: StoreManager;
}

function createStateMethods(
  config: Readonly<StateMethodsConfig>,
): Pick<TestAPI, 'getAgentCount' | 'getAgentDetails' | 'getAgents' | 'getConnectionStatus' | 'getLockCount' | 'getLocks' | 'getLockTreeItemCount' | 'getLogMessages' | 'getMessageCount' | 'getMessages' | 'getMessageTreeItemCount' | 'getPlans' | 'getUnreadMessageCount' | 'isConnected' | 'isConnecting'> {
  const { locksProvider, logMessages, messagesProvider, storeManager }: Readonly<StateMethodsConfig> = config;
  return {
    getAgentCount: (): number => { return storeManager.state.agents.length; },
    getAgentDetails: (): AgentDetails[] => { return selectAgentDetails(storeManager.state); },
    getAgents: (): readonly AgentIdentity[] => { return storeManager.state.agents; },
    getConnectionStatus: (): string => { return storeManager.state.connectionStatus; },
    getLockCount: (): number => { return storeManager.state.locks.length; },
    getLockTreeItemCount: (): number => { return countLockTreeItems(locksProvider); },
    getLocks: (): readonly FileLock[] => { return storeManager.state.locks; },
    getLogMessages: (): string[] => { return [...logMessages]; },
    getMessageCount: (): number => { return storeManager.state.messages.length; },
    getMessageTreeItemCount: (): number => { return countMessageTreeItems(messagesProvider); },
    getMessages: (): readonly Message[] => { return storeManager.state.messages; },
    getPlans: (): readonly AgentPlan[] => { return storeManager.state.plans; },
    getUnreadMessageCount: (): number => { return countUnread(storeManager); },
    isConnected: (): boolean => { return storeManager.isConnected; },
    isConnecting: (): boolean => { return storeManager.isConnecting; },
  };
}

// eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
export function createTestAPI(config: TestAPIConfig): TestAPI {
  const { agentsProvider, locksProvider, logMessages, messagesProvider, storeManager }:
    Readonly<TestAPIConfig> = config;
  return {
    ...createAsyncMethods(storeManager),
    ...createTreeMethods(agentsProvider, locksProvider, messagesProvider),
    ...createStateMethods({ locksProvider, logMessages, messagesProvider, storeManager }),
  } satisfies TestAPI;
}
