/**
 * TreeDataProvider for plans view.
 */

import * as vscode from 'vscode';
import { effect } from '@preact/signals-core';
import { plans } from '../../state/signals';
import type { AgentPlan } from '../../mcp/types';

export class PlanTreeItem extends vscode.TreeItem {
  constructor(
    label: string,
    description: string | undefined,
    collapsibleState: vscode.TreeItemCollapsibleState,
    public readonly plan?: AgentPlan
  ) {
    super(label, collapsibleState);
    this.description = description;
    this.iconPath = new vscode.ThemeIcon('target');

    if (plan) {
      this.tooltip = this.createTooltip(plan);
    }
  }

  private createTooltip(p: AgentPlan): vscode.MarkdownString {
    const md = new vscode.MarkdownString();
    md.appendMarkdown(`**Agent:** ${p.agentName}\n\n`);
    md.appendMarkdown(`**Goal:** ${p.goal}\n\n`);
    md.appendMarkdown(`**Current Task:** ${p.currentTask}\n\n`);
    md.appendMarkdown(
      `**Updated:** ${new Date(p.updatedAt).toLocaleString()}\n`
    );
    return md;
  }
}

export class PlansTreeProvider
  implements vscode.TreeDataProvider<PlanTreeItem>
{
  private _onDidChangeTreeData = new vscode.EventEmitter<
    PlanTreeItem | undefined
  >();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;
  private disposeEffect: (() => void) | null = null;

  constructor() {
    this.disposeEffect = effect(() => {
      plans.value; // Subscribe
      this._onDidChangeTreeData.fire(undefined);
    });
  }

  dispose(): void {
    this.disposeEffect?.();
    this._onDidChangeTreeData.dispose();
  }

  getTreeItem(element: PlanTreeItem): vscode.TreeItem {
    return element;
  }

  getChildren(element?: PlanTreeItem): PlanTreeItem[] {
    if (element) {
      // Show goal and current task as children
      if (element.plan) {
        return [
          new PlanTreeItem(
            `Goal: ${element.plan.goal}`,
            undefined,
            vscode.TreeItemCollapsibleState.None
          ),
          new PlanTreeItem(
            `Task: ${element.plan.currentTask}`,
            undefined,
            vscode.TreeItemCollapsibleState.None
          ),
        ];
      }
      return [];
    }

    const allPlans = plans.value;

    if (allPlans.length === 0) {
      return [
        new PlanTreeItem(
          'No plans',
          undefined,
          vscode.TreeItemCollapsibleState.None
        ),
      ];
    }

    // Sort by updated time, most recent first
    const sorted = [...allPlans].sort((a, b) => b.updatedAt - a.updatedAt);

    return sorted.map((plan) => {
      const preview =
        plan.currentTask.length > 30
          ? plan.currentTask.substring(0, 30) + '...'
          : plan.currentTask;

      return new PlanTreeItem(
        plan.agentName,
        preview,
        vscode.TreeItemCollapsibleState.Collapsed,
        plan
      );
    });
  }
}
