/// Integration test - spawn MCP server process, 5 agents hit it concurrently.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:test/test.dart';

void main() {
  group('Too Many Cooks MCP Server Integration', () {
    late _McpClient client;

    setUp(() async {
      client = _McpClient();
      await client.start();
    });

    tearDown(() async {
      await client.stop();
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
          'agent_name': a.name,
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
          'agent_name': agents[0].name,
          'agent_key': agents[0].key,
        }),
        client.callTool('lock', {
          'action': 'acquire',
          'file_path': contested,
          'agent_name': agents[1].name,
          'agent_key': agents[1].key,
        }),
      ]);

      final acquired0 =
          (jsonDecode(raceResults[0]) as Map)['acquired'] == true;
      final acquired1 =
          (jsonDecode(raceResults[1]) as Map)['acquired'] == true;

      // Exactly one should win the race
      expect(acquired0 != acquired1, isTrue);
    });

    test('5 agents update plans concurrently', () async {
      final agents = await _registerAgents(client, 5);

      final planFutures = agents.map(
        (a) => client.callTool('plan', {
          'action': 'update',
          'agent_name': a.name,
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
        msgFutures.add(client.callTool('message', {
          'action': 'send',
          'agent_name': sender.name,
          'agent_key': sender.key,
          'to_agent': recipient.name,
          'content': 'Hello from ${sender.name}!',
        }));
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
        'agent_name': agents[0].name,
        'agent_key': agents[0].key,
        'to_agent': '*',
        'content': 'Broadcast!',
      });
      expect((jsonDecode(broadcastResult) as Map)['sent'], isTrue);

      // All agents except sender should receive it
      for (var i = 1; i < agents.length; i++) {
        final inboxResult = await client.callTool('message', {
          'action': 'get',
          'agent_name': agents[i].name,
          'agent_key': agents[i].key,
        });
        final json = jsonDecode(inboxResult) as Map<String, Object?>;
        final messages = json['messages']! as List;
        expect(messages.isNotEmpty, isTrue);
      }
    });

    test('status shows correct counts', () async {
      final agents = await _registerAgents(client, 5);

      // Acquire locks
      for (final a in agents) {
        await client.callTool('lock', {
          'action': 'acquire',
          'file_path': '/src/${a.name}.dart',
          'agent_name': a.name,
          'agent_key': a.key,
        });
      }

      // Update plans
      for (final a in agents) {
        await client.callTool('plan', {
          'action': 'update',
          'agent_name': a.name,
          'agent_key': a.key,
          'goal': 'Goal',
          'current_task': 'Task',
        });
      }

      // Check status
      final statusJson = jsonDecode(await client.callTool('status', {}))
          as Map<String, Object?>;
      expect((statusJson['agents']! as List).length, equals(5));
      expect((statusJson['locks']! as List).length, equals(5));
      expect((statusJson['plans']! as List).length, equals(5));
    });

    test('agents release locks concurrently', () async {
      final agents = await _registerAgents(client, 5);

      // Acquire locks
      for (final a in agents) {
        await client.callTool('lock', {
          'action': 'acquire',
          'file_path': '/src/${a.name}.dart',
          'agent_name': a.name,
          'agent_key': a.key,
        });
      }

      // Release all concurrently
      final releaseFutures = agents.map(
        (a) => client.callTool('lock', {
          'action': 'release',
          'file_path': '/src/${a.name}.dart',
          'agent_name': a.name,
          'agent_key': a.key,
        }),
      );
      final results = await Future.wait(releaseFutures);

      for (final r in results) {
        final json = jsonDecode(r) as Map<String, Object?>;
        expect(json['released'], isTrue);
      }

      // Verify no locks remain
      final status = jsonDecode(await client.callTool('status', {}))
          as Map<String, Object?>;
      expect((status['locks']! as List).length, equals(0));
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

/// MCP Client - uses content-length framing like LSP/MCP stdio transport.
class _McpClient {
  JSObject? _process;
  final _pending = <int, Completer<Map<String, Object?>>>{};
  var _nextId = 1;
  var _buffer = '';
  int? _contentLength;

  Future<void> start() async {
    final childProcess = requireModule('child_process') as JSObject;
    final spawnFn = childProcess['spawn']! as JSFunction;

    _process = spawnFn.callAsFunction(
      null,
      'node'.toJS,
      <String>['build/bin/server.js'].jsify(),
      <String, Object?>{'stdio': ['pipe', 'pipe', 'inherit']}.jsify(),
    )! as JSObject;

    final stdout = _process!['stdout']! as JSObject;
    (stdout['on']! as JSFunction).callAsFunction(
      stdout,
      'data'.toJS,
      _onData.toJS,
    );

    await _request('initialize', {
      'protocolVersion': '2024-11-05',
      'capabilities': <String, Object?>{},
      'clientInfo': {'name': 'test-client', 'version': '1.0.0'},
    });

    _notify('notifications/initialized', {});
  }

  Future<void> stop() async {
    if (_process != null) {
      (_process!['kill']! as JSFunction).callAsFunction(_process);
    }
  }

  Future<String> callTool(String name, Map<String, Object?> args) async {
    final result =
        await _request('tools/call', {'name': name, 'arguments': args});
    final content =
        (result['content']! as List).first as Map<String, Object?>;
    return content['text']! as String;
  }

  Future<Map<String, Object?>> _request(
    String method,
    Map<String, Object?> params,
  ) {
    final id = _nextId++;
    final completer = Completer<Map<String, Object?>>();
    _pending[id] = completer;

    final body = jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    });

    // LSP/MCP framing: Content-Length header + blank line + body
    final msg = 'Content-Length: ${body.length}\r\n\r\n$body';
    _write(msg);

    return completer.future;
  }

  void _notify(String method, Map<String, Object?> params) {
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
    });
    final msg = 'Content-Length: ${body.length}\r\n\r\n$body';
    _write(msg);
  }

  void _write(String data) {
    final stdin = _process!['stdin']! as JSObject;
    (stdin['write']! as JSFunction).callAsFunction(stdin, data.toJS);
  }

  void _onData(JSAny chunk) {
    final bytes = (chunk as JSUint8Array).toDart;
    _buffer += String.fromCharCodes(bytes);
    _processBuffer();
  }

  void _processBuffer() {
    while (true) {
      if (_contentLength == null) {
        // Look for Content-Length header
        final headerEnd = _buffer.indexOf('\r\n\r\n');
        if (headerEnd == -1) return;

        final headers = _buffer.substring(0, headerEnd);
        final match = RegExp(r'Content-Length:\s*(\d+)').firstMatch(headers);
        if (match == null) {
          _buffer = _buffer.substring(headerEnd + 4);
          continue;
        }
        _contentLength = int.parse(match.group(1)!);
        _buffer = _buffer.substring(headerEnd + 4);
      }

      if (_buffer.length < _contentLength!) return;

      final body = _buffer.substring(0, _contentLength);
      _buffer = _buffer.substring(_contentLength!);
      _contentLength = null;

      _handleMessage(body);
    }
  }

  void _handleMessage(String body) {
    final json = jsonDecode(body) as Map<String, Object?>;
    final id = json['id'];
    if (id != null && _pending.containsKey(id)) {
      final completer = _pending.remove(id)!;
      if (json.containsKey('error')) {
        completer.completeError(Exception('MCP error: ${json['error']}'));
      } else {
        completer.complete(json['result']! as Map<String, Object?>);
      }
    }
  }
}
