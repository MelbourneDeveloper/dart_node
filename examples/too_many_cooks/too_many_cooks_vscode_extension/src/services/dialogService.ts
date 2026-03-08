// Dialog service - abstraction over vscode.window dialogs for testability.

import * as vscode from 'vscode';

export interface DialogService {
  readonly showErrorMessage: (message: string) => Thenable<string | undefined>;
  readonly showInformationMessage: (message: string) => Thenable<string | undefined>;
  // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
  readonly showInputBox: (options: Readonly<vscode.InputBoxOptions>) => Thenable<string | undefined>;
  // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
  readonly showQuickPick: (items: readonly string[], options: Readonly<vscode.QuickPickOptions>) => Thenable<string | undefined>;
  // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
  readonly showWarningMessage: (message: string, options: Readonly<vscode.MessageOptions>, ...items: string[]) => Thenable<string | undefined>;
}

function createDefaultDialogService(): DialogService {
  return {
    showErrorMessage: (message: string): Thenable<string | undefined> => {
      return vscode.window.showErrorMessage(message);
    },
    showInformationMessage: (message: string): Thenable<string | undefined> => {
      return vscode.window.showInformationMessage(message);
    },
    // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
    showInputBox: (options: Readonly<vscode.InputBoxOptions>): Thenable<string | undefined> => {
      return vscode.window.showInputBox(options);
    },
    showQuickPick: (items: readonly string[], options: Readonly<vscode.QuickPickOptions>): Thenable<string | undefined> => {
      return vscode.window.showQuickPick([...items], options);
    },
    // eslint-disable-next-line @typescript-eslint/prefer-readonly-parameter-types
    showWarningMessage: (message: string, options: Readonly<vscode.MessageOptions>, ...items: string[]): Thenable<string | undefined> => {
      return vscode.window.showWarningMessage(message, options, ...items);
    },
  };
}

let activeDialogService: DialogService = createDefaultDialogService();

export function getDialogService(): DialogService {
  return activeDialogService;
}

export function setDialogService(service: Readonly<DialogService>): void {
  activeDialogService = service;
}

export function resetDialogService(): void {
  activeDialogService = createDefaultDialogService();
}
