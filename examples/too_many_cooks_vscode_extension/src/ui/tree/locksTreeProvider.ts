/**
 * TreeDataProvider for file locks view.
 */

import * as vscode from 'vscode';
import { effect } from '@preact/signals-core';
import { locks, activeLocks, expiredLocks } from '../../state/signals';
import type { FileLock } from '../../mcp/types';

export class LockTreeItem extends vscode.TreeItem {
  constructor(
    label: string,
    description: string | undefined,
    collapsibleState: vscode.TreeItemCollapsibleState,
    public readonly isCategory: boolean,
    public readonly lock?: FileLock
  ) {
    super(label, collapsibleState);
    this.description = description;
    this.iconPath = this.getIcon();
    this.contextValue = lock ? 'lock' : (isCategory ? 'category' : undefined);

    if (lock) {
      this.tooltip = this.createTooltip(lock);
      this.command = {
        command: 'vscode.open',
        title: 'Open File',
        arguments: [vscode.Uri.file(lock.filePath)],
      };
    }
  }

  private getIcon(): vscode.ThemeIcon {
    if (this.isCategory) {
      return new vscode.ThemeIcon('folder');
    }
    if (this.lock && this.lock.expiresAt <= Date.now()) {
      return new vscode.ThemeIcon(
        'warning',
        new vscode.ThemeColor('errorForeground')
      );
    }
    return new vscode.ThemeIcon('lock');
  }

  private createTooltip(lock: FileLock): vscode.MarkdownString {
    const expired = lock.expiresAt <= Date.now();
    const md = new vscode.MarkdownString();
    md.appendMarkdown(`**${lock.filePath}**\n\n`);
    md.appendMarkdown(`- **Agent:** ${lock.agentName}\n`);
    md.appendMarkdown(
      `- **Status:** ${expired ? '**EXPIRED**' : 'Active'}\n`
    );
    if (!expired) {
      const expiresIn = Math.round((lock.expiresAt - Date.now()) / 1000);
      md.appendMarkdown(`- **Expires in:** ${expiresIn}s\n`);
    }
    if (lock.reason) {
      md.appendMarkdown(`- **Reason:** ${lock.reason}\n`);
    }
    return md;
  }
}

export class LocksTreeProvider
  implements vscode.TreeDataProvider<LockTreeItem>
{
  private _onDidChangeTreeData = new vscode.EventEmitter<
    LockTreeItem | undefined
  >();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;
  private disposeEffect: (() => void) | null = null;

  constructor() {
    this.disposeEffect = effect(() => {
      locks.value; // Subscribe
      this._onDidChangeTreeData.fire(undefined);
    });
  }

  dispose(): void {
    this.disposeEffect?.();
    this._onDidChangeTreeData.dispose();
  }

  getTreeItem(element: LockTreeItem): vscode.TreeItem {
    return element;
  }

  getChildren(element?: LockTreeItem): LockTreeItem[] {
    if (!element) {
      // Root: show categories
      const items: LockTreeItem[] = [];

      const active = activeLocks.value;
      const expired = expiredLocks.value;

      if (active.length > 0) {
        items.push(
          new LockTreeItem(
            `Active (${active.length})`,
            undefined,
            vscode.TreeItemCollapsibleState.Expanded,
            true
          )
        );
      }

      if (expired.length > 0) {
        items.push(
          new LockTreeItem(
            `Expired (${expired.length})`,
            undefined,
            vscode.TreeItemCollapsibleState.Collapsed,
            true
          )
        );
      }

      if (items.length === 0) {
        items.push(
          new LockTreeItem(
            'No locks',
            undefined,
            vscode.TreeItemCollapsibleState.None,
            false
          )
        );
      }

      return items;
    }

    // Children based on category
    if (element.isCategory) {
      const isActive = element.label?.toString().startsWith('Active');
      const lockList = isActive ? activeLocks.value : expiredLocks.value;

      return lockList.map((lock) => {
        const expiresIn = Math.max(
          0,
          Math.round((lock.expiresAt - Date.now()) / 1000)
        );
        const expired = lock.expiresAt <= Date.now();

        return new LockTreeItem(
          lock.filePath,
          expired ? `${lock.agentName} - EXPIRED` : `${lock.agentName} - ${expiresIn}s`,
          vscode.TreeItemCollapsibleState.None,
          false,
          lock
        );
      });
    }

    return [];
  }
}
