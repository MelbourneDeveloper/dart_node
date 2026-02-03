/// Store manager - manages database and syncs with Reflux store.
///
/// Uses TooManyCooksDb directly for all data access.
library;

import 'dart:async';

import 'package:nadz/nadz.dart';
import 'package:reflux/reflux.dart';
import 'package:too_many_cooks_data/too_many_cooks_data.dart';

import 'package:too_many_cooks_vscode_extension/state/log.dart' as logger;
import 'package:too_many_cooks_vscode_extension/state/state.dart';

void _log(String msg) => logger.log(msg);

/// Store manager that wraps the Reflux store and database.
class StoreManager {
  /// Creates a store manager for the given workspace folder.
  StoreManager({required this.workspaceFolder}) : _store = createAppStore();

  /// Workspace folder containing the .too_many_cooks/ database.
  final String workspaceFolder;
  final Store<AppState> _store;

  TooManyCooksDb? _db;
  Timer? _pollTimer;
  Completer<void>? _connectCompleter;

  /// The underlying Reflux store.
  Store<AppState> get store => _store;

  /// Current state.
  AppState get state => _store.getState();

  /// Subscribe to state changes.
  Unsubscribe subscribe(void Function() listener) => _store.subscribe(listener);

  /// Whether connected to database.
  bool get isConnected => _db != null;

  /// Whether currently attempting to connect.
  bool get isConnecting => _connectCompleter != null;

  /// Connect to the database.
  Future<void> connect() async {
    _log('[StoreManager] connect() called');
    if (_connectCompleter case final completer?) {
      _log('[StoreManager] Already connecting, waiting...');
      return completer.future;
    }

    if (_db != null) {
      _log('[StoreManager] Already connected');
      return;
    }

    _log('[StoreManager] Starting connection...');
    _store.dispatch(SetConnectionStatus(ConnectionStatus.connecting));
    _connectCompleter = Completer<void>();

    try {
      await _doConnect();
      _log('[StoreManager] _doConnect completed');
      _connectCompleter?.complete();
    } catch (e) {
      _log('[StoreManager] connect error: $e');
      _connectCompleter?.completeError(e);
      rethrow;
    } finally {
      _connectCompleter = null;
    }
  }

