/// TreeDataProvider for messages view.
///
/// Dart port of messagesTreeProvider.ts - displays inter-agent messages
/// in a flat list sorted by time.
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';

import 'package:too_many_cooks_vscode_extension_dart/state/state.dart';
import 'package:too_many_cooks_vscode_extension_dart/state/store.dart';

/// Typedef for MessageTreeItem (just a TreeItem with custom properties).
typedef MessageTreeItem = TreeItem;

/// Creates a message tree item.
TreeItem createMessageTreeItem({
  required String label,
  required int collapsibleState,
  String? description,
  Message? message,
}) {
  final item = TreeItem(label, collapsibleState);
  if (description != null) item.description = description;

  // Icon: unread = yellow circle, read = mail icon, no message = mail
  if (message == null) {
    item.iconPath = ThemeIcon('mail');
  } else if (message.readAt == null) {
    item.iconPath = ThemeIcon.withColor(
      'circle-filled',
      ThemeColor('charts.yellow'),
    );
  }

  item.contextValue = message != null ? 'message' : null;

  if (message != null) {
    item.tooltip = _createTooltip(message);
    _setProperty(item, 'messageId', message.id.toJS);
  }

  return item;
}

MarkdownString _createTooltip(Message msg) {
  // Header with from/to
  final target = msg.toAgent == '*' ? 'Everyone (broadcast)' : msg.toAgent;
  final quotedContent = msg.content.split('\n').join('\n> ');
  final sentDate = DateTime.fromMillisecondsSinceEpoch(msg.createdAt);
  final relativeTime = _getRelativeTime(msg.createdAt);

  final md = MarkdownString()
    ..isTrusted = true
    ..appendMarkdown('### ${msg.fromAgent} \u2192 $target\n\n')
    ..appendMarkdown('> $quotedContent\n\n')
    ..appendMarkdown('---\n\n')
    ..appendMarkdown('**Sent:** $sentDate ($relativeTime)\n\n');

  if (msg.readAt case final readAt?) {
    final readDate = DateTime.fromMillisecondsSinceEpoch(readAt);
    md.appendMarkdown('**Read:** $readDate\n\n');
  } else {
    md.appendMarkdown('**Status:** Unread\n\n');
  }

  // Message ID for debugging
  md.appendMarkdown('*ID: ${msg.id}*');

  return md;
}

String _getRelativeTime(int timestamp) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final diff = now - timestamp;
  final seconds = diff ~/ 1000;
  final minutes = seconds ~/ 60;
  final hours = minutes ~/ 60;
  final days = hours ~/ 24;

  if (days > 0) return '${days}d ago';
  if (hours > 0) return '${hours}h ago';
  if (minutes > 0) return '${minutes}m ago';
  return 'just now';
}

@JS('Object.defineProperty')
external void _setPropertyDescriptor(
  JSObject obj,
  String key,
  JSObject descriptor,
);

void _setProperty(JSObject obj, String key, JSAny value) {
  final descriptor = _createJSObject();
  _setRawProperty(descriptor, 'value', value);
  _setRawProperty(descriptor, 'writable', true.toJS);
  _setRawProperty(descriptor, 'enumerable', true.toJS);
  _setPropertyDescriptor(obj, key, descriptor);
}

@JS('Object')
external JSObject _createJSObject();

@JS()
external void _setRawProperty(JSObject obj, String key, JSAny? value);

/// Tree data provider for the messages view.
final class MessagesTreeProvider implements TreeDataProvider<TreeItem> {
  /// Creates a messages tree provider connected to the given store manager.
  MessagesTreeProvider(this._storeManager) {
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
  JSArray<TreeItem>? getChildren([TreeItem? element]) {
    // No children - flat list
    if (element != null) return <TreeItem>[].toJS;

    final allMessages = selectMessages(_storeManager.state);

    if (allMessages.isEmpty) {
      return <TreeItem>[
        createMessageTreeItem(
          label: 'No messages',
          collapsibleState: TreeItemCollapsibleState.none,
        ),
      ].toJS;
    }

    // Sort by created time, newest first
    final sorted = [...allMessages]..sort((a, b) => b.createdAt - a.createdAt);

    // Single row per message: "from → to | time | content"
    return sorted.map((msg) {
      final target = msg.toAgent == '*' ? 'all' : msg.toAgent;
      final relativeTime = _getRelativeTimeShort(msg.createdAt);
      final status = msg.readAt == null ? 'unread' : '';
      final statusPart = status.isNotEmpty ? ' [$status]' : '';

      return createMessageTreeItem(
        label: '${msg.fromAgent} \u2192 $target | $relativeTime$statusPart',
        description: msg.content,
        collapsibleState: TreeItemCollapsibleState.none,
        message: msg,
      );
    }).toList().toJS;
  }

  String _getRelativeTimeShort(int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - timestamp;
    final seconds = diff ~/ 1000;
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;
    final days = hours ~/ 24;

    if (days > 0) return '${days}d';
    if (hours > 0) return '${hours}h';
    if (minutes > 0) return '${minutes}m';
    return 'now';
  }

  /// Disposes of this provider.
  void dispose() {
    _unsubscribe?.call();
    _onDidChangeTreeData.dispose();
  }
}
