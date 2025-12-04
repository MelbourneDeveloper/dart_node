/// UI interaction tests for the mobile app.
///
/// Tests verify actual user interactions using the real lib/ components.
/// Run with: dart test -p chrome
@TestOn('js')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/src/testing_library.dart';
import 'package:mobile/app.dart' show MobileApp;
import 'package:mobile/websocket.dart';
import 'package:nadz/nadz.dart';
import 'package:shared/http/http_client.dart' show Fetch;
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  setUp(setupMocks);

  // ===== LOGIN SCREEN TESTS =====

  group('Login Screen', () {
    test('renders login screen with Sign In text', () {
      final result = render(MobileApp());

      expect(result.container.textContent, contains('Sign In'));
      expect(result.container.textContent, contains('Email'));
      expect(result.container.textContent, contains('Password'));

      result.unmount();
    });

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

      final result = render(MobileApp(fetchFn: mockFetch));

      expect(result.container.textContent, contains('Sign In'));

      final inputs = result.container.querySelectorAll('input');
      expect(inputs.length, greaterThanOrEqualTo(2));

      await userType(inputs[0], 'test@example.com');
      await userType(inputs[1], 'password123');

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.first);

      await waitForText(result, 'TaskFlow');

      result.unmount();
    });

    test('complete login flow - error', () async {
      final mockFetch = createMockFetch({
        '/auth/login': {'success': false, 'error': 'Invalid credentials'},
      });

      final result = render(MobileApp(fetchFn: mockFetch));

      final inputs = result.container.querySelectorAll('input');
      await userType(inputs[0], 'bad@email.com');
      await userType(inputs[1], 'wrong');

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.first);

      await waitForText(result, 'Invalid credentials');
      expect(result.container.textContent, contains('Sign In'));

      result.unmount();
    });

    test('login with fetch exception shows error', () async {
      final throwingFetch = createThrowingFetch();

      final result = render(MobileApp(fetchFn: throwingFetch));

      final inputs = result.container.querySelectorAll('input');
      await userType(inputs[0], 'x@y.com');
      await userType(inputs[1], 'pass');

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.first);

      await waitForText(result, 'Network error');

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

      final result = render(MobileApp(fetchFn: mockFetch));

      final inputs = result.container.querySelectorAll('input');
      await userType(inputs[0], 'x@y.com');
      await userType(inputs[1], 'pass');

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.first);

      await waitForText(result, 'No token');

      result.unmount();
    });

    test('login with null data in response', () async {
      final mockFetch = createMockFetch({
        '/auth/login': {'success': true, 'data': null},
      });

      final result = render(MobileApp(fetchFn: mockFetch));

      final inputs = result.container.querySelectorAll('input');
      await userType(inputs[0], 'x@y.com');
      await userType(inputs[1], 'pass');

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.first);

      await waitForText(result, 'Login failed');

      result.unmount();
    });

    test('switch between login and register views', () {
      final result = render(MobileApp());

      expect(result.container.textContent, contains('Sign In'));

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.last);

      expect(result.container.textContent, contains('Create Account'));
      expect(result.container.textContent, contains('Name'));

      final registerButtons = result.container.querySelectorAll('button');
      fireClick(registerButtons.last);

      expect(result.container.textContent, contains('Sign In'));

      result.unmount();
    });
  });

  // ===== REGISTER SCREEN TESTS =====

  group('Register Screen', () {
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

      final result = render(MobileApp(fetchFn: mockFetch));

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.last);

      await waitForText(result, 'Create Account');

      final inputs = result.container.querySelectorAll('input');
      await userType(inputs[0], 'New User');
      await userType(inputs[1], 'new@user.com');
      await userType(inputs[2], 'password');

      final registerButtons = result.container.querySelectorAll('button');
      fireClick(registerButtons.first);

      await waitForText(result, 'TaskFlow');

      result.unmount();
    });

    test('register with server error', () async {
      final mockFetch = createMockFetch({
        '/auth/register': {'success': false, 'error': 'Email already exists'},
      });

      final result = render(MobileApp(fetchFn: mockFetch));

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.last);

      await waitForText(result, 'Create Account');

      final inputs = result.container.querySelectorAll('input');
      await userType(inputs[0], 'Name');
      await userType(inputs[1], 'existing@email.com');
      await userType(inputs[2], 'pass');

      final registerButtons = result.container.querySelectorAll('button');
      fireClick(registerButtons.first);

      await waitForText(result, 'Email already exists');

      result.unmount();
    });

    test('register with fetch exception', () async {
      final throwingFetch = createThrowingFetch();

      final result = render(MobileApp(fetchFn: throwingFetch));

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.last);

      await waitForText(result, 'Create Account');

      final inputs = result.container.querySelectorAll('input');
      await userType(inputs[0], 'Name');
      await userType(inputs[1], 'a@b.com');
      await userType(inputs[2], 'pass');

      final registerButtons = result.container.querySelectorAll('button');
      fireClick(registerButtons.first);

      await waitForText(result, 'Network error');

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

      final result = render(MobileApp(fetchFn: mockFetch));

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.last);

      final inputs = result.container.querySelectorAll('input');
      await userType(inputs[0], 'Name');
      await userType(inputs[1], 'a@b.com');
      await userType(inputs[2], 'pass');

      final registerButtons = result.container.querySelectorAll('button');
      fireClick(registerButtons.first);

      // Should navigate to tasks (null token is set)
      await waitForText(result, 'TaskFlow');

      result.unmount();
    });

    test('register with null data in response', () async {
      final mockFetch = createMockFetch({
        '/auth/register': {'success': true, 'data': null},
      });

      final result = render(MobileApp(fetchFn: mockFetch));

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.last);

      final inputs = result.container.querySelectorAll('input');
      await userType(inputs[0], 'Name');
      await userType(inputs[1], 'a@b.com');
      await userType(inputs[2], 'pass');

      final registerButtons = result.container.querySelectorAll('button');
      fireClick(registerButtons.first);

      // Should navigate to tasks (null token/user)
      await waitForText(result, 'TaskFlow');

      result.unmount();
    });
  });

  // ===== TASK LIST SCREEN TESTS =====

  group('Task List Screen', () {
    Future<TestRenderResult> loginAndNavigateToTasks(Fetch mockFetch) async {
      final result = render(MobileApp(fetchFn: mockFetch));

      final inputs = result.container.querySelectorAll('input');
      await userType(inputs[0], 'test@example.com');
      await userType(inputs[1], 'password');

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.first);

      await waitForText(result, 'TaskFlow');
      return result;
    }

    test('shows tasks after successful login', () async {
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

      final result = await loginAndNavigateToTasks(mockFetch);

      await waitForText(result, 'Task One');
      expect(result.container.textContent, contains('Task Two'));

      result.unmount();
    });

    test('shows empty state when no tasks', () async {
      final mockFetch = createMockFetch({
        '/auth/login': {
          'success': true,
          'data': {
            'token': 'tok',
            'user': {'name': 'Alice'},
          },
        },
        '/tasks': {'success': true, 'data': <Map<String, Object?>>[]},
      });

      final result = await loginAndNavigateToTasks(mockFetch);

      await waitForText(result, 'No tasks yet');

      result.unmount();
    });

    test('shows user name in header', () async {
      final mockFetch = createMockFetch({
        '/auth/login': {
          'success': true,
          'data': {
            'token': 'tok',
            'user': {'name': 'Charlie'},
          },
        },
        '/tasks': {'success': true, 'data': <Map<String, Object?>>[]},
      });

      final result = await loginAndNavigateToTasks(mockFetch);

      await waitForText(result, 'Hi, Charlie');

      result.unmount();
    });

    test('shows "User" when name is null', () async {
      final mockFetch = createMockFetch({
        '/auth/login': {
          'success': true,
          'data': {
            'token': 'tok',
            'user': {'email': 'no-name@test.com'},
          },
        },
        '/tasks': {'success': true, 'data': <Map<String, Object?>>[]},
      });

      final result = await loginAndNavigateToTasks(mockFetch);

      await waitForText(result, 'Hi, User');

      result.unmount();
    });

    test('shows error message when task load fails', () async {
      final mockFetch = createMockFetch({
        '/auth/login': {
          'success': true,
          'data': {
            'token': 'tok',
            'user': {'name': 'Test'},
          },
        },
        '/tasks': {'success': false, 'error': 'Failed to load tasks'},
      });

      final result = await loginAndNavigateToTasks(mockFetch);

      await waitForText(result, 'Failed to load tasks');

      result.unmount();
    });

    test('shows error when task load throws exception', () async {
      var callCount = 0;
      Future<Result<JSObject, String>> customFetch(
        String url, {
        String method = 'GET',
        String? token,
        Map<String, Object?>? body,
      }) async {
        if (url.contains('/auth/login')) {
          return Success(
            createJSObject({
              'success': true,
              'data': {
                'token': 'tok',
                'user': {'name': 'Test'},
              },
            }),
          );
        }
        if (url.contains('/tasks')) {
          callCount++;
          throw Exception('Network error');
        }
        throw StateError('No mock for $method $url');
      }

      final result = render(MobileApp(fetchFn: customFetch));

      final inputs = result.container.querySelectorAll('input');
      await userType(inputs[0], 'test@example.com');
      await userType(inputs[1], 'password');

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.first);

      await waitForText(result, 'TaskFlow');
      await waitForText(result, 'Exception: Network error');

      expect(callCount, greaterThan(0));

      result.unmount();
    });

    test('logout clears state and returns to login', () async {
      final mockFetch = createMockFetch({
        '/auth/login': {
          'success': true,
          'data': {
            'token': 'tok',
            'user': {'name': 'Alice'},
          },
        },
        '/tasks': {'success': true, 'data': <Map<String, Object?>>[]},
      });

      final result = await loginAndNavigateToTasks(mockFetch);

      await waitForText(result, 'Logout');

      // Find and click Logout button
      final buttons = result.container.querySelectorAll('button');
      // Logout is the button containing "Logout" text
      for (final btn in buttons) {
        if (btn.textContent.contains('Logout')) {
          fireClick(btn);
          break;
        }
      }

      await waitForText(result, 'Sign In');
      expect(result.container.textContent, isNot(contains('TaskFlow')));

      result.unmount();
    });

    test('toggle task completion - success', () async {
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
            {'id': '1', 'title': 'Toggle Me', 'completed': false},
          ],
        },
        'PUT /tasks/1': {'success': true, 'data': {}},
      });

      final result = await loginAndNavigateToTasks(mockFetch);

      await waitForText(result, 'Toggle Me');

      // Find buttons - the checkbox is one of the first buttons after TaskFlow
      // Click on the task title text to toggle (it's a touchable)
      final allButtons = result.container.querySelectorAll('button');
      // Skip header buttons, find one that triggers toggle
      for (final btn in allButtons) {
        if (btn.textContent == 'Toggle Me') {
          fireClick(btn);
          break;
        }
      }

      // Give time for state update
      await Future<void>.delayed(const Duration(milliseconds: 200));

      result.unmount();
    });

    test('toggle task completion - error', () async {
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
            {'id': '1', 'title': 'Toggle Error', 'completed': false},
          ],
        },
        'PUT /tasks/1': {'success': false, 'error': 'Toggle failed'},
      });

      final result = await loginAndNavigateToTasks(mockFetch);

      await waitForText(result, 'Toggle Error');

      final allButtons = result.container.querySelectorAll('button');
      for (final btn in allButtons) {
        if (btn.textContent == 'Toggle Error') {
          fireClick(btn);
          break;
        }
      }

      await waitForText(result, 'Toggle failed');

      result.unmount();
    });

    test('toggle task throws exception', () async {
      var toggleCalled = false;
      Future<Result<JSObject, String>> customFetch(
        String url, {
        String method = 'GET',
        String? token,
        Map<String, Object?>? body,
      }) async {
        if (url.contains('/auth/login')) {
          return Success(
            createJSObject({
              'success': true,
              'data': {
                'token': 'tok',
                'user': {'name': 'Test'},
              },
            }),
          );
        }
        if (url.contains('/tasks') && method == 'GET') {
          return Success(
            createJSObject({
              'success': true,
              'data': [
                {'id': '1', 'title': 'Toggle Exception', 'completed': false},
              ],
            }),
          );
        }
        if (url.contains('/tasks/1') && method == 'PUT') {
          toggleCalled = true;
          throw Exception('Toggle network error');
        }
        throw StateError('No mock for $method $url');
      }

      final result = render(MobileApp(fetchFn: customFetch));

      final inputs = result.container.querySelectorAll('input');
      await userType(inputs[0], 'test@example.com');
      await userType(inputs[1], 'password');

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.first);

      await waitForText(result, 'Toggle Exception');

      final allButtons = result.container.querySelectorAll('button');
      for (final btn in allButtons) {
        if (btn.textContent == 'Toggle Exception') {
          fireClick(btn);
          break;
        }
      }

      await waitForText(result, 'Exception: Toggle network error');
      expect(toggleCalled, isTrue);

      result.unmount();
    });

    test('delete task - success', () async {
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
            {'id': '1', 'title': 'Delete Me', 'completed': false},
          ],
        },
        'DELETE /tasks/1': {'success': true, 'data': {}},
      });

      final result = await loginAndNavigateToTasks(mockFetch);

      await waitForText(result, 'Delete Me');

      // Find delete button (the × button)
      final allButtons = result.container.querySelectorAll('button');
      for (final btn in allButtons) {
        if (btn.textContent.contains('×')) {
          fireClick(btn);
          break;
        }
      }

      // Wait for task to be removed
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await waitForText(result, 'No tasks yet');

      result.unmount();
    });

    test('delete task - error shows error message', () async {
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
            {'id': '1', 'title': 'Task To Delete', 'completed': false},
          ],
        },
        'DELETE /tasks/1': {'success': false, 'error': 'Delete failed'},
      });

      final result = await loginAndNavigateToTasks(mockFetch);

      await waitForText(result, 'Task To Delete');

      final allButtons = result.container.querySelectorAll('button');
      for (final btn in allButtons) {
        if (btn.textContent.contains('×')) {
          fireClick(btn);
          break;
        }
      }

      // Error message should appear
      await waitForText(result, 'Delete failed');

      result.unmount();
    });

    test('delete task throws exception', () async {
      var deleteCalled = false;
      Future<Result<JSObject, String>> customFetch(
        String url, {
        String method = 'GET',
        String? token,
        Map<String, Object?>? body,
      }) async {
        if (url.contains('/auth/login')) {
          return Success(
            createJSObject({
              'success': true,
              'data': {
                'token': 'tok',
                'user': {'name': 'Test'},
              },
            }),
          );
        }
        if (url.contains('/tasks') && method == 'GET') {
          return Success(
            createJSObject({
              'success': true,
              'data': [
                {'id': '1', 'title': 'Delete Exception', 'completed': false},
              ],
            }),
          );
        }
        if (url.contains('/tasks/1') && method == 'DELETE') {
          deleteCalled = true;
          throw Exception('Delete network error');
        }
        throw StateError('No mock for $method $url');
      }

      final result = render(MobileApp(fetchFn: customFetch));

      final inputs = result.container.querySelectorAll('input');
      await userType(inputs[0], 'test@example.com');
      await userType(inputs[1], 'password');

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.first);

      await waitForText(result, 'Delete Exception');

      final allButtons = result.container.querySelectorAll('button');
      for (final btn in allButtons) {
        if (btn.textContent.contains('×')) {
          fireClick(btn);
          break;
        }
      }

      await waitForText(result, 'Exception: Delete network error');
      expect(deleteCalled, isTrue);

      result.unmount();
    });

    test('FAB shows add form when clicked', () async {
      final mockFetch = createMockFetch({
        '/auth/login': {
          'success': true,
          'data': {
            'token': 'tok',
            'user': {'name': 'Alice'},
          },
        },
        '/tasks': {'success': true, 'data': <Map<String, Object?>>[]},
      });

      final result = await loginAndNavigateToTasks(mockFetch);

      await waitForText(result, 'No tasks yet');

      // Find and click the FAB (+ button)
      final allButtons = result.container.querySelectorAll('button');
      for (final btn in allButtons) {
        if (btn.textContent == '+') {
          fireClick(btn);
          break;
        }
      }

      // Wait for form to appear (Add button visible means form is showing)
      await waitForText(result, 'Cancel');
      expect(result.container.textContent, contains('Add'));

      result.unmount();
    });

    test('add task form - cancel hides form', () async {
      final mockFetch = createMockFetch({
        '/auth/login': {
          'success': true,
          'data': {
            'token': 'tok',
            'user': {'name': 'Alice'},
          },
        },
        '/tasks': {'success': true, 'data': <Map<String, Object?>>[]},
      });

      final result = await loginAndNavigateToTasks(mockFetch);

      // Click FAB
      final allButtons = result.container.querySelectorAll('button');
      for (final btn in allButtons) {
        if (btn.textContent == '+') {
          fireClick(btn);
          break;
        }
      }

      await waitForText(result, 'Cancel');

      // Click Cancel
      final formButtons = result.container.querySelectorAll('button');
      for (final btn in formButtons) {
        if (btn.textContent == 'Cancel') {
          fireClick(btn);
          break;
        }
      }

      // Form should be hidden, FAB should be back
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(result.container.textContent, contains('+'));

      result.unmount();
    });

    test('add new task - success', () async {
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
          'data': {
            'id': 'new-1',
            'title': 'Brand New Task',
            'completed': false,
          },
        },
      });

      final result = await loginAndNavigateToTasks(mockFetch);

      // Click FAB
      final allButtons = result.container.querySelectorAll('button');
      for (final btn in allButtons) {
        if (btn.textContent == '+') {
          fireClick(btn);
          break;
        }
      }

      await waitForText(result, 'Cancel');

      // Type task title
      final inputs = result.container.querySelectorAll('input');
      await userType(inputs.first, 'Brand New Task');

      // Click Add
      final formButtons = result.container.querySelectorAll('button');
      for (final btn in formButtons) {
        if (btn.textContent == 'Add') {
          fireClick(btn);
          break;
        }
      }

      await waitForText(result, 'Brand New Task');
      // Form should be hidden
      expect(result.container.textContent, isNot(contains('Cancel')));

      result.unmount();
    });

    test('add new task - empty title ignored', () async {
      final mockFetch = createMockFetch({
        '/auth/login': {
          'success': true,
          'data': {
            'token': 'tok',
            'user': {'name': 'Alice'},
          },
        },
        '/tasks': {'success': true, 'data': <Map<String, Object?>>[]},
      });

      final result = await loginAndNavigateToTasks(mockFetch);

      // Click FAB
      final allButtons = result.container.querySelectorAll('button');
      for (final btn in allButtons) {
        if (btn.textContent == '+') {
          fireClick(btn);
          break;
        }
      }

      await waitForText(result, 'Cancel');

      // Don't type anything, just click Add
      final formButtons = result.container.querySelectorAll('button');
      for (final btn in formButtons) {
        if (btn.textContent == 'Add') {
          fireClick(btn);
          break;
        }
      }

      // Form should still be visible (nothing happened)
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(result.container.textContent, contains('Cancel'));

      result.unmount();
    });

    test('add task - error', () async {
      final mockFetch = createMockFetch({
        '/auth/login': {
          'success': true,
          'data': {
            'token': 'tok',
            'user': {'name': 'Alice'},
          },
        },
        '/tasks': {'success': true, 'data': <Map<String, Object?>>[]},
        'POST /tasks': {'success': false, 'error': 'Create failed'},
      });

      final result = await loginAndNavigateToTasks(mockFetch);

      final allButtons = result.container.querySelectorAll('button');
      for (final btn in allButtons) {
        if (btn.textContent == '+') {
          fireClick(btn);
          break;
        }
      }

      await waitForText(result, 'Cancel');

      final inputs = result.container.querySelectorAll('input');
      await userType(inputs.first, 'Failing Task');

      final formButtons = result.container.querySelectorAll('button');
      for (final btn in formButtons) {
        if (btn.textContent == 'Add') {
          fireClick(btn);
          break;
        }
      }

      await waitForText(result, 'Create failed');

      result.unmount();
    });

    test('add task throws exception', () async {
      var createCalled = false;
      Future<Result<JSObject, String>> customFetch(
        String url, {
        String method = 'GET',
        String? token,
        Map<String, Object?>? body,
      }) async {
        if (url.contains('/auth/login')) {
          return Success(
            createJSObject({
              'success': true,
              'data': {
                'token': 'tok',
                'user': {'name': 'Test'},
              },
            }),
          );
        }
        if (url.contains('/tasks') && method == 'GET') {
          return Success(
            createJSObject({'success': true, 'data': <Map<String, Object?>>[]}),
          );
        }
        if (url.contains('/tasks') && method == 'POST') {
          createCalled = true;
          throw Exception('Create network error');
        }
        throw StateError('No mock for $method $url');
      }

      final result = render(MobileApp(fetchFn: customFetch));

      final inputs = result.container.querySelectorAll('input');
      await userType(inputs[0], 'test@example.com');
      await userType(inputs[1], 'password');

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.first);

      await waitForText(result, 'TaskFlow');

      final allButtons = result.container.querySelectorAll('button');
      for (final btn in allButtons) {
        if (btn.textContent == '+') {
          fireClick(btn);
          break;
        }
      }

      await waitForText(result, 'Cancel');

      final taskInputs = result.container.querySelectorAll('input');
      await userType(taskInputs.first, 'Exception Task');

      final formButtons = result.container.querySelectorAll('button');
      for (final btn in formButtons) {
        if (btn.textContent == 'Add') {
          fireClick(btn);
          break;
        }
      }

      await waitForText(result, 'Exception: Create network error');
      expect(createCalled, isTrue);

      result.unmount();
    });
  });

  // ===== DUPLICATE TASK BUG TESTS =====

  group('Duplicate Task Prevention', () {
    test('add task - no duplicates when WS arrives after HTTP', () async {
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

      final result = render(MobileApp(fetchFn: mockFetch));

      // Login
      final inputs = result.container.querySelectorAll('input');
      await userType(inputs[0], 'a@b.com');
      await userType(inputs[1], 'pass');
      fireClick(result.container.querySelectorAll('button').first);

      await waitForText(result, 'No tasks yet');

      // Click FAB to add task
      final allButtons = result.container.querySelectorAll('button');
      for (final btn in allButtons) {
        if (btn.textContent == '+') {
          fireClick(btn);
          break;
        }
      }

      await waitForText(result, 'Cancel');

      // Type and submit
      final taskInputs = result.container.querySelectorAll('input');
      await userType(taskInputs.first, 'My New Task');

      final formButtons = result.container.querySelectorAll('button');
      for (final btn in formButtons) {
        if (btn.textContent == 'Add') {
          fireClick(btn);
          break;
        }
      }

      await waitForText(result, 'My New Task');

      // Simulate WebSocket also sending task_created (what the server does!)
      simulateWsMessage(
        '{"type":"task_created","data":'
        '{"id":"99","title":"My New Task","completed":false}}',
      );

      // Give React time to process the WebSocket event
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // CRITICAL: Count task items - should be exactly 1!
      final taskButtons = result.container.querySelectorAll('button');
      var taskCount = 0;
      for (final btn in taskButtons) {
        if (btn.textContent == 'My New Task') {
          taskCount++;
        }
      }
      expect(
        taskCount,
        1,
        reason: 'Should have exactly 1 task, not duplicates',
      );

      result.unmount();
    });

    test(
      'add task - WS arrives BEFORE HTTP response (race condition)',
      () async {
        // This tests the REAL bug: WebSocket is faster than HTTP response!
        // Server broadcasts task_created immediately, HTTP response is slower.

        Future<Result<JSObject, String>> racingFetch(
          String url, {
          String method = 'GET',
          String? token,
          Map<String, Object?>? body,
        }) async {
          if (url.contains('/auth/login')) {
            return Success(
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
            return Success(
              createJSObject({
                'success': true,
                'data': <Map<String, Object?>>[],
              }),
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
            return Success(
              createJSObject({
                'success': true,
                'data': {
                  'id': 'race-1',
                  'title': 'Race Task',
                  'completed': false,
                },
              }),
            );
          }
          throw StateError('No mock for $method $url');
        }

        final result = render(MobileApp(fetchFn: racingFetch));

        // Login
        final inputs = result.container.querySelectorAll('input');
        await userType(inputs[0], 'a@b.com');
        await userType(inputs[1], 'pass');
        fireClick(result.container.querySelectorAll('button').first);

        await waitForText(result, 'No tasks yet');

        // Click FAB
        final allButtons = result.container.querySelectorAll('button');
        for (final btn in allButtons) {
          if (btn.textContent == '+') {
            fireClick(btn);
            break;
          }
        }

        await waitForText(result, 'Cancel');

        // Type and submit - WS will arrive before HTTP!
        final taskInputs = result.container.querySelectorAll('input');
        await userType(taskInputs.first, 'Race Task');

        final formButtons = result.container.querySelectorAll('button');
        for (final btn in formButtons) {
          if (btn.textContent == 'Add') {
            fireClick(btn);
            break;
          }
        }

        // Wait for task to appear
        await waitForText(result, 'Race Task');
        await Future<void>.delayed(const Duration(milliseconds: 200));

        // CRITICAL: Count task items - must be exactly 1!
        final taskButtons = result.container.querySelectorAll('button');
        var taskCount = 0;
        for (final btn in taskButtons) {
          if (btn.textContent == 'Race Task') {
            taskCount++;
          }
        }
        expect(
          taskCount,
          1,
          reason: 'WS arrived first, HTTP should NOT add duplicate!',
        );

        result.unmount();
      },
    );
  });

  // ===== WEBSOCKET TESTS =====

  group('WebSocket Events', () {
    test(
      'WS task_created DURING initial load does NOT create duplicate',
      () async {
        // BUG: WebSocket task_created arrives DURING initial HTTP load,
        // BEFORE HTTP response. Then HTTP arrives and REPLACES the list,
        // but HTTP data + WS data = duplicate!
        //
        // Timeline:
        // 1. Login succeeds
        // 2. Component starts GET /tasks (async)
        // 3. WebSocket connects, server sends task_created event
        // 4. WS handler adds task to state (currently empty)
        // 5. HTTP /tasks responds with SAME task
        // 6. _loadTasks does tasksState.set() - REPLACES state!
        //
        // Result: WS added task + HTTP replaced with same task = OK normally
        // BUT if we don't deduplicate in set(), we can get race issues.
        //
        // Actually the REAL bug: WS arrives AFTER HTTP completes, but for
        // a task that was ALREADY in the HTTP response. Let's test that.

        Future<Result<JSObject, String>> racingFetch(
          String url, {
          String method = 'GET',
          String? token,
          Map<String, Object?>? body,
        }) async {
          if (url.contains('/auth/login')) {
            return Success(
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
            // HTTP returns task, but ALSO WS will send same task later
            return Success(
              createJSObject({
                'success': true,
                'data': [
                  {
                    'id': 'task_47',
                    'title': 'Existing Task',
                    'completed': false,
                  },
                ],
              }),
            );
          }
          throw StateError('No mock for $method $url');
        }

        final result = render(MobileApp(fetchFn: racingFetch));

        // Login
        final inputs = result.container.querySelectorAll('input');
        await userType(inputs[0], 'a@b.com');
        await userType(inputs[1], 'pass');
        fireClick(result.container.querySelectorAll('button').first);

        // Wait for task list to load
        await waitForText(result, 'Existing Task');

        // WS sends task_created for same task that's already loaded!
        // This simulates server broadcasting to all clients
        simulateWsMessage(
          '{"type":"task_created","data":'
          '{"id":"task_47","title":"Existing Task","completed":false}}',
        );

        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Count occurrences - must be exactly 1!
        final textContent = result.container.textContent;
        final matches = 'Existing Task'.allMatches(textContent).length;
        expect(
          matches,
          1,
          reason: 'WS task_created for existing task should NOT duplicate!',
        );

        result.unmount();
      },
    );

    test('task_created event adds task to list', () async {
      final mockFetch = createMockFetch({
        '/auth/login': {
          'success': true,
          'data': {
            'token': 'tok',
            'user': {'name': 'Alice'},
          },
        },
        '/tasks': {'success': true, 'data': <Map<String, Object?>>[]},
      });

      final result = render(MobileApp(fetchFn: mockFetch));

      final inputs = result.container.querySelectorAll('input');
      await userType(inputs[0], 'test@example.com');
      await userType(inputs[1], 'password');

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.first);

      await waitForText(result, 'No tasks yet');

      // Simulate websocket task_created
      simulateWsMessage(
        '{"type":"task_created","data":'
        '{"id":"ws-1","title":"WebSocket Task","completed":false}}',
      );

      await waitForText(result, 'WebSocket Task');

      result.unmount();
    });

    test('task_updated event updates task in list', () async {
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
            {'id': '1', 'title': 'Original Title', 'completed': false},
          ],
        },
      });

      final result = render(MobileApp(fetchFn: mockFetch));

      final inputs = result.container.querySelectorAll('input');
      await userType(inputs[0], 'test@example.com');
      await userType(inputs[1], 'password');

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.first);

      await waitForText(result, 'Original Title');

      // Simulate websocket task_updated
      simulateWsMessage(
        '{"type":"task_updated","data":'
        '{"id":"1","title":"Updated Title","completed":true}}',
      );

      await waitForText(result, 'Updated Title');

      result.unmount();
    });

    test('task_deleted event removes task from list', () async {
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
            {'id': '1', 'title': 'To Be Deleted', 'completed': false},
          ],
        },
      });

      final result = render(MobileApp(fetchFn: mockFetch));

      final inputs = result.container.querySelectorAll('input');
      await userType(inputs[0], 'test@example.com');
      await userType(inputs[1], 'password');

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.first);

      await waitForText(result, 'To Be Deleted');

      // Simulate websocket task_deleted
      simulateWsMessage(
        '{"type":"task_deleted","data":'
        '{"id":"1","title":"To Be Deleted","completed":false}}',
      );

      await waitForText(result, 'No tasks yet');

      result.unmount();
    });

    test('handles unknown event type gracefully', () async {
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
            {'id': '1', 'title': 'Existing Task', 'completed': false},
          ],
        },
      });

      final result = render(MobileApp(fetchFn: mockFetch));

      final inputs = result.container.querySelectorAll('input');
      await userType(inputs[0], 'test@example.com');
      await userType(inputs[1], 'password');

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.first);

      await waitForText(result, 'Existing Task');

      // Simulate websocket with unknown type
      simulateWsMessage(
        '{"type":"unknown_event","data":'
        '{"id":"1","title":"Existing Task","completed":false}}',
      );

      // Task should still be there, unchanged
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(result.container.textContent, contains('Existing Task'));

      result.unmount();
    });

    test('handles event with null data gracefully', () async {
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
            {'id': '1', 'title': 'Still Here', 'completed': false},
          ],
        },
      });

      final result = render(MobileApp(fetchFn: mockFetch));

      final inputs = result.container.querySelectorAll('input');
      await userType(inputs[0], 'test@example.com');
      await userType(inputs[1], 'password');

      final buttons = result.container.querySelectorAll('button');
      fireClick(buttons.first);

      await waitForText(result, 'Still Here');

      // Simulate websocket with null data
      simulateWsMessage('{"type":"task_created","data":null}');

      // Should not crash, task should still be there
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(result.container.textContent, contains('Still Here'));

      result.unmount();
    });
  });

  // ===== WEBSOCKET DIRECT TESTS =====

  group('WebSocket API', () {
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

    test('connectWebSocket without optional callbacks', () {
      final events = <JSObject>[];

      final ws = connectWebSocket(
        token: 'test-token',
        onTaskEvent: events.add,
        // No onOpen, onClose
      );

      expect(ws, isNotNull);

      // Should not throw when calling handlers
      final dummyEvent = JSObject();
      ws!.onopen?.callAsFunction(null, dummyEvent);
      ws.onclose?.callAsFunction(null, dummyEvent);

      ws.close();
    });
  });
}
