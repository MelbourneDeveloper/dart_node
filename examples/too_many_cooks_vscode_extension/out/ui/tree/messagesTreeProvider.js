"use strict";
/**
 * TreeDataProvider for messages view.
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
exports.MessagesTreeProvider = exports.MessageTreeItem = void 0;
const vscode = __importStar(require("vscode"));
const signals_core_1 = require("@preact/signals-core");
const signals_1 = require("../../state/signals");
class MessageTreeItem extends vscode.TreeItem {
    message;
    constructor(label, description, collapsibleState, message) {
        super(label, collapsibleState);
        this.message = message;
        this.description = description;
        this.iconPath = this.getIcon();
        if (message) {
            this.tooltip = this.createTooltip(message);
        }
    }
    getIcon() {
        if (!this.message) {
            return new vscode.ThemeIcon('mail');
        }
        if (this.message.toAgent === '*') {
            return new vscode.ThemeIcon('broadcast');
        }
        if (this.message.readAt === undefined) {
            return new vscode.ThemeIcon('mail-read', new vscode.ThemeColor('charts.yellow'));
        }
        return new vscode.ThemeIcon('mail');
    }
    createTooltip(msg) {
        const md = new vscode.MarkdownString();
        md.isTrusted = true;
        // Header with from/to
        const target = msg.toAgent === '*' ? 'Everyone (broadcast)' : msg.toAgent;
        md.appendMarkdown(`### ${msg.fromAgent} \u2192 ${target}\n\n`);
        // Full message content in a quote block for visibility
        md.appendMarkdown(`> ${msg.content.split('\n').join('\n> ')}\n\n`);
        // Time info with relative time
        const sentDate = new Date(msg.createdAt);
        const relativeTime = this.getRelativeTime(msg.createdAt);
        md.appendMarkdown('---\n\n');
        md.appendMarkdown(`**Sent:** ${sentDate.toLocaleString()} (${relativeTime})\n\n`);
        if (msg.readAt) {
            const readDate = new Date(msg.readAt);
            md.appendMarkdown(`**Read:** ${readDate.toLocaleString()}\n\n`);
        }
        else {
            md.appendMarkdown('**Status:** Unread\n\n');
        }
        // Message ID for debugging
        md.appendMarkdown(`*ID: ${msg.id}*`);
        return md;
    }
    getRelativeTime(timestamp) {
        const now = Date.now();
        const diff = now - timestamp;
        const seconds = Math.floor(diff / 1000);
        const minutes = Math.floor(seconds / 60);
        const hours = Math.floor(minutes / 60);
        const days = Math.floor(hours / 24);
        if (days > 0)
            return `${days}d ago`;
        if (hours > 0)
            return `${hours}h ago`;
        if (minutes > 0)
            return `${minutes}m ago`;
        return 'just now';
    }
}
exports.MessageTreeItem = MessageTreeItem;
class MessagesTreeProvider {
    _onDidChangeTreeData = new vscode.EventEmitter();
    onDidChangeTreeData = this._onDidChangeTreeData.event;
    disposeEffect = null;
    constructor() {
        this.disposeEffect = (0, signals_core_1.effect)(() => {
            signals_1.messages.value; // Subscribe
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
        if (element) {
            return [];
        }
        const allMessages = signals_1.messages.value;
        if (allMessages.length === 0) {
            return [
                new MessageTreeItem('No messages', undefined, vscode.TreeItemCollapsibleState.None),
            ];
        }
        // Sort by created time, newest first
        const sorted = [...allMessages].sort((a, b) => b.createdAt - a.createdAt);
        return sorted.map((msg) => {
            const isBroadcast = msg.toAgent === '*';
            const target = isBroadcast ? 'all' : msg.toAgent;
            const preview = msg.content.length > 30
                ? msg.content.substring(0, 30) + '...'
                : msg.content;
            return new MessageTreeItem(`${msg.fromAgent} → ${target}`, preview, vscode.TreeItemCollapsibleState.None, msg);
        });
    }
}
exports.MessagesTreeProvider = MessagesTreeProvider;
//# sourceMappingURL=messagesTreeProvider.js.map