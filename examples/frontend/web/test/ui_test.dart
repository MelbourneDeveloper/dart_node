/// UI interaction tests for Frontend Web components
/// Compiled to JS and run with Jest + React Testing Library
///
/// Build: dart compile js ui_test.dart -o dist/ui_test.js
/// Run: npm test
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart';
import 'package:ui_testing/ui_testing.dart';

// =============================================================================
// Testing Library Bindings
// =============================================================================

@JS('testingLibrary.render')
external JSObject _render(JSObject element);

@JS('testingLibrary.screen')
external JSObject get _screen;

@JS('testingLibrary.fireEvent')
external JSObject get _fireEvent;

@JS('userEvent.setup')
external JSObject _userEventSetup();

// =============================================================================
// Test Utilities
// =============================================================================

/// Render a React element for testing
JSObject render(JSObject element) => _render(element);

/// Screen queries
JSObject get screen => _screen;

/// Fire events on elements
JSObject get fireEvent => _fireEvent;

/// User event instance for realistic interactions
JSObject userEvent() => _userEventSetup();

/// Query by test ID
JSObject? queryByTestId(String testId) =>
    screen.callMethod('queryByTestId'.toJS, testId.toJS) as JSObject?;

/// Get by test ID (throws if not found)
JSObject getByTestId(String testId) =>
    switch (screen.callMethod('getByTestId'.toJS, testId.toJS)) {
      final JSObject obj => obj,
      _ => throw StateError('Element with testId "$testId" not found'),
    };

/// Query by text
JSObject? queryByText(String text) =>
    screen.callMethod('queryByText'.toJS, text.toJS) as JSObject?;

/// Get by text (throws if not found)
JSObject getByText(String text) =>
    screen.callMethod('getByText'.toJS, text.toJS)! as JSObject;

/// Click an element
void click(JSObject element) {
  fireEvent.callMethod('click'.toJS, element);
}

/// Change input value
void changeValue(JSObject element, String value) {
  final eventInit = JSObject()
    ..setProperty(
      'target'.toJS,
      JSObject()..setProperty('value'.toJS, value.toJS),
    );
  fireEvent.callMethod('change'.toJS, element, eventInit);
}

// =============================================================================
// Test Components - Login Form
// =============================================================================

/// Login form component for testing authentication flow
JSObject loginFormComponent({
  void Function(String email, String password)? onSubmit,
  void Function()? onRegisterClick,
}) =>
    createElement(
      ((JSAny props) {
        final emailState = useState(''.toJS);
        final passState = useState(''.toJS);
        final errorState = useState(null);
        final loadingState = useState(false.toJS);

        final email = stringFromState(emailState.$1);
        final password = stringFromState(passState.$1);
        final error = (errorState.$1 as JSString?)?.toDart;
        final loading = boolFromState(loadingState.$1);

        final setEmail = wrapSetState<String>(emailState.$2);
        final setPassword = wrapSetState<String>(passState.$2);
        final setError = wrapSetState<String?>(errorState.$2);
        final setLoading = wrapSetState<bool>(loadingState.$2);

        void handleSubmit() {
          (email.isEmpty || password.isEmpty)
              ? setError(errorMessageAllFieldsRequired)
              : () {
                  setLoading(true);
                  setError(null);
                  onSubmit?.call(email, password);
                }();
        }

        return div(
          props: {'data-testid': testIdLoginForm},
          children: [
            h2('Sign In'),
            if (error != null)
              div(
                props: {'data-testid': testIdErrorMessage},
                child: span(error),
              )
            else
              span(''),
            div(
              children: [
                input(
                  type: 'email',
                  placeholder: 'Email',
                  value: email,
                  onChange: (e) => setEmail(_extractInputValue(e)),
                  props: {'data-testid': testIdEmailInput},
                ),
              ],
            ),
            div(
              children: [
                input(
                  type: 'password',
                  placeholder: 'Password',
                  value: password,
                  onChange: (e) => setPassword(_extractInputValue(e)),
                  props: {'data-testid': testIdPasswordInput},
                ),
              ],
            ),
            button(
              text: loading ? 'Signing in...' : 'Sign In',
              onClick: loading ? null : handleSubmit,
              props: {'data-testid': testIdSubmitBtn},
            ),
            div(
              children: [
                span("Don't have an account? "),
                button(
                  text: 'Register',
                  onClick: onRegisterClick,
                  props: {'data-testid': testIdRegisterLink},
                ),
              ],
            ),
          ],
        );
      }).toJS,
    );

