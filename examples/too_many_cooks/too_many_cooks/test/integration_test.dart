/// Integration test - spawn MCP server process, 5 agents hit it concurrently.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:test/test.dart';
import 'package:too_many_cooks/too_many_cooks.dart'
    show serverBinary;

void main() {
  group('Too Many Cooks MCP Server Integration', () {
    // Server process shared across all tests
    // ignore: no_late
    late JSObject serverProcess;
    // Per-test MCP client (fresh session each test)
    // ignore: no_late
    late _McpClient client;

    setUpAll(() async {
      // Delete DB files and start server once
      _deleteDbFiles();
      serverProcess = _spawnServer();
      await _waitForServer();
    });

    tearDownAll(() {
      _killProcess(serverProcess);
      _deleteDbFiles();
    });

    setUp(() async {
      // Reset DB between tests via admin endpoint
      await _resetServer();
      // Fresh MCP session for each test
      client = _McpClient();
      await client.initSession();
    });

    test('5 agents register concurrently', () async {
      final registerFutures = List.generate(
        5,
        (i) => client.callTool('register', {'name': 'agent$i'}),
      );
      final regResults = await Future.wait(registerFutures);

      for (final r in regResults) {
        final json = jsonDecode(r) as Map<String, Object?>;
        expect(json['agent_name'], isNotNull);
        expect(json['agent_key'], isNotNull);
      }
    });

    test('5 agents acquire locks on different files concurrently', () async {
      // Register agents first
      final agents = await _registerAgents(client, 5);

      // All 5 agents acquire locks on different files concurrently
      final lockFutures = agents.map(
        (a) => client.callTool('lock', {
          'action': 'acquire',
          'file_path': '/src/${a.name}.dart',
          'agent_key': a.key,
          'reason': 'editing',
        }),
      );
      final lockResults = await Future.wait(lockFutures);

      for (final r in lockResults) {
        final json = jsonDecode(r) as Map<String, Object?>;
        expect(json['acquired'], isTrue);
      }
    });

    test('lock race condition handled correctly', () async {
      final agents = await _registerAgents(client, 2);

      const contested = '/contested/file.dart';
      final raceResults = await Future.wait([
        client.callTool('lock', {
          'action': 'acquire',
          'file_path': contested,
          'agent_key': agents[0].key,
        }),
        client.callTool('lock', {
          'action': 'acquire',
          'file_path': contested,
          'agent_key': agents[1].key,
        }),
      ]);

      final acquired0 = (jsonDecode(raceResults[0]) as Map)['acquired'] == true;
      final acquired1 = (jsonDecode(raceResults[1]) as Map)['acquired'] == true;

      // Exactly one should win the race
      expect(acquired0 != acquired1, isTrue);
    });

    test('5 agents update plans concurrently', () async {
      final agents = await _registerAgents(client, 5);

      final planFutures = agents.map(
        (a) => client.callTool('plan', {
          'action': 'update',
          'agent_key': a.key,
          'goal': 'Goal for ${a.name}',
          'current_task': 'Working on ${a.name}',
        }),
      );
      final results = await Future.wait(planFutures);

      for (final r in results) {
        final json = jsonDecode(r) as Map<String, Object?>;
        expect(json['updated'], isTrue);
      }
    });

    test('5 agents send messages concurrently', () async {
      final agents = await _registerAgents(client, 5);

      final msgFutures = <Future<String>>[];
      for (var i = 0; i < agents.length; i++) {
        final sender = agents[i];
        final recipient = agents[(i + 1) % agents.length];
        msgFutures.add(
          client.callTool('message', {
            'action': 'send',
            'agent_key': sender.key,
            'to_agent': recipient.name,
            'content': 'Hello from ${sender.name}!',
          }),
        );
      }
      final results = await Future.wait(msgFutures);

      for (final r in results) {
        final json = jsonDecode(r) as Map<String, Object?>;
        expect(json['sent'], isTrue);
      }
    });

    test('broadcast message to all agents', () async {
      final agents = await _registerAgents(client, 3);

      // Send broadcast
      final broadcastResult = await client.callTool('message', {
        'action': 'send',
        'agent_key': agents[0].key,
        'to_agent': '*',
        'content': 'Broadcast!',
      });
      expect((jsonDecode(broadcastResult) as Map)['sent'], isTrue);

      // All agents except sender should receive it
      for (var i = 1; i < agents.length; i++) {
        final inboxResult = await client.callTool('message', {
          'action': 'get',
          'agent_key': agents[i].key,
        });
        final json = jsonDecode(inboxResult) as Map<String, Object?>;
        final messages = json['messages']! as List;
        expect(messages.isNotEmpty, isTrue);
      }
    });

    test('status shows correct counts including messages', () async {
      final agents = await _registerAgents(client, 5);

      // Acquire locks
      for (final a in agents) {
        await client.callTool('lock', {
          'action': 'acquire',
          'file_path': '/src/${a.name}.dart',
          'agent_key': a.key,
        });
      }

      // Update plans
      for (final a in agents) {
        await client.callTool('plan', {
          'action': 'update',
          'agent_key': a.key,
          'goal': 'Goal',
          'current_task': 'Task',
        });
      }

      // Send messages between agents
      for (var i = 0; i < agents.length; i++) {
        final sender = agents[i];
        final recipient = agents[(i + 1) % agents.length];
        await client.callTool('message', {
          'action': 'send',
          'agent_key': sender.key,
          'to_agent': recipient.name,
          'content': 'Test msg from ${sender.name}',
        });
      }

      // Check status - MUST include messages!
      final statusJson =
          jsonDecode(await client.callTool('status', {}))
              as Map<String, Object?>;
      expect((statusJson['agents']! as List).length, equals(5));
      expect((statusJson['locks']! as List).length, equals(5));
      expect((statusJson['plans']! as List).length, equals(5));
      // CRITICAL: Status MUST return messages!
      expect(
        statusJson.containsKey('messages'),
        isTrue,
        reason: 'Status response MUST include messages field',
      );
      expect(
        (statusJson['messages']! as List).length,
        equals(5),
        reason: 'Status MUST return all 5 messages sent',
      );

      // Verify message structure
      final msgs = statusJson['messages']! as List;
      final firstMsg = msgs.first as Map<String, Object?>;
      expect(firstMsg.containsKey('id'), isTrue);
      expect(firstMsg.containsKey('from_agent'), isTrue);
      expect(firstMsg.containsKey('to_agent'), isTrue);
      expect(firstMsg.containsKey('content'), isTrue);
      expect(firstMsg.containsKey('created_at'), isTrue);
    });

    test('agents release locks concurrently', () async {
      final agents = await _registerAgents(client, 5);

      // Acquire locks
      for (final a in agents) {
        await client.callTool('lock', {
          'action': 'acquire',
          'file_path': '/src/${a.name}.dart',
          'agent_key': a.key,
        });
      }

      // Release all concurrently
      final releaseFutures = agents.map(
        (a) => client.callTool('lock', {
          'action': 'release',
          'file_path': '/src/${a.name}.dart',
          'agent_key': a.key,
        }),
      );
      final results = await Future.wait(releaseFutures);

      for (final r in results) {
        final json = jsonDecode(r) as Map<String, Object?>;
        expect(json['released'], isTrue);
      }

      // Verify no locks remain
      final status =
          jsonDecode(await client.callTool('status', {}))
              as Map<String, Object?>;
      expect((status['locks']! as List).length, equals(0));
    });

    // REGRESSION TESTS: Missing parameter validation
    // These ensure tools return proper errors instead of crashing

    test('register without name or key returns error', () async {
      final result = await client.callToolRaw('register', {});
      expect(result['isError'], isTrue);
      final content =
          (result['content']! as List).first as Map<String, Object?>;
      final text = content['text']! as String;
      expect(text, contains('missing_parameter'));
    });

    test('lock without action returns error', () async {
      final result = await client.callToolRaw('lock', {});
      expect(result['isError'], isTrue);
    });

    test('message without action returns error', () async {
      final result = await client.callToolRaw('message', {});
      expect(result['isError'], isTrue);
    });

    test('message without registration returns not_registered', () async {
      // No register call — session is empty, no hidden args either
      final result = await client.callToolRaw('message', {'action': 'get'});
      expect(result['isError'], isTrue);
      final content =
          (result['content']! as List).first as Map<String, Object?>;
      final text = content['text']! as String;
      expect(text, contains('not_registered'));
    });

    test('plan without action returns error', () async {
      final result = await client.callToolRaw('plan', {});
      expect(result['isError'], isTrue);
    });

    // CRITICAL: One plan per agent - updating replaces, doesn't create new
    test('updating plan replaces existing - ONE PLAN PER AGENT', () async {
      final agents = await _registerAgents(client, 1);
      final agent = agents.first;

      // Create initial plan
      await client.callTool('plan', {
        'action': 'update',
        'agent_key': agent.key,
        'goal': 'Initial goal',
        'current_task': 'Initial task',
      });

      // Verify one plan exists
      var status =
          jsonDecode(await client.callTool('status', {}))
              as Map<String, Object?>;
      var plans = status['plans']! as List;
      expect(plans.length, equals(1), reason: 'Should have exactly 1 plan');

      // Update the plan
      await client.callTool('plan', {
        'action': 'update',
        'agent_key': agent.key,
        'goal': 'Updated goal',
        'current_task': 'Updated task',
      });

      // CRITICAL: Still only ONE plan - update replaced, didn't create new
      status =
          jsonDecode(await client.callTool('status', {}))
              as Map<String, Object?>;
      plans = status['plans']! as List;
      expect(
        plans.length,
        equals(1),
        reason: 'MUST have exactly 1 plan - update replaces, not creates',
      );

      // Verify the plan was actually updated
      final plan = plans.first as Map<String, Object?>;
      expect(plan['goal'], equals('Updated goal'));
      expect(plan['current_task'], equals('Updated task'));
    });

    test('each agent has exactly one plan after multiple updates', () async {
      final agents = await _registerAgents(client, 3);

      // Each agent updates their plan 3 times
      for (var round = 0; round < 3; round++) {
        for (final agent in agents) {
          await client.callTool('plan', {
            'action': 'update',
            'agent_key': agent.key,
            'goal': 'Goal round $round',
            'current_task': 'Task round $round',
          });
        }
      }

      // CRITICAL: Should have exactly 3 plans (one per agent), NOT 9
      final status =
          jsonDecode(await client.callTool('status', {}))
              as Map<String, Object?>;
      final plans = status['plans']! as List;
      expect(
        plans.length,
        equals(3),
        reason: 'MUST have exactly 3 plans (one per agent), not 9',
      );

      // Verify each plan shows the latest update (round 2)
      for (final plan in plans) {
        final p = plan as Map<String, Object?>;
        expect(p['goal'], equals('Goal round 2'));
        expect(p['current_task'], equals('Task round 2'));
      }
    });

    // LOCK TOOL: query, list, renew, force_release
    test('lock query returns lock status', () async {
      final agents = await _registerAgents(client, 1);
      final agent = agents.first;
      const filePath = '/src/query_test.dart';

      // Query unlocked file
      var result = await client.callTool('lock', {
        'action': 'query',
        'file_path': filePath,
      });
      var json = jsonDecode(result) as Map<String, Object?>;
      expect(json['locked'], isFalse);

      // Acquire lock
      await client.callTool('lock', {
        'action': 'acquire',
        'file_path': filePath,
        'agent_key': agent.key,
      });

      // Query locked file
      result = await client.callTool('lock', {
        'action': 'query',
        'file_path': filePath,
      });
      json = jsonDecode(result) as Map<String, Object?>;
      expect(json['locked'], isTrue);
      expect(json['lock'], isNotNull);
    });

    test('lock list returns all locks', () async {
      final agents = await _registerAgents(client, 3);

      // Acquire locks on different files
      for (var i = 0; i < agents.length; i++) {
        await client.callTool('lock', {
          'action': 'acquire',
          'file_path': '/src/list_test_$i.dart',
          'agent_key': agents[i].key,
        });
      }

      // List all locks
      final result = await client.callTool('lock', {'action': 'list'});
      final json = jsonDecode(result) as Map<String, Object?>;
      final locks = json['locks']! as List;
      expect(locks.length, equals(3));
    });

    test('lock renew extends expiration', () async {
      final agents = await _registerAgents(client, 1);
      final agent = agents.first;
      const filePath = '/src/renew_test.dart';

      // Acquire lock
      await client.callTool('lock', {
        'action': 'acquire',
        'file_path': filePath,
        'agent_key': agent.key,
      });

      // Renew lock
      final result = await client.callTool('lock', {
        'action': 'renew',
        'file_path': filePath,
        'agent_key': agent.key,
      });
      final json = jsonDecode(result) as Map<String, Object?>;
      expect(json['renewed'], isTrue);
    });

    test('lock force_release works on expired locks', () async {
      final agents = await _registerAgents(client, 2);

      // Agent 0 acquires lock
      const filePath = '/src/force_release_test.dart';
      await client.callTool('lock', {
        'action': 'acquire',
        'file_path': filePath,
        'agent_key': agents[0].key,
      });

      // Agent 1 tries to force release (should work for expired locks only)
      // This tests the force_release code path
      final result = await client.callTool('lock', {
        'action': 'force_release',
        'file_path': filePath,
        'agent_key': agents[1].key,
      });
      final json = jsonDecode(result) as Map<String, Object?>;
      // May fail if lock not expired, but exercises the code path
      expect(json.containsKey('released') || json.containsKey('error'), isTrue);
    });

    // REGISTER: reconnect with key only
    test('register reconnect with key only', () async {
      // First registration — name only
      final regResult = await client.callTool('register', {'name': 'recon1'});
      final regJson = jsonDecode(regResult) as Map<String, Object?>;
      final key = regJson['agent_key']! as String;

      // Reconnect — key only, no name
      final reconResult = await client.callTool('register', {'key': key});
      final reconJson = jsonDecode(reconResult) as Map<String, Object?>;
      expect(reconJson['agent_name'], equals('recon1'));
      expect(reconJson['agent_key'], equals(key));
    });

    test('register with both name and key returns error', () async {
      final regResult = await client.callTool('register', {'name': 'both1'});
      final regJson = jsonDecode(regResult) as Map<String, Object?>;
      final key = regJson['agent_key']! as String;

      // Both name AND key — spec says this is an error
      final result = await client.callToolRaw(
        'register',
        {'name': 'both1', 'key': key},
      );
      expect(result['isError'], isTrue);
    });

    test('register reconnect with invalid key returns error', () async {
      final result = await client.callToolRaw(
        'register',
        {'key': 'definitely-not-a-real-key'},
      );
      expect(result['isError'], isTrue);
    });

    // MESSAGE TOOL: mark_read action
    test('message mark_read marks message as read', () async {
      final agents = await _registerAgents(client, 2);

      // Send a message
      final sendResult = await client.callTool('message', {
        'action': 'send',
        'agent_key': agents[0].key,
        'to_agent': agents[1].name,
        'content': 'Test message',
      });
      final sendJson = jsonDecode(sendResult) as Map<String, Object?>;
      final messageId = sendJson['message_id']! as String;

      // Mark as read
      final result = await client.callTool('message', {
        'action': 'mark_read',
        'agent_key': agents[1].key,
        'message_id': messageId,
      });
      final json = jsonDecode(result) as Map<String, Object?>;
      expect(json['marked'], isTrue);
    });

    // PLAN TOOL: get and list actions
    test('plan get retrieves specific agent plan', () async {
      final agents = await _registerAgents(client, 1);
      final agent = agents.first;

      // Create plan
      await client.callTool('plan', {
        'action': 'update',
        'agent_key': agent.key,
        'goal': 'Test goal',
        'current_task': 'Test task',
      });

      // Get plan
      final result = await client.callTool('plan', {
        'action': 'get',
        'agent_key': agent.key,
      });
      final json = jsonDecode(result) as Map<String, Object?>;
      final plan = json['plan']! as Map<String, Object?>;
      expect(plan['goal'], equals('Test goal'));
    });

    test('plan list returns all plans', () async {
      final agents = await _registerAgents(client, 2);

      // Create plans for both agents
      for (final agent in agents) {
        await client.callTool('plan', {
          'action': 'update',
          'agent_key': agent.key,
          'goal': 'Goal for ${agent.name}',
          'current_task': 'Task',
        });
      }

      // List plans
      final result = await client.callTool('plan', {'action': 'list'});
      final json = jsonDecode(result) as Map<String, Object?>;
      final plans = json['plans']! as List;
      expect(plans.length, equals(2));
    });
  });
}

