// Status bar item showing agent/lock/message counts.

import * as vscode from 'vscode';
import type { AppState, ConnectionStatus } from 'state/types';
import { selectAgentCount, selectConnectionStatus, selectLockCount, selectUnreadMessageCount } from 'state/selectors';
import type { StoreManager } from 'services/storeManager';

function pluralSuffix(count: number): string {
  if (count === 1) {
    return '';
  }
  return 's';
}

export class StatusBarManager {
  private readonly statusBarItem: vscode.StatusBarItem;
  private readonly unsubscribe: () => void;

  public constructor(storeManager: Readonly<StoreManager>) {
    this.statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left);
    this.statusBarItem.command = 'tooManyCooks.showDashboard';

    this.unsubscribe = storeManager.subscribe((): void => { this.update(storeManager); });
    this.update(storeManager);
    this.statusBarItem.show();
  }

  private update(storeManager: Readonly<StoreManager>): void {
    const { state }: { readonly state: AppState } = storeManager;
    const status: ConnectionStatus = selectConnectionStatus(state);
    const agents: number = selectAgentCount(state);
    const locks: number = selectLockCount(state);
    const unread: number = selectUnreadMessageCount(state);

    let background: vscode.ThemeColor | null = null;

    switch (status) {
      case 'disconnected':
        this.statusBarItem.text = '$(debug-disconnect) Too Many Cooks';
        this.statusBarItem.tooltip = 'Click to connect';
        background = new vscode.ThemeColor('statusBarItem.errorBackground');
        break;
      case 'connecting':
        this.statusBarItem.text = '$(sync~spin) Connecting...';
        this.statusBarItem.tooltip = 'Connecting to Too Many Cooks server';
        break;
      case 'connected':
        this.updateConnected(agents, locks, unread);
        break;
      default:
        break;
    }

    if (background === null) {
      this.statusBarItem.backgroundColor = new vscode.ThemeColor('statusBar.background');
    } else {
      this.statusBarItem.backgroundColor = background;
    }
  }

  private updateConnected(agents: number, locks: number, unread: number): void {
    this.statusBarItem.text =
      `$(person) ${String(agents)}  $(lock) ${String(locks)}  $(mail) ${String(unread)}`;
    this.statusBarItem.tooltip = [
      `${String(agents)} agent${pluralSuffix(agents)}`,
      `${String(locks)} lock${pluralSuffix(locks)}`,
      `${String(unread)} unread message${pluralSuffix(unread)}`,
      '',
      'Click to open dashboard',
    ].join('\n');
  }

  public dispose(): void {
    this.unsubscribe();
    this.statusBarItem.dispose();
  }
}
