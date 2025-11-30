/// UI interaction tests for Mobile App components
/// Compiled to JS and run with Jest + React Native Testing Library
///
/// Build: dart compile js ui_test.dart -o dist/ui_test.js
/// Run: npm test
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react_native/dart_node_react_native.dart';
import 'package:ui_testing/ui_testing.dart';

// =============================================================================
// Testing Library Bindings
// =============================================================================

@JS('rnTestingLibrary.render')
external JSObject _render(JSObject element);

@JS('rnTestingLibrary.screen')
external JSObject get _screen;

@JS('rnTestingLibrary.fireEvent')
external JSObject get _fireEvent;

// =============================================================================
// Test Utilities
// =============================================================================

/// Render a React Native element for testing
JSObject render(JSObject element) => _render(element);

/// Screen queries
JSObject get screen => _screen;

/// Fire events on elements
JSObject get fireEvent => _fireEvent;

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
    switch (screen.callMethod('getByText'.toJS, text.toJS)) {
      final JSObject obj => obj,
      _ => throw StateError('Element with text "$text" not found'),
    };

/// Press on a touchable element
void press(JSObject element) {
  fireEvent.callMethod('press'.toJS, element);
}

/// Change text in a TextInput
void changeText(JSObject element, String text) {
  fireEvent.callMethod('changeText'.toJS, element, text.toJS);
}

// =============================================================================
// Test Components - Login Screen
// =============================================================================

/// Login screen component for testing authentication flow
JSObject loginScreenComponent({
  void Function(String email, String password)? onSubmit,
  void Function()? onRegisterClick,
}) =>
    functionalComponent('LoginScreen', (props) {
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

      return view(
        props: {'testID': testIdLoginForm},
        children: [
          text('Sign In'),
          if (error != null)
            view(
              props: {'testID': testIdErrorMessage},
              child: text(error),
            )
          else
            view(),
          textInput(
            placeholder: 'Email',
            value: email,
            onChangeText: setEmail,
            props: {'testID': testIdEmailInput},
          ),
          textInput(
            placeholder: 'Password',
            value: password,
            secureTextEntry: true,
            onChangeText: setPassword,
            props: {'testID': testIdPasswordInput},
          ),
          touchableOpacity(
            onPress: loading ? null : handleSubmit,
            props: {'testID': testIdSubmitBtn},
            child: text(loading ? 'Signing in...' : 'Sign In'),
          ),
          view(
            children: [
              text("Don't have an account? "),
              touchableOpacity(
                onPress: onRegisterClick,
                props: {'testID': testIdRegisterLink},
                child: text('Register'),
              ),
            ],
          ),
        ],
      );
    });

// =============================================================================
// Test Components - Register Screen
// =============================================================================

/// Register screen component for testing registration flow
JSObject registerScreenComponent({
  void Function(String name, String email, String password)? onSubmit,
  void Function()? onLoginClick,
}) =>
    functionalComponent('RegisterScreen', (props) {
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

      return view(
        props: {'testID': testIdRegisterForm},
        children: [
          text('Create Account'),
          if (error != null)
            view(
              props: {'testID': testIdErrorMessage},
              child: text(error),
            )
          else
            view(),
          textInput(
            placeholder: 'Name',
            value: name,
            onChangeText: setName,
            props: {'testID': testIdNameInput},
          ),
          textInput(
            placeholder: 'Email',
            value: email,
            onChangeText: setEmail,
            props: {'testID': testIdEmailInput},
          ),
          textInput(
            placeholder: 'Password',
            value: password,
            secureTextEntry: true,
            onChangeText: setPassword,
            props: {'testID': testIdPasswordInput},
          ),
          touchableOpacity(
            onPress: loading ? null : handleSubmit,
            props: {'testID': testIdSubmitBtn},
            child: text(loading ? 'Creating...' : 'Create Account'),
          ),
          view(
            children: [
              text('Already have an account? '),
              touchableOpacity(
                onPress: onLoginClick,
                props: {'testID': testIdLoginLink},
                child: text('Sign In'),
              ),
            ],
          ),
        ],
      );
    });

// =============================================================================
// Test Components - Task List Screen
// =============================================================================

