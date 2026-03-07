// Message tree item with typed properties.

import * as vscode from 'vscode';
import type { Message } from 'state/types';

export class MessageTreeItem extends vscode.TreeItem {
  public readonly message: Message | null;

  public constructor(
    label: string,
    collapsibleState: vscode.TreeItemCollapsibleState,
    message: Readonly<Message> | null,
  ) {
    super(label, collapsibleState);
    this.message = message;
  }
}
