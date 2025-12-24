/// MCP Client - communicates with Too Many Cooks server via stdio JSON-RPC.
///
/// This is the Dart port of client.ts.
/// Uses Node.js child_process via JS interop (dart:io doesn't work in dart2js).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:too_many_cooks_vscode_extension_dart/mcp/child_process.dart';
import 'package:too_many_cooks_vscode_extension_dart/state/store.dart';

@JS('console.log')
external void _consoleLog(JSAny? message);

/// Implementation of McpClient that spawns the server process.
class McpClientImpl implements McpClient {
  /// Creates an MCP client with optional server path.
  McpClientImpl({this.serverPath});

  /// Path to the server (for testing).
  final String? serverPath;
  ChildProcess? _process;
  String _buffer = '';
  final _pending = <int, Completer<Object?>>{};
  int _nextId = 1;
  bool _initialized = false;

  // Stream controllers - recreated on each start() since stop() closes them
  StreamController<StoreNotificationEvent>? _notificationController;
  StreamController<String>? _logController;
  StreamController<Object>? _errorController;
  StreamController<void>? _closeController;

  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;
  StreamController<String>? _stdoutController;
  StreamController<String>? _stderrController;

  /// Lazily creates the notification controller if needed.
  StreamController<StoreNotificationEvent> get _notifications =>
      _notificationController ??=
          StreamController<StoreNotificationEvent>.broadcast();

  /// Lazily creates the log controller if needed.
  StreamController<String> get _logs =>
      _logController ??= StreamController<String>.broadcast();

  /// Lazily creates the error controller if needed.
  StreamController<Object> get _errors =>
      _errorController ??= StreamController<Object>.broadcast();

  /// Lazily creates the close controller if needed.
  StreamController<void> get _onCloseController =>
      _closeController ??= StreamController<void>.broadcast();

  @override
  Stream<StoreNotificationEvent> get notifications => _notifications.stream;

  @override
  Stream<String> get logs => _logs.stream;

  @override
  Stream<Object> get errors => _errors.stream;

  @override
  Stream<void> get onClose => _onCloseController.stream;

  @override
  Future<void> start() async {
    final String cmd;
    final List<String> args;
    final bool useShell;

    if (serverPath != null) {
      cmd = 'node';
      args = [serverPath!];
      useShell = false;
      _log('[MCP] Using server path: $serverPath');
    } else {
      cmd = 'npx';
      args = ['too-many-cooks'];
      useShell = true;
      _log('[MCP] Using npx too-many-cooks');
    }

    _log('[MCP] Spawning: $cmd ${args.join(" ")} (shell=$useShell)');
    _process = spawn(cmd, args, shell: useShell);
    _log('[MCP] Process spawned');

    _stdoutController = createStringStreamFromReadable(_process!.stdout);
    _stdoutSub = _stdoutController!.stream.listen(
      (data) {
        _log('[MCP] stdout received: ${data.length} chars');
        _onData(data);
      },
      onError: _onError,
    );

    _stderrController = createStringStreamFromReadable(_process!.stderr);
    _stderrSub = _stderrController!.stream.listen((msg) {
      _log('[MCP] stderr: $msg');
      _logs.add(msg);
    });

    _process!.onClose((code) {
      _log('[MCP] Process closed with code: $code');
      _onCloseController.add(null);
    });

    _log('[MCP] Sending initialize request...');
    await _request('initialize', {
      'protocolVersion': '2024-11-05',
      'capabilities': <String, Object?>{},
      'clientInfo': {'name': 'too-many-cooks-vscode-dart', 'version': '0.3.0'},
    });
    _log('[MCP] Initialize response received');

    _notify('notifications/initialized', {});
    _initialized = true;
    _log('[MCP] Client initialized');
  }

  void _log(String message) {
    // Use console.log for debugging
    _consoleLog(message.toJS);
  }

  @override
  Future<String> callTool(String name, Map<String, Object?> args) async {
    final result = await _request('tools/call', {
      'name': name,
      'arguments': args,
    });

    if (result case final Map<String, Object?> resultMap) {
      final isError = switch (resultMap['isError']) {
        final bool b => b,
        _ => false,
      };

      if (resultMap['content'] case final List<Object?> content) {
        if (content.isEmpty) {
          return isError ? throw StateError('Unknown error') : '{}';
        }

        if (content[0] case final Map<String, Object?> firstItem) {
          final text = switch (firstItem['text']) {
            final String t => t,
            _ => '{}',
          };
          if (isError) throw StateError(text);
          return text;
        }
      }
    }
    return '{}';
  }

