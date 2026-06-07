import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

const _baseUrl = 'http://localhost:3000';

void main() {
  Process? serverProcess;

  setUpAll(() async {
    final currentDir = Directory.current.path;
    serverProcess = await Process.start('node', [
      'build/server.js',
    ], workingDirectory: currentDir);
    await Future<void>.delayed(const Duration(seconds: 2));
  });

  tearDownAll(() {
    serverProcess?.kill();
  });

  group('Pomodoro endpoints', () {
    late String authToken;

    setUp(() async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'pomodoro_$timestamp@test.com';
      final registerResponse = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': 'password123',
          'name': 'Pomodoro Test User',
        }),
      );
      final body = jsonDecode(registerResponse.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      authToken = data['token'] as String;
    });

    test('POST /pomodoro/start requires authentication', () async {
      final response = await http.post(
        Uri.parse('$_baseUrl/pomodoro/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': 'Test Session'}),
      );
      expect(response.statusCode, equals(401));
    });

    test('GET /pomodoro/active returns null initially', () async {
      final response = await http.get(
        Uri.parse('$_baseUrl/pomodoro/active'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      expect(response.statusCode, equals(200));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['success'], isTrue);
      expect(body['data'], isNull);
    });

    test('POST /pomodoro/start creates and starts a session', () async {
      final response = await http.post(
        Uri.parse('$_baseUrl/pomodoro/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'title': 'Focus Session',
          'duration': 25,
          'breakDuration': 5,
        }),
      );
      expect(response.statusCode, equals(201));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['success'], isTrue);
      final data = body['data'] as Map<String, dynamic>;
      expect(data['title'], equals('Focus Session'));
      expect(data['duration'], equals(25));
      expect(data['breakDuration'], equals(5));
      expect(data['startedAt'], isNotNull);
    });

    test('POST /pomodoro/:id/pause pauses the session', () async {
      final startResponse = await http.post(
        Uri.parse('$_baseUrl/pomodoro/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'title': 'Pause Test Session'}),
      );
      final startBody = jsonDecode(startResponse.body) as Map<String, dynamic>;
      final startData = startBody['data'] as Map<String, dynamic>;
      final sessionId = startData['id'] as String;

      final response = await http.post(
        Uri.parse('$_baseUrl/pomodoro/$sessionId/pause'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      expect(response.statusCode, equals(200));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['success'], isTrue);
    });

    test('POST /pomodoro/:id/resume resumes the session', () async {
      final startResponse = await http.post(
        Uri.parse('$_baseUrl/pomodoro/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'title': 'Resume Test Session'}),
      );
      final startBody = jsonDecode(startResponse.body) as Map<String, dynamic>;
      final startData = startBody['data'] as Map<String, dynamic>;
      final sessionId = startData['id'] as String;

      await http.post(
        Uri.parse('$_baseUrl/pomodoro/$sessionId/pause'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/pomodoro/$sessionId/resume'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      expect(response.statusCode, equals(200));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['success'], isTrue);
    });

    test('POST /pomodoro/:id/complete completes the session', () async {
      final startResponse = await http.post(
        Uri.parse('$_baseUrl/pomodoro/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'title': 'Complete Test Session'}),
      );
      final startBody = jsonDecode(startResponse.body) as Map<String, dynamic>;
      final startData = startBody['data'] as Map<String, dynamic>;
      final sessionId = startData['id'] as String;

      final response = await http.post(
        Uri.parse('$_baseUrl/pomodoro/$sessionId/complete'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      expect(response.statusCode, equals(200));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['success'], isTrue);
      final data = body['data'] as Map<String, dynamic>;
      expect(data['completedAt'], isNotNull);
    });

    test('GET /pomodoro/active returns session after start', () async {
      await http.post(
        Uri.parse('$_baseUrl/pomodoro/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'title': 'Active Session'}),
      );

      final response = await http.get(
        Uri.parse('$_baseUrl/pomodoro/active'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      expect(response.statusCode, equals(200));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['success'], isTrue);
      final data = body['data'] as Map<String, dynamic>;
      expect(data['title'], equals('Active Session'));
    });

    test('POST /pomodoro/start uses default duration values', () async {
      final response = await http.post(
        Uri.parse('$_baseUrl/pomodoro/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'title': 'Default Duration Session'}),
      );
      expect(response.statusCode, equals(201));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      expect(data['duration'], equals(25));
      expect(data['breakDuration'], equals(5));
    });

    test('POST /pomodoro/:id/pause returns 404 for non-existent', () async {
      final response = await http.post(
        Uri.parse('$_baseUrl/pomodoro/nonexistent/pause'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      expect(response.statusCode, equals(404));
    });

    test('POST /pomodoro/:id/resume returns 404 for non-existent', () async {
      final response = await http.post(
        Uri.parse('$_baseUrl/pomodoro/nonexistent/resume'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      expect(response.statusCode, equals(404));
    });

    test('POST /pomodoro/:id/complete returns 404 for non-existent', () async {
      final response = await http.post(
        Uri.parse('$_baseUrl/pomodoro/nonexistent/complete'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      expect(response.statusCode, equals(404));
    });

    test('POST /pomodoro/start can link to a task', () async {
      final taskResponse = await http.post(
        Uri.parse('$_baseUrl/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'title': 'Linked Task'}),
      );
      final taskBody = jsonDecode(taskResponse.body) as Map<String, dynamic>;
      final taskData = taskBody['data'] as Map<String, dynamic>;
      final taskId = taskData['id'] as String;

      final response = await http.post(
        Uri.parse('$_baseUrl/pomodoro/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'title': 'Task-linked Session',
          'linkedTaskId': taskId,
        }),
      );
      expect(response.statusCode, equals(201));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      expect(data['linkedTaskId'], equals(taskId));
    });
  });

  group('Pomodoro authorization', () {
    late String user1Token;
    late String user2Token;
    late String user1SessionId;

    setUp(() async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final user1Response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'pom_user1_$timestamp@test.com',
          'password': 'password123',
          'name': 'Pom User 1',
        }),
      );
      final user1Body = jsonDecode(user1Response.body) as Map<String, dynamic>;
      final user1Data = user1Body['data'] as Map<String, dynamic>;
      user1Token = user1Data['token'] as String;

      final user2Response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'pom_user2_$timestamp@test.com',
          'password': 'password123',
          'name': 'Pom User 2',
        }),
      );
      final user2Body = jsonDecode(user2Response.body) as Map<String, dynamic>;
      final user2Data = user2Body['data'] as Map<String, dynamic>;
      user2Token = user2Data['token'] as String;

      final sessionResponse = await http.post(
        Uri.parse('$_baseUrl/pomodoro/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $user1Token',
        },
        body: jsonEncode({'title': 'User 1 Session'}),
      );
      final sessionBody =
          jsonDecode(sessionResponse.body) as Map<String, dynamic>;
      final sessionData = sessionBody['data'] as Map<String, dynamic>;
      user1SessionId = sessionData['id'] as String;
    });

    test("user cannot pause another user's session", () async {
      final response = await http.post(
        Uri.parse('$_baseUrl/pomodoro/$user1SessionId/pause'),
        headers: {'Authorization': 'Bearer $user2Token'},
      );
      expect(response.statusCode, equals(403));
    });

    test("user cannot resume another user's session", () async {
      final response = await http.post(
        Uri.parse('$_baseUrl/pomodoro/$user1SessionId/resume'),
        headers: {'Authorization': 'Bearer $user2Token'},
      );
      expect(response.statusCode, equals(403));
    });

    test("user cannot complete another user's session", () async {
      final response = await http.post(
        Uri.parse('$_baseUrl/pomodoro/$user1SessionId/complete'),
        headers: {'Authorization': 'Bearer $user2Token'},
      );
      expect(response.statusCode, equals(403));
    });
  });
}
