/// MCP Client - communicates with Too Many Cooks server via stdio JSON-RPC.
///
/// This is the Dart port of client.ts.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:too_many_cooks_vscode_extension_dart/state/store.dart';

/// Implementation of McpClient that spawns the server process.
class McpClientImpl implements McpClient {
  /// Creates an MCP client with optional server path.
  McpClientImpl({this.serverPath});

  /// Path to the server (for testing).
  final String? serverPath;
  Process? _process;
  String _buffer = '';
  final _pending = <int, Completer<Object?>>{};
  int _nextId = 1;
  bool _initialized = false;

  final _notificationController =
      StreamController<StoreNotificationEvent>.broadcast();
  final _logController = StreamController<String>.broadcast();
  final _errorController = StreamController<Object>.broadcast();
  final _closeController = StreamController<void>.broadcast();

  @override
  Stream<StoreNotificationEvent> get notifications =>
      _notificationController.stream;

  @override
  Stream<String> get logs => _logController.stream;

  @override
  Stream<Object> get errors => _errorController.stream;

  @override
  Stream<void> get onClose => _closeController.stream;

  @override
  Future<void> start() async {
    // If serverPath is provided (testing), use node with that path
    // Otherwise use npx to run the globally installed too-many-cooks package
    final String cmd;
    final List<String> args;
    final bool useShell;

    if (serverPath != null) {
      cmd = 'node';
      args = [serverPath!];
      useShell = false;
    } else {
      cmd = 'npx';
      args = ['too-many-cooks'];
      useShell = true;
    }

    _process = await Process.start(
      cmd,
      args,
      runInShell: useShell,
    );

    // Listen to stdout for JSON-RPC messages
    _process!.stdout
        .transform(utf8.decoder)
        .listen(_onData, onError: _onError);

    // Listen to stderr for logs
    _process!.stderr.transform(utf8.decoder).listen(_logController.add);

    // Handle process exit
    unawaited(
      _process!.exitCode.then((_) {
        _closeController.add(null);
      }),
    );

    // Initialize MCP connection
    await _request('initialize', {
      'protocolVersion': '2024-11-05',
      'capabilities': <String, Object?>{},
      'clientInfo': {'name': 'too-many-cooks-vscode-dart', 'version': '0.3.0'},
    });

    // Send initialized notification
    _notify('notifications/initialized', {});
    _initialized = true;
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

  Future<Object?> _request(String method, Map<String, Object?> params) {
    final id = _nextId++;
    final completer = Completer<Object?>();
    _pending[id] = completer;
    _send({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    });
    return completer.future;
  }

  void _notify(String method, Map<String, Object?> params) {
    _send({
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
    });
  }

  void _send(Map<String, Object?> message) {
    // MCP SDK stdio uses newline-delimited JSON
    final body = '${jsonEncode(message)}\n';
    _process?.stdin.write(body);
  }

  void _onData(String chunk) {
    _buffer += chunk;
    _processBuffer();
  }

  void _onError(Object error) {
    _errorController.add(error);
  }

  void _processBuffer() {
    var newlineIndex = _buffer.indexOf('\n');
    while (newlineIndex != -1) {
      var line = _buffer.substring(0, newlineIndex);
      _buffer = _buffer.substring(newlineIndex + 1);

      // Remove trailing carriage return if present
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
        _errorController.add(e);
      }
      newlineIndex = _buffer.indexOf('\n');
    }
  }

  void _handleMessage(Map<String, Object?> msg) {
    final id = switch (msg['id']) {
      final int i => i,
      _ => null,
    };

    // Handle responses
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

    // Handle notifications
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
            _notificationController.add((
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
    // Only try to unsubscribe if we successfully initialized
    if (_initialized && isConnected()) {
      await unsubscribe();
    }

    // Reject any pending requests
    for (final handler in _pending.values) {
      handler.completeError(StateError('Client stopped'));
    }
    _pending.clear();

    _process?.kill();
    _process = null;
    _initialized = false;

    await _notificationController.close();
    await _logController.close();
    await _errorController.close();
    await _closeController.close();
  }

  @override
  bool isConnected() => _process != null && _initialized;
}