  @override
  Future<void> subscribe(List<String> events) async {
    await callTool('subscribe', {
      'action': 'subscribe',
      'subscriber_id': 'vscode-extension-dart',
      'events': events,
    });
  }

  @override
  Future<void> unsubscribe() async {
    try {
      await callTool('subscribe', {
        'action': 'unsubscribe',
        'subscriber_id': 'vscode-extension-dart',
      });
    } on Object catch (_) {
      // Ignore errors during unsubscribe
    }
  }

  Future<Object?> _request(
    String method,
    Map<String, Object?> params, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final id = _nextId++;
    _log('[MCP] _request($method) id=$id');
    final completer = Completer<Object?>();
    _pending[id] = completer;
    _send({'jsonrpc': '2.0', 'id': id, 'method': method, 'params': params});
    _log('[MCP] _request($method) sent, awaiting response...');
    try {
      final result = await completer.future.timeout(
        timeout,
        onTimeout: () {
          _log('[MCP] _request($method) TIMEOUT after $timeout');
          _pending.remove(id);
          throw TimeoutException(r'Request $method timed out after $timeout');
        },
      );
      _log('[MCP] _request($method) completed');
      return result;
    } on TimeoutException {
      _pending.remove(id);
      rethrow;
    }
  }

  void _notify(String method, Map<String, Object?> params) {
    _send({'jsonrpc': '2.0', 'method': method, 'params': params});
  }

  void _send(Map<String, Object?> message) {
    final body = '${jsonEncode(message)}\n';
    if (_process != null) {
      writeToStream(_process!.stdin, body);
    }
  }

  void _onData(String chunk) {
    _buffer += chunk;
    _processBuffer();
  }

  void _onError(Object error) {
    _errors.add(error);
  }

  void _processBuffer() {
    var newlineIndex = _buffer.indexOf('\n');
    while (newlineIndex != -1) {
      var line = _buffer.substring(0, newlineIndex);
      _buffer = _buffer.substring(newlineIndex + 1);

      if (line.endsWith('\r')) {
        line = line.substring(0, line.length - 1);
      }

      if (line.isEmpty) {
        newlineIndex = _buffer.indexOf('\n');
        continue;
      }

      try {
        final decoded = jsonDecode(line);
        if (decoded case final Map<String, Object?> message) {
          _handleMessage(message);
        }
      } on Object catch (e) {
        _errors.add(e);
      }
      newlineIndex = _buffer.indexOf('\n');
    }
  }

  void _handleMessage(Map<String, Object?> msg) {
    final id = switch (msg['id']) {
      final int i => i,
      _ => null,
    };

    if (id != null && _pending.containsKey(id)) {
      final handler = _pending.remove(id);
      if (handler == null) return;

      if (msg['error'] case final Map<String, Object?> error) {
        final message = switch (error['message']) {
          final String m => m,
          _ => 'Unknown error',
        };
        handler.completeError(StateError(message));
      } else {
        handler.complete(msg['result']);
      }
      return;
    }

    if (msg['method'] == 'notifications/message') {
      if (msg['params'] case final Map<String, Object?> params) {
        if (params['data'] case final Map<String, Object?> data) {
          if (data['event'] case final String event) {
            final timestamp = switch (data['timestamp']) {
              final int t => t,
              _ => DateTime.now().millisecondsSinceEpoch,
            };
            final payload = switch (data['payload']) {
              final Map<String, Object?> p => p,
              _ => <String, Object?>{},
            };
            _notifications.add((
              event: event,
              timestamp: timestamp,
              payload: payload,
            ));
          }
        }
      }
    }
  }

  @override
  Future<void> stop() async {
    if (_initialized && isConnected()) {
      await unsubscribe();
    }

    for (final handler in _pending.values) {
      handler.completeError(StateError('Client stopped'));
    }
    _pending.clear();

    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    await _stdoutController?.close();
    await _stderrController?.close();

    _process?.kill();
    _process = null;
    _initialized = false;

    await _notificationController?.close();
    await _logController?.close();
    await _errorController?.close();
    await _closeController?.close();
    _notificationController = null;
    _logController = null;
    _errorController = null;
    _closeController = null;
    _buffer = '';
  }

  @override
  bool isConnected() => _process != null && _initialized;
}