// =============================================================================
// Test Components - Register Form
// =============================================================================

/// Register form component for testing registration flow
JSObject registerFormComponent({
  void Function(String name, String email, String password)? onSubmit,
  void Function()? onLoginClick,
}) =>
    createElement(
      ((JSAny props) {
        final nameState = useState(''.toJS);
        final emailState = useState(''.toJS);
        final passState = useState(''.toJS);
        final errorState = useState(null);
        final loadingState = useState(false.toJS);

        final name = stringFromState(nameState.$1);
        final email = stringFromState(emailState.$1);
        final password = stringFromState(passState.$1);
        final error = (errorState.$1 as JSString?)?.toDart;
        final loading = boolFromState(loadingState.$1);

        final setName = wrapSetState<String>(nameState.$2);
        final setEmail = wrapSetState<String>(emailState.$2);
        final setPassword = wrapSetState<String>(passState.$2);
        final setError = wrapSetState<String?>(errorState.$2);
        final setLoading = wrapSetState<bool>(loadingState.$2);

        void handleSubmit() {
          (name.isEmpty || email.isEmpty || password.isEmpty)
              ? setError(errorMessageAllFieldsRequired)
              : () {
                  setLoading(true);
                  setError(null);
                  onSubmit?.call(name, email, password);
                }();
        }

        return div(
          props: {'data-testid': testIdRegisterForm},
          children: [
            h2('Create Account'),
            if (error != null)
              div(
                props: {'data-testid': testIdErrorMessage},
                child: span(error),
              )
            else
              span(''),
            div(
              children: [
                input(
                  type: 'text',
                  placeholder: 'Name',
                  value: name,
                  onChange: (e) => setName(_extractInputValue(e)),
                  props: {'data-testid': testIdNameInput},
                ),
              ],
            ),
            div(
              children: [
                input(
                  type: 'email',
                  placeholder: 'Email',
                  value: email,
                  onChange: (e) => setEmail(_extractInputValue(e)),
                  props: {'data-testid': testIdEmailInput},
                ),
              ],
            ),
            div(
              children: [
                input(
                  type: 'password',
                  placeholder: 'Password',
                  value: password,
                  onChange: (e) => setPassword(_extractInputValue(e)),
                  props: {'data-testid': testIdPasswordInput},
                ),
              ],
            ),
            button(
              text: loading ? 'Creating...' : 'Create Account',
              onClick: loading ? null : handleSubmit,
              props: {'data-testid': testIdSubmitBtn},
            ),
            div(
              children: [
                span('Already have an account? '),
                button(
                  text: 'Sign In',
                  onClick: onLoginClick,
                  props: {'data-testid': testIdLoginLink},
                ),
              ],
            ),
          ],
        );
      }).toJS,
    );

// =============================================================================
// Test Components - Task Manager
// =============================================================================

