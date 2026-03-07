// TreeDataProvider for file locks view.

import * as vscode from 'vscode';
import { selectActiveLocks, selectExpiredLocks } from 'state/selectors';
import type { StoreManager } from 'services/storeManager';
import type { FileLock } from 'state/types';
import { LockTreeItem } from 'ui/tree/lockTreeItem';

// eslint-disable-next-line @typescript-eslint/no-inferrable-types
const MS_PER_SECOND: number = 1000;

export class LocksTreeProvider implements vscode.TreeDataProvider<LockTreeItem> {
  private readonly changeEmitter: vscode.EventEmitter<LockTreeItem | null> =
    new vscode.EventEmitter<LockTreeItem | null>();

  public readonly onDidChangeTreeData: vscode.Event<LockTreeItem | null> =
    this.changeEmitter.event;

  private readonly unsubscribe: () => void;

  public constructor(private readonly storeManager: Readonly<StoreManager>) {
    this.unsubscribe = storeManager.subscribe((): void => {
      this.changeEmitter.fire(null);
    });
  }

  // eslint-disable-next-line class-methods-use-this, @typescript-eslint/prefer-readonly-parameter-types
  public getTreeItem(element: LockTreeItem): vscode.TreeItem {
    return element;
  }

  // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
  public getChildren(element?: LockTreeItem): LockTreeItem[] {
    if (typeof element === 'undefined') {
      return this.getRootItems();
    }

    if (element.isCategory) {
      return this.getCategoryChildren(element);
    }

    return [];
  }

  private getRootItems(): LockTreeItem[] {
    const { state }: Readonly<StoreManager> = this.storeManager;
    const active: readonly FileLock[] = selectActiveLocks(state);
    const expired: readonly FileLock[] = selectExpiredLocks(state);
    const items: LockTreeItem[] = [];

    if (active.length > 0) {
      const item: LockTreeItem = new LockTreeItem({
        collapsibleState: vscode.TreeItemCollapsibleState.Expanded,
        isCategory: true,
        label: `Active (${String(active.length)})`,
        lock: null,
      });
      item.iconPath = new vscode.ThemeIcon('folder');
      item.contextValue = 'category';
      items.push(item);
    }

    if (expired.length > 0) {
      const item: LockTreeItem = new LockTreeItem({
        collapsibleState: vscode.TreeItemCollapsibleState.Collapsed,
        isCategory: true,
        label: `Expired (${String(expired.length)})`,
        lock: null,
      });
      item.iconPath = new vscode.ThemeIcon('folder');
      item.contextValue = 'category';
      items.push(item);
    }

    if (items.length === 0) {
      items.push(new LockTreeItem({
        collapsibleState: vscode.TreeItemCollapsibleState.None,
        isCategory: false,
        label: 'No locks',
        lock: null,
      }));
    }

    return items;
  }

  // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
  private getCategoryChildren(element: LockTreeItem): LockTreeItem[] {
    // eslint-disable-next-line prefer-destructuring
    const rawLabel: vscode.TreeItemLabel | string | undefined = element.label;
    let label: string = '';
    if (typeof rawLabel === 'string') {
      label = rawLabel;
    }
    const isActive: boolean = label.startsWith('Active');
    const { state }: Readonly<StoreManager> = this.storeManager;
    let lockList: readonly FileLock[];
    if (isActive) {
      lockList = selectActiveLocks(state);
    } else {
      lockList = selectExpiredLocks(state);
    }
    const now: number = Date.now();

    return lockList.map((lock: Readonly<FileLock>): LockTreeItem => {
      return createLockItem(lock, now);
    });
  }

  public dispose(): void {
    this.unsubscribe();
    this.changeEmitter.dispose();
  }
}

function createLockItem(lock: Readonly<FileLock>, now: number): LockTreeItem {
  const expiresIn: number = Math.max(0, Math.round((lock.expiresAt - now) / MS_PER_SECOND));
  const expired: boolean = lock.expiresAt <= now;
  let desc: string;
  if (expired) {
    desc = `${lock.agentName} - EXPIRED`;
  } else {
    desc = `${lock.agentName} - ${String(expiresIn)}s`;
  }

  const item: LockTreeItem = new LockTreeItem({
    collapsibleState: vscode.TreeItemCollapsibleState.None,
    isCategory: false,
    label: lock.filePath,
    lock,
  });
  item.description = desc;
  item.contextValue = 'lock';
  item.tooltip = createLockTooltip(lock);
  item.command = {
    arguments: [vscode.Uri.file(lock.filePath)],
    command: 'vscode.open',
    title: 'Open File',
  };

  if (expired) {
    item.iconPath = new vscode.ThemeIcon('warning', new vscode.ThemeColor('errorForeground'));
  } else {
    item.iconPath = new vscode.ThemeIcon('lock');
  }

  return item;
}

function createLockTooltip(lock: Readonly<FileLock>): vscode.MarkdownString {
  const expired: boolean = lock.expiresAt <= Date.now();
  const md: vscode.MarkdownString = new vscode.MarkdownString();
  md.appendMarkdown(`**${lock.filePath}**\n\n`);
  md.appendMarkdown(`- **Agent:** ${lock.agentName}\n`);
  if (expired) {
    md.appendMarkdown('- **Status:** **EXPIRED**\n');
  } else {
    md.appendMarkdown('- **Status:** Active\n');
    const expiresIn: number = Math.round((lock.expiresAt - Date.now()) / MS_PER_SECOND);
    md.appendMarkdown(`- **Expires in:** ${String(expiresIn)}s\n`);
  }
  if (lock.reason !== null) {
    md.appendMarkdown(`- **Reason:** ${lock.reason}\n`);
  }
  return md;
}