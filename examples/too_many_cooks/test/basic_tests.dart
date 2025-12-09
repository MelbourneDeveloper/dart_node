// stuff
// ignore_for_file: lines_longer_than_80_chars

/*

/// Integration test - spawn MCP server process, 5 agents hit it concurrently.
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:test/test.dart';

void main() {
  late _McpClient client;

  setUp(() async {
    // Spawn actual MCP server process
    client = _McpClient();
    await client.start();
  });

  tearDown(() async {
    await client.stop();
  });

  test('5 agents register, lock, message, plan concurrently', () async {
    // Register 5 agents concurrently
    final registerFutures = List.generate(
      5,
      (i) => client.callTool('register', {'name': 'agent$i'}),
    );
    final regResults = await Future.wait(registerFutures);
    final agents = regResults.map((r) {
      final json = jsonDecode(r) as Map<String, Object?>;
      return (name: json['agent_name']! as String, key: json['agent_key']! as String);
    }).toList();
    expect(agents.length, 5);

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
      expect(json['acquired'], true);
    }

    // Race: agent0 and agent1 try to lock SAME file
    final contested = '/contested/file.dart';
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
    final acquired0 = (jsonDecode(raceResults[0]) as Map)['acquired'] == true;
    final acquired1 = (jsonDecode(raceResults[1]) as Map)['acquired'] == true;
    expect(acquired0 != acquired1, true, reason: 'Exactly one should win');

    // All agents update plans concurrently
    final planFutures = agents.map(
      (a) => client.callTool('plan', {
        'action': 'update',
        'agent_name': a.name,
        'agent_key': a.key,
        'goal': 'Goal for ${a.name}',
        'current_task': 'Working on ${a.name}',
      }),
    );
    await Future.wait(planFutures);

    // All agents send messages concurrently
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
    await Future.wait(msgFutures);

    // Broadcast from agent0
    await client.callTool('message', {
      'action': 'send',
      'agent_name': agents[0].name,
      'agent_key': agents[0].key,
      'to_agent': '*',
      'content': 'Broadcast!',
    });

    // All agents check messages concurrently
    final inboxFutures = agents.map(
      (a) => client.callTool('message', {
        'action': 'get',
        'agent_name': a.name,
        'agent_key': a.key,
      }),
    );
    final inboxResults = await Future.wait(inboxFutures);
    for (var i = 0; i < inboxResults.length; i++) {
      final json = jsonDecode(inboxResults[i]) as Map<String, Object?>;
      final messages = json['messages']! as List;
      expect(messages.isNotEmpty, true, reason: '${agents[i].name} has messages');
    }

    // Status check
    final statusJson =
        jsonDecode(await client.callTool('status', {})) as Map<String, Object?>;
    expect((statusJson['agents']! as List).length, 5);
    expect((statusJson['locks']! as List).length, 6);
    expect((statusJson['plans']! as List).length, 5);

    // All agents release locks concurrently
    final releaseFutures = agents.map(
      (a) => client.callTool('lock', {
        'action': 'release',
        'file_path': '/src/${a.name}.dart',
        'agent_name': a.name,
        'agent_key': a.key,
      }),
    );
    await Future.wait(releaseFutures);

    // Verify
    final finalStatus =
        jsonDecode(await client.callTool('status', {})) as Map<String, Object?>;
    expect((finalStatus['locks']! as List).length, 1);
  });
}

/// MCP Client that spawns server process and communicates via JSON-RPC.
class _McpClient {
  JSObject? _process;
  final _pending = <int, void Function(Map<String, Object?>)>{};
  var _nextId = 1;
  var _buffer = '';

  Future<void> start() async {
    final childProcess = requireModule('child_process') as JSObject;
    final spawnFn = childProcess['spawn']! as JSFunction;

    // Spawn the server
    _process = spawnFn.callAsFunction(
      null,
      'node'.toJS,
      ['build/bin/server.js'].toJS,
      <String, Object?>{'stdio': ['pipe', 'pipe', 'inherit']}.jsify(),
    ) as JSObject;

    // Listen for stdout data
    final stdout = _process!['stdout']! as JSObject;
    (stdout['on']! as JSFunction).callAsFunction(
      stdout,
      'data'.toJS,
      ((JSUint8Array chunk) {
        _onData(chunk);
      }).toJS,
    );

    // Send initialize
    await _request('initialize', {
      'protocolVersion': '2024-11-05',
      'capabilities': <String, Object?>{},
      'clientInfo': {'name': 'test-client', 'version': '1.0.0'},
    });

    // Send initialized notification
    _notify('notifications/initialized', {});
  }

  Future<void> stop() async {
    if (_process != null) {
      (_process!['kill']! as JSFunction).callAsFunction(_process);
    }
  }

  Future<String> callTool(String name, Map<String, Object?> args) async {
    final result = await _request('tools/call', {'name': name, 'arguments': args});
    final content = (result['content']! as List).first as Map<String, Object?>;
    return content['text']! as String;
  }

  Future<Map<String, Object?>> _request(
    String method,
    Map<String, Object?> params,
  ) async {
    final id = _nextId++;
    final completer = <void Function(Map<String, Object?>)>[];

    final future = Future<Map<String, Object?>>((resolve) {
      _pending[id] = resolve;
    });

    final msg = jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    });
    _write('$msg\n');

    return future;
  }

  void _notify(String method, Map<String, Object?> params) {
    final msg = jsonEncode({
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
    });
    _write('$msg\n');
  }

  void _write(String data) {
    final stdin = _process!['stdin']! as JSObject;
    (stdin['write']! as JSFunction).callAsFunction(stdin, data.toJS);
  }

  void _onData(JSUint8Array chunk) {
    _buffer += String.fromCharCodes(chunk.toDart);
    while (_buffer.contains('\n')) {
      final idx = _buffer.indexOf('\n');
      final line = _buffer.substring(0, idx);
      _buffer = _buffer.substring(idx + 1);
      if (line.trim().isEmpty) continue;
      _handleMessage(line);
    }
  }

  void _handleMessage(String line) {
    final json = jsonDecode(line) as Map<String, Object?>;
    final id = json['id'];
    if (id != null && _pending.containsKey(id)) {
      final callback = _pending.remove(id)!;
      if (json.containsKey('error')) {
        throw Exception('MCP error: ${json['error']}');
      }
      callback(json['result']! as Map<String, Object?>);
    }
  }
}


*/
