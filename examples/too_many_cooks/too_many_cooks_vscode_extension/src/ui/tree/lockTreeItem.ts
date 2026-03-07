// Lock tree item with typed properties.

import * as vscode from 'vscode';
import type { FileLock } from 'state/types';

export interface LockTreeItemConfig {
  readonly collapsibleState: vscode.TreeItemCollapsibleState;
  readonly isCategory: boolean;
  readonly label: string;
  readonly lock: FileLock | null;
}

export class LockTreeItem extends vscode.TreeItem {
  public readonly isCategory: boolean;
  public readonly lock: FileLock | null;

  public constructor(config: Readonly<LockTreeItemConfig>) {
    super(config.label, config.collapsibleState);
    this.isCategory = config.isCategory;
    this.lock = config.lock;
  }
}
