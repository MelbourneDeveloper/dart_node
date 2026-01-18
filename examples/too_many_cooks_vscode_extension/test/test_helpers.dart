/// Test helpers for integration tests.
///
/// Provides utilities for MCP client testing including mock factories,
/// condition waiting, and cleanup helpers.
library;

import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:too_many_cooks_vscode_extension/state/state.dart';
import 'package:too_many_cooks_vscode_extension/state/store.dart';

export 'package:too_many_cooks_vscode_extension/state/state.dart';
export 'package:too_many_cooks_vscode_extension/state/store.dart'
    show StoreManager, StoreNotificationEvent;

/// Extract string from args map, returns null if not found or wrong type.
String? _str(Map<String, Object?> args, String key) =>
    switch (args[key]) { final String s => s, _ => null };

/// Extract bool from args map with default.
bool _bool(Map<String, Object?> args, String key, {bool def = false}) =>
    switch (args[key]) { final bool b => b, _ => def };

/// Extract agent key from JSON response. Use instead of `as String` cast.
String extractKey(String jsonResponse) {
  final decoded = jsonDecode(jsonResponse);
  if (decoded case {'agent_key': final String key}) return key;
  throw StateError('No agent_key in response: $jsonResponse');
}

/// Mock MCP client for testing.
class MockMcpClient implements McpClient {
  MockMcpClient();

  final _notificationController =
      StreamController<StoreNotificationEvent>.broadcast();
  final _logController = StreamController<String>.broadcast();
  final _errorController = StreamController<Object>.broadcast();
  final _closeController = StreamController<void>.broadcast();

  bool _connected = false;
  final Map<String, String Function(Map<String, Object?>)> _toolHandlers = {};
  final List<String> _toolCalls = [];

  /// Track tool calls for assertions.
  List<String> get toolCalls => List.unmodifiable(_toolCalls);

  /// Mock agents in the "database".
  final Map<String, ({String key, int registeredAt, int lastActive})> agents =
      {};

  /// Mock locks in the "database".
  final Map<String, ({String agentName, int expiresAt, String? reason})> locks =
      {};

  /// Mock messages in the "database".
  final List<
      ({
        String id,
        String from,
        String to,
        String content,
        int createdAt,
        int? readAt,
      })> messages = [];

  /// Mock plans in the "database".
  final Map<String, ({String goal, String currentTask, int updatedAt})> plans =
      {};

  /// Register a mock tool handler.
  void registerTool(
    String name,
    String Function(Map<String, Object?>) handler,
  ) {
    _toolHandlers[name] = handler;
  }

