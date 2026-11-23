/**
 * TreeDataProvider for agents view.
 */

import * as vscode from 'vscode';
import { effect } from '@preact/signals-core';
import { agentDetails, type AgentDetails } from '../../state/signals';

type TreeItemType = 'agent' | 'lock' | 'plan' | 'message-summary';

export class AgentTreeItem extends vscode.TreeItem {
  constructor(
    label: string,
    description: string | undefined,
    collapsibleState: vscode.TreeItemCollapsibleState,
    public readonly itemType: TreeItemType,
    public readonly agentName?: string,
    public readonly filePath?: string,
    tooltip?: vscode.MarkdownString
  ) {
    super(label, collapsibleState);
    this.description = description;
    this.iconPath = this.getIcon();
    // Use specific contextValue for context menu targeting
    this.contextValue = itemType === 'agent' ? 'deletableAgent' : itemType;
    if (tooltip) {
      this.tooltip = tooltip;
    }
  }

  private getIcon(): vscode.ThemeIcon {
    switch (this.itemType) {
      case 'agent':
        return new vscode.ThemeIcon('person');
      case 'lock':
        return new vscode.ThemeIcon('lock');
      case 'plan':
        return new vscode.ThemeIcon('target');
      case 'message-summary':
        return new vscode.ThemeIcon('mail');
    }
  }
}

export class AgentsTreeProvider
  implements vscode.TreeDataProvider<AgentTreeItem>
{
  private _onDidChangeTreeData = new vscode.EventEmitter<
    AgentTreeItem | undefined
  >();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;
  private disposeEffect: (() => void) | null = null;

  constructor() {
    // React to signal changes
    this.disposeEffect = effect(() => {
      agentDetails.value; // Subscribe to changes
      this._onDidChangeTreeData.fire(undefined);
    });
  }

  dispose(): void {
    this.disposeEffect?.();
    this._onDidChangeTreeData.dispose();
  }

  getTreeItem(element: AgentTreeItem): vscode.TreeItem {
    return element;
  }

  getChildren(element?: AgentTreeItem): AgentTreeItem[] {
    if (!element) {
      // Root: list all agents
      return agentDetails.value.map((detail) => this.createAgentItem(detail));
    }

    // Children: agent's plan, locks, messages
    if (element.itemType === 'agent' && element.agentName) {
      const detail = agentDetails.value.find(
        (d) => d.agent.agentName === element.agentName
      );
      if (!detail) return [];
      return this.createAgentChildren(detail);
    }

    return [];
  }

  private createAgentItem(detail: AgentDetails): AgentTreeItem {
    const lockCount = detail.locks.length;
    const msgCount =
      detail.sentMessages.length + detail.receivedMessages.length;
    const parts: string[] = [];
    if (lockCount > 0) parts.push(`${lockCount} lock${lockCount > 1 ? 's' : ''}`);
    if (msgCount > 0) parts.push(`${msgCount} msg${msgCount > 1 ? 's' : ''}`);

    return new AgentTreeItem(
      detail.agent.agentName,
      parts.join(', ') || 'idle',
      vscode.TreeItemCollapsibleState.Collapsed,
      'agent',
      detail.agent.agentName,
      undefined,
      this.createAgentTooltip(detail)
    );
  }

  private createAgentTooltip(detail: AgentDetails): vscode.MarkdownString {
    const md = new vscode.MarkdownString();
    const agent = detail.agent;

    md.appendMarkdown(`**Agent:** ${agent.agentName}\n\n`);
    md.appendMarkdown(
      `**Registered:** ${new Date(agent.registeredAt).toLocaleString()}\n\n`
    );
    md.appendMarkdown(
      `**Last Active:** ${new Date(agent.lastActive).toLocaleString()}\n\n`
    );

    if (detail.plan) {
      md.appendMarkdown('---\n\n');
      md.appendMarkdown(`**Goal:** ${detail.plan.goal}\n\n`);
      md.appendMarkdown(`**Current Task:** ${detail.plan.currentTask}\n\n`);
    }

    if (detail.locks.length > 0) {
      md.appendMarkdown('---\n\n');
      md.appendMarkdown(`**Locks (${detail.locks.length}):**\n`);
      for (const lock of detail.locks) {
        const expired = lock.expiresAt <= Date.now();
        const status = expired ? 'EXPIRED' : 'active';
        md.appendMarkdown(`- \`${lock.filePath}\` (${status})\n`);
      }
    }

    const unread = detail.receivedMessages.filter(
      (m) => m.readAt === undefined
    ).length;
    if (detail.sentMessages.length > 0 || detail.receivedMessages.length > 0) {
      md.appendMarkdown('\n---\n\n');
      md.appendMarkdown(
        `**Messages:** ${detail.sentMessages.length} sent, ` +
          `${detail.receivedMessages.length} received` +
          (unread > 0 ? ` **(${unread} unread)**` : '') +
          '\n'
      );
    }

    return md;
  }

  private createAgentChildren(detail: AgentDetails): AgentTreeItem[] {
    const children: AgentTreeItem[] = [];

    // Plan
    if (detail.plan) {
      children.push(
        new AgentTreeItem(
          `Goal: ${detail.plan.goal}`,
          `Task: ${detail.plan.currentTask}`,
          vscode.TreeItemCollapsibleState.None,
          'plan',
          detail.agent.agentName
        )
      );
    }

    // Locks
    for (const lock of detail.locks) {
      const expiresIn = Math.max(
        0,
        Math.round((lock.expiresAt - Date.now()) / 1000)
      );
      const expired = lock.expiresAt <= Date.now();
      children.push(
        new AgentTreeItem(
          lock.filePath,
          expired
            ? 'EXPIRED'
            : `${expiresIn}s${lock.reason ? ` (${lock.reason})` : ''}`,
          vscode.TreeItemCollapsibleState.None,
          'lock',
          detail.agent.agentName,
          lock.filePath
        )
      );
    }

    // Message summary
    const unread = detail.receivedMessages.filter(
      (m) => m.readAt === undefined
    ).length;
    if (detail.sentMessages.length > 0 || detail.receivedMessages.length > 0) {
      children.push(
        new AgentTreeItem(
          'Messages',
          `${detail.sentMessages.length} sent, ${detail.receivedMessages.length} received${unread > 0 ? ` (${unread} unread)` : ''}`,
          vscode.TreeItemCollapsibleState.None,
          'message-summary',
          detail.agent.agentName
        )
      );
    }

    return children;
  }
}
