// TreeDataProvider for messages view.

import * as vscode from 'vscode';
import { StoreManager } from '../../services/storeManager';
import { Message } from '../../state/types';
import { selectMessages } from '../../state/selectors';
import { MessageTreeItem } from './treeItems';

export class MessagesTreeProvider implements vscode.TreeDataProvider<MessageTreeItem> {
  private readonly _onDidChangeTreeData = new vscode.EventEmitter<MessageTreeItem | undefined>();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;
  private readonly unsubscribe: () => void;

  constructor(private readonly storeManager: StoreManager) {
    this.unsubscribe = storeManager.subscribe(() => {
      this._onDidChangeTreeData.fire(undefined);
    });
  }

  getTreeItem(element: MessageTreeItem): vscode.TreeItem {
    return element;
  }

  getChildren(element?: MessageTreeItem): MessageTreeItem[] {
    if (element) { return []; }

    const allMessages = selectMessages(this.storeManager.state);

    if (allMessages.length === 0) {
      return [new MessageTreeItem('No messages', vscode.TreeItemCollapsibleState.None)];
    }

    const sorted = [...allMessages].sort((a, b) => b.createdAt - a.createdAt);

    return sorted.map(msg => {
      const target = msg.toAgent === '*' ? 'all' : msg.toAgent;
      const relativeTime = getRelativeTimeShort(msg.createdAt);
      const status = msg.readAt === null ? 'unread' : '';
      const statusPart = status ? ` [${status}]` : '';

      const item = new MessageTreeItem(
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
    });
  }

  dispose(): void {
    this.unsubscribe();
    this._onDidChangeTreeData.dispose();
  }
}

function createTooltip(msg: Message): vscode.MarkdownString {
  const target = msg.toAgent === '*' ? 'Everyone (broadcast)' : msg.toAgent;
  const quotedContent = msg.content.split('\n').join('\n> ');
  const sentDate = new Date(msg.createdAt);
  const relativeTime = getRelativeTime(msg.createdAt);

  const md = new vscode.MarkdownString();
  md.isTrusted = true;
  md.appendMarkdown(`### ${msg.fromAgent} \u2192 ${target}\n\n`);
  md.appendMarkdown(`> ${quotedContent}\n\n`);
  md.appendMarkdown('---\n\n');
  md.appendMarkdown(`**Sent:** ${sentDate} (${relativeTime})\n\n`);

  if (msg.readAt !== null) {
    const readDate = new Date(msg.readAt);
    md.appendMarkdown(`**Read:** ${readDate}\n\n`);
  } else {
    md.appendMarkdown('**Status:** Unread\n\n');
  }

  md.appendMarkdown(`*ID: ${msg.id}*`);
  return md;
}

function getRelativeTime(timestamp: number): string {
  const diff = Date.now() - timestamp;
  const seconds = Math.floor(diff / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);

  if (days > 0) { return `${days}d ago`; }
  if (hours > 0) { return `${hours}h ago`; }
  if (minutes > 0) { return `${minutes}m ago`; }
  return 'just now';
}

function getRelativeTimeShort(timestamp: number): string {
  const diff = Date.now() - timestamp;
  const seconds = Math.floor(diff / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);

  if (days > 0) { return `${days}d`; }
  if (hours > 0) { return `${hours}h`; }
  if (minutes > 0) { return `${minutes}m`; }
  return 'now';
}