  /// Setup default tool handlers that mimic the real server.
  void setupDefaultHandlers() {
    registerTool('status', (_) {
      final now = DateTime.now().millisecondsSinceEpoch;
      return jsonEncode({
        'agents': agents.entries
            .map((e) => {
                  'agent_name': e.key,
                  'registered_at': e.value.registeredAt,
                  'last_active': e.value.lastActive,
                })
            .toList(),
        'locks': locks.entries
            .map((e) => {
                  'file_path': e.key,
                  'agent_name': e.value.agentName,
                  'acquired_at': now - 1000,
                  'expires_at': e.value.expiresAt,
                  'reason': e.value.reason,
                })
            .toList(),
        'plans': plans.entries
            .map((e) => {
                  'agent_name': e.key,
                  'goal': e.value.goal,
                  'current_task': e.value.currentTask,
                  'updated_at': e.value.updatedAt,
                })
            .toList(),
        'messages': messages
            .map((m) => {
                  'id': m.id,
                  'from_agent': m.from,
                  'to_agent': m.to,
                  'content': m.content,
                  'created_at': m.createdAt,
                  'read_at': m.readAt,
                })
            .toList(),
      });
    });

    registerTool('register', (args) {
      final name = _str(args, 'name')!;
      final now = DateTime.now().millisecondsSinceEpoch;
      final key = 'key-$name-$now';
      agents[name] = (key: key, registeredAt: now, lastActive: now);

      _notificationController.add((
        event: 'agent_registered',
        timestamp: now,
        payload: {'agent_name': name, 'registered_at': now},
      ));

      return jsonEncode({'agent_name': name, 'agent_key': key});
    });

    registerTool('lock', (args) {
      final action = _str(args, 'action')!;
      final filePath = _str(args, 'file_path');
      final agentName = _str(args, 'agent_name');
      final agentKey = _str(args, 'agent_key');
      final reason = _str(args, 'reason');

      final now = DateTime.now().millisecondsSinceEpoch;

      switch (action) {
        case 'acquire':
          if (filePath == null || agentName == null || agentKey == null) {
            return jsonEncode({'error': 'Missing required arguments'});
          }
          final agent = agents[agentName];
          if (agent == null || agent.key != agentKey) {
            return jsonEncode({'error': 'Invalid agent key'});
          }
          final expiresAt = now + 60000;
          locks[filePath] =
              (agentName: agentName, expiresAt: expiresAt, reason: reason);

          _notificationController.add((
            event: 'lock_acquired',
            timestamp: now,
            payload: {
              'file_path': filePath,
              'agent_name': agentName,
              'expires_at': expiresAt,
              'reason': reason,
            },
          ));

          return jsonEncode({'acquired': true, 'expires_at': expiresAt});

        case 'release':
          if (filePath == null || agentName == null || agentKey == null) {
            return jsonEncode({'error': 'Missing required arguments'});
          }
          locks.remove(filePath);

          _notificationController.add((
            event: 'lock_released',
            timestamp: now,
            payload: {'file_path': filePath, 'agent_name': agentName},
          ));

          return jsonEncode({'released': true});

        case 'renew':
          if (filePath == null || agentName == null || agentKey == null) {
            return jsonEncode({'error': 'Missing required arguments'});
          }
          final lock = locks[filePath];
          if (lock == null) {
            return jsonEncode({'error': 'Lock not found'});
          }
          final expiresAt = now + 60000;
          locks[filePath] = (
            agentName: lock.agentName,
            expiresAt: expiresAt,
            reason: lock.reason,
          );

          _notificationController.add((
            event: 'lock_renewed',
            timestamp: now,
            payload: {'file_path': filePath, 'expires_at': expiresAt},
          ));

          return jsonEncode({'renewed': true, 'expires_at': expiresAt});

        default:
          return jsonEncode({'error': 'Unknown action: $action'});
      }
    });

    registerTool('message', (args) {
      final action = _str(args, 'action')!;
      final agentName = _str(args, 'agent_name');
      final agentKey = _str(args, 'agent_key');

      final now = DateTime.now().millisecondsSinceEpoch;

      switch (action) {
        case 'send':
          final toAgent = _str(args, 'to_agent');
          final content = _str(args, 'content');
          if (agentName == null ||
              agentKey == null ||
              toAgent == null ||
              content == null) {
            return jsonEncode({'error': 'Missing required arguments'});
          }
          final id = 'msg-$now';
          messages.add((
            id: id,
            from: agentName,
            to: toAgent,
            content: content,
            createdAt: now,
            readAt: null,
          ));

          _notificationController.add((
            event: 'message_sent',
            timestamp: now,
            payload: {
              'message_id': id,
              'from_agent': agentName,
              'to_agent': toAgent,
              'content': content,
            },
          ));

          return jsonEncode({'sent': true, 'message_id': id});

        case 'get':
          final unreadOnly = _bool(args, 'unread_only');
          final agentMsgs = messages.where((m) {
            if (m.to != agentName && m.to != '*') return false;
            if (unreadOnly && m.readAt != null) return false;
            return true;
          }).toList();

          // Auto-mark as read
          for (var i = 0; i < messages.length; i++) {
            final m = messages[i];
            if ((m.to == agentName || m.to == '*') && m.readAt == null) {
              messages[i] = (
                id: m.id,
                from: m.from,
                to: m.to,
                content: m.content,
                createdAt: m.createdAt,
                readAt: now,
              );
            }
          }

          return jsonEncode({
            'messages': agentMsgs
                .map((m) => {
                      'id': m.id,
                      'from_agent': m.from,
                      'to_agent': m.to,
                      'content': m.content,
                      'created_at': m.createdAt,
                      'read_at': m.readAt,
                    })
                .toList(),
          });

        case 'mark_read':
          final messageId = _str(args, 'message_id');
          if (messageId == null) {
            return jsonEncode({'error': 'Missing message_id'});
          }
          for (var i = 0; i < messages.length; i++) {
            if (messages[i].id == messageId) {
              final m = messages[i];
              messages[i] = (
                id: m.id,
                from: m.from,
                to: m.to,
                content: m.content,
                createdAt: m.createdAt,
                readAt: now,
              );
              break;
            }
          }
          return jsonEncode({'marked_read': true});

        default:
          return jsonEncode({'error': 'Unknown action: $action'});
      }
    });

    registerTool('plan', (args) {
      final action = _str(args, 'action')!;
      final agentName = _str(args, 'agent_name');

      final now = DateTime.now().millisecondsSinceEpoch;

      switch (action) {
        case 'update':
          final goal = _str(args, 'goal');
          final currentTask = _str(args, 'current_task');
          if (agentName == null || goal == null || currentTask == null) {
            return jsonEncode({'error': 'Missing required arguments'});
          }
          plans[agentName] =
              (goal: goal, currentTask: currentTask, updatedAt: now);

          _notificationController.add((
            event: 'plan_updated',
            timestamp: now,
            payload: {
              'agent_name': agentName,
              'goal': goal,
              'current_task': currentTask,
            },
          ));

          return jsonEncode({'updated': true});

        case 'get':
          if (agentName == null) {
            return jsonEncode({'error': 'Missing agent_name'});
          }
          final plan = plans[agentName];
          if (plan == null) {
            return jsonEncode({'error': 'Plan not found'});
          }
          return jsonEncode({
            'agent_name': agentName,
            'goal': plan.goal,
            'current_task': plan.currentTask,
            'updated_at': plan.updatedAt,
          });

        case 'list':
          return jsonEncode({
            'plans': plans.entries
                .map((e) => {
                      'agent_name': e.key,
                      'goal': e.value.goal,
                      'current_task': e.value.currentTask,
                      'updated_at': e.value.updatedAt,
                    })
                .toList(),
          });

        default:
          return jsonEncode({'error': 'Unknown action: $action'});
      }
    });

    registerTool('admin', (args) {
      final action = _str(args, 'action')!;

      switch (action) {
        case 'delete_lock':
          final filePath = _str(args, 'file_path');
          if (filePath == null) {
            return jsonEncode({'error': 'Missing file_path'});
          }
          locks.remove(filePath);
          return jsonEncode({'deleted': true});

        case 'delete_agent':
          final agentName = _str(args, 'agent_name');
          if (agentName == null) {
            return jsonEncode({'error': 'Missing agent_name'});
          }
          if (!agents.containsKey(agentName)) {
            return jsonEncode({'error': 'NOT_FOUND: Agent not found'});
          }
          agents.remove(agentName);
          locks.removeWhere((_, v) => v.agentName == agentName);
          plans.remove(agentName);
          return jsonEncode({'deleted': true});

        default:
          return jsonEncode({'error': 'Unknown action: $action'});
      }
    });

    registerTool('subscribe', (args) {
      final action = _str(args, 'action')!;
      switch (action) {
        case 'subscribe':
          return jsonEncode({'subscribed': true});
        case 'unsubscribe':
          return jsonEncode({'unsubscribed': true});
        case 'list':
          return jsonEncode({'subscribers': <Map<String, Object?>>[]});
        default:
          return jsonEncode({'error': 'Unknown action: $action'});
      }
    });
  }

