// TreeDataProvider for agents view.

import * as vscode from 'vscode';
import type { AgentDetails, FileLock, Message } from 'state/types';
import { AgentTreeItem } from 'ui/tree/agentTreeItem';
import type { StoreManager } from 'services/storeManager';
import { selectAgentDetails } from 'state/selectors';

// eslint-disable-next-line @typescript-eslint/no-inferrable-types
const MS_PER_SECOND: number = 1000;

export class AgentsTreeProvider implements vscode.TreeDataProvider<AgentTreeItem> {
  private readonly changeEmitter: vscode.EventEmitter<AgentTreeItem | null> =
    new vscode.EventEmitter<AgentTreeItem | null>();

  public readonly onDidChangeTreeData: vscode.Event<AgentTreeItem | null> =
    this.changeEmitter.event;

  private readonly unsubscribe: () => void;

  public constructor(private readonly storeManager: Readonly<StoreManager>) {
    this.unsubscribe = storeManager.subscribe((): void => {
      this.changeEmitter.fire(null);
    });
  }

  // eslint-disable-next-line class-methods-use-this, @typescript-eslint/prefer-readonly-parameter-types
  public getTreeItem(element: AgentTreeItem): vscode.TreeItem {
    return element;
  }

  // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
  public getChildren(element?: AgentTreeItem): AgentTreeItem[] {
    const { state }: Readonly<StoreManager> = this.storeManager;
    const details: readonly AgentDetails[] = selectAgentDetails(state);

    if (typeof element === 'undefined') {
      return details.map((detail: Readonly<AgentDetails>): AgentTreeItem => {
        return createAgentItem(detail);
      });
    }

    if (element.itemType === 'agent' && typeof element.agentName === 'string') {
      const found: AgentDetails | undefined = details.find(
        (detail: Readonly<AgentDetails>): boolean => {
          return detail.agent.agentName === element.agentName;
        },
      );
      if (typeof found === 'undefined') {
        return [];
      }
      return createAgentChildren(found);
    }

    return [];
  }

  public dispose(): void {
    this.unsubscribe();
    this.changeEmitter.dispose();
  }
}

function createAgentItem(detail: Readonly<AgentDetails>): AgentTreeItem {
  const lockCount: number = detail.locks.length;
  const msgCount: number = detail.sentMessages.length + detail.receivedMessages.length;
  const parts: string[] = [];
  if (lockCount > 0) {
    let suffix: string = '';
    if (lockCount > 1) {
      suffix = 's';
    }
    parts.push(`${String(lockCount)} lock${suffix}`);
  }
  if (msgCount > 0) {
    let suffix: string = '';
    if (msgCount > 1) {
      suffix = 's';
    }
    parts.push(`${String(msgCount)} msg${suffix}`);
  }

  let desc: string = 'idle';
  if (parts.length > 0) {
    desc = parts.join(', ');
  }

  const item: AgentTreeItem = new AgentTreeItem({
    agentName: detail.agent.agentName,
    collapsibleState: vscode.TreeItemCollapsibleState.Collapsed,
    itemType: 'agent',
    label: detail.agent.agentName,
  });
  item.description = desc;
  item.iconPath = new vscode.ThemeIcon('person');
  item.contextValue = 'deletableAgent';
  item.tooltip = createAgentTooltip(detail);
  return item;
}

function createAgentTooltip(detail: Readonly<AgentDetails>): vscode.MarkdownString {
  const { agent }: Readonly<AgentDetails> = detail;
  const regDate: Date = new Date(agent.registeredAt);
  const activeDate: Date = new Date(agent.lastActive);

  const md: vscode.MarkdownString = new vscode.MarkdownString();
  md.appendMarkdown(`**Agent:** ${agent.agentName}\n\n`);
  md.appendMarkdown(`**Registered:** ${String(regDate)}\n\n`);
  md.appendMarkdown(`**Last Active:** ${String(activeDate)}\n\n`);

  if (detail.plan !== null) {
    md.appendMarkdown('---\n\n');
    md.appendMarkdown(`**Goal:** ${detail.plan.goal}\n\n`);
    md.appendMarkdown(`**Current Task:** ${detail.plan.currentTask}\n\n`);
  }

  appendLocksTooltip(md, detail);
  appendMessagesTooltip(md, detail);

  return md;
}

// eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
function appendLocksTooltip(md: vscode.MarkdownString, detail: Readonly<AgentDetails>): void {
  if (detail.locks.length === 0) {
    return;
  }
  md.appendMarkdown('---\n\n');
  md.appendMarkdown(`**Locks (${String(detail.locks.length)}):**\n`);
  const now: number = Date.now();
  for (const lock of detail.locks) {
    const expired: boolean = lock.expiresAt <= now;
    let status: string = 'active';
    if (expired) {
      status = 'EXPIRED';
    }
    md.appendMarkdown(`- \`${lock.filePath}\` (${status})\n`);
  }
}

// eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
function appendMessagesTooltip(md: vscode.MarkdownString, detail: Readonly<AgentDetails>): void {
  const unread: number = detail.receivedMessages.filter(
    (msg: Readonly<Message>): boolean => { return msg.readAt === null; },
  ).length;
  if (detail.sentMessages.length === 0 && detail.receivedMessages.length === 0) {
    return;
  }
  md.appendMarkdown('\n---\n\n');
  // eslint-disable-next-line @typescript-eslint/no-inferrable-types
  let unreadStr: string = '';
  if (unread > 0) {
    unreadStr = ` **(${String(unread)} unread)**`;
  }
  md.appendMarkdown(
    `**Messages:** ${String(detail.sentMessages.length)} sent, ` +
    `${String(detail.receivedMessages.length)} received${unreadStr}\n`,
  );
}

function createAgentChildren(detail: Readonly<AgentDetails>): AgentTreeItem[] {
  const children: AgentTreeItem[] = [];
  const now: number = Date.now();

  if (detail.plan !== null) {
    children.push(createPlanChild(detail));
  }

  for (const lock of detail.locks) {
    children.push(createLockChild(lock, detail.agent.agentName, now));
  }

  addMessageSummaryChild(children, detail);

  return children;
}

function createPlanChild(detail: Readonly<AgentDetails>): AgentTreeItem {
  const item: AgentTreeItem = new AgentTreeItem({
    agentName: detail.agent.agentName,
    collapsibleState: vscode.TreeItemCollapsibleState.None,
    itemType: 'plan',
    label: `Goal: ${detail.plan?.goal ?? ''}`,
  });
  item.description = `Task: ${detail.plan?.currentTask ?? ''}`;
  item.iconPath = new vscode.ThemeIcon('target');
  return item;
}

function createLockChild(
  lock: Readonly<FileLock>,
  agentName: string,
  now: number,
): AgentTreeItem {
  const expiresIn: number = Math.max(0, Math.round((lock.expiresAt - now) / MS_PER_SECOND));
  const expired: boolean = lock.expiresAt <= now;
  const item: AgentTreeItem = new AgentTreeItem({
    agentName,
    collapsibleState: vscode.TreeItemCollapsibleState.None,
    filePath: lock.filePath,
    itemType: 'lock',
    label: lock.filePath,
  });
  if (expired) {
    item.description = 'EXPIRED';
  } else if (lock.reason === null) {
    item.description = `${String(expiresIn)}s`;
  } else {
    item.description = `${String(expiresIn)}s (${lock.reason})`;
  }
  item.iconPath = new vscode.ThemeIcon('lock');
  item.contextValue = 'lock';
  return item;
}

// eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
function addMessageSummaryChild(children: AgentTreeItem[], detail: Readonly<AgentDetails>): void {
  const unread: number = detail.receivedMessages.filter(
    (msg: Readonly<Message>): boolean => { return msg.readAt === null; },
  ).length;
  if (detail.sentMessages.length === 0 && detail.receivedMessages.length === 0) {
    return;
  }
  const sent: number = detail.sentMessages.length;
  const recv: number = detail.receivedMessages.length;
  // eslint-disable-next-line @typescript-eslint/no-inferrable-types
  let unreadStr: string = '';
  if (unread > 0) {
    unreadStr = ` (${String(unread)} unread)`;
  }
  const item: AgentTreeItem = new AgentTreeItem({
    agentName: detail.agent.agentName,
    collapsibleState: vscode.TreeItemCollapsibleState.None,
    itemType: 'messageSummary',
    label: 'Messages',
  });
  item.description = `${String(sent)} sent, ${String(recv)} received${unreadStr}`;
  item.iconPath = new vscode.ThemeIcon('mail');
  children.push(item);
}