  Future<void> _doConnect() async {
    _log('[StoreManager] _doConnect starting');
    _log('[StoreManager] workspace: $workspaceFolder');

    final config = createDataConfigFromWorkspace(workspaceFolder);
    _log('[StoreManager] dbPath: ${config.dbPath}');

    final result = createDb(config);
    switch (result) {
      case Success(:final value):
        _db = value;
        _log('[StoreManager] Database opened');
      case Error(:final error):
        _log('[StoreManager] Failed to open database: $error');
        throw StateError('Failed to open database: $error');
    }

    await refreshStatus();
    _log('[StoreManager] refreshStatus completed');

    _store.dispatch(SetConnectionStatus(ConnectionStatus.connected));

    // Start polling for changes
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (isConnected) {
        unawaited(refreshStatus().catchError((_) {}));
      }
    });
  }

  /// Disconnect from the database.
  Future<void> disconnect() async {
    _log('[StoreManager] disconnect() called');
    if (_connectCompleter case final completer?) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Disconnected while connecting'));
      }
    }
    _connectCompleter = null;

    _pollTimer?.cancel();
    _pollTimer = null;

    _db?.close();
    _db = null;

    _store
      ..dispatch(ResetState())
      ..dispatch(SetConnectionStatus(ConnectionStatus.disconnected));
  }

  /// Refresh status from the database.
  Future<void> refreshStatus() async {
    final db = _db;
    if (db == null) throw StateError('Not connected');

    // Get agents
    switch (db.listAgents()) {
      case Success(:final value):
        _store.dispatch(SetAgents(value));
      case Error(:final error):
        _log('[StoreManager] listAgents error: ${error.message}');
    }

    // Get locks
    switch (db.listLocks()) {
      case Success(:final value):
        _store.dispatch(SetLocks(value));
      case Error(:final error):
        _log('[StoreManager] listLocks error: ${error.message}');
    }

    // Get plans
    switch (db.listPlans()) {
      case Success(:final value):
        _store.dispatch(SetPlans(value));
      case Error(:final error):
        _log('[StoreManager] listPlans error: ${error.message}');
    }

    // Get messages
    switch (db.listAllMessages()) {
      case Success(:final value):
        _store.dispatch(SetMessages(value));
      case Error(:final error):
        _log('[StoreManager] listAllMessages error: ${error.message}');
    }
  }

  /// Force release a lock (admin operation).
  void forceReleaseLock(String filePath) {
    final db = _db;
    if (db == null) throw StateError('Not connected');

    switch (db.adminDeleteLock(filePath)) {
      case Success():
        _store.dispatch(RemoveLock(filePath));
      case Error(:final error):
        throw StateError('${error.code}: ${error.message}');
    }
  }

  /// Delete an agent (admin operation).
  void deleteAgent(String agentName) {
    final db = _db;
    if (db == null) throw StateError('Not connected');

    switch (db.adminDeleteAgent(agentName)) {
      case Success():
        _store.dispatch(RemoveAgent(agentName));
      case Error(:final error):
        throw StateError('${error.code}: ${error.message}');
    }
  }

  /// Send a message from VSCode user to an agent.
  void sendMessage(String fromAgent, String toAgent, String content) {
    final db = _db;
    if (db == null) throw StateError('Not connected');

    // Register sender and get key
    final registerResult = db.register(fromAgent);
    final agentKey = switch (registerResult) {
      Success(:final value) => value.agentKey,
      Error(:final error) => throw StateError(
        '${error.code}: ${error.message}',
      ),
    };

    // Send the message
    switch (db.sendMessage(fromAgent, agentKey, toAgent, content)) {
      case Success():
        break;
      case Error(:final error):
        throw StateError('${error.code}: ${error.message}');
    }
  }

  /// Get the database for direct access.
  TooManyCooksDb? get db => _db;

  /// Call a tool by name - compatibility layer for tests.
  ///
  /// Uses shared serializers from too_many_cooks_data - SAME API as MCP.
  Future<String> callTool(String name, Map<String, Object?> args) async {
    final db = _db;
    if (db == null) return '{"error":"Not connected"}';

    return switch (name) {
      'status' => _statusJson(db),
      'register' => _registerJson(db, args),
      'lock' => _lockJson(db, args),
      'message' => _messageJson(db, args),
      'plan' => _planJson(db, args),
      'admin' => _adminJson(db, args),
      'subscribe' => _subscribeJson(args),
      _ => '{"error":"Unknown tool: $name"}',
    };
  }

  // All serializers below use shared functions from too_many_cooks_data.
  // MCP server uses the EXACT SAME serializers - NO DUPLICATION.

  String _statusJson(TooManyCooksDb db) {
    final agents = switch (db.listAgents()) {
      Success(:final value) => value.map(agentIdentityToJson).join(','),
      Error() => '',
    };
    final locks = switch (db.listLocks()) {
      Success(:final value) => value.map(fileLockToJson).join(','),
      Error() => '',
    };
    final plans = switch (db.listPlans()) {
      Success(:final value) => value.map(agentPlanToJson).join(','),
      Error() => '',
    };
    final messages = switch (db.listAllMessages()) {
      Success(:final value) => value.map(messageToJson).join(','),
      Error() => '',
    };
    return '{"agents":[$agents],"locks":[$locks],'
        '"plans":[$plans],"messages":[$messages]}';
  }

  String _registerJson(TooManyCooksDb db, Map<String, Object?> args) {
    final name = args['name'] as String?;
    if (name == null) return '{"error":"name required"}';
    return switch (db.register(name)) {
      Success(:final value) => agentRegistrationToJson(value),
      Error(:final error) => dbErrorToJson(error),
    };
  }

  String _lockJson(TooManyCooksDb db, Map<String, Object?> args) {
    final action = args['action'] as String?;
    final path = args['file_path'] as String?;
    final name = args['agent_name'] as String?;
    final key = args['agent_key'] as String?;
    final reason = args['reason'] as String?;
    return switch (action) {
      'acquire' when path != null && name != null && key != null => switch (db
          .acquireLock(path, name, key, reason, 600000)) {
        Success(:final value) => lockResultToJson(value),
        Error(:final error) => dbErrorToJson(error),
      },
      'release' when path != null && name != null && key != null => switch (db
          .releaseLock(path, name, key)) {
        Success() => '{"released":true}',
        Error(:final error) => dbErrorToJson(error),
      },
      'query' when path != null => switch (db.queryLock(path)) {
        Success(:final value) when value == null => '{"locked":false}',
        Success(:final value) =>
          '{"locked":true,"lock":${fileLockToJson(value!)}}',
        Error(:final error) => dbErrorToJson(error),
      },
      'list' => switch (db.listLocks()) {
        Success(:final value) =>
          '{"locks":[${value.map(fileLockToJson).join(',')}]}',
        Error(:final error) => dbErrorToJson(error),
      },
      'renew' when path != null && name != null && key != null => switch (db
          .renewLock(path, name, key, 600000)) {
        Success() => '{"renewed":true}',
        Error(:final error) => dbErrorToJson(error),
      },
      _ => '{"error":"Invalid lock action or missing params"}',
    };
  }

  String _messageJson(TooManyCooksDb db, Map<String, Object?> args) {
    final action = args['action'] as String?;
    final name = args['agent_name'] as String?;
    final key = args['agent_key'] as String?;
    return switch (action) {
      'send' when name != null && key != null => () {
        final to = args['to_agent'] as String?;
        final content = args['content'] as String?;
        if (to == null || content == null) {
          return '{"error":"to_agent and content required"}';
        }
        return switch (db.sendMessage(name, key, to, content)) {
          Success(:final value) => '{"sent":true,"message_id":"$value"}',
          Error(:final error) => dbErrorToJson(error),
        };
      }(),
      'get' when name != null && key != null => () {
        final unread = args['unread_only'] as bool? ?? true;
        return switch (db.getMessages(name, key, unreadOnly: unread)) {
          Success(:final value) =>
            '{"messages":[${value.map(messageToJson).join(',')}]}',
          Error(:final error) => dbErrorToJson(error),
        };
      }(),
      'mark_read' when name != null && key != null => () {
        final id = args['message_id'] as String?;
        if (id == null) return '{"error":"message_id required"}';
        return switch (db.markRead(id, name, key)) {
          Success() => '{"marked":true}',
          Error(:final error) => dbErrorToJson(error),
        };
      }(),
      _ => '{"error":"Invalid message action or missing params"}',
    };
  }

  String _planJson(TooManyCooksDb db, Map<String, Object?> args) {
    final action = args['action'] as String?;
    return switch (action) {
      'update' => () {
        final name = args['agent_name'] as String?;
        final key = args['agent_key'] as String?;
        final goal = args['goal'] as String?;
        final task = args['current_task'] as String?;
        if (name == null || key == null || goal == null || task == null) {
          return '{"error":"agent_name, agent_key, goal, '
              'current_task required"}';
        }
        return switch (db.updatePlan(name, key, goal, task)) {
          Success() => '{"updated":true}',
          Error(:final error) => dbErrorToJson(error),
        };
      }(),
      'get' => () {
        final name = args['agent_name'] as String?;
        if (name == null) return '{"error":"agent_name required"}';
        return switch (db.getPlan(name)) {
          Success(:final value) when value == null => '{"plan":null}',
          Success(:final value) => '{"plan":${agentPlanToJson(value!)}}',
          Error(:final error) => dbErrorToJson(error),
        };
      }(),
      'list' => switch (db.listPlans()) {
        Success(:final value) =>
          '{"plans":[${value.map(agentPlanToJson).join(',')}]}',
        Error(:final error) => dbErrorToJson(error),
      },
      _ => '{"error":"Invalid plan action"}',
    };
  }

  String _adminJson(TooManyCooksDb db, Map<String, Object?> args) {
    final action = args['action'] as String?;
    return switch (action) {
      'delete_lock' => () {
        final path = args['file_path'] as String?;
        if (path == null) return '{"error":"file_path required"}';
        return switch (db.adminDeleteLock(path)) {
          Success() => '{"deleted":true}',
          Error(:final error) => dbErrorToJson(error),
        };
      }(),
      'delete_agent' => () {
        final name = args['agent_name'] as String?;
        if (name == null) return '{"error":"agent_name required"}';
        return switch (db.adminDeleteAgent(name)) {
          Success() => '{"deleted":true}',
          Error(:final error) => dbErrorToJson(error),
        };
      }(),
      'reset_key' => () {
        final name = args['agent_name'] as String?;
        if (name == null) return '{"error":"agent_name required"}';
        return switch (db.adminResetKey(name)) {
          Success(:final value) => agentRegistrationToJson(value),
          Error(:final error) => dbErrorToJson(error),
        };
      }(),
      _ => '{"error":"Invalid admin action"}',
    };
  }

  String _subscribeJson(Map<String, Object?> args) {
    final action = args['action'] as String?;
    return switch (action) {
      'list' => '{"subscribers":[]}',
      'subscribe' => '{"subscribed":true}',
      'unsubscribe' => '{"unsubscribed":true}',
      _ => '{"subscribed":true}',
    };
  }
}
