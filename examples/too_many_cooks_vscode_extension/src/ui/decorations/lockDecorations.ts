/**
 * FileDecorationProvider for lock badges on files.
 */

import * as vscode from 'vscode';
import { effect } from '@preact/signals-core';
import { locksByFile } from '../../state/signals';
import type { FileLock } from '../../mcp/types';

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

  private createLockTooltip(lock: FileLock, expired: boolean): string {
    const lines: string[] = [];

    if (expired) {
      lines.push(`⚠️ EXPIRED LOCK`);
      lines.push(`Was held by: ${lock.agentName}`);
    } else {
      lines.push(`🔒 Locked by ${lock.agentName}`);
      const expiresIn = Math.round((lock.expiresAt - Date.now()) / 1000);
      lines.push(`Expires in: ${expiresIn}s`);
    }

    if (lock.reason) {
      lines.push(`Reason: ${lock.reason}`);
    }

    const acquiredDate = new Date(lock.acquiredAt);
    lines.push(`Acquired: ${acquiredDate.toLocaleString()}`);

    return lines.join('\n');
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
        badge: '⚠️',
        color: new vscode.ThemeColor('charts.red'),
        tooltip: this.createLockTooltip(lock, true),
      };
    }

    // Show agent name initials (up to 2 chars) as badge
    const badge = lock.agentName.substring(0, 2).toUpperCase();
    return {
      badge,
      color: new vscode.ThemeColor('charts.yellow'),
      tooltip: this.createLockTooltip(lock, false),
    };
  }
}