/// Task manager component for testing task CRUD operations
JSObject taskManagerComponent({List<Map<String, dynamic>>? initialTasks}) =>
    createElement(
      ((JSAny props) {
        final tasksState = useState(
          (initialTasks ?? [])
              .map((t) {
                final obj = JSObject()
                  ..setProperty('id'.toJS, (t['id'] as String).toJS)
                  ..setProperty('title'.toJS, (t['title'] as String).toJS)
                  ..setProperty(
                    'completed'.toJS,
                    (t['completed'] as bool).toJS,
                  );
                return obj as JSAny;
              })
              .toList()
              .toJS,
        );
        final newTaskState = useState(''.toJS);

        final tasks = listFromState(tasksState.$1);
        final newTask = stringFromState(newTaskState.$1);

        final setNewTask = wrapSetState<String>(newTaskState.$2);

        void addTask() {
          switch (newTask.trim().isEmpty) {
            case true:
              return;
            case false:
              final id = DateTime.now().millisecondsSinceEpoch.toString();
              final task = JSObject()
                ..setProperty('id'.toJS, id.toJS)
                ..setProperty('title'.toJS, newTask.toJS)
                ..setProperty('completed'.toJS, false.toJS);
              tasksState.$2.callAsFunction(null, [...tasks, task].toJS);
              setNewTask('');
          }
        }

        void toggleTask(String id) {
          final updated = tasks.map((t) {
            final obj = switch (t) {
              final JSObject o => o,
              _ => throw StateError('Invalid task'),
            };
            final taskId = (obj['id'] as JSString?)?.toDart;
            return (taskId == id) ? _toggleTaskCompleted(obj) : t;
          }).toList();
          tasksState.$2.callAsFunction(null, updated.toJS);
        }

        void deleteTask(String id) {
          final filtered = tasks.where((t) {
            final obj = switch (t) {
              final JSObject o => o,
              _ => throw StateError('Invalid task'),
            };
            final taskId = (obj['id'] as JSString?)?.toDart;
            return taskId != id;
          }).toList();
          tasksState.$2.callAsFunction(null, filtered.toJS);
        }

        final taskList = tasks
            .map((t) => switch (t) {
                  final JSObject o => o,
                  _ => throw StateError('Invalid task'),
                })
            .toList();
        final completed =
            taskList.where((t) => boolFromState(t['completed'])).length;

        return div(
          props: {'data-testid': testIdTaskManager},
          children: [
            div(
              children: [
                h2('Your Tasks'),
                span(
                  '$completed/${taskList.length} completed',
                  props: {'data-testid': testIdTaskStats},
                ),
              ],
            ),
            div(
              children: [
                input(
                  type: 'text',
                  placeholder: 'What needs to be done?',
                  value: newTask,
                  onChange: (e) => setNewTask(_extractInputValue(e)),
                  props: {'data-testid': testIdNewTaskInput},
                ),
                button(
                  text: '+ Add Task',
                  onClick: addTask,
                  props: {'data-testid': testIdAddTaskBtn},
                ),
              ],
            ),
            div(
              props: {'data-testid': testIdTaskList},
              children: taskList.isEmpty
                  ? [
                      div(
                        props: {'data-testid': testIdEmptyState},
                        child: span(textPatternNoTasks),
                      ),
                    ]
                  : taskList.asMap().entries.map((entry) {
                      final task = entry.value;
                      final id = switch (task['id']) {
                        final JSString s => s.toDart,
                        _ => throw StateError('Invalid task id'),
                      };
                      final title = switch (task['title']) {
                        final JSString s => s.toDart,
                        _ => throw StateError('Invalid task title'),
                      };
                      final isCompleted = boolFromState(task['completed']);

                      return div(
                        props: {
                          'key': id,
                          'data-testid': testIdTaskItem(entry.key),
                        },
                        children: [
                          div(
                            props: {
                              'onClick': ((JSAny? _) => toggleTask(id)).toJS,
                              'data-testid': testIdToggleTask(entry.key),
                            },
                            child: isCompleted ? span('✓') : span(''),
                          ),
                          span(
                            title,
                            props: {'data-testid': testIdTaskTitle(entry.key)},
                          ),
                          button(
                            text: '×',
                            onClick: () => deleteTask(id),
                            props: {'data-testid': testIdDeleteTask(entry.key)},
                          ),
                        ],
                      );
                    }).toList(),
            ),
          ],
        );
      }).toJS,
    );

// =============================================================================
// Test Components - Header
// =============================================================================

/// Header component for testing user info and logout
JSObject headerComponent({String? userName, void Function()? onLogout}) =>
    createElement(
      ((JSAny props) => header(
            props: {'data-testid': testIdAppHeader},
            children: [
              div(
                children: [
                  h1('TaskFlow'),
                  if (userName != null)
                    div(
                      children: [
                        span(
                          'Welcome, $userName',
                          props: {'data-testid': testIdUserName},
                        ),
                        button(
                          text: 'Logout',
                          onClick: onLogout,
                          props: {'data-testid': testIdLogoutBtn},
                        ),
                      ],
                    )
                  else
                    span(''),
                ],
              ),
            ],
          )).toJS,
    );

// =============================================================================
// Helpers
// =============================================================================

