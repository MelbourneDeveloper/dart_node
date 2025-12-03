/// UI interaction tests for the TaskFlow web app.
///
/// Tests verify actual user interactions and state changes.
/// Run with: dart test -p chrome
@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart' hide render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  group('Login Form Interactions', () {
    test('typing in email field updates the input value', () async {
      final loginForm = registerFunctionComponent((props) {
        final emailState = useState('');
        return div(
          children: [
            input(
              type: 'email',
              placeholder: 'you@example.com',
              value: emailState.value,
              className: 'input',
              onChange: (e) => emailState.set(_getInputValue(e)),
              props: {'data-testid': 'email-input'},
            ),
            pEl(
              'Email: ${emailState.value}',
              props: {'data-testid': 'email-display'},
            ),
          ],
        );
      });

      final result = render(fc(loginForm));
      final emailInput = result.getByTestId('email-input');

      await userType(emailInput, 'test@example.com');

      expect(
        result.getByTestId('email-display').textContent,
        equals('Email: test@example.com'),
      );

      result.unmount();
    });

    test('typing in password field updates the input value', () async {
      final loginForm = registerFunctionComponent((props) {
        final passState = useState('');
        return div(
          children: [
            input(
              type: 'password',
              placeholder: '••••••••',
              value: passState.value,
              className: 'input',
              onChange: (e) => passState.set(_getInputValue(e)),
              props: {'data-testid': 'password-input'},
            ),
            pEl(
              'Password length: ${passState.value.length}',
              props: {'data-testid': 'password-display'},
            ),
          ],
        );
      });

      final result = render(fc(loginForm));
      final passwordInput = result.getByTestId('password-input');

      await userType(passwordInput, 'secret123');

      expect(
        result.getByTestId('password-display').textContent,
        equals('Password length: 9'),
      );

      result.unmount();
    });

    test('clicking register link switches to register view', () {
      final authView = registerFunctionComponent((props) {
        final viewState = useState('login');
        return div(
          children: [
            pEl(
              'Current view: ${viewState.value}',
              props: {'data-testid': 'view'},
            ),
            if (viewState.value == 'login')
              button(
                text: 'Register',
                className: 'btn-link',
                onClick: () => viewState.set('register'),
                props: {'data-testid': 'register-link'},
              )
            else
              button(
                text: 'Sign In',
                className: 'btn-link',
                onClick: () => viewState.set('login'),
                props: {'data-testid': 'login-link'},
              ),
          ],
        );
      });

      final result = render(fc(authView));

      expect(
        result.getByTestId('view').textContent,
        equals('Current view: login'),
      );

      fireClick(result.getByTestId('register-link'));

      expect(
        result.getByTestId('view').textContent,
        equals('Current view: register'),
      );

      result.unmount();
    });

    test('submit button shows loading state when clicked', () {
      final loginForm = registerFunctionComponent((props) {
        final loadingState = useState(false);
        return div(
          children: [
            button(
              text: loadingState.value ? 'Signing in...' : 'Sign In',
              className: 'btn btn-primary btn-full',
              onClick: loadingState.value ? null : () => loadingState.set(true),
              props: {'data-testid': 'submit-btn'},
            ),
          ],
        );
      });

      final result = render(fc(loginForm));
      final submitBtn = result.getByTestId('submit-btn');

      expect(submitBtn.textContent, equals('Sign In'));

      fireClick(submitBtn);

      expect(
        result.getByTestId('submit-btn').textContent,
        equals('Signing in...'),
      );

      result.unmount();
    });

    test('error message displays when error state is set', () {
      final loginForm = registerFunctionComponent((props) {
        final errorState = useState<String?>(null);
        return div(
          children: [
            if (errorState.value != null)
              div(
                className: 'error-msg',
                child: span(errorState.value!),
                props: {'data-testid': 'error-msg'},
              )
            else
              span(''),
            button(
              text: 'Trigger Error',
              onClick: () => errorState.set('Invalid credentials'),
              props: {'data-testid': 'error-btn'},
            ),
          ],
        );
      });

      final result = render(fc(loginForm));

      expect(result.queryByTestId('error-msg'), isNull);

      fireClick(result.getByTestId('error-btn'));

      expect(
        result.getByTestId('error-msg').textContent,
        equals('Invalid credentials'),
      );

      result.unmount();
    });
  });

  group('Register Form Interactions', () {
    test('typing in name field updates the input value', () async {
      final registerForm = registerFunctionComponent((props) {
        final nameState = useState('');
        return div(
          children: [
            input(
              type: 'text',
              placeholder: 'Your name',
              value: nameState.value,
              className: 'input',
              onChange: (e) => nameState.set(_getInputValue(e)),
              props: {'data-testid': 'name-input'},
            ),
            pEl(
              'Name: ${nameState.value}',
              props: {'data-testid': 'name-display'},
            ),
          ],
        );
      });

      final result = render(fc(registerForm));
      final nameInput = result.getByTestId('name-input');

      await userType(nameInput, 'John Doe');

      expect(
        result.getByTestId('name-display').textContent,
        equals('Name: John Doe'),
      );

      result.unmount();
    });

    test('clicking sign in link switches to login view', () {
      final authView = registerFunctionComponent((props) {
        final viewState = useState('register');
        return div(
          children: [
            pEl(
              'Current view: ${viewState.value}',
              props: {'data-testid': 'view'},
            ),
            if (viewState.value == 'register')
              button(
                text: 'Sign In',
                className: 'btn-link',
                onClick: () => viewState.set('login'),
                props: {'data-testid': 'login-link'},
              )
            else
              button(
                text: 'Register',
                className: 'btn-link',
                onClick: () => viewState.set('register'),
                props: {'data-testid': 'register-link'},
              ),
          ],
        );
      });

      final result = render(fc(authView));

      expect(
        result.getByTestId('view').textContent,
        equals('Current view: register'),
      );

      fireClick(result.getByTestId('login-link'));

      expect(
        result.getByTestId('view').textContent,
        equals('Current view: login'),
      );

      result.unmount();
    });

    test('create account button shows loading state', () {
      final registerForm = registerFunctionComponent((props) {
        final loadingState = useState(false);
        return button(
          text: loadingState.value ? 'Creating...' : 'Create Account',
          className: 'btn btn-primary btn-full',
          onClick: loadingState.value ? null : () => loadingState.set(true),
          props: {'data-testid': 'submit-btn'},
        );
      });

      final result = render(fc(registerForm));

      expect(
        result.getByTestId('submit-btn').textContent,
        equals('Create Account'),
      );

      fireClick(result.getByTestId('submit-btn'));

      expect(
        result.getByTestId('submit-btn').textContent,
        equals('Creating...'),
      );

      result.unmount();
    });
  });

  group('Header Interactions', () {
    test('logout button clears user state', () {
      final headerComponent = registerFunctionComponent((props) {
        final userState = useState<String?>('John');
        return div(
          children: [
            if (userState.value != null)
              div(
                children: [
                  span(
                    'Welcome, ${userState.value}',
                    props: {'data-testid': 'user-name'},
                  ),
                  button(
                    text: 'Logout',
                    className: 'btn btn-ghost',
                    onClick: () => userState.set(null),
                    props: {'data-testid': 'logout-btn'},
                  ),
                ],
              )
            else
              pEl('Logged out', props: {'data-testid': 'logged-out'}),
          ],
        );
      });

      final result = render(fc(headerComponent));

      expect(
        result.getByTestId('user-name').textContent,
        equals('Welcome, John'),
      );

      fireClick(result.getByTestId('logout-btn'));

      expect(result.queryByTestId('user-name'), isNull);
      expect(
        result.getByTestId('logged-out').textContent,
        equals('Logged out'),
      );

      result.unmount();
    });
  });

  group('Task Manager Interactions', () {
    test('typing in task title input updates value', () async {
      final taskForm = registerFunctionComponent((props) {
        final newTaskState = useState('');
        return div(
          children: [
            input(
              type: 'text',
              placeholder: 'What needs to be done?',
              value: newTaskState.value,
              className: 'input input-lg',
              onChange: (e) => newTaskState.set(_getInputValue(e)),
              props: {'data-testid': 'task-input'},
            ),
            pEl(
              'Task: ${newTaskState.value}',
              props: {'data-testid': 'task-display'},
            ),
          ],
        );
      });

      final result = render(fc(taskForm));

      await userType(result.getByTestId('task-input'), 'Buy groceries');

      expect(
        result.getByTestId('task-display').textContent,
        equals('Task: Buy groceries'),
      );

      result.unmount();
    });

    test('clicking add task button adds task to list', () {
      final taskManager = registerFunctionComponent((props) {
        // Use comma-separated string for list state (JS interop compatible)
        final tasksStr = useState('');
        final newTaskState = useState('New Task');

        List<String> getTasks() =>
            tasksStr.value.isEmpty ? [] : tasksStr.value.split(',');

        return div(
          children: [
            button(
              text: '+ Add Task',
              className: 'btn btn-primary',
              onClick: () {
                final current = tasksStr.value;
                tasksStr.set(
                  current.isEmpty
                      ? newTaskState.value
                      : '$current,${newTaskState.value}',
                );
                newTaskState.set('');
              },
              props: {'data-testid': 'add-btn'},
            ),
            div(
              className: 'task-list',
              props: {'data-testid': 'task-list'},
              children: getTasks()
                  .map((task) => div(className: 'task-item', child: span(task)))
                  .toList(),
            ),
            pEl(
              'Task count: ${getTasks().length}',
              props: {'data-testid': 'count'},
            ),
          ],
        );
      });

      final result = render(fc(taskManager));

      expect(result.getByTestId('count').textContent, equals('Task count: 0'));

      fireClick(result.getByTestId('add-btn'));

      expect(result.getByTestId('count').textContent, equals('Task count: 1'));
      expect(result.getByTestId('task-list').textContent, contains('New Task'));

      result.unmount();
    });

    test('clicking checkbox toggles task completion', () {
      final taskItem = registerFunctionComponent((props) {
        final completedState = useState(false);
        return div(
          className: completedState.value ? 'task-item completed' : 'task-item',
          props: {'data-testid': 'task-item'},
          children: [
            div(
              className: completedState.value
                  ? 'task-checkbox completed'
                  : 'task-checkbox',
              props: {
                'data-testid': 'checkbox',
                'onClick': ((JSAny? _) => completedState.set(
                  !completedState.value,
                )).toJS,
              },
              child: completedState.value ? span('\u2713') : span(''),
            ),
            span('Test Task', className: 'task-title'),
            pEl(
              'Status: ${completedState.value ? "completed" : "pending"}',
              props: {'data-testid': 'status'},
            ),
          ],
        );
      });

      final result = render(fc(taskItem));

      expect(
        result.getByTestId('status').textContent,
        equals('Status: pending'),
      );
      expect(result.getByTestId('task-item').className, equals('task-item'));

      fireClick(result.getByTestId('checkbox'));

      expect(
        result.getByTestId('status').textContent,
        equals('Status: completed'),
      );
      expect(
        result.getByTestId('task-item').className,
        equals('task-item completed'),
      );

      fireClick(result.getByTestId('checkbox'));

      expect(
        result.getByTestId('status').textContent,
        equals('Status: pending'),
      );

      result.unmount();
    });

    test('clicking delete button removes task from list', () {
      final taskManager = registerFunctionComponent((props) {
        // Use comma-separated string for list state
        final tasksStr = useState('Task 1,Task 2,Task 3');

        List<String> getTasks() =>
            tasksStr.value.isEmpty ? [] : tasksStr.value.split(',');

        return div(
          children: [
            div(
              className: 'task-list',
              children: getTasks()
                  .map(
                    (task) => div(
                      className: 'task-item',
                      children: [
                        span(task),
                        button(
                          text: '\u00D7',
                          className: 'btn-delete',
                          onClick: () {
                            final filtered = getTasks()
                                .where((t) => t != task)
                                .join(',');
                            tasksStr.set(filtered);
                          },
                          props: {'data-testid': 'delete-$task'},
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
            pEl(
              'Task count: ${getTasks().length}',
              props: {'data-testid': 'count'},
            ),
          ],
        );
      });

      final result = render(fc(taskManager));

      expect(result.getByTestId('count').textContent, equals('Task count: 3'));

      fireClick(result.getByTestId('delete-Task 2'));

      expect(result.getByTestId('count').textContent, equals('Task count: 2'));
      expect(result.queryByTestId('delete-Task 2'), isNull);

      result.unmount();
    });

    test('empty state shows when no tasks exist', () {
      final taskManager = registerFunctionComponent((props) {
        // Use comma-separated string for list state
        final tasksStr = useState('');

        List<String> getTasks() =>
            tasksStr.value.isEmpty ? [] : tasksStr.value.split(',');

        return div(
          children: [
            if (getTasks().isEmpty)
              div(
                className: 'empty-state',
                props: {'data-testid': 'empty-state'},
                children: [
                  pEl('No tasks yet. Add one above!', className: 'empty-text'),
                ],
              )
            else
              div(
                className: 'task-list',
                children: getTasks().map(pEl).toList(),
              ),
            button(
              text: 'Add Task',
              onClick: () {
                final current = tasksStr.value;
                tasksStr.set(
                  current.isEmpty ? 'New Task' : '$current,New Task',
                );
              },
              props: {'data-testid': 'add-btn'},
            ),
          ],
        );
      });

      final result = render(fc(taskManager));

      expect(result.getByTestId('empty-state'), isNotNull);

      fireClick(result.getByTestId('add-btn'));

      expect(result.queryByTestId('empty-state'), isNull);

      result.unmount();
    });

    test('stats update when tasks are completed', () {
      final taskStats = registerFunctionComponent((props) {
        // Use separate state for each task's completion status
        final task1Done = useState(false);
        final task2Done = useState(false);
        final task3Done = useState(true);

        int getCompleted() => [
          task1Done.value,
          task2Done.value,
          task3Done.value,
        ].where((done) => done).length;

        return div(
          children: [
            span(
              '${getCompleted()}/3 completed',
              props: {'data-testid': 'stats'},
            ),
            button(
              text: 'Complete Task 1',
              onClick: () => task1Done.set(true),
              props: {'data-testid': 'complete-btn'},
            ),
          ],
        );
      });

      final result = render(fc(taskStats));

      expect(result.getByTestId('stats').textContent, equals('1/3 completed'));

      fireClick(result.getByTestId('complete-btn'));

      expect(result.getByTestId('stats').textContent, equals('2/3 completed'));

      result.unmount();
    });
  });

  group('Auth Flow Interactions', () {
    test('successful login shows task manager', () {
      final app = registerFunctionComponent((props) {
        final tokenState = useState<String?>(null);
        final viewState = useState('login');

        return div(
          children: [
            if (tokenState.value == null)
              div(
                props: {'data-testid': 'auth-view'},
                children: [
                  pEl('View: ${viewState.value}'),
                  button(
                    text: 'Sign In',
                    onClick: () => tokenState.set('fake-token'),
                    props: {'data-testid': 'login-btn'},
                  ),
                ],
              )
            else
              div(
                props: {'data-testid': 'task-manager'},
                children: [
                  pEl('Task Manager'),
                  button(
                    text: 'Logout',
                    onClick: () => tokenState.set(null),
                    props: {'data-testid': 'logout-btn'},
                  ),
                ],
              ),
          ],
        );
      });

      final result = render(fc(app));

      expect(result.getByTestId('auth-view'), isNotNull);
      expect(result.queryByTestId('task-manager'), isNull);

      fireClick(result.getByTestId('login-btn'));

      expect(result.queryByTestId('auth-view'), isNull);
      expect(result.getByTestId('task-manager'), isNotNull);

      fireClick(result.getByTestId('logout-btn'));

      expect(result.getByTestId('auth-view'), isNotNull);
      expect(result.queryByTestId('task-manager'), isNull);

      result.unmount();
    });

    test('switching between login and register views', () {
      final authView = registerFunctionComponent((props) {
        final viewState = useState('login');

        return div(
          children: [
            pEl(
              'Current: ${viewState.value}',
              props: {'data-testid': 'current-view'},
            ),
            if (viewState.value == 'login')
              div(
                props: {'data-testid': 'login-form'},
                children: [
                  h2('Sign In', className: 'auth-title'),
                  button(
                    text: 'Register',
                    onClick: () => viewState.set('register'),
                    props: {'data-testid': 'to-register'},
                  ),
                ],
              )
            else
              div(
                props: {'data-testid': 'register-form'},
                children: [
                  h2('Create Account', className: 'auth-title'),
                  button(
                    text: 'Sign In',
                    onClick: () => viewState.set('login'),
                    props: {'data-testid': 'to-login'},
                  ),
                ],
              ),
          ],
        );
      });

      final result = render(fc(authView));

      expect(
        result.getByTestId('current-view').textContent,
        equals('Current: login'),
      );
      expect(result.getByTestId('login-form'), isNotNull);
      expect(result.queryByTestId('register-form'), isNull);

      fireClick(result.getByTestId('to-register'));

      expect(
        result.getByTestId('current-view').textContent,
        equals('Current: register'),
      );
      expect(result.queryByTestId('login-form'), isNull);
      expect(result.getByTestId('register-form'), isNotNull);

      fireClick(result.getByTestId('to-login'));

      expect(
        result.getByTestId('current-view').textContent,
        equals('Current: login'),
      );
      expect(result.getByTestId('login-form'), isNotNull);

      result.unmount();
    });
  });
}

String _getInputValue(JSAny event) {
  final obj = event as JSObject;
  final target = obj.getProperty('target'.toJS);
  return switch (target) {
    final JSObject t => switch (t.getProperty('value'.toJS)) {
      final JSString v => v.toDart,
      _ => throw StateError('Input value is not a string'),
    },
    _ => throw StateError('Event target is not an object'),
  };
}
