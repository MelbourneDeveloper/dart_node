"use strict";
/**
 * TreeDataProvider for plans view.
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
exports.PlansTreeProvider = exports.PlanTreeItem = void 0;
const vscode = __importStar(require("vscode"));
const signals_core_1 = require("@preact/signals-core");
const signals_1 = require("../../state/signals");
class PlanTreeItem extends vscode.TreeItem {
    plan;
    constructor(label, description, collapsibleState, plan) {
        super(label, collapsibleState);
        this.plan = plan;
        this.description = description;
        this.iconPath = new vscode.ThemeIcon('target');
        if (plan) {
            this.tooltip = this.createTooltip(plan);
        }
    }
    createTooltip(p) {
        const md = new vscode.MarkdownString();
        md.appendMarkdown(`**Agent:** ${p.agentName}\n\n`);
        md.appendMarkdown(`**Goal:** ${p.goal}\n\n`);
        md.appendMarkdown(`**Current Task:** ${p.currentTask}\n\n`);
        md.appendMarkdown(`**Updated:** ${new Date(p.updatedAt).toLocaleString()}\n`);
        return md;
    }
}
exports.PlanTreeItem = PlanTreeItem;
class PlansTreeProvider {
    _onDidChangeTreeData = new vscode.EventEmitter();
    onDidChangeTreeData = this._onDidChangeTreeData.event;
    disposeEffect = null;
    constructor() {
        this.disposeEffect = (0, signals_core_1.effect)(() => {
            signals_1.plans.value; // Subscribe
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
            // Show goal and current task as children
            if (element.plan) {
                return [
                    new PlanTreeItem(`Goal: ${element.plan.goal}`, undefined, vscode.TreeItemCollapsibleState.None),
                    new PlanTreeItem(`Task: ${element.plan.currentTask}`, undefined, vscode.TreeItemCollapsibleState.None),
                ];
            }
            return [];
        }
        const allPlans = signals_1.plans.value;
        if (allPlans.length === 0) {
            return [
                new PlanTreeItem('No plans', undefined, vscode.TreeItemCollapsibleState.None),
            ];
        }
        // Sort by updated time, most recent first
        const sorted = [...allPlans].sort((a, b) => b.updatedAt - a.updatedAt);
        return sorted.map((plan) => {
            const preview = plan.currentTask.length > 30
                ? plan.currentTask.substring(0, 30) + '...'
                : plan.currentTask;
            return new PlanTreeItem(plan.agentName, preview, vscode.TreeItemCollapsibleState.Collapsed, plan);
        });
    }
}
exports.PlansTreeProvider = PlansTreeProvider;
//# sourceMappingURL=plansTreeProvider.js.map