// TreeDataProvider for file locks view.

import * as vscode from 'vscode';
import { StoreManager } from '../../services/storeManager';
import { FileLock } from '../../state/types';
import { selectActiveLocks, selectExpiredLocks } from '../../state/selectors';
import { LockTreeItem } from './treeItems';

export class LocksTreeProvider implements vscode.TreeDataProvider<LockTreeItem> {
  private readonly _onDidChangeTreeData = new vscode.EventEmitter<LockTreeItem | undefined>();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;
  private readonly unsubscribe: () => void;

  constructor(private readonly storeManager: StoreManager) {
    this.unsubscribe = storeManager.subscribe(() => {
      this._onDidChangeTreeData.fire(undefined);
    });
  }

  getTreeItem(element: LockTreeItem): vscode.TreeItem {
    return element;
  }

  getChildren(element?: LockTreeItem): LockTreeItem[] {
    const state = this.storeManager.state;

    if (!element) {
      const items: LockTreeItem[] = [];
      const active = selectActiveLocks(state);
      const expired = selectExpiredLocks(state);

      if (active.length > 0) {
        const item = new LockTreeItem(
          `Active (${active.length})`,
          vscode.TreeItemCollapsibleState.Expanded,
          true,
        );
        item.iconPath = new vscode.ThemeIcon('folder');
        item.contextValue = 'category';
        items.push(item);
      }

      if (expired.length > 0) {
        const item = new LockTreeItem(
          `Expired (${expired.length})`,
          vscode.TreeItemCollapsibleState.Collapsed,
          true,
        );
        item.iconPath = new vscode.ThemeIcon('folder');
        item.contextValue = 'category';
        items.push(item);
      }

      if (items.length === 0) {
        const item = new LockTreeItem(
          'No locks',
          vscode.TreeItemCollapsibleState.None,
          false,
        );
        items.push(item);
      }

      return items;
    }

    // Children based on category
    if (element.isCategory) {
      const label = typeof element.label === 'string' ? element.label : '';
      const isActive = label.startsWith('Active');
      const currentState = this.storeManager.state;
      const lockList = isActive
        ? selectActiveLocks(currentState)
        : selectExpiredLocks(currentState);
      const now = Date.now();

      return lockList.map(lock => this.createLockItem(lock, now));
    }

    return [];
  }

  private createLockItem(lock: FileLock, now: number): LockTreeItem {
    const expiresIn = Math.max(0, Math.round((lock.expiresAt - now) / 1000));
    const expired = lock.expiresAt <= now;
    const desc = expired
      ? `${lock.agentName} - EXPIRED`
      : `${lock.agentName} - ${expiresIn}s`;

    const item = new LockTreeItem(
      lock.filePath,
      vscode.TreeItemCollapsibleState.None,
      false,
      lock,
    );
    item.description = desc;
    item.contextValue = 'lock';
    item.tooltip = this.createLockTooltip(lock);
    item.command = {
      command: 'vscode.open',
      title: 'Open File',
      arguments: [vscode.Uri.file(lock.filePath)],
    };

    if (expired) {
      item.iconPath = new vscode.ThemeIcon('warning', new vscode.ThemeColor('errorForeground'));
    } else {
      item.iconPath = new vscode.ThemeIcon('lock');
    }

    return item;
  }

  private createLockTooltip(lock: FileLock): vscode.MarkdownString {
    const expired = lock.expiresAt <= Date.now();
    const md = new vscode.MarkdownString();
    md.appendMarkdown(`**${lock.filePath}**\n\n`);
    md.appendMarkdown(`- **Agent:** ${lock.agentName}\n`);
    md.appendMarkdown(`- **Status:** ${expired ? '**EXPIRED**' : 'Active'}\n`);
    if (!expired) {
      const expiresIn = Math.round((lock.expiresAt - Date.now()) / 1000);
      md.appendMarkdown(`- **Expires in:** ${expiresIn}s\n`);
    }
    if (lock.reason) {
      md.appendMarkdown(`- **Reason:** ${lock.reason}\n`);
    }
    return md;
  }

  dispose(): void {
    this.unsubscribe();
    this._onDidChangeTreeData.dispose();
  }
}
