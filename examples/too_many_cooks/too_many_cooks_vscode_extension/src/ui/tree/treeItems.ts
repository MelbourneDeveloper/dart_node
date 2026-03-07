// Tree item subclasses with typed properties (no Reflect.get/set hacks).

import * as vscode from 'vscode';
import { FileLock, Message } from '../../state/types';

// Agent tree item type enum for context menu targeting.
export type AgentTreeItemType = 'agent' | 'lock' | 'plan' | 'messageSummary';

export class AgentTreeItem extends vscode.TreeItem {
  constructor(
    label: string,
    collapsibleState: vscode.TreeItemCollapsibleState,
    public readonly itemType: AgentTreeItemType,
    public readonly agentName?: string,
    public readonly filePath?: string,
  ) {
    super(label, collapsibleState);
  }
}

export class LockTreeItem extends vscode.TreeItem {
  constructor(
    label: string,
    collapsibleState: vscode.TreeItemCollapsibleState,
    public readonly isCategory: boolean,
    public readonly lock?: FileLock,
  ) {
    super(label, collapsibleState);
  }
}

export class MessageTreeItem extends vscode.TreeItem {
  constructor(
    label: string,
    collapsibleState: vscode.TreeItemCollapsibleState,
    public readonly message?: Message,
  ) {
    super(label, collapsibleState);
  }
}