  /// Emit a notification.
  void emitNotification(StoreNotificationEvent event) {
    _notificationController.add(event);
  }

  /// Emit a log message.
  void emitLog(String message) {
    _logController.add(message);
  }

  /// Emit an error.
  void emitError(Object error) {
    _errorController.add(error);
  }

  /// Simulate close.
  void simulateClose() {
    _closeController.add(null);
    _connected = false;
  }

  /// Clear all mock data.
  void reset() {
    agents.clear();
    locks.clear();
    messages.clear();
    plans.clear();
    _toolCalls.clear();
  }

  @override
  Future<void> start() async {
    _connected = true;
  }

  @override
  Future<void> stop() async {
    _connected = false;
  }

  @override
  Future<String> callTool(String name, Map<String, Object?> args) async {
    _toolCalls.add('$name:${jsonEncode(args)}');
    final handler = _toolHandlers[name];
    if (handler == null) {
      throw StateError('Tool not found: $name');
    }
    return handler(args);
  }

  @override
  Future<void> subscribe(List<String> events) async {}

  @override
  Future<void> unsubscribe() async {}

  @override
  bool isConnected() => _connected;

  @override
  Stream<StoreNotificationEvent> get notifications =>
      _notificationController.stream;

  @override
  Stream<String> get logs => _logController.stream;

