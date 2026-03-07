// Status bar item showing agent/lock/message counts.

import * as vscode from 'vscode';
import { StoreManager } from '../services/storeManager';
import {
  selectConnectionStatus, selectAgentCount,
  selectLockCount, selectUnreadMessageCount,
} from '../state/selectors';

export class StatusBarManager {
  private readonly statusBarItem: vscode.StatusBarItem;
  private readonly unsubscribe: () => void;

  constructor(storeManager: StoreManager) {
    this.statusBarItem = vscode.window.createStatusBarItem(
      vscode.StatusBarAlignment.Left, 100
    );
    this.statusBarItem.command = 'tooManyCooks.showDashboard';

    this.unsubscribe = storeManager.subscribe(() => this.update(storeManager));
    this.update(storeManager);
    this.statusBarItem.show();
  }

  private update(storeManager: StoreManager): void {
    const state = storeManager.state;
    const status = selectConnectionStatus(state);
    const agents = selectAgentCount(state);
    const locks = selectLockCount(state);
    const unread = selectUnreadMessageCount(state);

    switch (status) {
      case 'disconnected':
        this.statusBarItem.text = '$(debug-disconnect) Too Many Cooks';
        this.statusBarItem.tooltip = 'Click to connect';
        this.statusBarItem.backgroundColor = new vscode.ThemeColor('statusBarItem.errorBackground');
        break;
      case 'connecting':
        this.statusBarItem.text = '$(sync~spin) Connecting...';
        this.statusBarItem.tooltip = 'Connecting to Too Many Cooks server';
        this.statusBarItem.backgroundColor = undefined;
        break;
      case 'connected':
        this.statusBarItem.text = `$(person) ${agents}  $(lock) ${locks}  $(mail) ${unread}`;
        this.statusBarItem.tooltip = [
          `${agents} agent${agents !== 1 ? 's' : ''}`,
          `${locks} lock${locks !== 1 ? 's' : ''}`,
          `${unread} unread message${unread !== 1 ? 's' : ''}`,
          '',
          'Click to open dashboard',
        ].join('\n');
        this.statusBarItem.backgroundColor = undefined;
        break;
    }
  }

  dispose(): void {
    this.unsubscribe();
    this.statusBarItem.dispose();
  }
}
