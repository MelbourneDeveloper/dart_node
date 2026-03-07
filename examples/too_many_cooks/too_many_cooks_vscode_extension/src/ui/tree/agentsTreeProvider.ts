// TreeDataProvider for agents view.

import * as vscode from 'vscode';
import { StoreManager } from '../../services/storeManager';
import { AgentDetails } from '../../state/types';
import { selectAgentDetails } from '../../state/selectors';
import { AgentTreeItem } from './treeItems';

export class AgentsTreeProvider implements vscode.TreeDataProvider<AgentTreeItem> {
  private readonly _onDidChangeTreeData = new vscode.EventEmitter<AgentTreeItem | undefined>();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;
  private readonly unsubscribe: () => void;

  constructor(private readonly storeManager: StoreManager) {
    this.unsubscribe = storeManager.subscribe(() => {
      this._onDidChangeTreeData.fire(undefined);
    });
  }

  getTreeItem(element: AgentTreeItem): vscode.TreeItem {
    return element;
  }

  getChildren(element?: AgentTreeItem): AgentTreeItem[] {
    const state = this.storeManager.state;
    const details = selectAgentDetails(state);

    if (!element) {
      return details.map(d => this.createAgentItem(d));
    }

    if (element.itemType === 'agent' && element.agentName) {
      const detail = details.find(d => d.agent.agentName === element.agentName);
      return detail ? this.createAgentChildren(detail) : [];
    }

    return [];
  }

  private createAgentItem(detail: AgentDetails): AgentTreeItem {
    const lockCount = detail.locks.length;
    const msgCount = detail.sentMessages.length + detail.receivedMessages.length;
    const parts: string[] = [];
    if (lockCount > 0) { parts.push(`${lockCount} lock${lockCount > 1 ? 's' : ''}`); }
    if (msgCount > 0) { parts.push(`${msgCount} msg${msgCount > 1 ? 's' : ''}`); }

    const item = new AgentTreeItem(
      detail.agent.agentName,
      vscode.TreeItemCollapsibleState.Collapsed,
      'agent',
      detail.agent.agentName,
    );
    item.description = parts.length > 0 ? parts.join(', ') : 'idle';
    item.iconPath = new vscode.ThemeIcon('person');
    item.contextValue = 'deletableAgent';
    item.tooltip = this.createAgentTooltip(detail);
    return item;
  }

  private createAgentTooltip(detail: AgentDetails): vscode.MarkdownString {
    const agent = detail.agent;
    const regDate = new Date(agent.registeredAt);
    const activeDate = new Date(agent.lastActive);

    const md = new vscode.MarkdownString();
    md.appendMarkdown(`**Agent:** ${agent.agentName}\n\n`);
    md.appendMarkdown(`**Registered:** ${regDate}\n\n`);
    md.appendMarkdown(`**Last Active:** ${activeDate}\n\n`);

    if (detail.plan) {
      md.appendMarkdown('---\n\n');
      md.appendMarkdown(`**Goal:** ${detail.plan.goal}\n\n`);
      md.appendMarkdown(`**Current Task:** ${detail.plan.currentTask}\n\n`);
    }

    if (detail.locks.length > 0) {
      md.appendMarkdown('---\n\n');
      md.appendMarkdown(`**Locks (${detail.locks.length}):**\n`);
      const now = Date.now();
      for (const lock of detail.locks) {
        const expired = lock.expiresAt <= now;
        const status = expired ? 'EXPIRED' : 'active';
        md.appendMarkdown(`- \`${lock.filePath}\` (${status})\n`);
      }
    }

    const unread = detail.receivedMessages.filter(m => m.readAt === null).length;
    if (detail.sentMessages.length > 0 || detail.receivedMessages.length > 0) {
      md.appendMarkdown('\n---\n\n');
      md.appendMarkdown(
        `**Messages:** ${detail.sentMessages.length} sent, ` +
        `${detail.receivedMessages.length} received` +
        `${unread > 0 ? ` **(${unread} unread)**` : ''}\n`
      );
    }

    return md;
  }

  private createAgentChildren(detail: AgentDetails): AgentTreeItem[] {
    const children: AgentTreeItem[] = [];
    const now = Date.now();

    // Plan
    if (detail.plan) {
      const item = new AgentTreeItem(
        `Goal: ${detail.plan.goal}`,
        vscode.TreeItemCollapsibleState.None,
        'plan',
        detail.agent.agentName,
      );
      item.description = `Task: ${detail.plan.currentTask}`;
      item.iconPath = new vscode.ThemeIcon('target');
      children.push(item);
    }

    // Locks
    for (const lock of detail.locks) {
      const expiresIn = Math.max(0, Math.round((lock.expiresAt - now) / 1000));
      const expired = lock.expiresAt <= now;
      const reason = lock.reason;
      const item = new AgentTreeItem(
        lock.filePath,
        vscode.TreeItemCollapsibleState.None,
        'lock',
        detail.agent.agentName,
        lock.filePath,
      );
      item.description = expired
        ? 'EXPIRED'
        : `${expiresIn}s${reason ? ` (${reason})` : ''}`;
      item.iconPath = new vscode.ThemeIcon('lock');
      item.contextValue = 'lock';
      children.push(item);
    }

    // Message summary
    const unread = detail.receivedMessages.filter(m => m.readAt === null).length;
    if (detail.sentMessages.length > 0 || detail.receivedMessages.length > 0) {
      const sent = detail.sentMessages.length;
      const recv = detail.receivedMessages.length;
      const unreadStr = unread > 0 ? ` (${unread} unread)` : '';
      const item = new AgentTreeItem(
        'Messages',
        vscode.TreeItemCollapsibleState.None,
        'messageSummary',
        detail.agent.agentName,
      );
      item.description = `${sent} sent, ${recv} received${unreadStr}`;
      item.iconPath = new vscode.ThemeIcon('mail');
      children.push(item);
    }

    return children;
  }

  dispose(): void {
    this.unsubscribe();
    this._onDidChangeTreeData.dispose();
  }
}
