"use strict";
/**
 * TreeDataProvider for agents view.
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
exports.AgentsTreeProvider = exports.AgentTreeItem = void 0;
const vscode = __importStar(require("vscode"));
const signals_core_1 = require("@preact/signals-core");
const signals_1 = require("../../state/signals");
class AgentTreeItem extends vscode.TreeItem {
    itemType;
    agentName;
    filePath;
    constructor(label, description, collapsibleState, itemType, agentName, filePath, tooltip) {
        super(label, collapsibleState);
        this.itemType = itemType;
        this.agentName = agentName;
        this.filePath = filePath;
        this.description = description;
        this.iconPath = this.getIcon();
        this.contextValue = itemType;
        if (tooltip) {
            this.tooltip = tooltip;
        }
    }
    getIcon() {
        switch (this.itemType) {
            case 'agent':
                return new vscode.ThemeIcon('person');
            case 'lock':
                return new vscode.ThemeIcon('lock');
            case 'plan':
                return new vscode.ThemeIcon('target');
            case 'message-summary':
                return new vscode.ThemeIcon('mail');
        }
    }
}
exports.AgentTreeItem = AgentTreeItem;
class AgentsTreeProvider {
    _onDidChangeTreeData = new vscode.EventEmitter();
    onDidChangeTreeData = this._onDidChangeTreeData.event;
    disposeEffect = null;
    constructor() {
        // React to signal changes
        this.disposeEffect = (0, signals_core_1.effect)(() => {
            signals_1.agentDetails.value; // Subscribe to changes
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
            // Root: list all agents
            return signals_1.agentDetails.value.map((detail) => this.createAgentItem(detail));
        }
        // Children: agent's plan, locks, messages
        if (element.itemType === 'agent' && element.agentName) {
            const detail = signals_1.agentDetails.value.find((d) => d.agent.agentName === element.agentName);
            if (!detail)
                return [];
            return this.createAgentChildren(detail);
        }
        return [];
    }
    createAgentItem(detail) {
        const lockCount = detail.locks.length;
        const msgCount = detail.sentMessages.length + detail.receivedMessages.length;
        const parts = [];
        if (lockCount > 0)
            parts.push(`${lockCount} lock${lockCount > 1 ? 's' : ''}`);
        if (msgCount > 0)
            parts.push(`${msgCount} msg${msgCount > 1 ? 's' : ''}`);
        return new AgentTreeItem(detail.agent.agentName, parts.join(', ') || 'idle', vscode.TreeItemCollapsibleState.Collapsed, 'agent', detail.agent.agentName, undefined, this.createAgentTooltip(detail));
    }
    createAgentTooltip(detail) {
        const md = new vscode.MarkdownString();
        const agent = detail.agent;
        md.appendMarkdown(`**Agent:** ${agent.agentName}\n\n`);
        md.appendMarkdown(`**Registered:** ${new Date(agent.registeredAt).toLocaleString()}\n\n`);
        md.appendMarkdown(`**Last Active:** ${new Date(agent.lastActive).toLocaleString()}\n\n`);
        if (detail.plan) {
            md.appendMarkdown('---\n\n');
            md.appendMarkdown(`**Goal:** ${detail.plan.goal}\n\n`);
            md.appendMarkdown(`**Current Task:** ${detail.plan.currentTask}\n\n`);
        }
        if (detail.locks.length > 0) {
            md.appendMarkdown('---\n\n');
            md.appendMarkdown(`**Locks (${detail.locks.length}):**\n`);
            for (const lock of detail.locks) {
                const expired = lock.expiresAt <= Date.now();
                const status = expired ? 'EXPIRED' : 'active';
                md.appendMarkdown(`- \`${lock.filePath}\` (${status})\n`);
            }
        }
        const unread = detail.receivedMessages.filter((m) => m.readAt === undefined).length;
        if (detail.sentMessages.length > 0 || detail.receivedMessages.length > 0) {
            md.appendMarkdown('\n---\n\n');
            md.appendMarkdown(`**Messages:** ${detail.sentMessages.length} sent, ` +
                `${detail.receivedMessages.length} received` +
                (unread > 0 ? ` **(${unread} unread)**` : '') +
                '\n');
        }
        return md;
    }
    createAgentChildren(detail) {
        const children = [];
        // Plan
        if (detail.plan) {
            children.push(new AgentTreeItem(`Goal: ${detail.plan.goal}`, `Task: ${detail.plan.currentTask}`, vscode.TreeItemCollapsibleState.None, 'plan', detail.agent.agentName));
        }
        // Locks
        for (const lock of detail.locks) {
            const expiresIn = Math.max(0, Math.round((lock.expiresAt - Date.now()) / 1000));
            const expired = lock.expiresAt <= Date.now();
            children.push(new AgentTreeItem(lock.filePath, expired
                ? 'EXPIRED'
                : `${expiresIn}s${lock.reason ? ` (${lock.reason})` : ''}`, vscode.TreeItemCollapsibleState.None, 'lock', detail.agent.agentName, lock.filePath));
        }
        // Message summary
        const unread = detail.receivedMessages.filter((m) => m.readAt === undefined).length;
        if (detail.sentMessages.length > 0 || detail.receivedMessages.length > 0) {
            children.push(new AgentTreeItem('Messages', `${detail.sentMessages.length} sent, ${detail.receivedMessages.length} received${unread > 0 ? ` (${unread} unread)` : ''}`, vscode.TreeItemCollapsibleState.None, 'message-summary', detail.agent.agentName));
        }
        return children;
    }
}
exports.AgentsTreeProvider = AgentsTreeProvider;
//# sourceMappingURL=agentsTreeProvider.js.map