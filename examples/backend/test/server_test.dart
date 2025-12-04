import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

const _baseUrl = 'http://localhost:3000';

void main() {
  Process? serverProcess;

  setUpAll(() async {
    // The current working directory should be the example dir when running
    // dart test
    final currentDir = Directory.current.path;

    // Start the server
    serverProcess = await Process.start('node', [
      'build/server.js',
    ], workingDirectory: currentDir);

    // Wait for server to be ready
    await Future<void>.delayed(const Duration(seconds: 2));
  });

  tearDownAll(() {
    serverProcess?.kill();
  });

  group('API endpoint', () {
    test('GET /api returns Hello from Dart API!', () async {
      final response = await http.get(Uri.parse('$_baseUrl/api'));

      expect(response.statusCode, equals(200));
      expect(response.body, equals('Hello from Dart API!'));
    });
  });

  group('Health endpoint', () {
    test('GET /health returns health status', () async {
      final response = await http.get(Uri.parse('$_baseUrl/health'));

      expect(response.statusCode, equals(200));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['status'], equals('healthy'));
      expect(body['timestamp'], isNotNull);
    });
  });

  group('Auth endpoints', () {
    test('POST /auth/register creates user and returns token', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'register_$timestamp@test.com';
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': 'password123',
          'name': 'Test User',
        }),
      );

      expect(response.statusCode, equals(201));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['success'], isTrue);
      final data = body['data'] as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;
      expect(user['email'], equals(email));
      expect(data['token'], isNotNull);
    });

    test('POST /auth/register rejects duplicate email', () async {
      // Register first user
      await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'duplicate@example.com',
          'password': 'password123',
          'name': 'First User',
        }),
      );

      // Try to register with same email
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'duplicate@example.com',
          'password': 'password456',
          'name': 'Second User',
        }),
      );

      expect(response.statusCode, equals(409));
    });

    test('POST /auth/register validates input', () async {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'invalid-email',
          'password': 'short',
          'name': '',
        }),
      );

      expect(response.statusCode, equals(400));
    });

    test('POST /auth/login returns token for valid credentials', () async {
      // Register user
      await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'login@example.com',
          'password': 'password123',
          'name': 'Login User',
        }),
      );

      // Login
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'login@example.com',
          'password': 'password123',
        }),
      );

      expect(response.statusCode, equals(200));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['success'], isTrue);
      final data = body['data'] as Map<String, dynamic>;
      expect(data['token'], isNotNull);
    });

    test('POST /auth/login rejects invalid password', () async {
      // Register user
      await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'badpass@example.com',
          'password': 'correctpassword',
          'name': 'Bad Pass User',
        }),
      );

      // Try wrong password
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'badpass@example.com',
          'password': 'wrongpassword',
        }),
      );

      expect(response.statusCode, equals(401));
    });
  });

  group('Task endpoints', () {
    String? authToken;

    setUp(() async {
      // Create user and get token
      final email = 'tasks_${DateTime.now().millisecondsSinceEpoch}@test.com';
      final registerResponse = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': 'password123',
          'name': 'Task Test User',
        }),
      );
      final body = jsonDecode(registerResponse.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      authToken = data['token'] as String;
    });

    test('GET /tasks requires authentication', () async {
      final response = await http.get(Uri.parse('$_baseUrl/tasks'));

      expect(response.statusCode, equals(401));
    });

    test('GET /tasks returns empty list initially', () async {
      final response = await http.get(
        Uri.parse('$_baseUrl/tasks'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      expect(response.statusCode, equals(200));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['success'], isTrue);
      expect(body['data'], isEmpty);
    });

    test('POST /tasks creates a new task', () async {
      final response = await http.post(
        Uri.parse('$_baseUrl/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'title': 'Test Task',
          'description': 'Test description',
        }),
      );

      expect(response.statusCode, equals(201));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['success'], isTrue);
      final data = body['data'] as Map<String, dynamic>;
      expect(data['title'], equals('Test Task'));
      expect(data['completed'], isFalse);
    });

    test('GET /tasks/:id returns task', () async {
      // Create task
      final createResponse = await http.post(
        Uri.parse('$_baseUrl/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'title': 'Get Test Task'}),
      );
      final createBody =
          jsonDecode(createResponse.body) as Map<String, dynamic>;
      final createData = createBody['data'] as Map<String, dynamic>;
      final taskId = createData['id'] as String;

      // Get task
      final response = await http.get(
        Uri.parse('$_baseUrl/tasks/$taskId'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      expect(response.statusCode, equals(200));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      expect(data['id'], equals(taskId));
    });

    test('PUT /tasks/:id updates task', () async {
      // Create task
      final createResponse = await http.post(
        Uri.parse('$_baseUrl/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'title': 'Update Test Task'}),
      );
      final createBody =
          jsonDecode(createResponse.body) as Map<String, dynamic>;
      final createData = createBody['data'] as Map<String, dynamic>;
      final taskId = createData['id'] as String;

      // Update task
      final response = await http.put(
        Uri.parse('$_baseUrl/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'title': 'Updated Title', 'completed': true}),
      );

      expect(response.statusCode, equals(200));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      expect(data['title'], equals('Updated Title'));
      expect(data['completed'], isTrue);
    });

    test('DELETE /tasks/:id removes task', () async {
      // Create task
      final createResponse = await http.post(
        Uri.parse('$_baseUrl/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'title': 'Delete Test Task'}),
      );
      final createBody =
          jsonDecode(createResponse.body) as Map<String, dynamic>;
      final createData = createBody['data'] as Map<String, dynamic>;
      final taskId = createData['id'] as String;

      // Delete task
      final deleteResponse = await http.delete(
        Uri.parse('$_baseUrl/tasks/$taskId'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      expect(deleteResponse.statusCode, equals(200));

      // Verify task is gone
      final getResponse = await http.get(
        Uri.parse('$_baseUrl/tasks/$taskId'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      expect(getResponse.statusCode, equals(404));
    });

    test('GET /tasks/:id returns 404 for non-existent task', () async {
      final response = await http.get(
        Uri.parse('$_baseUrl/tasks/nonexistent'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      expect(response.statusCode, equals(404));
    });
  });

  group('Task authorization', () {
    String? user1Token;
    String? user2Token;
    String? user1TaskId;

    setUp(() async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Create user 1
      final user1Response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'user1_$timestamp@test.com',
          'password': 'password123',
          'name': 'User 1',
        }),
      );
      final user1Body = jsonDecode(user1Response.body) as Map<String, dynamic>;
      final user1Data = user1Body['data'] as Map<String, dynamic>;
      user1Token = user1Data['token'] as String;

      // Create user 2
      final user2Response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'user2_$timestamp@test.com',
          'password': 'password123',
          'name': 'User 2',
        }),
      );
      final user2Body = jsonDecode(user2Response.body) as Map<String, dynamic>;
      final user2Data = user2Body['data'] as Map<String, dynamic>;
      user2Token = user2Data['token'] as String;

      // Create task for user 1
      final taskResponse = await http.post(
        Uri.parse('$_baseUrl/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $user1Token',
        },
        body: jsonEncode({'title': 'User 1 Task'}),
      );
      final taskBody = jsonDecode(taskResponse.body) as Map<String, dynamic>;
      final taskData = taskBody['data'] as Map<String, dynamic>;
      user1TaskId = taskData['id'] as String;
    });

    test("user cannot access another user's task", () async {
      final response = await http.get(
        Uri.parse('$_baseUrl/tasks/$user1TaskId'),
        headers: {'Authorization': 'Bearer $user2Token'},
      );

      expect(response.statusCode, equals(403));
    });

    test("user cannot update another user's task", () async {
      final response = await http.put(
        Uri.parse('$_baseUrl/tasks/$user1TaskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $user2Token',
        },
        body: jsonEncode({'title': 'Hacked Title'}),
      );

      expect(response.statusCode, equals(403));
    });

    test("user cannot delete another user's task", () async {
      final response = await http.delete(
        Uri.parse('$_baseUrl/tasks/$user1TaskId'),
        headers: {'Authorization': 'Bearer $user2Token'},
      );

      expect(response.statusCode, equals(403));
    });
  });
}
