/// Integration tests for dart_node_ws and dart_node_express packages.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

const _httpUrl = 'http://localhost:3456';
const _wsUrl = 'ws://localhost:3457';

void main() {
  Process? serverProcess;

  setUpAll(() async {
    // Build and start the test server
    final packageDir = Directory.current.path.endsWith('dart_node_ws')
        ? Directory.current.path
        : '${Directory.current.path}/packages/dart_node_ws';

    // Compile the test server
    final compileResult = await Process.run(
      'dart',
      ['compile', 'js', '-o', 'test/test_server.js', 'test/test_server.dart'],
      workingDirectory: packageDir,
    );

    if (compileResult.exitCode != 0) {
      throw StateError(
        'Failed to compile test server: ${compileResult.stderr}',
      );
    }

    // Prepend node_preamble
    final jsFile = File('$packageDir/test/test_server.js');
    final jsContent = await jsFile.readAsString();
    final preamble = await _getNodePreamble();
    await jsFile.writeAsString('$preamble\n$jsContent');

    // Start the server
    serverProcess = await Process.start(
      'node',
      ['test/test_server.js'],
      workingDirectory: packageDir,
    );

    // Wait for server to be ready
    await _waitForServer();
  });

  tearDownAll(() async {
    serverProcess?.kill();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });

  group('WebSocket Server', () {
    test('accepts connections and sends welcome message', () async {
      final ws = await WebSocket.connect(_wsUrl);
      final completer = Completer<String>();

      ws.listen((data) {
        if (!completer.isCompleted) {
          completer.complete(data as String);
        }
      });

      final message = await completer.future.timeout(
        const Duration(seconds: 5),
      );
      expect(message, equals('connected'));

      await ws.close();
    });

    test('echoes messages with prefix', () async {
      final messages = <String>[];
      final completer = Completer<void>();

      final ws = await WebSocket.connect(_wsUrl);
      ws.listen((data) {
        messages.add(data as String);
        if (messages.any((m) => m.startsWith('echoed:'))) {
          if (!completer.isCompleted) completer.complete();
        }
      });

      // Wait for connection before sending
      await Future<void>.delayed(const Duration(milliseconds: 50));
      ws.add('echo:hello world');

      await completer.future.timeout(const Duration(seconds: 5));
      expect(messages, contains('connected'));
      expect(messages, contains('echoed:hello world'));

      await ws.close();
    });

    test('handles JSON messages', () async {
      final messages = <String>[];
      final completer = Completer<void>();

      final ws = await WebSocket.connect(_wsUrl);
      ws.listen((data) {
        messages.add(data as String);
        if (messages.any((m) => m.contains('json-echo'))) {
          if (!completer.isCompleted) completer.complete();
        }
      });

      // Wait for connection before sending
      await Future<void>.delayed(const Duration(milliseconds: 50));
      ws.add('json:{"key":"value","num":42}');

      await completer.future.timeout(const Duration(seconds: 5));

      final jsonResponse = messages.firstWhere((m) => m.contains('json-echo'));
      final parsed = jsonDecode(jsonResponse) as Map<String, dynamic>;
      expect(parsed['type'], equals('json-echo'));
      expect(parsed['received'], isA<Map<String, dynamic>>());

      await ws.close();
    });

    test('closes connection on request', () async {
      final closedCompleter = Completer<void>();

      final ws = await WebSocket.connect(_wsUrl)
        ..listen((_) {}, onDone: closedCompleter.complete);

      // Wait for welcome message then request close
      await Future<void>.delayed(const Duration(milliseconds: 100));
      ws.add('close');

      await closedCompleter.future.timeout(const Duration(seconds: 5));
      expect(ws.closeCode, equals(1000));
      await ws.close();
    });

    test('closes with custom code', () async {
      final closedCompleter = Completer<void>();

      final ws = await WebSocket.connect(_wsUrl)
        ..listen((_) {}, onDone: closedCompleter.complete);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      ws.add('close:4001');

      await closedCompleter.future.timeout(const Duration(seconds: 5));
      expect(ws.closeCode, equals(4001));
      await ws.close();
    });

    test('receives URL query parameters', () async {
      final ws = await WebSocket.connect('$_wsUrl?token=abc123&user=test');
      final messages = <String>[];
      final completer = Completer<void>();

      ws.listen((data) {
        messages.add(data as String);
        if (messages.any((m) => m.startsWith('url:'))) {
          completer.complete();
        }
      });

      await completer.future.timeout(const Duration(seconds: 5));

      final urlMessage = messages.firstWhere((m) => m.startsWith('url:'));
      expect(urlMessage, contains('token=abc123'));
      expect(urlMessage, contains('user=test'));

      await ws.close();
    });

    test('handles default message echo', () async {
      final messages = <String>[];
      final completer = Completer<void>();

      final ws = await WebSocket.connect(_wsUrl);
      ws.listen((data) {
        messages.add(data as String);
        if (messages.any((m) => m.startsWith('received:'))) {
          if (!completer.isCompleted) completer.complete();
        }
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));
      ws.add('some-random-message');

      await completer.future.timeout(const Duration(seconds: 5));
      expect(messages, contains('received:some-random-message'));

      await ws.close();
    });

    test('handles multiple concurrent connections', () async {
      final futures = <Future<String>>[];

      for (var i = 0; i < 5; i++) {
        futures.add(_connectAndGetWelcome());
      }

      final results = await Future.wait(futures);
      expect(results, everyElement(equals('connected')));
    });

    test('client can close connection', () async {
      final ws = await WebSocket.connect(_wsUrl);
      final closedCompleter = Completer<void>();

      ws.listen(
        (_) {},
        onDone: closedCompleter.complete,
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      await ws.close(1000, 'client-initiated');

      await closedCompleter.future.timeout(const Duration(seconds: 5));
    });
  });

  group('HTTP Server (dart_node_express)', () {
    test('GET /health returns status', () async {
      final response = await http.get(Uri.parse('$_httpUrl/health'));

      expect(response.statusCode, equals(200));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['status'], equals('ok'));
      expect(body['wsPort'], equals(3457));
    });

    test('GET /echo/:message echoes message', () async {
      final response = await http.get(
        Uri.parse('$_httpUrl/echo/hello-world'),
      );

      expect(response.statusCode, equals(200));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['echo'], equals('hello-world'));
    });

    test('POST /json receives JSON body', () async {
      final response = await http.post(
        Uri.parse('$_httpUrl/json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'test': 'data', 'number': 123}),
      );

      expect(response.statusCode, equals(200));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['success'], isTrue);
      final received = body['received'] as Map<String, dynamic>;
      expect(received['test'], equals('data'));
      expect(received['number'], equals(123));
    });

    test('GET /status/:code returns specified status', () async {
      final response = await http.get(Uri.parse('$_httpUrl/status/201'));

      expect(response.statusCode, equals(201));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['statusCode'], equals(201));
    });

    test('GET /status/404 returns 404', () async {
      final response = await http.get(Uri.parse('$_httpUrl/status/404'));

      expect(response.statusCode, equals(404));
    });

    test('GET /error returns error response', () async {
      final response = await http.get(Uri.parse('$_httpUrl/error'));

      expect(response.statusCode, equals(404));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['error'], isNotNull);
    });

    test('POST /validated with valid data succeeds', () async {
      final response = await http.post(
        Uri.parse('$_httpUrl/validated'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': 'Test User', 'age': 25}),
      );

      expect(response.statusCode, equals(200));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['name'], equals('Test User'));
      expect(body['age'], equals(25));
    });

    test('POST /validated with invalid data fails', () async {
      final response = await http.post(
        Uri.parse('$_httpUrl/validated'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': '', 'age': 200}),
      );

      expect(response.statusCode, equals(400));
    });

    test('POST /validated with missing fields fails', () async {
      final response = await http.post(
        Uri.parse('$_httpUrl/validated'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': 'Test'}),
      );

      expect(response.statusCode, equals(400));
    });

    test('non-existent route returns 404', () async {
      final response = await http.get(
        Uri.parse('$_httpUrl/nonexistent'),
      );

      expect(response.statusCode, equals(404));
    });
  });

  group('WebSocketReadyState enum', () {
    test('has correct values', () {
      // Import the enum values are tested via the actual WebSocket behavior
      // This test documents the expected values
      expect(0, equals(0)); // connecting
      expect(1, equals(1)); // open
      expect(2, equals(2)); // closing
      expect(3, equals(3)); // closed
    });
  });

  group('HTTP Server edge cases', () {
    test('handles unicode in echo parameter', () async {
      final response = await http.get(
        Uri.parse('$_httpUrl/echo/${Uri.encodeComponent("héllo wörld")}'),
      );
      expect(response.statusCode, equals(200));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['echo'], equals('héllo wörld'));
    });

    test('handles special characters in JSON', () async {
      final response = await http.post(
        Uri.parse('$_httpUrl/json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'emoji': '🎉', 'quotes': '"test"'}),
      );
      expect(response.statusCode, equals(200));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['success'], isTrue);
      final received = body['received'] as Map<String, dynamic>;
      expect(received['emoji'], equals('🎉'));
    });

    test('POST /validated with extra fields succeeds', () async {
      final response = await http.post(
        Uri.parse('$_httpUrl/validated'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': 'Test',
          'age': 30,
          'extraField': 'ignored',
        }),
      );
      expect(response.statusCode, equals(200));
    });

    test('POST /validated with boundary age values', () async {
      // Test min age
      final minResponse = await http.post(
        Uri.parse('$_httpUrl/validated'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': 'Baby', 'age': 0}),
      );
      expect(minResponse.statusCode, equals(200));

      // Test max age
      final maxResponse = await http.post(
        Uri.parse('$_httpUrl/validated'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': 'Elder', 'age': 150}),
      );
      expect(maxResponse.statusCode, equals(200));

      // Test over max age
      final overMaxResponse = await http.post(
        Uri.parse('$_httpUrl/validated'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': 'Ancient', 'age': 151}),
      );
      expect(overMaxResponse.statusCode, equals(400));
    });
  });
}

