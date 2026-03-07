// Agent tree item with typed properties.

import * as vscode from 'vscode';

// Agent tree item type enum for context menu targeting.
export type AgentTreeItemType = 'agent' | 'lock' | 'messageSummary' | 'plan';

export interface AgentTreeItemConfig {
  readonly agentName?: string;
  readonly collapsibleState: vscode.TreeItemCollapsibleState;
  readonly filePath?: string;
  readonly itemType: AgentTreeItemType;
  readonly label: string;
}

export class AgentTreeItem extends vscode.TreeItem {
  public readonly agentName?: string | undefined;
  public readonly filePath?: string | undefined;
  public readonly itemType: AgentTreeItemType;

  public constructor(config: Readonly<AgentTreeItemConfig>) {
    super(config.label, config.collapsibleState);
    this.itemType = config.itemType;
    this.agentName = config.agentName;
    this.filePath = config.filePath;
  }
}
