/// E2E streaming test — spawn MCP server, open SSE stream on
/// /admin/events, trigger state changes via tool calls, ASSERT
/// that events arrive over the stream.
///
/// This is the PROOF that Streamable HTTP push works end-to-end.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:test/test.dart';
import 'package:too_many_cooks/too_many_cooks.dart'
    show serverBinary;

const _baseUrl = 'http://localhost:4040';
const _accept = 'application/json, text/event-stream';
const _adminEventsPath = '/admin/events';
const _mcpProtocolVersion = '2025-03-26';

void main() {
  group('Streaming E2E - SSE Events Over Streamable HTTP', () {
    // Server process shared across all tests
    // ignore: no_late
    late JSObject serverProcess;
    // MCP client for tool calls
    // ignore: no_late
    late _McpClient mcpClient;

    setUpAll(() async {
      _deleteDbFiles();
      serverProcess = _spawnServer();
      await _waitForServer();
    });

    tearDownAll(() {
      _killProcess(serverProcess);
      _deleteDbFiles();
    });

    setUp(() async {
      await _resetServer();
      mcpClient = _McpClient();
      await mcpClient.initSession();
    });

    test(
      'admin SSE stream receives event when agent registers',
      () async {
        // 1. Open admin SSE stream
        final sse = await _AdminSseClient.connect();

        // 2. Register agent via MCP tool call
        final regResult = await mcpClient.callTool(
          'register',
          {'name': 'sse-agent-1'},
        );
        final regJson =
            jsonDecode(regResult) as Map<String, Object?>;
        expect(regJson['agent_name'], equals('sse-agent-1'));

        // 3. ASSERT: SSE event arrives
        final events = await sse.waitForEvents(1);
        sse.close();

        expect(
          events.length,
          greaterThanOrEqualTo(1),
          reason:
              'MUST receive at least 1 SSE event after register',
        );
        // Verify event contains notification data
        final firstEvent = events.first;
        expect(
          firstEvent,
          contains('notifications/message'),
          reason:
              'SSE event MUST be an MCP logging notification',
        );
      },
    );

    test(
      'admin SSE stream receives events for ALL tool operations',
      () async {
        final sse = await _AdminSseClient.connect();

        // Register 2 agents
        final reg1 = jsonDecode(
          await mcpClient.callTool(
            'register',
            {'name': 'stream-all-1'},
          ),
        ) as Map<String, Object?>;
        final key1 = reg1['agent_key']! as String;

        final reg2 = jsonDecode(
          await mcpClient.callTool(
            'register',
            {'name': 'stream-all-2'},
          ),
        ) as Map<String, Object?>;

        // Wait for register events
        final regEvents = await sse.waitForEvents(2);
        expect(
          regEvents.length,
          greaterThanOrEqualTo(2),
          reason: 'MUST get events for both registrations',
        );

        // Acquire lock
        await mcpClient.callTool('lock', {
          'action': 'acquire',
          'file_path': '/stream/e2e.dart',
          'agent_key': key1,
          'reason': 'e2e test',
        });

        // Wait for lock event
        final lockEvents = await sse.waitForEvents(1);
        expect(
          lockEvents.isNotEmpty,
          isTrue,
          reason: 'MUST get SSE event for lock acquire',
        );

        // Update plan
        await mcpClient.callTool('plan', {
          'action': 'update',
          'agent_key': key1,
          'goal': 'Stream e2e goal',
          'current_task': 'Testing streaming',
        });

        // Wait for plan event
        final planEvents = await sse.waitForEvents(1);
        expect(
          planEvents.isNotEmpty,
          isTrue,
          reason: 'MUST get SSE event for plan update',
        );

        // Send message
        await mcpClient.callTool('message', {
          'action': 'send',
          'agent_key': key1,
          'to_agent': reg2['agent_name']! as String,
          'content': 'SSE e2e test message',
        });

        // Wait for message event
        final msgEvents = await sse.waitForEvents(1);
        expect(
          msgEvents.isNotEmpty,
          isTrue,
          reason: 'MUST get SSE event for message send',
        );

        // Release lock
        await mcpClient.callTool('lock', {
          'action': 'release',
          'file_path': '/stream/e2e.dart',
          'agent_key': key1,
        });

        // Wait for release event
        final releaseEvents = await sse.waitForEvents(1);
        expect(
          releaseEvents.isNotEmpty,
          isTrue,
          reason: 'MUST get SSE event for lock release',
        );

        sse.close();
      },
    );

    test(
      'SSE events contain correct payload structure',
      () async {
        final sse = await _AdminSseClient.connect();

        // Register agent
        await mcpClient.callTool(
          'register',
          {'name': 'payload-check'},
        );

        final events = await sse.waitForEvents(1);
        sse.close();

        expect(events.isNotEmpty, isTrue);

        // Parse the SSE data as JSON-RPC notification
        final eventJson =
            jsonDecode(events.first) as Map<String, Object?>;
        expect(eventJson['jsonrpc'], equals('2.0'));
        expect(
          eventJson['method'],
          equals('notifications/message'),
        );

        // Params must contain logging data
        final params =
            eventJson['params'] as Map<String, Object?>?;
        expect(params, isNotNull);
        expect(params!['level'], equals('info'));

        // Data must contain event and payload
        final data =
            params['data'] as Map<String, Object?>?;
        expect(data, isNotNull);
        expect(data!.containsKey('event'), isTrue);
        expect(data.containsKey('payload'), isTrue);
        expect(data.containsKey('timestamp'), isTrue);
        expect(
          data['event'],
          equals('agent_registered'),
          reason:
              'Event type MUST be agent_registered for register',
        );
      },
    );

    test(
      'multiple SSE clients each receive all events',
      () async {
        // Open 2 independent SSE streams
        final sse1 = await _AdminSseClient.connect();
        final sse2 = await _AdminSseClient.connect();

        // Register agent
        await mcpClient.callTool(
          'register',
          {'name': 'multi-sse-test'},
        );

        // Both clients MUST receive the event
        final events1 = await sse1.waitForEvents(1);
        final events2 = await sse2.waitForEvents(1);

        sse1.close();
        sse2.close();

        expect(
          events1.isNotEmpty,
          isTrue,
          reason: 'SSE client 1 MUST receive event',
        );
        expect(
          events2.isNotEmpty,
          isTrue,
          reason: 'SSE client 2 MUST receive event',
        );
      },
    );

    test(
      'SSE stream delivers events for concurrent tool calls',
      () async {
        final sse = await _AdminSseClient.connect();

        // Register 5 agents concurrently
        const agentCount = 5;
        final regFutures = List.generate(
          agentCount,
          (i) => mcpClient.callTool(
            'register',
            {'name': 'concurrent-$i'},
          ),
        );
        await Future.wait(regFutures);

        // MUST receive events for all 5 registrations
        final events =
            await sse.waitForEvents(agentCount);
        sse.close();

        expect(
          events.length,
          greaterThanOrEqualTo(agentCount),
          reason:
              'MUST receive $agentCount events for '
              '$agentCount concurrent registrations',
        );
      },
    );

    test(
      'admin REST push delivers events to SSE stream',
      () async {
        // Register via MCP first so agents exist
        final reg = jsonDecode(
          await mcpClient.callTool(
            'register',
            {'name': 'admin-push-agent'},
          ),
        ) as Map<String, Object?>;

        final sse = await _AdminSseClient.connect();

        // Use admin REST to send message (bypasses MCP)
        await _adminPost('/admin/send-message', {
          'fromAgent': reg['agent_name']! as String,
          'toAgent': '*',
          'content': 'Admin push test',
        });

        // SSE stream MUST receive the event
        final events = await sse.waitForEvents(1);
        sse.close();

        expect(
          events.isNotEmpty,
          isTrue,
          reason:
              'Admin REST push MUST deliver events to SSE',
        );
      },
    );

    test(
      'full round trip: register, lock, plan, message '
      'all stream as SSE events',
      () async {
        final sse = await _AdminSseClient.connect();
        final allEvents = <String>[];

        // Register
        final reg = jsonDecode(
          await mcpClient.callTool(
            'register',
            {'name': 'roundtrip-agent'},
          ),
        ) as Map<String, Object?>;
        final key = reg['agent_key']! as String;
        allEvents.addAll(await sse.waitForEvents(1));

        // Lock
        await mcpClient.callTool('lock', {
          'action': 'acquire',
          'file_path': '/roundtrip/test.dart',
          'agent_key': key,
          'reason': 'roundtrip',
        });
        allEvents.addAll(await sse.waitForEvents(1));

        // Plan
        await mcpClient.callTool('plan', {
          'action': 'update',
          'agent_key': key,
          'goal': 'Roundtrip goal',
          'current_task': 'Roundtrip task',
        });
        allEvents.addAll(await sse.waitForEvents(1));

        // Message
        await mcpClient.callTool('message', {
          'action': 'send',
          'agent_key': key,
          'to_agent': '*',
          'content': 'Roundtrip broadcast',
        });
        allEvents.addAll(await sse.waitForEvents(1));

        // Release lock
        await mcpClient.callTool('lock', {
          'action': 'release',
          'file_path': '/roundtrip/test.dart',
          'agent_key': key,
        });
        allEvents.addAll(await sse.waitForEvents(1));

        sse.close();

        // MUST have received events for all operations
        expect(
          allEvents.length,
          greaterThanOrEqualTo(5),
          reason:
              'MUST receive at least 5 SSE events for '
              'register+lock+plan+message+release',
        );

        // Extract event types from all events
        final eventTypes = allEvents.map((e) {
          final json =
              jsonDecode(e) as Map<String, Object?>;
          final params =
              json['params'] as Map<String, Object?>?;
          final data =
              params?['data'] as Map<String, Object?>?;
          return data?['event'] as String?;
        }).toList();

        expect(
          eventTypes,
          contains('agent_registered'),
          reason: 'MUST have agent_registered event',
        );
        expect(
          eventTypes,
          contains('lock_acquired'),
          reason: 'MUST have lock_acquired event',
        );
        expect(
          eventTypes,
          contains('plan_updated'),
          reason: 'MUST have plan_updated event',
        );
        expect(
          eventTypes,
          contains('message_sent'),
          reason: 'MUST have message_sent event',
        );
        expect(
          eventTypes,
          contains('lock_released'),
          reason: 'MUST have lock_released event',
        );
      },
    );
  });
}

