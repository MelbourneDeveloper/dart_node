/// Store manager - manages MCP client and syncs with Reflux store.
///
/// This is the Dart port of store.ts. It integrates the MCP client
/// with the Reflux store for state management.
library;

import 'dart:async';
import 'dart:convert';

import 'package:reflux/reflux.dart';

import 'package:too_many_cooks_vscode_extension_dart/state/state.dart';

/// Local notification event type for store handling (uses string event name).
typedef StoreNotificationEvent = ({
  String event,
  int timestamp,
  Map<String, Object?> payload,
});

/// MCP Client interface - will be implemented in mcp/client.dart
abstract interface class McpClient {
  /// Start the MCP client connection.
  Future<void> start();

  /// Stop the MCP client connection.
  Future<void> stop();

  /// Call a tool on the MCP server.
  Future<String> callTool(String name, Map<String, Object?> args);

  /// Subscribe to notification events.
  Future<void> subscribe(List<String> events);

  /// Unsubscribe from notification events.
  Future<void> unsubscribe();

  /// Check if connected to the MCP server.
  bool isConnected();

  /// Stream of notification events.
  Stream<StoreNotificationEvent> get notifications;

  /// Stream of log messages.
  Stream<String> get logs;

  /// Stream of errors.
  Stream<Object> get errors;

  /// Stream that emits when the connection closes.
  Stream<void> get onClose;
}

/// Store manager that wraps the Reflux store and MCP client.
class StoreManager {
  /// Creates a store manager with optional server path and MCP client.
  StoreManager({this.serverPath, McpClient? client})
      : _client = client,
        _store = createAppStore();

  /// Path to the MCP server.
  final String? serverPath;
  final Store<AppState> _store;
  final McpClient? _client;
  Timer? _pollTimer;
  Completer<void>? _connectCompleter;
  StreamSubscription<StoreNotificationEvent>? _notificationSub;
  StreamSubscription<void>? _closeSub;
  StreamSubscription<Object>? _errorSub;
  StreamSubscription<String>? _logSub;

  /// The underlying Reflux store.
  Store<AppState> get store => _store;

  /// Current state.
  AppState get state => _store.getState();

  /// Subscribe to state changes.
  Unsubscribe subscribe(void Function() listener) =>
      _store.subscribe(listener);

  /// Whether connected to MCP server.
  bool get isConnected => _client?.isConnected() ?? false;

  /// Connect to the MCP server.
  Future<void> connect() async {
    // If already connecting, wait for that to complete
    if (_connectCompleter case final completer?) {
      return completer.future;
    }

    if (_client?.isConnected() ?? false) {
      return;
    }

    _store.dispatch(SetConnectionStatus(ConnectionStatus.connecting));
    _connectCompleter = Completer<void>();

    try {
      await _doConnect();
      _connectCompleter?.complete();
    } catch (e) {
      _connectCompleter?.completeError(e);
      rethrow;
    } finally {
      _connectCompleter = null;
    }
  }

