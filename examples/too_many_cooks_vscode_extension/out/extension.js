"use strict";
/**
 * Too Many Cooks VSCode Extension
 *
 * Visualizes the Too Many Cooks multi-agent coordination system.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = activate;
exports.deactivate = deactivate;
const vscode = __importStar(require("vscode"));
const store_1 = require("./state/store");
const agentsTreeProvider_1 = require("./ui/tree/agentsTreeProvider");
const locksTreeProvider_1 = require("./ui/tree/locksTreeProvider");
const messagesTreeProvider_1 = require("./ui/tree/messagesTreeProvider");
const plansTreeProvider_1 = require("./ui/tree/plansTreeProvider");
const lockDecorations_1 = require("./ui/decorations/lockDecorations");
const statusBarItem_1 = require("./ui/statusBar/statusBarItem");
const dashboardPanel_1 = require("./ui/webview/dashboardPanel");
const test_api_1 = require("./test-api");
let store;
let statusBar;
let agentsProvider;
let locksProvider;
let messagesProvider;
let plansProvider;
let lockDecorations;
let outputChannel;
function log(message) {
    const timestamp = new Date().toISOString();
    const fullMessage = `[${timestamp}] ${message}`;
    outputChannel?.appendLine(fullMessage);
    // Also store for test verification
    (0, test_api_1.addLogMessage)(fullMessage);
}
async function activate(context) {
    // Create output channel for logging - show it immediately so user can see logs
    outputChannel = vscode.window.createOutputChannel('Too Many Cooks');
    outputChannel.show(true); // Show but don't take focus
    // Expose globally for Store to use
    globalThis._tooManyCooksOutput = outputChannel;
    log('Extension activating...');
    const config = vscode.workspace.getConfiguration('tooManyCooks');
    let serverPath = config.get('serverPath', '');
    // Auto-detect server path if not configured
    if (!serverPath) {
        const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
        if (workspaceFolder) {
            // Try common locations relative to workspace
            const candidates = [
                'examples/too_many_cooks/build/bin/server_node.js',
                'too_many_cooks/build/bin/server_node.js',
                'build/bin/server_node.js',
            ];
            const fs = require('fs');
            const path = require('path');
            for (const candidate of candidates) {
                const fullPath = path.join(workspaceFolder.uri.fsPath, candidate);
                if (fs.existsSync(fullPath)) {
                    serverPath = fullPath;
                    log(`Auto-detected server at: ${serverPath}`);
                    break;
                }
            }
        }
    }
    if (!serverPath) {
        log('WARNING: No server path configured and auto-detect failed');
        vscode.window.showWarningMessage('Too Many Cooks: Set tooManyCooks.serverPath in settings');
    }
    log(`Server path: ${serverPath}`);
    // Initialize store
    store = new store_1.Store(serverPath);
    // Create tree providers
    agentsProvider = new agentsTreeProvider_1.AgentsTreeProvider();
    locksProvider = new locksTreeProvider_1.LocksTreeProvider();
    messagesProvider = new messagesTreeProvider_1.MessagesTreeProvider();
    plansProvider = new plansTreeProvider_1.PlansTreeProvider();
    // Register tree views
    const agentsView = vscode.window.createTreeView('tooManyCooksAgents', {
        treeDataProvider: agentsProvider,
        showCollapseAll: true,
    });
    const locksView = vscode.window.createTreeView('tooManyCooksLocks', {
        treeDataProvider: locksProvider,
    });
    const messagesView = vscode.window.createTreeView('tooManyCooksMessages', {
        treeDataProvider: messagesProvider,
    });
    const plansView = vscode.window.createTreeView('tooManyCooksPlans', {
        treeDataProvider: plansProvider,
        showCollapseAll: true,
    });
    // Create file decoration provider
    lockDecorations = new lockDecorations_1.LockDecorationProvider();
    const decorationDisposable = vscode.window.registerFileDecorationProvider(lockDecorations);
    // Create status bar
    statusBar = new statusBarItem_1.StatusBarManager();
    // Register commands
    const connectCmd = vscode.commands.registerCommand('tooManyCooks.connect', async () => {
        log('Connect command triggered');
        try {
            await store?.connect();
            log('Connected successfully');
            vscode.window.showInformationMessage('Connected to Too Many Cooks server');
        }
        catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            log(`Connection failed: ${msg}`);
            vscode.window.showErrorMessage(`Failed to connect: ${msg}`);
        }
    });
    const disconnectCmd = vscode.commands.registerCommand('tooManyCooks.disconnect', async () => {
        await store?.disconnect();
        vscode.window.showInformationMessage('Disconnected from Too Many Cooks server');
    });
    const refreshCmd = vscode.commands.registerCommand('tooManyCooks.refresh', async () => {
        try {
            await store?.refreshStatus();
        }
        catch (err) {
            vscode.window.showErrorMessage(`Failed to refresh: ${err instanceof Error ? err.message : String(err)}`);
        }
    });
    const dashboardCmd = vscode.commands.registerCommand('tooManyCooks.showDashboard', () => {
        dashboardPanel_1.DashboardPanel.createOrShow(context.extensionUri);
    });
    // Auto-connect on startup if configured (default: true)
    const autoConnect = config.get('autoConnect', true);
    log(`Auto-connect: ${autoConnect}`);
    if (autoConnect) {
        log('Attempting auto-connect...');
        store.connect().then(() => {
            log('Auto-connect successful');
        }).catch((err) => {
            log(`Auto-connect failed: ${err instanceof Error ? err.message : String(err)}`);
            console.error('Auto-connect failed:', err);
        });
    }
    // Watch for config changes
    const configListener = vscode.workspace.onDidChangeConfiguration((e) => {
        if (e.affectsConfiguration('tooManyCooks.serverPath')) {
            const newPath = vscode.workspace
                .getConfiguration('tooManyCooks')
                .get('serverPath', 'dart run too_many_cooks');
            store?.setServerPath(newPath);
        }
    });
    log('Extension activated');
    // Register disposables
    context.subscriptions.push(outputChannel, agentsView, locksView, messagesView, plansView, decorationDisposable, connectCmd, disconnectCmd, refreshCmd, dashboardCmd, configListener, {
        dispose: () => {
            store?.disconnect();
            statusBar?.dispose();
            agentsProvider?.dispose();
            locksProvider?.dispose();
            messagesProvider?.dispose();
            plansProvider?.dispose();
            lockDecorations?.dispose();
        },
    });
    // Return test API for integration tests
    return (0, test_api_1.createTestAPI)(store, {
        agents: agentsProvider,
        locks: locksProvider,
        messages: messagesProvider,
        plans: plansProvider,
    });
}
function deactivate() {
    // Cleanup handled by disposables
}
//# sourceMappingURL=extension.js.map