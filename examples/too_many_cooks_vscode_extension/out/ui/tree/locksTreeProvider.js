"use strict";
/**
 * TreeDataProvider for file locks view.
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
exports.LocksTreeProvider = exports.LockTreeItem = void 0;
const vscode = __importStar(require("vscode"));
const signals_core_1 = require("@preact/signals-core");
const signals_1 = require("../../state/signals");
class LockTreeItem extends vscode.TreeItem {
    isCategory;
    lock;
    constructor(label, description, collapsibleState, isCategory, lock) {
        super(label, collapsibleState);
        this.isCategory = isCategory;
        this.lock = lock;
        this.description = description;
        this.iconPath = this.getIcon();
        if (lock) {
            this.tooltip = this.createTooltip(lock);
            this.command = {
                command: 'vscode.open',
                title: 'Open File',
                arguments: [vscode.Uri.file(lock.filePath)],
            };
        }
    }
    getIcon() {
        if (this.isCategory) {
            return new vscode.ThemeIcon('folder');
        }
        if (this.lock && this.lock.expiresAt <= Date.now()) {
            return new vscode.ThemeIcon('warning', new vscode.ThemeColor('errorForeground'));
        }
        return new vscode.ThemeIcon('lock');
    }
    createTooltip(lock) {
        const expired = lock.expiresAt <= Date.now();
        const md = new vscode.MarkdownString();
        md.appendMarkdown(`**${lock.filePath}**\n\n`);
        md.appendMarkdown(`- **Agent:** ${lock.agentName}\n`);
        md.appendMarkdown(`- **Status:** ${expired ? '**EXPIRED**' : 'Active'}\n`);
        if (!expired) {
            const expiresIn = Math.round((lock.expiresAt - Date.now()) / 1000);
            md.appendMarkdown(`- **Expires in:** ${expiresIn}s\n`);
        }
        if (lock.reason) {
            md.appendMarkdown(`- **Reason:** ${lock.reason}\n`);
        }
        return md;
    }
}
exports.LockTreeItem = LockTreeItem;
class LocksTreeProvider {
    _onDidChangeTreeData = new vscode.EventEmitter();
    onDidChangeTreeData = this._onDidChangeTreeData.event;
    disposeEffect = null;
    constructor() {
        this.disposeEffect = (0, signals_core_1.effect)(() => {
            signals_1.locks.value; // Subscribe
            this._onDidChangeTreeData.fire(undefined);
        });
    }
    dispose() {
        this.disposeEffect?.();
        this._onDidChangeTreeData.dispose();
    }
    getTreeItem(element) {
        return element;
    }
    getChildren(element) {
        if (!element) {
            // Root: show categories
            const items = [];
            const active = signals_1.activeLocks.value;
            const expired = signals_1.expiredLocks.value;
            if (active.length > 0) {
                items.push(new LockTreeItem(`Active (${active.length})`, undefined, vscode.TreeItemCollapsibleState.Expanded, true));
            }
            if (expired.length > 0) {
                items.push(new LockTreeItem(`Expired (${expired.length})`, undefined, vscode.TreeItemCollapsibleState.Collapsed, true));
            }
            if (items.length === 0) {
                items.push(new LockTreeItem('No locks', undefined, vscode.TreeItemCollapsibleState.None, false));
            }
            return items;
        }
        // Children based on category
        if (element.isCategory) {
            const isActive = element.label?.toString().startsWith('Active');
            const lockList = isActive ? signals_1.activeLocks.value : signals_1.expiredLocks.value;
            return lockList.map((lock) => {
                const expiresIn = Math.max(0, Math.round((lock.expiresAt - Date.now()) / 1000));
                const expired = lock.expiresAt <= Date.now();
                return new LockTreeItem(lock.filePath, expired ? `${lock.agentName} - EXPIRED` : `${lock.agentName} - ${expiresIn}s`, vscode.TreeItemCollapsibleState.None, false, lock);
            });
        }
        return [];
    }
}
exports.LocksTreeProvider = LocksTreeProvider;
//# sourceMappingURL=locksTreeProvider.js.map