/// Task list component for testing task CRUD operations
JSObject taskListComponent({List<Map<String, dynamic>>? initialTasks}) =>
    functionalComponent('TaskListScreen', (props) {
      final tasksState = useState(
        (initialTasks ?? [])
            .map((t) {
              final obj = JSObject()
                ..setProperty('id'.toJS, (t['id'] as String).toJS)
                ..setProperty('title'.toJS, (t['title'] as String).toJS)
                ..setProperty('completed'.toJS, (t['completed'] as bool).toJS);
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

      return view(
        props: {'testID': testIdTaskManager},
        children: [
          view(
            children: [
              text('Your Tasks'),
              text(
                '$completed/${taskList.length} completed',
                props: {'testID': testIdTaskStats},
              ),
            ],
          ),
          view(
            children: [
              textInput(
                placeholder: 'What needs to be done?',
                value: newTask,
                onChangeText: setNewTask,
                props: {'testID': testIdNewTaskInput},
              ),
              touchableOpacity(
                onPress: addTask,
                props: {'testID': testIdAddTaskBtn},
                child: text('+ Add Task'),
              ),
            ],
          ),
          view(
            props: {'testID': testIdTaskList},
            children: taskList.isEmpty
                ? [
                    view(
                      props: {'testID': testIdEmptyState},
                      child: text(textPatternNoTasks),
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

                    return view(
                      props: {
                        'key': id,
                        'testID': testIdTaskItem(entry.key),
                      },
                      children: [
                        touchableOpacity(
                          onPress: () => toggleTask(id),
                          props: {'testID': testIdToggleTask(entry.key)},
                          child: isCompleted ? text('✓') : text(''),
                        ),
                        text(
                          title,
                          props: {'testID': testIdTaskTitle(entry.key)},
                        ),
                        touchableOpacity(
                          onPress: () => deleteTask(id),
                          props: {'testID': testIdDeleteTask(entry.key)},
                          child: text('×'),
                        ),
                      ],
                    );
                  }).toList(),
          ),
        ],
      );
    });

// =============================================================================
// Test Components - Header
// =============================================================================

/// Header component for testing user info and logout
JSObject headerComponent({String? userName, void Function()? onLogout}) =>
    functionalComponent('Header', (props) => view(
          props: {'testID': testIdAppHeader},
          children: [
            text('TaskFlow'),
            if (userName != null)
              view(
                children: [
                  text(
                    'Welcome, $userName',
                    props: {'testID': testIdUserName},
                  ),
                  touchableOpacity(
                    onPress: onLogout,
                    props: {'testID': testIdLogoutBtn},
                    child: text('Logout'),
                  ),
                ],
              )
            else
              view(),
          ],
        ));

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

// =============================================================================
// Export test components for Jest
// =============================================================================

@JS('mobileAppTests')
external set _mobileAppTests(JSObject value);

void main() {
  _mobileAppTests = JSObject()
    // Export components
    ..setProperty(
      'loginScreenComponent'.toJS,
      ((JSAny? onSubmit, JSAny? onRegisterClick) =>
          (onSubmit == null || onSubmit.isUndefinedOrNull)
              ? loginScreenComponent(
                  onRegisterClick: (onRegisterClick is JSFunction)
                      ? () => onRegisterClick.callAsFunction(null)
                      : null,
                )
              : loginScreenComponent(
                  onSubmit: (email, password) => (onSubmit as JSFunction)
                      .callAsFunction(null, email.toJS, password.toJS),
                  onRegisterClick: (onRegisterClick is JSFunction)
                      ? () => onRegisterClick.callAsFunction(null)
                      : null,
                )).toJS,
    )
    ..setProperty(
      'registerScreenComponent'.toJS,
      ((JSAny? onSubmit, JSAny? onLoginClick) =>
          (onSubmit == null || onSubmit.isUndefinedOrNull)
              ? registerScreenComponent(
                  onLoginClick: (onLoginClick is JSFunction)
                      ? () => onLoginClick.callAsFunction(null)
                      : null,
                )
              : registerScreenComponent(
                  onSubmit: (name, email, password) =>
                      (onSubmit as JSFunction).callAsFunction(
                    null,
                    name.toJS,
                    email.toJS,
                    password.toJS,
                  ),
                  onLoginClick: (onLoginClick is JSFunction)
                      ? () => onLoginClick.callAsFunction(null)
                      : null,
                )).toJS,
    )
    ..setProperty(
      'taskListComponent'.toJS,
      ((JSAny? initialTasks) =>
          (initialTasks == null || initialTasks.isUndefinedOrNull)
              ? taskListComponent()
              : taskListComponent(
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
            userName: (userName is JSString) ? userName.toDart : null,
            onLogout: (onLogout is JSFunction)
                ? () => onLogout.callAsFunction(null)
                : null,
          )).toJS,
    )
    // Export utilities
    ..setProperty('render'.toJS, render.toJS)
    ..setProperty('getByTestId'.toJS, getByTestId.toJS)
    ..setProperty('queryByTestId'.toJS, queryByTestId.toJS)
    ..setProperty('getByText'.toJS, getByText.toJS)
    ..setProperty('queryByText'.toJS, queryByText.toJS)
    ..setProperty('press'.toJS, press.toJS)
    ..setProperty('changeText'.toJS, changeText.toJS);
}
