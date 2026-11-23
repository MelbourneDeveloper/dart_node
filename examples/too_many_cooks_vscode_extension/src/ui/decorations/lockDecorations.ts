/**
 * FileDecorationProvider for lock badges on files.
 */

import * as vscode from 'vscode';
import { effect } from '@preact/signals-core';
import { locksByFile } from '../../state/signals';

export class LockDecorationProvider implements vscode.FileDecorationProvider {
  private _onDidChangeFileDecorations = new vscode.EventEmitter<
    vscode.Uri | vscode.Uri[] | undefined
  >();
  readonly onDidChangeFileDecorations = this._onDidChangeFileDecorations.event;
  private disposeEffect: (() => void) | null = null;

  constructor() {
    this.disposeEffect = effect(() => {
      locksByFile.value; // Subscribe
      this._onDidChangeFileDecorations.fire(undefined);
    });
  }

  dispose(): void {
    this.disposeEffect?.();
    this._onDidChangeFileDecorations.dispose();
  }

  provideFileDecoration(
    uri: vscode.Uri
  ): vscode.FileDecoration | undefined {
    const locksMap = locksByFile.value;
    const filePath = uri.fsPath;

    // Check if this file has a lock
    const lock = locksMap.get(filePath);
    if (!lock) {
      return undefined;
    }

    const now = Date.now();
    const isExpired = lock.expiresAt < now;

    if (isExpired) {
      return {
        badge: '!',
        color: new vscode.ThemeColor('charts.red'),
        tooltip: `Expired lock (was held by ${lock.agentName})`,
      };
    }

    return {
      badge: 'L',
      color: new vscode.ThemeColor('charts.yellow'),
      tooltip: `Locked by ${lock.agentName}${lock.reason ? `: ${lock.reason}` : ''}`,
    };
  }
}