// ============================================================
// Admin SSE Client — opens GET /admin/events and reads events
// ============================================================

class _AdminSseClient {
  _AdminSseClient._();

  final _events = <String>[];
  _SseReader? _reader;

  /// Connect: init admin session, then open GET SSE stream.
  static Future<_AdminSseClient> connect() async {
    final sessionId = await _initAdminSession();
    final client = _AdminSseClient._();
    client._reader = await _SseReader.open(
      '$_baseUrl$_adminEventsPath',
      sessionId,
      client._events,
    );
    // Give the stream a moment to establish
    await Future<void>.delayed(
      const Duration(milliseconds: 200),
    );
    return client;
  }

  /// Wait for at least [count] NEW events (beyond what
  /// we've already consumed). Timeout after 3 seconds.
  Future<List<String>> waitForEvents(
    int count, {
    int timeoutMs = 3000,
  }) async {
    final start = DateTime.now().millisecondsSinceEpoch;
    final startLen = _events.length;
    while (DateTime.now().millisecondsSinceEpoch - start <
        timeoutMs) {
      if (_events.length - startLen >= count) {
        return _events.sublist(startLen);
      }
      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );
    }
    // Return whatever we got
    return _events.sublist(startLen);
  }

  void close() {
    _reader?.abort();
  }
}

