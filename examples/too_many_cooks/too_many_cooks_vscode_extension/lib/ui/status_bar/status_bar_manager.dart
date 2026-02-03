/// Status bar item showing agent/lock/message counts.
///
/// Dart port of statusBarItem.ts - displays connection status and summary
/// counts in the VSCode status bar.
library;

import 'package:dart_node_vsix/dart_node_vsix.dart';
import 'package:too_many_cooks_vscode_extension/state/state.dart';
import 'package:too_many_cooks_vscode_extension/state/store.dart';

/// Manages the status bar item for Too Many Cooks.
final class StatusBarManager {
  /// Creates a status bar manager connected to the given store manager.
  factory StatusBarManager(StoreManager storeManager, Window window) {
    final statusBarItem = window.createStatusBarItem(
      StatusBarAlignment.left.value,
      100,
    )..command = 'tooManyCooks.showDashboard';

    final manager = StatusBarManager._(storeManager, statusBarItem);
    manager
      .._unsubscribe = storeManager.subscribe(manager._update)
      .._update();
    statusBarItem.show();

    return manager;
  }

  StatusBarManager._(this._storeManager, this._statusBarItem);

  final StoreManager _storeManager;
  final StatusBarItem _statusBarItem;
  void Function()? _unsubscribe;

  void _update() {
    final state = _storeManager.state;
    final status = selectConnectionStatus(state);
    final agents = selectAgentCount(state);
    final locks = selectLockCount(state);
    final unread = selectUnreadMessageCount(state);

    switch (status) {
      case ConnectionStatus.disconnected:
        _statusBarItem
          ..text = r'$(debug-disconnect) Too Many Cooks'
          ..tooltip = 'Click to connect'
          ..backgroundColor = ThemeColor('statusBarItem.errorBackground');
      case ConnectionStatus.connecting:
        _statusBarItem
          ..text = r'$(sync~spin) Connecting...'
          ..tooltip = 'Connecting to Too Many Cooks server'
          ..backgroundColor = null;
      case ConnectionStatus.connected:
        final parts = [
          '\$(person) $agents',
          '\$(lock) $locks',
          '\$(mail) $unread',
        ];
        _statusBarItem
          ..text = parts.join('  ')
          ..tooltip = [
            '$agents agent${agents != 1 ? 's' : ''}',
            '$locks lock${locks != 1 ? 's' : ''}',
            '$unread unread message${unread != 1 ? 's' : ''}',
            '',
            'Click to open dashboard',
          ].join('\n')
          ..backgroundColor = null;
    }
  }

  /// Disposes of this manager.
  void dispose() {
    _unsubscribe?.call();
    _statusBarItem.dispose();
  }
}
