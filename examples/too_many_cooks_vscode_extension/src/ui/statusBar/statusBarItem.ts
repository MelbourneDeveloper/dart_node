/**
 * Status bar item showing agent/lock/message counts.
 */

import * as vscode from 'vscode';
import { effect } from '@preact/signals-core';
import {
  agentCount,
  lockCount,
  unreadMessageCount,
  connectionStatus,
} from '../../state/signals';

export class StatusBarManager {
  private statusBarItem: vscode.StatusBarItem;
  private disposeEffect: (() => void) | null = null;

  constructor() {
    this.statusBarItem = vscode.window.createStatusBarItem(
      vscode.StatusBarAlignment.Left,
      100
    );
    this.statusBarItem.command = 'tooManyCooks.showDashboard';

    this.disposeEffect = effect(() => {
      this.update();
    });

    this.statusBarItem.show();
  }

  private update(): void {
    const status = connectionStatus.value;
    const agents = agentCount.value;
    const locks = lockCount.value;
    const unread = unreadMessageCount.value;

    if (status === 'disconnected') {
      this.statusBarItem.text = '$(debug-disconnect) Too Many Cooks';
      this.statusBarItem.tooltip = 'Click to connect';
      this.statusBarItem.backgroundColor = new vscode.ThemeColor(
        'statusBarItem.errorBackground'
      );
      return;
    }

    if (status === 'connecting') {
      this.statusBarItem.text = '$(sync~spin) Connecting...';
      this.statusBarItem.tooltip = 'Connecting to Too Many Cooks server';
      this.statusBarItem.backgroundColor = undefined;
      return;
    }

    // Connected
    const parts = [
      `$(person) ${agents}`,
      `$(lock) ${locks}`,
      `$(mail) ${unread}`,
    ];
    this.statusBarItem.text = parts.join('  ');
    this.statusBarItem.tooltip = [
      `${agents} agent${agents !== 1 ? 's' : ''}`,
      `${locks} lock${locks !== 1 ? 's' : ''}`,
      `${unread} unread message${unread !== 1 ? 's' : ''}`,
      '',
      'Click to open dashboard',
    ].join('\n');
    this.statusBarItem.backgroundColor = undefined;
  }

  dispose(): void {
    this.disposeEffect?.();
    this.statusBarItem.dispose();
  }
}