JSObject _toggleTaskCompleted(JSObject task) {
  final completed = boolFromState(task['completed']);
  final newTask = JSObject()
    ..setProperty('id'.toJS, task['id'])
    ..setProperty('title'.toJS, task['title'])
    ..setProperty('completed'.toJS, (!completed).toJS);
  return newTask;
}

String _extractInputValue(JSAny event) {
  final obj = event as JSObject;
  final target = obj['target'] as JSObject?;
  return (target?['value'] as JSString?)?.toDart ?? '';
}

// =============================================================================
// Export test components for Jest
// =============================================================================

@JS('frontendWebTests')
external set _frontendWebTests(JSObject value);

void main() {
  _frontendWebTests = JSObject()
    // Export components
    ..setProperty(
      'loginFormComponent'.toJS,
      ((JSAny? onSubmit, JSAny? onRegisterClick) =>
          (onSubmit == null || onSubmit.isUndefinedOrNull)
              ? loginFormComponent(
                  onRegisterClick: onRegisterClick.isA<JSFunction>()
                      ? () => (onRegisterClick! as JSFunction).callAsFunction()
                      : null,
                )
              : loginFormComponent(
                  onSubmit: (email, password) => (onSubmit as JSFunction)
                      .callAsFunction(null, email.toJS, password.toJS),
                  onRegisterClick: onRegisterClick.isA<JSFunction>()
                      ? () => (onRegisterClick! as JSFunction).callAsFunction()
                      : null,
                )).toJS,
    )
    ..setProperty(
      'registerFormComponent'.toJS,
      ((JSAny? onSubmit, JSAny? onLoginClick) =>
          (onSubmit == null || onSubmit.isUndefinedOrNull)
              ? registerFormComponent(
                  onLoginClick: onLoginClick.isA<JSFunction>()
                      ? () => (onLoginClick! as JSFunction).callAsFunction()
                      : null,
                )
              : registerFormComponent(
                  onSubmit: (name, email, password) =>
                      (onSubmit as JSFunction).callAsFunction(
                    null,
                    name.toJS,
                    email.toJS,
                    password.toJS,
                  ),
                  onLoginClick: onLoginClick.isA<JSFunction>()
                      ? () => (onLoginClick! as JSFunction).callAsFunction()
                      : null,
                )).toJS,
    )
    ..setProperty(
      'taskManagerComponent'.toJS,
      ((JSAny? initialTasks) => (initialTasks == null ||
              initialTasks.isUndefinedOrNull)
          ? taskManagerComponent()
          : taskManagerComponent(
              initialTasks: (initialTasks as JSArray)
                  .toDart
                  .map((t) {
                    final obj = switch (t) {
                      final JSObject o => o,
                      _ => throw StateError('Invalid task'),
                    };
                    return {
                      'id': switch (obj['id']) {
                        final JSString s => s.toDart,
                        _ => throw StateError('Invalid id'),
                      },
                      'title': switch (obj['title']) {
                        final JSString s => s.toDart,
                        _ => throw StateError('Invalid title'),
                      },
                      'completed': switch (obj['completed']) {
                        final JSBoolean b => b.toDart,
                        _ => throw StateError('Invalid completed'),
                      },
                    };
                  })
                  .toList()
                  .cast<Map<String, dynamic>>(),
            )).toJS,
    )
    ..setProperty(
      'headerComponent'.toJS,
      ((JSAny? userName, JSAny? onLogout) => headerComponent(
            userName: userName.isA<JSString>()
                ? (userName! as JSString).toDart
                : null,
            onLogout: onLogout.isA<JSFunction>()
                ? () => (onLogout! as JSFunction).callAsFunction()
                : null,
          )).toJS,
    )
    // Export utilities
    ..setProperty('render'.toJS, render.toJS)
    ..setProperty('getByTestId'.toJS, getByTestId.toJS)
    ..setProperty('queryByTestId'.toJS, queryByTestId.toJS)
    ..setProperty('getByText'.toJS, getByText.toJS)
    ..setProperty('queryByText'.toJS, queryByText.toJS)
    ..setProperty('click'.toJS, click.toJS)
    ..setProperty('changeValue'.toJS, changeValue.toJS)
    ..setProperty('userEvent'.toJS, userEvent.toJS);
}