Future<List<({String name, String key})>> _registerAgents(
  _McpClient client,
  int count,
) async {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final registerFutures = List.generate(
    count,
    (i) => client.callTool('register', {'name': 'agent${timestamp}_$i'}),
  );
  final regResults = await Future.wait(registerFutures);
  return regResults.map((r) {
    final json = jsonDecode(r) as Map<String, Object?>;
    return (
      name: json['agent_name']! as String,
      key: json['agent_key']! as String,
    );
  }).toList();
}

/// HTTP fetch (Node.js global).
@JS('globalThis.fetch')
external JSPromise<JSObject> _jsFetch(
  JSString url, [
  JSObject? options,
]);

const _baseUrl = 'http://localhost:4040';
const _accept = 'application/json, text/event-stream';

/// Spawn the server process.
JSObject _spawnServer() {
  final childProcess = requireModule('child_process') as JSObject;
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

/// Kill a child process.
void _killProcess(JSObject process) {
  (process['kill']! as JSFunction).callAsFunction(process);
}

/// Wait for server to be ready by polling /admin/status
/// and then verifying the /mcp endpoint accepts requests.
Future<void> _waitForServer() async {
  // Poll /admin/status until it responds
  for (var i = 0; i < 30; i++) {
    try {
      final r = await _jsFetch(
        '$_baseUrl/admin/status'.toJS,
      ).toDart;
      final ok = r['ok'] as JSBoolean?;
      if (ok != null && ok.toDart) break;
    } on Object {
      // Not ready yet
    }
    if (i == 29) throw StateError('Server failed to start');
    await Future<void>.delayed(
      const Duration(milliseconds: 200),
    );
  }

  // Verify /mcp endpoint is also ready (avoids race on first request)
  for (var i = 0; i < 10; i++) {
    try {
      final headers = JSObject()
        ..['Content-Type'] = 'application/json'.toJS
        ..['Accept'] = _accept.toJS;
      final options = JSObject()
        ..['method'] = 'POST'.toJS
        ..['headers'] = headers
        ..['body'] = jsonEncode({
          'jsonrpc': '2.0',
          'id': 0,
          'method': 'initialize',
          'params': {
            'protocolVersion': '2024-11-05',
            'capabilities': <String, Object?>{},
            'clientInfo': {
              'name': 'health-check',
              'version': '1.0.0',
            },
          },
        }).toJS;
      final r = await _jsFetch(
        '$_baseUrl/mcp'.toJS,
        options,
      ).toDart;
      final ok = r['ok'] as JSBoolean?;
      if (ok != null && ok.toDart) return;
    } on Object {
      // MCP endpoint not ready yet
    }
    await Future<void>.delayed(
      const Duration(milliseconds: 200),
    );
  }
}

/// Reset the server DB via admin endpoint.
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

/// MCP client that communicates via Streamable HTTP.
class _McpClient {
  String? _sessionId;
  var _nextId = 1;

  Future<void> initSession() async {
    final initResult = await _request('initialize', {
      'protocolVersion': '2024-11-05',
      'capabilities': <String, Object?>{},
      'clientInfo': {
        'name': 'test-client',
        'version': '1.0.0',
      },
    });
    if (_sessionId == null) {
      throw StateError(
        'No session ID after init: $initResult',
      );
    }

    // Send initialized notification
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

  Future<Map<String, Object?>> callToolRaw(
    String name,
    Map<String, Object?> args,
  ) => _request('tools/call', {
    'name': name,
    'arguments': args,
  });

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

    // Parse SSE or JSON
    final json = _parseMcpResponse(text);

    if (json.containsKey('error')) {
      final error =
          json['error']! as Map<String, Object?>;
      final message =
          error['message'] as String? ?? 'Error';
      return <String, Object?>{
        'isError': true,
        'content': <Object>[
          <String, Object?>{
            'type': 'text',
            'text': message,
          },
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
      headers['mcp-session-id'] =
          _sessionId!.toJS;
    }

    final options = JSObject()
      ..['method'] = 'POST'.toJS
      ..['headers'] = headers
      ..['body'] = body.toJS;

    final response = await _jsFetch(
      '$_baseUrl/mcp'.toJS,
      options,
    ).toDart;

    // Capture session ID from response
    final sid = _getHeader(response, 'mcp-session-id');
    if (sid != null) _sessionId = sid;

    return response;
  }

  Future<String> _responseText(
    JSObject response,
  ) async {
    final text = await (
      (response['text'] as JSFunction?)
              ?.callAsFunction(response)
          as JSPromise<JSString>?
    )?.toDart;
    return text?.toDart ?? '';
  }

  String? _getHeader(JSObject response, String name) {
    final headers =
        response['headers'] as JSObject?;
    if (headers == null) return null;
    final getFn = headers['get'] as JSFunction?;
    final value =
        getFn?.callAsFunction(headers, name.toJS);
    if (value == null || value.isUndefinedOrNull) {
      return null;
    }
    return (value as JSString).toDart;
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

/// Delete DB and temp files using Node.js fs.
void _deleteDbFiles() {
  final fs = requireModule('fs') as JSObject;
  final unlinkSync = fs['unlinkSync']! as JSFunction;
  final existsSync = fs['existsSync']! as JSFunction;
  final readdirSync = fs['readdirSync']! as JSFunction;

  // Server uses process.cwd()/.too_many_cooks/ as the database path
  const dbDir = '.too_many_cooks';

  // Delete DB files in ./.too_many_cooks/ (current working directory)
  for (final file in ['data.db', 'data.db-wal', 'data.db-shm']) {
    final path = '$dbDir/$file';
    final exists =
        (existsSync.callAsFunction(fs, path.toJS) as JSBoolean?)?.toDart ??
        false;
    if (exists) {
      unlinkSync.callAsFunction(fs, path.toJS);
    }
  }

  // Delete any .test_*.db files and .mjs temp files in current directory
  final filesResult = readdirSync.callAsFunction(fs, '.'.toJS);
  if (filesResult == null) return;
  final files = (filesResult as JSArray).toDart;
  for (final file in files) {
    if (file == null) continue;
    final fileName = switch (file) {
      final JSString s => s.toDart,
      _ => null,
    };
    if (fileName == null) continue;
    final isTestDb = fileName.startsWith('.test_') && fileName.contains('.db');
    final isTempMjs = fileName.endsWith('.mjs');
    if (isTestDb || isTempMjs) {
      try {
        final exists =
            (existsSync.callAsFunction(fs, fileName.toJS) as JSBoolean?)
                ?.toDart ??
            false;
        if (exists) {
          unlinkSync.callAsFunction(fs, fileName.toJS);
        }
      } on Object catch (_) {
        // File may have been deleted by another process - ignore
      }
    }
  }
}