/// Initialize an admin MCP session and return the session ID.
Future<String> _initAdminSession() async {
  final headers = JSObject()
    ..['Content-Type'] = 'application/json'.toJS
    ..['Accept'] = _accept.toJS;
  final body = jsonEncode({
    'jsonrpc': '2.0',
    'id': 1,
    'method': 'initialize',
    'params': {
      'protocolVersion': _mcpProtocolVersion,
      'capabilities': <String, Object?>{},
      'clientInfo': {
        'name': 'streaming-e2e-test',
        'version': '1.0.0',
      },
    },
  });
  final options = JSObject()
    ..['method'] = 'POST'.toJS
    ..['headers'] = headers
    ..['body'] = body.toJS;

  final response = await _jsFetch(
    '$_baseUrl$_adminEventsPath'.toJS,
    options,
  ).toDart;

  final sessionId =
      _getResponseHeader(response, 'mcp-session-id');
  if (sessionId == null) {
    throw StateError('No admin session ID in response');
  }

  // Send initialized notification
  final notifyHeaders = JSObject()
    ..['Content-Type'] = 'application/json'.toJS
    ..['Accept'] = _accept.toJS
    ..['mcp-session-id'] = sessionId.toJS;
  final notifyBody = jsonEncode({
    'jsonrpc': '2.0',
    'method': 'notifications/initialized',
    'params': <String, Object?>{},
  });
  final notifyOpts = JSObject()
    ..['method'] = 'POST'.toJS
    ..['headers'] = notifyHeaders
    ..['body'] = notifyBody.toJS;
  await _jsFetch(
    '$_baseUrl$_adminEventsPath'.toJS,
    notifyOpts,
  ).toDart;

  return sessionId;
}

