/// TreeDataProvider for agents view.
///
/// Dart port of agentsTreeProvider.ts - displays registered agents with their
/// locks, plans, and messages in a tree view.
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';

import 'package:too_many_cooks_vscode_extension/state/state.dart';
import 'package:too_many_cooks_vscode_extension/state/store.dart';

/// Tree item type enum for context menu targeting.
enum AgentTreeItemType {
  /// An agent node in the tree.
  agent,

  /// A lock node belonging to an agent.
  lock,

  /// A plan node showing agent's current goal.
  plan,

  /// A message summary node for an agent.
  messageSummary,
}

/// Creates an agent tree item (TreeItem with extra properties).
TreeItem createAgentTreeItem({
  required String label,
  required int collapsibleState,
  required AgentTreeItemType itemType,
  String? description,
  String? agentName,
  String? filePath,
  MarkdownString? tooltip,
}) {
  final item = TreeItem(label, collapsibleState)
    ..description = description
    ..iconPath = switch (itemType) {
      AgentTreeItemType.agent => ThemeIcon('person'),
      AgentTreeItemType.lock => ThemeIcon('lock'),
      AgentTreeItemType.plan => ThemeIcon('target'),
      AgentTreeItemType.messageSummary => ThemeIcon('mail'),
    }
    ..contextValue = itemType == AgentTreeItemType.agent
        ? 'deletableAgent'
        : itemType.name
    ..tooltip = tooltip;

  // Attach extra properties for command handlers
  if (agentName != null) _setProperty(item, 'agentName', agentName.toJS);
  if (filePath != null) _setProperty(item, 'filePath', filePath.toJS);
  _setProperty(item, 'itemType', itemType.name.toJS);

  return item;
}

void _setProperty(JSObject obj, String key, JSAny value) {
  _setPropertyBracket(obj, key, value);
}

/// Helper to set a property on a JS object using bracket notation.
extension _JSObjectExt on JSObject {
  external void operator []=(String key, JSAny? value);
}

void _setPropertyBracket(JSObject target, String key, JSAny? value) =>
    target[key] = value;

/// Gets a custom property from a tree item.
AgentTreeItemType? getItemType(TreeItem item) {
  final value = _getPropertyValue(item, 'itemType');
  if (value == null) return null;
  final str = (value as JSString?)?.toDart;
  if (str == null) return null;
  return AgentTreeItemType.values.where((t) => t.name == str).firstOrNull;
}

/// Gets the agent name from a tree item.
String? getAgentName(TreeItem item) {
  final value = _getPropertyValue(item, 'agentName');
  return (value as JSString?)?.toDart;
}

/// Gets the file path from a tree item.
String? getFilePath(TreeItem item) {
  final value = _getPropertyValue(item, 'filePath');
  return (value as JSString?)?.toDart;
}

@JS('Reflect.get')
external JSAny? _getPropertyValue(JSObject obj, String key);

/// Tree data provider for the agents view.
final class AgentsTreeProvider implements TreeDataProvider<TreeItem> {
  /// Creates an agents tree provider connected to the given store manager.
  AgentsTreeProvider(this._storeManager) {
    _unsubscribe = _storeManager.subscribe(() {
      _onDidChangeTreeData.fire(null);
    });
  }

  final StoreManager _storeManager;
  final EventEmitter<TreeItem?> _onDidChangeTreeData = EventEmitter();
  void Function()? _unsubscribe;

  @override
  Event<TreeItem?> get onDidChangeTreeData => _onDidChangeTreeData.event;

  @override
  TreeItem getTreeItem(TreeItem element) => element;

  @override
  List<TreeItem>? getChildren([TreeItem? element]) {
    final state = _storeManager.state;
    final details = selectAgentDetails(state);

    if (element == null) {
      // Root: list all agents
      return details.map(_createAgentItem).toList();
    }

    // Children: agent's plan, locks, messages
    final itemType = getItemType(element);
    final agentName = getAgentName(element);
    if (itemType == AgentTreeItemType.agent && agentName != null) {
      final detail = details
          .where((d) => d.agent.agentName == agentName)
          .firstOrNull;
      return detail != null ? _createAgentChildren(detail) : <TreeItem>[];
    }

    return <TreeItem>[];
  }

