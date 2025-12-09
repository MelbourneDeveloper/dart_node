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

    if (message) {
      this.tooltip = this.createTooltip(message);
    }
  }

  private getIcon(): vscode.ThemeIcon {
    if (!this.message) {
      return new vscode.ThemeIcon('mail');
    }
    if (this.message.toAgent === '*') {
      return new vscode.ThemeIcon('broadcast');
    }
    if (this.message.readAt === undefined) {
      return new vscode.ThemeIcon(
        'mail-read',
        new vscode.ThemeColor('charts.yellow')
      );
    }
    return new vscode.ThemeIcon('mail');
  }

  private createTooltip(msg: Message): vscode.MarkdownString {
    const md = new vscode.MarkdownString();
    md.appendMarkdown(`**From:** ${msg.fromAgent}\n\n`);
    md.appendMarkdown(
      `**To:** ${msg.toAgent === '*' ? 'Everyone (broadcast)' : msg.toAgent}\n\n`
    );
    md.appendMarkdown(`**Content:**\n\n${msg.content}\n\n`);
    md.appendMarkdown(
      `**Sent:** ${new Date(msg.createdAt).toLocaleString()}\n`
    );
    if (msg.readAt) {
      md.appendMarkdown(
        `**Read:** ${new Date(msg.readAt).toLocaleString()}\n`
      );
    }
    return md;
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

    return sorted.map((msg) => {
      const isBroadcast = msg.toAgent === '*';
      const target = isBroadcast ? 'all' : msg.toAgent;
      const preview =
        msg.content.length > 30
          ? msg.content.substring(0, 30) + '...'
          : msg.content;

      return new MessageTreeItem(
        `${msg.fromAgent} → ${target}`,
        preview,
        vscode.TreeItemCollapsibleState.None,
        msg
      );
    });
  }
}
