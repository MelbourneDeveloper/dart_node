// TreeDataProvider for messages view.

import * as vscode from 'vscode';
import type { Message } from 'state/types';
import { MessageTreeItem } from 'ui/tree/messageTreeItem';
import type { StoreManager } from 'services/storeManager';
import { selectMessages } from 'state/selectors';

// eslint-disable-next-line @typescript-eslint/no-inferrable-types
const MS_PER_SECOND: number = 1000;
// eslint-disable-next-line @typescript-eslint/no-inferrable-types
const SECONDS_PER_MINUTE: number = 60;
// eslint-disable-next-line @typescript-eslint/no-inferrable-types
const MINUTES_PER_HOUR: number = 60;
// eslint-disable-next-line @typescript-eslint/no-inferrable-types
const HOURS_PER_DAY: number = 24;

export class MessagesTreeProvider implements vscode.TreeDataProvider<MessageTreeItem> {
  private readonly changeEmitter: vscode.EventEmitter<MessageTreeItem | null> =
    new vscode.EventEmitter<MessageTreeItem | null>();

  public readonly onDidChangeTreeData: vscode.Event<MessageTreeItem | null> =
    this.changeEmitter.event;

  private readonly unsubscribe: () => void;

  public constructor(private readonly storeManager: Readonly<StoreManager>) {
    this.unsubscribe = storeManager.subscribe((): void => {
      this.changeEmitter.fire(null);
    });
  }

  // eslint-disable-next-line class-methods-use-this, @typescript-eslint/prefer-readonly-parameter-types
  public getTreeItem(element: MessageTreeItem): vscode.TreeItem {
    return element;
  }

  // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
  public getChildren(element?: MessageTreeItem): MessageTreeItem[] {
    if (typeof element !== 'undefined') {
      return [];
    }

    const allMessages: readonly Message[] = selectMessages(this.storeManager.state);

    if (allMessages.length === 0) {
      return [new MessageTreeItem('No messages', vscode.TreeItemCollapsibleState.None, null)];
    }

    const sorted: Message[] = [...allMessages].sort(
      (msgA: Readonly<Message>, msgB: Readonly<Message>): number => {
        return msgB.createdAt - msgA.createdAt;
      },
    );

    return sorted.map((msg: Readonly<Message>): MessageTreeItem => {
      return createMessageItem(msg);
    });
  }

  public dispose(): void {
    this.unsubscribe();
    this.changeEmitter.dispose();
  }
}

function createMessageItem(msg: Readonly<Message>): MessageTreeItem {
  let target: string;
  if (msg.toAgent === '*') {
    target = 'all';
  } else {
    target = msg.toAgent;
  }
  const relativeTime: string = getRelativeTimeShort(msg.createdAt);
  // eslint-disable-next-line @typescript-eslint/no-inferrable-types
  let statusPart: string = '';
  if (msg.readAt === null) {
    statusPart = ' [unread]';
  }

  const item: MessageTreeItem = new MessageTreeItem(
    `${msg.fromAgent} \u2192 ${target} | ${relativeTime}${statusPart}`,
    vscode.TreeItemCollapsibleState.None,
    msg,
  );
  item.description = msg.content;
  item.contextValue = 'message';
  item.tooltip = createTooltip(msg);

  if (msg.readAt === null) {
    item.iconPath = new vscode.ThemeIcon(
      'circle-filled',
      new vscode.ThemeColor('charts.yellow'),
    );
  }

  return item;
}

function createTooltip(msg: Readonly<Message>): vscode.MarkdownString {
  let target: string;
  if (msg.toAgent === '*') {
    target = 'Everyone (broadcast)';
  } else {
    target = msg.toAgent;
  }
  const quotedContent: string = msg.content.split('\n').join('\n> ');
  const sentDate: Date = new Date(msg.createdAt);
  const relativeTime: string = getRelativeTime(msg.createdAt);

  const md: vscode.MarkdownString = new vscode.MarkdownString();
  md.isTrusted = true;
  md.appendMarkdown(`### ${msg.fromAgent} \u2192 ${target}\n\n`);
  md.appendMarkdown(`> ${quotedContent}\n\n`);
  md.appendMarkdown('---\n\n');
  md.appendMarkdown(`**Sent:** ${String(sentDate)} (${relativeTime})\n\n`);

  if (msg.readAt === null) {
    md.appendMarkdown('**Status:** Unread\n\n');
  } else {
    const readDate: Date = new Date(msg.readAt);
    md.appendMarkdown(`**Read:** ${String(readDate)}\n\n`);
  }

  md.appendMarkdown(`*ID: ${msg.id}*`);
  return md;
}

function getRelativeTime(timestamp: number): string {
  const diff: number = Date.now() - timestamp;
  const seconds: number = Math.floor(diff / MS_PER_SECOND);
  const minutes: number = Math.floor(seconds / SECONDS_PER_MINUTE);
  const hours: number = Math.floor(minutes / MINUTES_PER_HOUR);
  const days: number = Math.floor(hours / HOURS_PER_DAY);

  if (days > 0) { return `${String(days)}d ago`; }
  if (hours > 0) { return `${String(hours)}h ago`; }
  if (minutes > 0) { return `${String(minutes)}m ago`; }
  return 'just now';
}

function getRelativeTimeShort(timestamp: number): string {
  const diff: number = Date.now() - timestamp;
  const seconds: number = Math.floor(diff / MS_PER_SECOND);
  const minutes: number = Math.floor(seconds / SECONDS_PER_MINUTE);
  const hours: number = Math.floor(minutes / MINUTES_PER_HOUR);
  const days: number = Math.floor(hours / HOURS_PER_DAY);

  if (days > 0) { return `${String(days)}d`; }
  if (hours > 0) { return `${String(hours)}h`; }
  if (minutes > 0) { return `${String(minutes)}m`; }
  return 'now';
}