/// SSE stream reader — reads chunks from a GET response.
class _SseReader {
  _SseReader._(this._controller);

  final JSObject _controller;
  static const _dataPrefix = 'data: ';

  static Future<_SseReader> open(
    String url,
    String sessionId,
    List<String> events,
  ) async {
    final controller = _createAbortController();
    final signal = controller['signal']!;

    final headers = JSObject()
      ..['Accept'] = _accept.toJS
      ..['mcp-session-id'] = sessionId.toJS;
    final options = JSObject()
      ..['method'] = 'GET'.toJS
      ..['headers'] = headers
      ..['signal'] = signal;

    // Start reading in the background
    unawaited(
      _jsFetch(url.toJS, options).toDart.then(
        (response) async {
          final ok = response['ok'] as JSBoolean?;
          if (ok == null || !ok.toDart) return;

          final body = response['body'];
          if (body == null || body.isUndefinedOrNull) return;

          final reader =
              ((body as JSObject)['getReader']!
                      as JSFunction)
                  .callAsFunction(body)!
              as JSObject;
          final decoder = _createTextDecoder();
          var buffer = '';

          for (;;) {
            final chunk = await (
              (reader['read']! as JSFunction)
                      .callAsFunction(reader)!
                  as JSPromise<JSObject>
            ).toDart;

            final done = chunk['done'] as JSBoolean?;
            if (done != null && done.toDart) break;

            final value = chunk['value'];
            if (value == null || value.isUndefinedOrNull) {
              continue;
            }

            final decoded = (decoder['decode']! as JSFunction)
                .callAsFunction(
                  decoder,
                  value,
                  _streamOptions,
                )!
                as JSString;
            final buf = StringBuffer(buffer)
              ..write(decoded.toDart);
            buffer = buf.toString();

            // Parse SSE lines
            final lines = buffer.split('\n');
            buffer = lines.removeLast();
            for (final line in lines) {
              if (line.startsWith(_dataPrefix)) {
                final data =
                    line.substring(_dataPrefix.length).trim();
                if (data.isNotEmpty) {
                  events.add(data);
                }
              }
            }
          }
        },
        onError: (_) {
          // Stream aborted or errored — ignore
        },
      ),
    );

    return _SseReader._(controller);
  }

  void abort() {
    (_controller['abort']! as JSFunction)
        .callAsFunction(_controller);
  }
}

// ============================================================
// Shared HTTP / Node.js helpers
// ============================================================

@JS('globalThis.fetch')
external JSPromise<JSObject> _jsFetch(
  JSString url, [
  JSObject? options,
]);

@JS('globalThis.AbortController')
external JSFunction get _abortControllerCtor;

JSObject _createAbortController() =>
    _abortControllerCtor.callAsConstructor<JSObject>();

@JS('globalThis.TextDecoder')
external JSFunction get _textDecoderCtor;

JSObject _createTextDecoder() =>
    _textDecoderCtor.callAsConstructor<JSObject>();

final JSObject _streamOptions = JSObject()
  ..['stream'] = true.toJS;

String? _getResponseHeader(
  JSObject response,
  String name,
) {
  final headers = response['headers'] as JSObject?;
  if (headers == null) return null;
  final getFn = headers['get'] as JSFunction?;
  final value = getFn?.callAsFunction(headers, name.toJS);
  if (value == null || value.isUndefinedOrNull) return null;
  return (value as JSString).toDart;
}

Future<void> _adminPost(
  String path,
  Map<String, Object?> body,
) async {
  final headers = JSObject()
    ..['Content-Type'] = 'application/json'.toJS;
  final options = JSObject()
    ..['method'] = 'POST'.toJS
    ..['headers'] = headers
    ..['body'] = jsonEncode(body).toJS;
  await _jsFetch('$_baseUrl$path'.toJS, options).toDart;
}

// ============================================================
// MCP Client (reused from integration_test.dart pattern)
// ============================================================

class _McpClient {
  String? _sessionId;
  var _nextId = 1;

  Future<void> initSession() async {
    final initResult = await _request('initialize', {
      'protocolVersion': _mcpProtocolVersion,
      'capabilities': <String, Object?>{},
      'clientInfo': {
        'name': 'streaming-e2e-mcp',
        'version': '1.0.0',
      },
    });
    if (_sessionId == null) {
      throw StateError(
        'No session ID after init: $initResult',
      );
    }
    await _postMcp(jsonEncode({
      'jsonrpc': '2.0',
      'method': 'notifications/initialized',
      'params': <String, Object?>{},
    }));
  }

