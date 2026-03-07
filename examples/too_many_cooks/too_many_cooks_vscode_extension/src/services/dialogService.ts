// Dialog service - abstraction over vscode.window dialogs for testability.

import * as vscode from 'vscode';

export interface DialogService {
  showErrorMessage(message: string): Thenable<string | undefined>;
  showInformationMessage(message: string): Thenable<string | undefined>;
  showInputBox(options: vscode.InputBoxOptions): Thenable<string | undefined>;
  showQuickPick(items: string[], options: vscode.QuickPickOptions): Thenable<string | undefined>;
  showWarningMessage(message: string, options: vscode.MessageOptions, ...items: string[]): Thenable<string | undefined>;
}

function createDefaultDialogService(): DialogService {
  return {
    showErrorMessage: (message: string): Thenable<string | undefined> => {
      return vscode.window.showErrorMessage(message);
    },
    showInformationMessage: (message: string): Thenable<string | undefined> => {
      return vscode.window.showInformationMessage(message);
    },
    showInputBox: (options: vscode.InputBoxOptions): Thenable<string | undefined> => {
      return vscode.window.showInputBox(options);
    },
    showQuickPick: (items: string[], options: vscode.QuickPickOptions): Thenable<string | undefined> => {
      return vscode.window.showQuickPick(items, options);
    },
    showWarningMessage: (message: string, options: vscode.MessageOptions, ...items: string[]): Thenable<string | undefined> => {
      return vscode.window.showWarningMessage(message, options, ...items);
    },
  };
}

let activeDialogService: DialogService = createDefaultDialogService();

export function getDialogService(): DialogService {
  return activeDialogService;
}

export function setDialogService(service: DialogService): void {
  activeDialogService = service;
}

export function resetDialogService(): void {
  activeDialogService = createDefaultDialogService();
}