  Future<void> _doConnect() async {
    // Client should be injected or created externally
    // This allows for testing with mock clients
    final client = _client;
    if (client == null) {
      throw StateError(
        'McpClient not provided. Inject client via constructor.',
      );
    }

    // Set up event handlers
    _notificationSub = client.notifications.listen(_handleNotification);
    _closeSub = client.onClose.listen((_) {
      _store.dispatch(SetConnectionStatus(ConnectionStatus.disconnected));
    });
    _errorSub = client.errors.listen((err) {
      // Log error - in real impl would use output channel
    });
    _logSub = client.logs.listen((msg) {
      // Log message - in real impl would use output channel
    });

    await client.start();
    await client.subscribe(['*']);
    await refreshStatus();

    _store.dispatch(SetConnectionStatus(ConnectionStatus.connected));

    // Start polling for changes from other MCP server instances
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (isConnected) {
        unawaited(refreshStatus().catchError((_) {}));
      }
    });
  }

  /// Disconnect from the MCP server.
  Future<void> disconnect() async {
    _connectCompleter = null;

    _pollTimer?.cancel();
    _pollTimer = null;

    await _notificationSub?.cancel();
    await _closeSub?.cancel();
    await _errorSub?.cancel();
    await _logSub?.cancel();
    _notificationSub = null;
    _closeSub = null;
    _errorSub = null;
    _logSub = null;

    if (_client case final client?) {
      await client.stop();
    }

    _store
      ..dispatch(ResetState())
      ..dispatch(SetConnectionStatus(ConnectionStatus.disconnected));
  }

  /// Refresh status from the MCP server.
  Future<void> refreshStatus() async {
    final client = _client;
    if (client == null || !client.isConnected()) {
      throw StateError('Not connected');
    }

    final statusJson = await client.callTool('status', {});
    final decoded = jsonDecode(statusJson);

    if (decoded case final Map<String, Object?> status) {
      _updateAgentsFromStatus(status);
      _updateLocksFromStatus(status);
      _updatePlansFromStatus(status);
      _updateMessagesFromStatus(status);
    }
  }

  void _updateAgentsFromStatus(Map<String, Object?> status) {
    final agents = <AgentIdentity>[];
    if (status['agents'] case final List<Object?> agentsList) {
      for (final item in agentsList) {
        if (item case final Map<String, Object?> map) {
          if (map['agent_name'] case final String agentName) {
            if (map['registered_at'] case final int registeredAt) {
              if (map['last_active'] case final int lastActive) {
                agents.add((
                  agentName: agentName,
                  registeredAt: registeredAt,
                  lastActive: lastActive,
                ));
              }
            }
          }
        }
      }
    }
    _store.dispatch(SetAgents(agents));
  }

  void _updateLocksFromStatus(Map<String, Object?> status) {
    final locks = <FileLock>[];
    if (status['locks'] case final List<Object?> locksList) {
      for (final item in locksList) {
        if (item case final Map<String, Object?> map) {
          if (map['file_path'] case final String filePath) {
            if (map['agent_name'] case final String agentName) {
              if (map['acquired_at'] case final int acquiredAt) {
                if (map['expires_at'] case final int expiresAt) {
                  final reason = switch (map['reason']) {
                    final String r => r,
                    _ => null,
                  };
                  locks.add((
                    filePath: filePath,
                    agentName: agentName,
                    acquiredAt: acquiredAt,
                    expiresAt: expiresAt,
                    reason: reason,
                    version: 1,
                  ));
                }
              }
            }
          }
        }
      }
    }
    _store.dispatch(SetLocks(locks));
  }

  void _updatePlansFromStatus(Map<String, Object?> status) {
    final plans = <AgentPlan>[];
    if (status['plans'] case final List<Object?> plansList) {
      for (final item in plansList) {
        if (item case final Map<String, Object?> map) {
          if (map['agent_name'] case final String agentName) {
            if (map['goal'] case final String goal) {
              if (map['current_task'] case final String currentTask) {
                if (map['updated_at'] case final int updatedAt) {
                  plans.add((
                    agentName: agentName,
                    goal: goal,
                    currentTask: currentTask,
                    updatedAt: updatedAt,
                  ));
                }
              }
            }
          }
        }
      }
    }
    _store.dispatch(SetPlans(plans));
  }

  void _updateMessagesFromStatus(Map<String, Object?> status) {
    final messages = <Message>[];
    if (status['messages'] case final List<Object?> messagesList) {
      for (final item in messagesList) {
        if (item case final Map<String, Object?> map) {
          if (map['id'] case final String id) {
            if (map['from_agent'] case final String fromAgent) {
              if (map['to_agent'] case final String toAgent) {
                if (map['content'] case final String content) {
                  if (map['created_at'] case final int createdAt) {
                    final readAt = switch (map['read_at']) {
                      final int r => r,
                      _ => null,
                    };
                    messages.add((
                      id: id,
                      fromAgent: fromAgent,
                      toAgent: toAgent,
                      content: content,
                      createdAt: createdAt,
                      readAt: readAt,
                    ));
                  }
                }
              }
            }
          }
        }
      }
    }
    _store.dispatch(SetMessages(messages));
  }

  void _handleNotification(StoreNotificationEvent event) {
    final payload = event.payload;

    switch (event.event) {
      case 'agent_registered':
        if (payload['agent_name'] case final String agentName) {
          if (payload['registered_at'] case final int registeredAt) {
            _store.dispatch(
              AddAgent((
                agentName: agentName,
                registeredAt: registeredAt,
                lastActive: event.timestamp,
              )),
            );
          }
        }

      case 'lock_acquired':
        if (payload['file_path'] case final String filePath) {
          if (payload['agent_name'] case final String agentName) {
            if (payload['expires_at'] case final int expiresAt) {
              final reason = switch (payload['reason']) {
                final String r => r,
                _ => null,
              };
              _store.dispatch(
                UpsertLock((
                  filePath: filePath,
                  agentName: agentName,
                  acquiredAt: event.timestamp,
                  expiresAt: expiresAt,
                  reason: reason,
                  version: 1,
                )),
              );
            }
          }
        }

      case 'lock_released':
        if (payload['file_path'] case final String filePath) {
          _store.dispatch(RemoveLock(filePath));
        }

      case 'lock_renewed':
        if (payload['file_path'] case final String filePath) {
          if (payload['expires_at'] case final int expiresAt) {
            _store.dispatch(RenewLock(filePath, expiresAt));
          }
        }

      case 'message_sent':
        if (payload['message_id'] case final String id) {
          if (payload['from_agent'] case final String fromAgent) {
            if (payload['to_agent'] case final String toAgent) {
              if (payload['content'] case final String content) {
                _store.dispatch(
                  AddMessage((
                    id: id,
                    fromAgent: fromAgent,
                    toAgent: toAgent,
                    content: content,
                    createdAt: event.timestamp,
                    readAt: null,
                  )),
                );
              }
            }
          }
        }

      case 'plan_updated':
        if (payload['agent_name'] case final String agentName) {
          if (payload['goal'] case final String goal) {
            if (payload['current_task'] case final String currentTask) {
              _store.dispatch(
                UpsertPlan((
                  agentName: agentName,
                  goal: goal,
                  currentTask: currentTask,
                  updatedAt: event.timestamp,
                )),
              );
            }
          }
        }
    }
  }

  /// Call a tool on the MCP server.
  Future<String> callTool(String name, Map<String, Object?> args) {
    final client = _client;
    if (client == null || !client.isConnected()) {
      throw StateError('Not connected');
    }
    return client.callTool(name, args);
  }

  /// Force release a lock (admin operation).
  Future<void> forceReleaseLock(String filePath) async {
    final result = await callTool('admin', {
      'action': 'delete_lock',
      'file_path': filePath,
    });
    final decoded = jsonDecode(result);
    if (decoded case final Map<String, Object?> parsed) {
      if (parsed['error'] case final String error) {
        throw StateError(error);
      }
    }
    _store.dispatch(RemoveLock(filePath));
  }

  /// Delete an agent (admin operation).
  Future<void> deleteAgent(String agentName) async {
    final result = await callTool('admin', {
      'action': 'delete_agent',
      'agent_name': agentName,
    });
    final decoded = jsonDecode(result);
    if (decoded case final Map<String, Object?> parsed) {
      if (parsed['error'] case final String error) {
        throw StateError(error);
      }
    }
    _store.dispatch(RemoveAgent(agentName));
  }

  /// Send a message from VSCode user to an agent.
  Future<void> sendMessage(
    String fromAgent,
    String toAgent,
    String content,
  ) async {
    // Register sender and get key
    final registerResult = await callTool('register', {'name': fromAgent});
    final registerDecoded = jsonDecode(registerResult);

    String? agentKey;
    if (registerDecoded case final Map<String, Object?> registerParsed) {
      if (registerParsed['error'] case final String error) {
        throw StateError(error);
      }
      if (registerParsed['agent_key'] case final String key) {
        agentKey = key;
      }
    }

    if (agentKey == null) {
      throw StateError('Failed to get agent key from registration');
    }

    // Send the message
    final sendResult = await callTool('message', {
      'action': 'send',
      'agent_name': fromAgent,
      'agent_key': agentKey,
      'to_agent': toAgent,
      'content': content,
    });
    final sendDecoded = jsonDecode(sendResult);
    if (sendDecoded case final Map<String, Object?> sendParsed) {
      if (sendParsed['error'] case final String error) {
        throw StateError(error);
      }
    }
  }
}