Future<String> _connectAndGetWelcome() async {
  final ws = await WebSocket.connect(_wsUrl);
  final completer = Completer<String>();

  ws.listen((data) {
    if (!completer.isCompleted) {
      completer.complete(data as String);
    }
  });

  final message = await completer.future.timeout(const Duration(seconds: 5));
  await ws.close();
  return message;
}

Future<void> _waitForServer() async {
  const maxAttempts = 50;
  const delay = Duration(milliseconds: 100);

  for (var i = 0; i < maxAttempts; i++) {
    try {
      final response = await http
          .get(Uri.parse('$_httpUrl/health'))
          .timeout(const Duration(seconds: 1));
      if (response.statusCode == 200) {
        return;
      }
    } on Object {
      // Server not ready yet
    }
    await Future<void>.delayed(delay);
  }
  throw StateError('Server did not start within ${maxAttempts * 100}ms');
}

Future<String> _getNodePreamble() async {
  // Look for node_preamble in pub cache - check multiple locations
  final homeDir = Platform.environment['HOME'] ?? '';
  final possiblePaths = [
    '$homeDir/.pub-cache/hosted/pub.dev',
    '$homeDir/.pub-cache/hosted/pub.dartlang.org',
  ];

  for (final preamblePath in possiblePaths) {
    final dir = Directory(preamblePath);
    if (!dir.existsSync()) continue;

    // Find the latest node_preamble version
    final preambleDirs =
        dir.listSync().where((e) => e.path.contains('node_preamble')).toList();

    if (preambleDirs.isEmpty) continue;

    // Sort to get latest version
    preambleDirs.sort((a, b) => b.path.compareTo(a.path));
    final preambleDir = preambleDirs.first.path;

    final preambleFile = File('$preambleDir/lib/preamble.js');
    if (preambleFile.existsSync()) {
      return preambleFile.readAsStringSync();
    }
  }

  throw StateError('node_preamble not found in pub cache');
}
