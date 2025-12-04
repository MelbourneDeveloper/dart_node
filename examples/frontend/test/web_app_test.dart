/// UI interaction tests for the TaskFlow web app.
///
/// Tests verify actual user interactions using the real lib/ components.
/// Run with: dart test -p chrome
@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/src/testing_library.dart';
import 'package:frontend/src/websocket.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

import '../web/app.dart' show App;
import 'test_helpers.dart';

void main() {
  setUp(mockWebSocket);

  test('complete login flow - success', () async {
    final mockFetch = createMockFetch({
      '/auth/login': {
        'success': true,
        'data': {
          'token': 'test-token-123',
          'user': {'name': 'Test User', 'email': 'test@example.com'},
        },
      },
      '/tasks': {'success': true, 'data': <Map<String, Object?>>[]},
    });

    final result = render(App(fetchFn: mockFetch));

    expect(result.container.textContent, contains('Sign In'));

    final emailInput = result.container.querySelector('input[type="email"]');
    final passInput = result.container.querySelector('input[type="password"]');
    await userType(emailInput!, 'test@example.com');
    await userType(passInput!, 'password123');

    fireClick(result.container.querySelector('.btn-primary')!);

    await waitForText(result, 'Your Tasks');
    expect(result.container.textContent, contains('Welcome, Test User'));

    result.unmount();
  });

  test('complete login flow - error', () async {
    final mockFetch = createMockFetch({
      '/auth/login': {'success': false, 'error': 'Invalid credentials'},
    });

    final result = render(App(fetchFn: mockFetch));

    await userType(
      result.container.querySelector('input[type="email"]')!,
      'bad@email.com',
    );
    await userType(
      result.container.querySelector('input[type="password"]')!,
      'wrong',
    );

    fireClick(result.container.querySelector('.btn-primary')!);

    await waitForText(result, 'Invalid credentials');
    // Verify error message div is rendered (line 67 coverage)
    expect(result.container.querySelector('.error-msg'), isNotNull);
    expect(result.container.textContent, contains('Sign In'));

    result.unmount();
  });

  test('login -> view tasks -> logout', () async {
    final mockFetch = createMockFetch({
      '/auth/login': {
        'success': true,
        'data': {
          'token': 'tok',
          'user': {'name': 'Alice'},
        },
      },
      '/tasks': {
        'success': true,
        'data': [
          {'id': '1', 'title': 'Task One', 'completed': false},
          {'id': '2', 'title': 'Task Two', 'completed': true},
        ],
      },
    });

    final result = render(App(fetchFn: mockFetch));

    await userType(
      result.container.querySelector('input[type="email"]')!,
      'a@b.com',
    );
    await userType(
      result.container.querySelector('input[type="password"]')!,
      'pass',
    );
    fireClick(result.container.querySelector('.btn-primary')!);

    await waitForText(result, 'Task One');
    expect(result.container.textContent, contains('Task Two'));
    expect(result.container.textContent, contains('1/2 completed'));

    fireClick(result.container.querySelector('.btn-ghost')!);

    await waitForText(result, 'Sign In');
    expect(result.container.textContent, isNot(contains('Welcome')));

    result.unmount();
  });

  test('login -> add new task (no duplicates from websocket)', () async {
    final mockFetch = createMockFetch({
      '/auth/login': {
        'success': true,
        'data': {
          'token': 'tok',
          'user': {'name': 'Alice'},
        },
      },
      '/tasks': {'success': true, 'data': <Map<String, Object?>>[]},
      'POST /tasks': {
        'success': true,
        'data': {'id': '99', 'title': 'My New Task', 'completed': false},
      },
    });

    final result = render(App(fetchFn: mockFetch));

    // Login
    await userType(
      result.container.querySelector('input[type="email"]')!,
      'a@b.com',
    );
    await userType(
      result.container.querySelector('input[type="password"]')!,
      'pass',
    );
    fireClick(result.container.querySelector('.btn-primary')!);

    await waitForText(result, 'Your Tasks');
    // Verify 0 tasks initially
    expect(result.container.textContent, contains('0/0 completed'));

    // Add a new task
    final taskInput = result.container.querySelector(
      'input[placeholder="What needs to be done?"]',
    )!;
    await userType(taskInput, 'My New Task');

    // Click Add Task button
    final addButton = result.container.querySelector('.btn-primary')!;
    fireClick(addButton);

    // The new task should appear in the list
    await waitForText(result, 'My New Task');

    // Simulate WebSocket also sending task_created (what the server does!)
    simulateWsMessage(
      '{"type":"task_created","data":'
      '{"id":"99","title":"My New Task","completed":false}}',
    );

    // Give React time to process the WebSocket event
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // CRITICAL: Assert EXACTLY ONE task, not duplicates!
    final taskItems = result.container.querySelectorAll('.task-item');
    expect(
      taskItems.length,
      1,
      reason: 'Should have exactly 1 task, not duplicates',
    );
    expect(result.container.textContent, contains('0/1 completed'));

    result.unmount();
  });

  test('add task - WS arrives BEFORE HTTP response (race condition)', () async {
    // This tests the REAL bug: WebSocket is faster than HTTP response!
    // Server broadcasts task_created immediately, HTTP response is slower.

    // Create fetch that triggers WS message BEFORE returning HTTP response
    Future<Result<JSObject, String>> racingFetch(
      String url, {
      String method = 'GET',
      String? token,
      Map<String, Object?>? body,
    }) async {
      if (url.contains('/auth/login')) {
        return Success<JSObject, String>(
          createJSObject({
            'success': true,
            'data': {
              'token': 'tok',
              'user': {'name': 'Alice'},
            },
          }),
        );
      }
      if (url.contains('/tasks') && method == 'GET') {
        return Success<JSObject, String>(
          createJSObject({'success': true, 'data': <Map<String, Object?>>[]}),
        );
      }
      if (url.contains('/tasks') && method == 'POST') {
        // SIMULATE RACE: WebSocket arrives BEFORE HTTP response!
        simulateWsMessage(
          '{"type":"task_created","data":'
          '{"id":"race-1","title":"Race Task","completed":false}}',
        );
        // Small delay, then HTTP returns
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return Success<JSObject, String>(
          createJSObject({
            'success': true,
            'data': {'id': 'race-1', 'title': 'Race Task', 'completed': false},
          }),
        );
      }
      throw StateError('No mock for $method $url');
    }

    final result = render(App(fetchFn: racingFetch));

    // Login
    await userType(
      result.container.querySelector('input[type="email"]')!,
      'a@b.com',
    );
    await userType(
      result.container.querySelector('input[type="password"]')!,
      'pass',
    );
    fireClick(result.container.querySelector('.btn-primary')!);

    await waitForText(result, 'Your Tasks');

    // Add task - WS will arrive before HTTP!
    final taskInput = result.container.querySelector(
      'input[placeholder="What needs to be done?"]',
    )!;
    await userType(taskInput, 'Race Task');
    fireClick(result.container.querySelector('.btn-primary')!);

    // Wait for task to appear
    await waitForText(result, 'Race Task');
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // CRITICAL: Must have exactly 1 task, not 2!
    final taskItems = result.container.querySelectorAll('.task-item');
    expect(
      taskItems.length,
      1,
      reason: 'WS arrived first, HTTP should NOT add duplicate!',
    );

    result.unmount();
  });

  test('switch between login and register views', () {
    final result = render(App());

    expect(result.container.textContent, contains('Sign In'));

    fireClick(result.container.querySelector('.btn-link')!);

    expect(result.container.textContent, contains('Create Account'));
    expect(result.container.textContent, contains('Name'));

    fireClick(result.container.querySelector('.btn-link')!);

    expect(result.container.textContent, contains('Sign In'));

    result.unmount();
  });

  test('register flow - success', () async {
    final mockFetch = createMockFetch({
      '/auth/register': {
        'success': true,
        'data': {
          'token': 'new-token',
          'user': {'name': 'New User'},
        },
      },
      '/tasks': {'success': true, 'data': <Map<String, Object?>>[]},
    });

    final result = render(App(fetchFn: mockFetch));

    fireClick(result.container.querySelector('.btn-link')!);

    final inputs = result.container.querySelectorAll('input');
    await userType(inputs[0], 'New User');
    await userType(inputs[1], 'new@user.com');
    await userType(inputs[2], 'password');

    fireClick(result.container.querySelector('.btn-primary')!);

    await waitForText(result, 'Your Tasks');
    expect(result.container.textContent, contains('Welcome, New User'));

    result.unmount();
  });

  test('login with no token in response', () async {
    final mockFetch = createMockFetch({
      '/auth/login': {
        'success': true,
        'data': {
          'user': {'name': 'No Token User'},
        },
      },
    });

    final result = render(App(fetchFn: mockFetch));

    await userType(
      result.container.querySelector('input[type="email"]')!,
      'x@y.com',
    );
    await userType(
      result.container.querySelector('input[type="password"]')!,
      'pass',
    );
    fireClick(result.container.querySelector('.btn-primary')!);

    await waitForText(result, 'No token');

    result.unmount();
  });

  test('login with null data in response', () async {
    final mockFetch = createMockFetch({
      '/auth/login': {'success': true, 'data': null},
    });

    final result = render(App(fetchFn: mockFetch));

    await userType(
      result.container.querySelector('input[type="email"]')!,
      'x@y.com',
    );
    await userType(
      result.container.querySelector('input[type="password"]')!,
      'pass',
    );
    fireClick(result.container.querySelector('.btn-primary')!);

    await waitForText(result, 'Login failed');

    result.unmount();
  });

  test('register with no token in response', () async {
    final mockFetch = createMockFetch({
      '/auth/register': {
        'success': true,
        'data': {
          'user': {'name': 'No Token'},
        },
      },
    });

    final result = render(App(fetchFn: mockFetch));

    fireClick(result.container.querySelector('.btn-link')!);

    final inputs = result.container.querySelectorAll('input');
    await userType(inputs[0], 'Name');
    await userType(inputs[1], 'a@b.com');
    await userType(inputs[2], 'pass');

    fireClick(result.container.querySelector('.btn-primary')!);

    await waitForText(result, 'No token');

    result.unmount();
  });

  test('register with null data in response', () async {
    final mockFetch = createMockFetch({
      '/auth/register': {'success': true, 'data': null},
    });

    final result = render(App(fetchFn: mockFetch));

    fireClick(result.container.querySelector('.btn-link')!);

    final inputs = result.container.querySelectorAll('input');
    await userType(inputs[0], 'Name');
    await userType(inputs[1], 'a@b.com');
    await userType(inputs[2], 'pass');

    fireClick(result.container.querySelector('.btn-primary')!);

    await waitForText(result, 'Registration failed');

    result.unmount();
  });

  test('register with server error', () async {
    final mockFetch = createMockFetch({
      '/auth/register': {'success': false, 'error': 'Email already exists'},
    });

    final result = render(App(fetchFn: mockFetch));

    fireClick(result.container.querySelector('.btn-link')!);

    final inputs = result.container.querySelectorAll('input');
    await userType(inputs[0], 'Name');
    await userType(inputs[1], 'existing@email.com');
    await userType(inputs[2], 'pass');

    fireClick(result.container.querySelector('.btn-primary')!);

    await waitForText(result, 'Email already exists');

    result.unmount();
  });

  test('login with fetch exception', () async {
    // Create a fetch that throws to test catchError branch
    final throwingFetch = createThrowingFetch();

    final result = render(App(fetchFn: throwingFetch));

    await userType(
      result.container.querySelector('input[type="email"]')!,
      'x@y.com',
    );
    await userType(
      result.container.querySelector('input[type="password"]')!,
      'pass',
    );
    fireClick(result.container.querySelector('.btn-primary')!);

    await waitForText(result, 'Network error');

    result.unmount();
  });

  test('register with fetch exception', () async {
    final throwingFetch = createThrowingFetch();

    final result = render(App(fetchFn: throwingFetch));

    fireClick(result.container.querySelector('.btn-link')!);

    final inputs = result.container.querySelectorAll('input');
    await userType(inputs[0], 'Name');
    await userType(inputs[1], 'a@b.com');
    await userType(inputs[2], 'pass');

    fireClick(result.container.querySelector('.btn-primary')!);

    await waitForText(result, 'Network error');

    result.unmount();
  });

  // --- WebSocket Tests ---

  test('handleWebSocketMessage parses JSON and calls callback', () {
    final events = <JSObject>[];
    handleWebSocketMessage('{"type":"created","data":{"id":"1"}}', events.add);

    expect(events.length, 1);
    expect((events[0]['type']! as JSString).toDart, 'created');
  });

  test('connectWebSocket creates websocket with handlers', () {
    var openCalled = false;
    var closeCalled = false;
    final events = <JSObject>[];

    final ws = connectWebSocket(
      token: 'test-token',
      onTaskEvent: events.add,
      onOpen: () => openCalled = true,
      onClose: () => closeCalled = true,
    );

    expect(ws, isNotNull);

    // Trigger the handlers manually via the mock
    final dummyEvent = JSObject();
    ws!.onopen?.callAsFunction(null, dummyEvent);
    expect(openCalled, isTrue);

    ws.onclose?.callAsFunction(null, dummyEvent);
    expect(closeCalled, isTrue);

    // Test message handler with valid JSON string
    final messageEvent = JSObject();
    messageEvent['data'] = '{"type":"test"}'.toJS;
    ws.onmessage?.callAsFunction(null, messageEvent);
    expect(events.length, 1);

    // Test error handler (should not throw)
    ws.onerror?.callAsFunction(null, dummyEvent);

    ws.close();
  });

  test('connectWebSocket handles non-string message data', () {
    final events = <JSObject>[];

    final ws = connectWebSocket(token: 'test-token', onTaskEvent: events.add);

    // Send non-string data (should be ignored)
    final messageEvent = JSObject();
    messageEvent['data'] = 123.toJS;
    ws!.onmessage?.callAsFunction(null, messageEvent);

    expect(events, isEmpty);
    ws.close();
  });
}
