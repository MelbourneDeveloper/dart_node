/// TreeDataProvider for file locks view.
///
/// Dart port of locksTreeProvider.ts - displays active and expired file locks
/// in a categorized tree view.
library;

import 'dart:js_interop';

import 'package:dart_node_vsix/dart_node_vsix.dart';
import 'package:too_many_cooks_vscode_extension/state/state.dart';
import 'package:too_many_cooks_vscode_extension/state/store.dart';

/// Typedef for LockTreeItem (just a TreeItem with custom properties).
typedef LockTreeItem = TreeItem;

/// Creates a lock tree item (TreeItem with extra properties).
TreeItem createLockTreeItem({
  required String label,
  required int collapsibleState,
  required bool isCategory,
  String? description,
  FileLock? lock,
}) {
  final item = TreeItem(label, collapsibleState);
  if (description != null) item.description = description;

  // Icon
  if (isCategory) {
    item.iconPath = ThemeIcon('folder');
  } else if (lock != null &&
      lock.expiresAt <= DateTime.now().millisecondsSinceEpoch) {
    item.iconPath = ThemeIcon.withColor(
      'warning',
      ThemeColor('errorForeground'),
    );
  } else {
    item.iconPath = ThemeIcon('lock');
  }

  // Context value for menus
  if (lock != null) {
    item.contextValue = 'lock';
  } else if (isCategory) {
    item.contextValue = 'category';
  }

  // Tooltip and command for lock items
  if (lock != null) {
    item
      ..tooltip = _createLockTooltip(lock)
      ..command = Command(
        command: 'vscode.open',
        title: 'Open File',
        arguments: <JSAny?>[VsUri.file(lock.filePath)].toJS,
      );
  }

  // Attach extra properties for retrieval
  _setProperty(item, 'isCategory', isCategory.toJS);
  if (lock != null) {
    _setProperty(item, 'filePath', lock.filePath.toJS);
    _setProperty(item, 'agentName', lock.agentName.toJS);
  }

  return item;
}

MarkdownString _createLockTooltip(FileLock lock) {
  final expired = lock.expiresAt <= DateTime.now().millisecondsSinceEpoch;
  final md = MarkdownString()
    ..appendMarkdown('**${lock.filePath}**\n\n')
    ..appendMarkdown('- **Agent:** ${lock.agentName}\n')
    ..appendMarkdown('- **Status:** ${expired ? '**EXPIRED**' : 'Active'}\n');
  if (!expired) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresIn = ((lock.expiresAt - now) / 1000).round();
    md.appendMarkdown('- **Expires in:** ${expiresIn}s\n');
  }
  if (lock.reason case final reason?) {
    md.appendMarkdown('- **Reason:** $reason\n');
  }
  return md;
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

/// Gets whether item is a category.
bool getIsCategory(TreeItem item) {
  final value = _getPropertyValue(item, 'isCategory');
  return value.dartify() == true;
}

@JS('Reflect.get')
external JSAny? _getPropertyValue(JSObject obj, String key);

/// Tree data provider for the locks view.
final class LocksTreeProvider implements TreeDataProvider<TreeItem> {
  /// Creates a locks tree provider connected to the given store manager.
  LocksTreeProvider(this._storeManager) {
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

    if (element == null) {
      // Root: show categories
      final items = <TreeItem>[];
      final active = selectActiveLocks(state);
      final expired = selectExpiredLocks(state);

      if (active.isNotEmpty) {
        items.add(
          createLockTreeItem(
            label: 'Active (${active.length})',
            collapsibleState: TreeItemCollapsibleState.expanded,
            isCategory: true,
          ),
        );
      }

      if (expired.isNotEmpty) {
        items.add(
          createLockTreeItem(
            label: 'Expired (${expired.length})',
            collapsibleState: TreeItemCollapsibleState.collapsed,
            isCategory: true,
          ),
        );
      }

      if (items.isEmpty) {
        items.add(
          createLockTreeItem(
            label: 'No locks',
            collapsibleState: TreeItemCollapsibleState.none,
            isCategory: false,
          ),
        );
      }

      return items;
    }

    // Children based on category
    if (getIsCategory(element)) {
      final isActive = element.label.startsWith('Active');
      final currentState = _storeManager.state;
      final lockList = isActive
          ? selectActiveLocks(currentState)
          : selectExpiredLocks(currentState);
      final now = DateTime.now().millisecondsSinceEpoch;

      return lockList.map((lock) {
        final expiresIn = ((lock.expiresAt - now) / 1000).round().clamp(
          0,
          999999,
        );
        final expired = lock.expiresAt <= now;
        final desc = expired
            ? '${lock.agentName} - EXPIRED'
            : '${lock.agentName} - ${expiresIn}s';

        return createLockTreeItem(
          label: lock.filePath,
          description: desc,
          collapsibleState: TreeItemCollapsibleState.none,
          isCategory: false,
          lock: lock,
        );
      }).toList();
    }

    return <TreeItem>[];
  }

  /// Disposes of this provider.
  void dispose() {
    _unsubscribe?.call();
    _onDidChangeTreeData.dispose();
  }
}
