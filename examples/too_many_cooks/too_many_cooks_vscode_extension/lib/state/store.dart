/// Store manager - HTTP client for the MCP server.
///
/// Talks to the MCP server via:
/// - `/admin/*` REST endpoints for VSIX operations
/// - `/admin/events` SSE for real-time push
/// - `/mcp` Streamable HTTP for MCP tool calls (tests)
///
/// Nothing touches the DB directly.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:reflux/reflux.dart';
import 'package:too_many_cooks_vscode_extension/state/log.dart'
    as logger;
import 'package:too_many_cooks_vscode_extension/state/state.dart';

void _log(String msg) => logger.log(msg);

/// HTTP fetch function (Node.js global).
@JS('globalThis.fetch')
external JSPromise<JSObject> _jsFetch(
  JSString url, [
  JSObject? options,
]);

/// Store manager that wraps the Reflux store and HTTP
/// client to the MCP server.
class StoreManager {
  /// Creates a store manager for the given workspace.
  StoreManager({required this.workspaceFolder})
      : _store = createAppStore();

  /// Workspace folder.
  final String workspaceFolder;
  final Store<AppState> _store;

  JSObject? _serverProcess;
  Timer? _pollTimer;
  Completer<void>? _connectCompleter;
  String? _mcpSessionId;

  /// Base URL for the MCP server.
  static const _baseUrl = 'http://localhost:4040';

  /// The underlying Reflux store.
  Store<AppState> get store => _store;

  /// Current state.
  AppState get state => _store.getState();

  /// Subscribe to state changes.
  Unsubscribe subscribe(void Function() listener) =>
      _store.subscribe(listener);

  /// Whether connected to MCP server.
  bool get isConnected => _serverProcess != null;

  /// Whether currently attempting to connect.
  bool get isConnecting => _connectCompleter != null;