  TreeItem _createAgentItem(AgentDetails detail) {
    final lockCount = detail.locks.length;
    final msgCount =
        detail.sentMessages.length + detail.receivedMessages.length;
    final parts = <String>[];
    if (lockCount > 0) {
      parts.add('$lockCount lock${lockCount > 1 ? 's' : ''}');
    }
    if (msgCount > 0) {
      parts.add('$msgCount msg${msgCount > 1 ? 's' : ''}');
    }

    return createAgentTreeItem(
      label: detail.agent.agentName,
      description: parts.isNotEmpty ? parts.join(', ') : 'idle',
      collapsibleState: TreeItemCollapsibleState.collapsed,
      itemType: AgentTreeItemType.agent,
      agentName: detail.agent.agentName,
      tooltip: _createAgentTooltip(detail),
    );
  }

  MarkdownString _createAgentTooltip(AgentDetails detail) {
    final agent = detail.agent;
    final regDate = DateTime.fromMillisecondsSinceEpoch(agent.registeredAt);
    final activeDate = DateTime.fromMillisecondsSinceEpoch(agent.lastActive);

    final md = MarkdownString()
      ..appendMarkdown('**Agent:** ${agent.agentName}\n\n')
      ..appendMarkdown('**Registered:** $regDate\n\n')
      ..appendMarkdown('**Last Active:** $activeDate\n\n');

    if (detail.plan case final plan?) {
      md
        ..appendMarkdown('---\n\n')
        ..appendMarkdown('**Goal:** ${plan.goal}\n\n')
        ..appendMarkdown('**Current Task:** ${plan.currentTask}\n\n');
    }

    if (detail.locks.isNotEmpty) {
      md
        ..appendMarkdown('---\n\n')
        ..appendMarkdown('**Locks (${detail.locks.length}):**\n');
      for (final lock in detail.locks) {
        final expired = lock.expiresAt <= DateTime.now().millisecondsSinceEpoch;
        final status = expired ? 'EXPIRED' : 'active';
        md.appendMarkdown('- `${lock.filePath}` ($status)\n');
      }
    }

    final unread = detail.receivedMessages
        .where((m) => m.readAt == null)
        .length;
    if (detail.sentMessages.isNotEmpty || detail.receivedMessages.isNotEmpty) {
      md
        ..appendMarkdown('\n---\n\n')
        ..appendMarkdown(
          '**Messages:** ${detail.sentMessages.length} sent, '
          '${detail.receivedMessages.length} received'
          '${unread > 0 ? ' **($unread unread)**' : ''}\n',
        );
    }

    return md;
  }

  List<TreeItem> _createAgentChildren(AgentDetails detail) {
    final children = <TreeItem>[];
    final now = DateTime.now().millisecondsSinceEpoch;

    // Plan
    if (detail.plan case final plan?) {
      children.add(
        createAgentTreeItem(
          label: 'Goal: ${plan.goal}',
          description: 'Task: ${plan.currentTask}',
          collapsibleState: TreeItemCollapsibleState.none,
          itemType: AgentTreeItemType.plan,
          agentName: detail.agent.agentName,
        ),
      );
    }

    // Locks
    for (final lock in detail.locks) {
      final expiresIn = ((lock.expiresAt - now) / 1000).round().clamp(
        0,
        999999,
      );
      final expired = lock.expiresAt <= now;
      final reason = lock.reason;
      children.add(
        createAgentTreeItem(
          label: lock.filePath,
          description: expired
              ? 'EXPIRED'
              : '${expiresIn}s${reason != null ? ' ($reason)' : ''}',
          collapsibleState: TreeItemCollapsibleState.none,
          itemType: AgentTreeItemType.lock,
          agentName: detail.agent.agentName,
          filePath: lock.filePath,
        ),
      );
    }

    // Message summary
    final unread = detail.receivedMessages
        .where((m) => m.readAt == null)
        .length;
    if (detail.sentMessages.isNotEmpty || detail.receivedMessages.isNotEmpty) {
      final sent = detail.sentMessages.length;
      final recv = detail.receivedMessages.length;
      final unreadStr = unread > 0 ? ' ($unread unread)' : '';
      children.add(
        createAgentTreeItem(
          label: 'Messages',
          description: '$sent sent, $recv received$unreadStr',
          collapsibleState: TreeItemCollapsibleState.none,
          itemType: AgentTreeItemType.messageSummary,
          agentName: detail.agent.agentName,
        ),
      );
    }

    return children;
  }

  /// Disposes of this provider.
  void dispose() {
    _unsubscribe?.call();
    _onDidChangeTreeData.dispose();
  }
}