  Future<String> callTool(
    String name,
    Map<String, Object?> args,
  ) async {
    final result = await _request('tools/call', {
      'name': name,
      'arguments': args,
    });
    final content =
        (result['content']! as List).first
            as Map<String, Object?>;
    return content['text']! as String;
  }

  Future<Map<String, Object?>> _request(
    String method,
    Map<String, Object?> params,
  ) async {
    final id = _nextId++;
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    });
    final response = await _postMcp(body);
    final text = await _responseText(response);
    final json = _parseMcpResponse(text);
    if (json.containsKey('error')) {
      final error =
          json['error']! as Map<String, Object?>;
      final message =
          error['message'] as String? ?? 'Error';
      return <String, Object?>{
        'isError': true,
        'content': <Object>[
          <String, Object?>{'type': 'text', 'text': message},
        ],
      };
    }
    return json['result']! as Map<String, Object?>;
  }

  Future<JSObject> _postMcp(String body) async {
    final headers = JSObject()
      ..['Content-Type'] = 'application/json'.toJS
      ..['Accept'] = _accept.toJS;
    if (_sessionId != null) {
      headers['mcp-session-id'] = _sessionId!.toJS;
    }
    final options = JSObject()
      ..['method'] = 'POST'.toJS
      ..['headers'] = headers
      ..['body'] = body.toJS;
    final response = await _jsFetch(
      '$_baseUrl/mcp'.toJS,
      options,
    ).toDart;
    final sid = _getResponseHeader(
      response,
      'mcp-session-id',
    );
    if (sid != null) _sessionId = sid;
    return response;
  }

  Future<String> _responseText(JSObject response) async {
    final text = await (
      (response['text'] as JSFunction?)
              ?.callAsFunction(response)
          as JSPromise<JSString>?
    )?.toDart;
    return text?.toDart ?? '';
  }

  Map<String, Object?> _parseMcpResponse(String text) {
    if (text.trimLeft().startsWith('{')) {
      return jsonDecode(text) as Map<String, Object?>;
    }
    for (final line in text.split('\n')) {
      if (line.startsWith('data: ')) {
        try {
          return jsonDecode(line.substring(6))
              as Map<String, Object?>;
        } on Object {
          continue;
        }
      }
    }
    throw StateError('Could not parse: $text');
  }
}

// ============================================================
// Server lifecycle helpers
// ============================================================

JSObject _spawnServer() {
  final childProcess =
      requireModule('child_process') as JSObject;
  final spawnFn = childProcess['spawn']! as JSFunction;
  return spawnFn.callAsFunction(
    null,
    'node'.toJS,
    <String>[serverBinary].jsify(),
    <String, Object?>{
      'stdio': ['pipe', 'pipe', 'inherit'],
    }.jsify(),
  )! as JSObject;
}

void _killProcess(JSObject process) {
  (process['kill']! as JSFunction)
      .callAsFunction(process);
}

Future<void> _waitForServer() async {
  for (var i = 0; i < 30; i++) {
    try {
      final r = await _jsFetch(
        '$_baseUrl/admin/status'.toJS,
      ).toDart;
      final ok = r['ok'] as JSBoolean?;
      if (ok != null && ok.toDart) return;
    } on Object {
      // Not ready yet
    }
    if (i == 29) throw StateError('Server failed to start');
    await Future<void>.delayed(
      const Duration(milliseconds: 200),
    );
  }
}

Future<void> _resetServer() async {
  final options = JSObject()
    ..['method'] = 'POST'.toJS
    ..['headers'] = (JSObject()
      ..['Content-Type'] = 'application/json'.toJS);
  final r = await _jsFetch(
    '$_baseUrl/admin/reset'.toJS,
    options,
  ).toDart;
  final ok = r['ok'] as JSBoolean?;
  if (ok == null || !ok.toDart) {
    throw StateError('Failed to reset server');
  }
}

void _deleteDbFiles() {
  final fs = requireModule('fs') as JSObject;
  final unlinkSync = fs['unlinkSync']! as JSFunction;
  final existsSync = fs['existsSync']! as JSFunction;

  const dbDir = '.too_many_cooks';
  for (final file in [
    'data.db',
    'data.db-wal',
    'data.db-shm',
  ]) {
    final path = '$dbDir/$file';
    final exists = (existsSync.callAsFunction(
              fs,
              path.toJS,
            ) as JSBoolean?)
                ?.toDart ??
            false;
    if (exists) {
      unlinkSync.callAsFunction(fs, path.toJS);
    }
  }
}