  /// Connect to the MCP server.
  Future<void> connect() async {
    _log('[StoreManager] connect() called');
    if (_connectCompleter case final completer?) {
      _log('[StoreManager] Already connecting...');
      return completer.future;
    }

    if (_serverProcess != null) {
      _log('[StoreManager] Already connected');
      return;
    }

    _log('[StoreManager] Starting connection...');
    _store.dispatch(
      SetConnectionStatus(ConnectionStatus.connecting),
    );
    _connectCompleter = Completer<void>();

    try {
      await _doConnect();
      _log('[StoreManager] Connected');
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
    _log('[StoreManager] workspace: $workspaceFolder');

    // Find and spawn the MCP server
    final serverPath = _findServerPath();
    _log('[StoreManager] server path: $serverPath');

    final childProcess =
        requireModule('child_process') as JSObject;
    final spawnFn =
        childProcess['spawn'] as JSFunction?;

    _serverProcess = spawnFn?.callAsFunction(
      null,
      'node'.toJS,
      <String>[serverPath].jsify(),
      <String, Object?>{
        'stdio': ['pipe', 'pipe', 'inherit'],
        'env': <String, Object?>{
          ...(_getProcessEnv()),
          'TMC_WORKSPACE': workspaceFolder,
        },
      }.jsify(),
    ) as JSObject?;

    // Listen for process exit
    final process = _serverProcess;
    if (process != null) {
      (process['on'] as JSFunction?)?.callAsFunction(
        process,
        'exit'.toJS,
        ((JSAny? code) {
          _log('[StoreManager] Server exited: $code');
          _serverProcess = null;
          _store.dispatch(
            SetConnectionStatus(
              ConnectionStatus.disconnected,
            ),
          );
        }).toJS,
      );
    }

    // Wait for server to be ready
    await _waitForServer();

    await refreshStatus();
    _log('[StoreManager] refreshStatus completed');

    _store.dispatch(
      SetConnectionStatus(ConnectionStatus.connected),
    );

    // Poll for changes via admin status endpoint
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        if (isConnected) {
          unawaited(
            refreshStatus().catchError((_) {}),
          );
        }
      },
    );
  }

  /// Wait for the HTTP server to be ready.
  Future<void> _waitForServer() async {
    for (var i = 0; i < 30; i++) {
      try {
        final response = await _fetch(
          '$_baseUrl/admin/status',
        );
        if (response != null) {
          _log('[StoreManager] Server is ready');
          return;
        }
      } on Object {
        // Server not ready yet
      }
      await Future<void>.delayed(
        const Duration(milliseconds: 200),
      );
    }
    throw StateError('Server failed to start');
  }

  /// Find the MCP server binary path.
  String _findServerPath() {
    final path = requireModule('path') as JSObject;
    final fs = requireModule('fs') as JSObject;
    final joinFn = path['join'] as JSFunction?;
    final existsSyncFn =
        fs['existsSync'] as JSFunction?;

    final candidates = [
      joinFn?.callAsFunction(
        null,
        workspaceFolder.toJS,
        'build/bin/server_node.js'.toJS,
      ) as JSString?,
      joinFn?.callAsFunction(
        null,
        workspaceFolder.toJS,
        '../too_many_cooks/build/bin/server_node.js'
            .toJS,
      ) as JSString?,
    ];

    for (final candidate in candidates) {
      if (candidate == null) continue;
      final exists = existsSyncFn?.callAsFunction(
        fs,
        candidate,
      );
      if (exists != null &&
          (exists as JSBoolean).toDart) {
        return candidate.toDart;
      }
    }

    throw StateError(
      'MCP server binary not found. '
      'Run scripts/build_mcp.sh first.',
    );
  }

  /// Get process.env as a Dart map.
  Map<String, String> _getProcessEnv() {
    try {
      final process =
          requireModule('process') as JSObject;
      final env = process['env'] as JSObject?;
      if (env == null) return {};
      final dartified = env.dartify();
      if (dartified is Map) {
        return Map<String, String>.fromEntries(
          dartified.entries.map(
            (e) => MapEntry(
              e.key.toString(),
              e.value.toString(),
            ),
          ),
        );
      }
    } on Object catch (_) {}
    return {};
  }

  /// Disconnect from the MCP server.
  Future<void> disconnect() async {
    _log('[StoreManager] disconnect() called');
    if (_connectCompleter case final completer?) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('Disconnected while connecting'),
        );
      }
    }
    _connectCompleter = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _mcpSessionId = null;

    if (_serverProcess != null) {
      (_serverProcess?['kill'] as JSFunction?)
          ?.callAsFunction(_serverProcess);
      _serverProcess = null;
    }

    _store
      ..dispatch(ResetState())
      ..dispatch(
        SetConnectionStatus(
          ConnectionStatus.disconnected,
        ),
      );
  }

  /// Refresh status from the admin endpoint.
  Future<void> refreshStatus() async {
    if (_serverProcess == null) {
      throw StateError('Not connected');
    }

    final json = await _fetchJson(
      '$_baseUrl/admin/status',
    );
    if (json != null) {
      _parseAndDispatchStatus(json);
    }
  }

  void _parseAndDispatchStatus(
    Map<String, Object?> json,
  ) {
    if (json['agents'] case final List<Object?> list) {
      final agents = list
          .whereType<Map<String, Object?>>()
          .map(
            (a) => (
              agentName: a['agent_name'] as String? ??
                  '',
              registeredAt:
                  a['registered_at'] as int? ?? 0,
              lastActive:
                  a['last_active'] as int? ?? 0,
            ),
          )
          .toList();
      _store.dispatch(SetAgents(agents));
    }

    if (json['locks'] case final List<Object?> list) {
      final locks = list
          .whereType<Map<String, Object?>>()
          .map(
            (l) => (
              filePath:
                  l['file_path'] as String? ?? '',
              agentName:
                  l['agent_name'] as String? ?? '',
              acquiredAt:
                  l['acquired_at'] as int? ?? 0,
              expiresAt:
                  l['expires_at'] as int? ?? 0,
              reason: l['reason'] as String?,
              version: l['version'] as int? ?? 0,
            ),
          )
          .toList();
      _store.dispatch(SetLocks(locks));
    }

    if (json['plans'] case final List<Object?> list) {
      final plans = list
          .whereType<Map<String, Object?>>()
          .map(
            (p) => (
              agentName:
                  p['agent_name'] as String? ?? '',
              goal: p['goal'] as String? ?? '',
              currentTask:
                  p['current_task'] as String? ?? '',
              updatedAt:
                  p['updated_at'] as int? ?? 0,
            ),
          )
          .toList();
      _store.dispatch(SetPlans(plans));
    }

    if (json['messages']
        case final List<Object?> list) {
      final messages = list
          .whereType<Map<String, Object?>>()
          .map(
            (m) => (
              id: m['id'] as String? ?? '',
              fromAgent:
                  m['from_agent'] as String? ?? '',
              toAgent:
                  m['to_agent'] as String? ?? '',
              content:
                  m['content'] as String? ?? '',
              createdAt:
                  m['created_at'] as int? ?? 0,
              readAt: m['read_at'] as int?,
            ),
          )
          .toList();
      _store.dispatch(SetMessages(messages));
    }
  }

  /// Force release a lock via admin endpoint.
  void forceReleaseLock(String filePath) {
    unawaited(
      _postJson('$_baseUrl/admin/delete-lock', {
        'filePath': filePath,
      }).then((_) {
        _log('[StoreManager] Lock released: $filePath');
        _store.dispatch(RemoveLock(filePath));
      }),
    );
  }

  /// Delete an agent via admin endpoint.
  void deleteAgent(String agentName) {
    unawaited(
      _postJson('$_baseUrl/admin/delete-agent', {
        'agentName': agentName,
      }).then((_) {
        _log('[StoreManager] Agent deleted: '
            '$agentName');
        _store.dispatch(RemoveAgent(agentName));
      }),
    );
  }

  /// Send a message via admin endpoint.
  void sendMessage(
    String fromAgent,
    String toAgent,
    String content,
  ) {
    unawaited(
      _postJson('$_baseUrl/admin/send-message', {
        'fromAgent': fromAgent,
        'toAgent': toAgent,
        'content': content,
      }).then((_) {
        _log('[StoreManager] Message sent');
      }),
    );
  }

  /// Call an MCP tool via Streamable HTTP at /mcp.
  ///
  /// Used by tests to exercise the real MCP server.
  Future<String> callTool(
    String name,
    Map<String, Object?> args,
  ) async {
    if (_serverProcess == null) {
      return '{"error":"Not connected"}';
    }

    try {
      // Ensure we have an MCP session
      _mcpSessionId ??= await _initMcpSession();

      final result = await _mcpRequest(
        'tools/call',
        {'name': name, 'arguments': args},
      );
      final content = (result['content'] as List?)
              ?.first
          as Map<String, Object?>?;
      return content?['text'] as String? ??
          '{"error":"No text content"}';
    } on Object catch (e) {
      // Reset session on error
      _mcpSessionId = null;
      return '{"error":"$e"}';
    }
  }

  // === MCP Streamable HTTP ===

  static const _mcpAccept =
      'application/json, text/event-stream';

  /// Initialize an MCP session via POST /mcp.
  Future<String> _initMcpSession() async {
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'initialize',
      'params': {
        'protocolVersion': '2024-11-05',
        'capabilities': <String, Object?>{},
        'clientInfo': {
          'name': 'too-many-cooks-vsix',
          'version': '1.0.0',
        },
      },
    });

    final response = await _mcpFetch(body);

    final sessionId =
        _getResponseHeader(response, 'mcp-session-id');
    if (sessionId == null) {
      throw StateError('No session ID in response');
    }

    // Send initialized notification
    final notifyBody = jsonEncode({
      'jsonrpc': '2.0',
      'method': 'notifications/initialized',
      'params': <String, Object?>{},
    });
    await _mcpFetch(notifyBody, sessionId: sessionId);

    return sessionId;
  }

  /// Make an MCP JSON-RPC request via POST /mcp.
  Future<Map<String, Object?>> _mcpRequest(
    String method,
    Map<String, Object?> params,
  ) async {
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'id': DateTime.now().millisecondsSinceEpoch,
      'method': method,
      'params': params,
    });

    final response =
        await _mcpFetch(body, sessionId: _mcpSessionId);
    final text = await _getResponseText(response);

    if (text == null || text.isEmpty) {
      throw StateError('Empty response');
    }

    // Parse SSE or JSON response
    final json = _parseMcpResponse(text);

    if (json.containsKey('error')) {
      final error =
          json['error'] as Map<String, Object?>?;
      final message =
          error?['message'] as String? ?? 'Error';
      throw StateError(message);
    }

    return json['result'] as Map<String, Object?>? ??
        {};
  }

  /// POST to /mcp with correct headers.
  Future<JSObject> _mcpFetch(
    String body, {
    String? sessionId,
  }) {
    final headers = JSObject()
      ..['Content-Type'] = 'application/json'.toJS
      ..['Accept'] = _mcpAccept.toJS;
    if (sessionId != null) {
      headers['mcp-session-id'] = sessionId.toJS;
    }

    final options = JSObject()
      ..['method'] = 'POST'.toJS
      ..['headers'] = headers
      ..['body'] = body.toJS;

    return _jsFetch('$_baseUrl/mcp'.toJS, options)
        .toDart;
  }

  /// Parse MCP response which may be SSE or JSON.
  Map<String, Object?> _parseMcpResponse(String text) {
    // Try direct JSON first
    if (text.trimLeft().startsWith('{')) {
      return jsonDecode(text) as Map<String, Object?>;
    }

    // Parse SSE: extract data from "data: {...}" lines
    for (final line in text.split('\n')) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6);
        try {
          return jsonDecode(data)
              as Map<String, Object?>;
        } on Object {
          continue;
        }
      }
    }

    throw StateError('Could not parse MCP response');
  }

  /// Get response body as text.
  Future<String?> _getResponseText(
    JSObject response,
  ) async {
    final text = await (
      (response['text'] as JSFunction?)
              ?.callAsFunction(response)
          as JSPromise<JSString>?
    )?.toDart;
    return text?.toDart;
  }

  // === HTTP helpers ===

  /// Fetch a URL and return the response object.
  Future<JSObject?> _fetch(String url) async {
    final response =
        await _jsFetch(url.toJS).toDart;
    final ok = response['ok'];
    if (ok == null ||
        !(ok as JSBoolean).toDart) {
      return null;
    }
    return response;
  }

  /// Fetch JSON from a URL.
  Future<Map<String, Object?>?> _fetchJson(
    String url,
  ) async {
    final response = await _fetch(url);
    if (response == null) return null;

    final text = await (
      (response['text'] as JSFunction?)
              ?.callAsFunction(response)
          as JSPromise<JSString>?
    )?.toDart;

    if (text == null) return null;
    return jsonDecode(text.toDart)
        as Map<String, Object?>?;
  }

  /// POST JSON to a URL.
  Future<String?> _postJson(
    String url,
    Map<String, Object?> body,
  ) async {
    final options = JSObject()
      ..['method'] = 'POST'.toJS
      ..['headers'] = (JSObject()
        ..['Content-Type'] =
            'application/json'.toJS)
      ..['body'] = jsonEncode(body).toJS;

    final response = await _jsFetch(
      url.toJS,
      options,
    ).toDart;

    final text = await (
      (response['text'] as JSFunction?)
              ?.callAsFunction(response)
          as JSPromise<JSString>?
    )?.toDart;

    return text?.toDart;
  }

  /// Get a response header value.
  String? _getResponseHeader(
    JSObject response,
    String name,
  ) {
    final headers =
        response['headers'] as JSObject?;
    if (headers == null) return null;
    final getFn =
        headers['get'] as JSFunction?;
    final value = getFn?.callAsFunction(
      headers,
      name.toJS,
    );
    if (value == null || value.isUndefinedOrNull) {
      return null;
    }
    return (value as JSString).toDart;
  }
}