  @override
  Stream<Object> get errors => _errorController.stream;

  @override
  Stream<void> get onClose => _closeController.stream;

  void dispose() {
    unawaited(_notificationController.close());
    unawaited(_logController.close());
    unawaited(_errorController.close());
    unawaited(_closeController.close());
  }
}

/// Create a StoreManager with a mock client for testing.
({StoreManager manager, MockMcpClient client}) createTestStore() {
  final client = MockMcpClient()..setupDefaultHandlers();
  final manager = StoreManager(client: client);
  return (manager: manager, client: client);
}

/// Wait for a condition to be true, polling at regular intervals.
Future<void> waitForCondition(
  bool Function() condition, {
  String? message,
  Duration timeout = const Duration(seconds: 5),
  Duration interval = const Duration(milliseconds: 100),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    if (condition()) {
      return;
    }
    await Future<void>.delayed(interval);
  }
  throw TimeoutException(message ?? 'Condition not met within timeout');
}

/// Wait for store state to match a condition.
Future<void> waitForState(
  StoreManager manager,
  bool Function(AppState) condition, {
  String? message,
  Duration timeout = const Duration(seconds: 5),
}) async {
  await waitForCondition(
    () => condition(manager.state),
    message: message,
    timeout: timeout,
  );
}

/// Helper to run async tests with cleanup.
Future<void> withTestStore(
  Future<void> Function(StoreManager manager, MockMcpClient client) test,
) async {
  final (:manager, :client) = createTestStore();
  try {
    await test(manager, client);
  } finally {
    await manager.disconnect();
    client.dispose();
  }
}

/// Assert state matches expected values.
void expectState(
  StoreManager manager, {
  ConnectionStatus? connectionStatus,
  int? agentCount,
  int? lockCount,
  int? messageCount,
  int? planCount,
}) {
  final state = manager.state;
  if (connectionStatus != null) {
    expect(state.connectionStatus, equals(connectionStatus));
  }
  if (agentCount != null) {
    expect(state.agents.length, equals(agentCount));
  }
  if (lockCount != null) {
    expect(state.locks.length, equals(lockCount));
  }
  if (messageCount != null) {
    expect(state.messages.length, equals(messageCount));
  }
  if (planCount != null) {
    expect(state.plans.length, equals(planCount));
  }
}

/// Find an agent in the store state by name.
AgentIdentity? findAgent(StoreManager manager, String name) =>
    manager.state.agents.where((a) => a.agentName == name).firstOrNull;

/// Find a lock in the store state by file path.
FileLock? findLock(StoreManager manager, String filePath) =>
    manager.state.locks.where((l) => l.filePath == filePath).firstOrNull;

/// Find a message containing the given content.
Message? findMessage(StoreManager manager, String contentSubstring) =>
    manager.state.messages
        .where((m) => m.content.contains(contentSubstring))
        .firstOrNull;

/// Find a plan for an agent.
AgentPlan? findPlan(StoreManager manager, String agentName) =>
    manager.state.plans.where((p) => p.agentName == agentName).firstOrNull;

/// Parse JSON string to typed Map, returns empty map if parsing fails.
Map<String, Object?> parseJson(String json) {
  final decoded = jsonDecode(json);
  if (decoded case final Map<String, Object?> map) {
    return map;
  }
  return <String, Object?>{};
}

/// Extract string value from JSON map by key.
String? extractString(Map<String, Object?> map, String key) =>
    switch (map[key]) { final String s => s, _ => null };

/// Extract agent key from register result.
String extractAgentKey(String registerResult) {
  final map = parseJson(registerResult);
  return extractString(map, 'agent_key') ?? '';
}
