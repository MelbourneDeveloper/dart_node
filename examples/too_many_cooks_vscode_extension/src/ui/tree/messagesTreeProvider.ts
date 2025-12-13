/**
 * TreeDataProvider for messages view.
 */

import * as vscode from 'vscode';
import { effect } from '@preact/signals-core';
import { messages } from '../../state/signals';
import type { Message } from '../../mcp/types';

export class MessageTreeItem extends vscode.TreeItem {
  constructor(
    label: string,
    description: string | undefined,
    collapsibleState: vscode.TreeItemCollapsibleState,
    public readonly message?: Message
  ) {
    super(label, collapsibleState);
    this.description = description;
    this.iconPath = this.getIcon();
    this.contextValue = message ? 'message' : undefined;

    if (message) {
      this.tooltip = this.createTooltip(message);
    }
  }

  private getIcon(): vscode.ThemeIcon | undefined {
    if (!this.message) {
      return new vscode.ThemeIcon('mail');
    }
    // Status icon: unread = yellow circle, read = none
    if (this.message.readAt === undefined) {
      return new vscode.ThemeIcon(
        'circle-filled',
        new vscode.ThemeColor('charts.yellow')
      );
    }
    return undefined;
  }

  private createTooltip(msg: Message): vscode.MarkdownString {
    const md = new vscode.MarkdownString();
    md.isTrusted = true;

    // Header with from/to
    const target = msg.toAgent === '*' ? 'Everyone (broadcast)' : msg.toAgent;
    md.appendMarkdown(`### ${msg.fromAgent} \u2192 ${target}\n\n`);

    // Full message content in a quote block for visibility
    md.appendMarkdown(`> ${msg.content.split('\n').join('\n> ')}\n\n`);

    // Time info with relative time
    const sentDate = new Date(msg.createdAt);
    const relativeTime = this.getRelativeTime(msg.createdAt);
    md.appendMarkdown('---\n\n');
    md.appendMarkdown(`**Sent:** ${sentDate.toLocaleString()} (${relativeTime})\n\n`);

    if (msg.readAt) {
      const readDate = new Date(msg.readAt);
      md.appendMarkdown(`**Read:** ${readDate.toLocaleString()}\n\n`);
    } else {
      md.appendMarkdown('**Status:** Unread\n\n');
    }

    // Message ID for debugging
    md.appendMarkdown(`*ID: ${msg.id}*`);

    return md;
  }

  private getRelativeTime(timestamp: number): string {
    const now = Date.now();
    const diff = now - timestamp;
    const seconds = Math.floor(diff / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) return `${days}d ago`;
    if (hours > 0) return `${hours}h ago`;
    if (minutes > 0) return `${minutes}m ago`;
    return 'just now';
  }
}

export class MessagesTreeProvider
  implements vscode.TreeDataProvider<MessageTreeItem>
{
  private _onDidChangeTreeData = new vscode.EventEmitter<
    MessageTreeItem | undefined
  >();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;
  private disposeEffect: (() => void) | null = null;

  constructor() {
    this.disposeEffect = effect(() => {
      messages.value; // Subscribe
      this._onDidChangeTreeData.fire(undefined);
    });
  }

  dispose(): void {
    this.disposeEffect?.();
    this._onDidChangeTreeData.dispose();
  }

  getTreeItem(element: MessageTreeItem): vscode.TreeItem {
    return element;
  }

  getChildren(element?: MessageTreeItem): MessageTreeItem[] {
    // No children - flat list
    if (element) {
      return [];
    }

    const allMessages = messages.value;

    if (allMessages.length === 0) {
      return [
        new MessageTreeItem(
          'No messages',
          undefined,
          vscode.TreeItemCollapsibleState.None
        ),
      ];
    }

    // Sort by created time, newest first
    const sorted = [...allMessages].sort(
      (a, b) => b.createdAt - a.createdAt
    );

    // Single row per message: "from → to | time | content"
    return sorted.map((msg) => {
      const target = msg.toAgent === '*' ? 'all' : msg.toAgent;
      const relativeTime = this.getRelativeTime(msg.createdAt);
      const status = msg.readAt === undefined ? 'unread' : '';
      const statusPart = status ? ` [${status}]` : '';

      return new MessageTreeItem(
        `${msg.fromAgent} → ${target} | ${relativeTime}${statusPart}`,
        msg.content,
        vscode.TreeItemCollapsibleState.None,
        msg
      );
    });
  }

  private getRelativeTime(timestamp: number): string {
    const now = Date.now();
    const diff = now - timestamp;
    const seconds = Math.floor(diff / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) return `${days}d`;
    if (hours > 0) return `${hours}h`;
    if (minutes > 0) return `${minutes}m`;
    return 'now';
  }
}
