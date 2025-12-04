/// UI interaction tests for the TaskFlow web app.
///
/// Tests verify actual user interactions using the real lib/ components.
/// Run with: dart test -p chrome
@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart' hide render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:frontend/frontend.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('Header Component', () {
    test('displays user name when logged in', () {
      final user = createJSObject({'name': 'John Doe'});

      final result = render(buildHeader(user, () {}));

      expect(result.container.textContent, contains('Welcome, John Doe'));
      expect(result.container.textContent, contains('Logout'));

      result.unmount();
    });

    test('shows spacer when no user', () {
      final result = render(buildHeader(null, () {}));

      expect(result.container.textContent, isNot(contains('Welcome')));

      result.unmount();
    });

    test('logout button calls callback when clicked', () {
      final user = createJSObject({'name': 'Test User'});
      var logoutCalled = false;

      final result = render(buildHeader(user, () => logoutCalled = true));

      final logoutBtn = result.container.querySelector('.btn-ghost');
      expect(logoutBtn, isNotNull);
      fireClick(logoutBtn!);

      expect(logoutCalled, isTrue);

      result.unmount();
    });
  });

  group('Login Form Component', () {
    test('renders login form with sign in title', () {
      final auth = createMockAuth();

      final result = render(buildLoginForm(auth));

      expect(result.container.textContent, contains('Sign In'));

      result.unmount();
    });

    test('renders email and password labels', () {
      final auth = createMockAuth();

      final result = render(buildLoginForm(auth));

      expect(result.container.textContent, contains('Email'));
      expect(result.container.textContent, contains('Password'));

      result.unmount();
    });

    test('renders register link', () {
      final auth = createMockAuth();

      final result = render(buildLoginForm(auth));

      expect(result.container.textContent, contains("Don't have an account?"));
      expect(result.container.textContent, contains('Register'));

      result.unmount();
    });

    test('clicking register switches view', () {
      var viewValue = '';
      final auth = (
        setToken: (JSString? _) {},
        setUser: (JSObject? _) {},
        setView: (String v) => viewValue = v,
      );

      final result = render(buildLoginForm(auth));

      final registerBtn = result.container.querySelector('.btn-link');
      expect(registerBtn, isNotNull);
      fireClick(registerBtn!);

      expect(viewValue, equals('register'));

      result.unmount();
    });
  });

  group('Register Form Component', () {
    test('renders register form with create account title', () {
      final auth = createMockAuth();

      final result = render(buildRegisterForm(auth));

      expect(result.container.textContent, contains('Create Account'));

      result.unmount();
    });

    test('renders name, email, and password labels', () {
      final auth = createMockAuth();

      final result = render(buildRegisterForm(auth));

      expect(result.container.textContent, contains('Name'));
      expect(result.container.textContent, contains('Email'));
      expect(result.container.textContent, contains('Password'));

      result.unmount();
    });

    test('renders sign in link', () {
      final auth = createMockAuth();

      final result = render(buildRegisterForm(auth));

      expect(
        result.container.textContent,
        contains('Already have an account?'),
      );

      result.unmount();
    });

    test('clicking sign in switches view', () {
      var viewValue = '';
      final auth = (
        setToken: (JSString? _) {},
        setUser: (JSObject? _) {},
        setView: (String v) => viewValue = v,
      );

      final result = render(buildRegisterForm(auth));

      final signInBtn = result.container.querySelector('.btn-link');
      expect(signInBtn, isNotNull);
      fireClick(signInBtn!);

      expect(viewValue, equals('login'));

      result.unmount();
    });
  });

  group('Form Helpers', () {
    test('formGroup creates labeled input', () {
      final inputEl = input(
        type: 'text',
        className: 'test-input',
        props: {'data-testid': 'test-input'},
      );
      final group = formGroup('Test Label', inputEl);

      final result = render(group);

      expect(result.container.textContent, contains('Test Label'));
      expect(result.getByTestId('test-input'), isNotNull);

      result.unmount();
    });

    test('labelEl creates label element', () {
      final label = labelEl('My Label');

      final result = render(label);

      expect(result.container.textContent, equals('My Label'));

      result.unmount();
    });

    test('getInputValue extracts value from input event', () async {
      final component = registerFunctionComponent((props) {
        final state = useState('');
        return div(
          children: [
            input(
              type: 'text',
              value: state.value,
              onChange: (e) => state.set(getInputValue(e).toDart),
              props: {'data-testid': 'input'},
            ),
            span(state.value, props: {'data-testid': 'output'}),
          ],
        );
      });

      final result = render(fc(component));

      await userType(result.getByTestId('input'), 'hello');

      expect(result.getByTestId('output').textContent, equals('hello'));

      result.unmount();
    });
  });

  group('Task Components - buildStats', () {
    test('shows completion stats for tasks', () {
      final tasks = [
        createMockTask({'id': '1', 'completed': true}),
        createMockTask({'id': '2', 'completed': false}),
        createMockTask({'id': '3', 'completed': true}),
      ];

      final stats = buildStats(tasks);
      final result = render(stats);

      expect(result.container.textContent, contains('2/3 completed'));

      result.unmount();
    });

    test('shows 0/0 for empty list', () {
      final stats = buildStats([]);
      final result = render(stats);

      expect(result.container.textContent, contains('0/0 completed'));

      result.unmount();
    });

    test('shows 100% for all completed', () {
      final tasks = [
        createMockTask({'id': '1', 'completed': true}),
        createMockTask({'id': '2', 'completed': true}),
      ];

      final stats = buildStats(tasks);
      final result = render(stats);

      expect(result.container.textContent, contains('2/2 completed'));

      result.unmount();
    });
  });

  group('Task Components - buildTaskList', () {
    test('shows empty state when no tasks', () {
      final list = buildTaskList([], (a, b) {}, (c) {});

      final wrapper = div(children: list);
      final result = render(wrapper);

      expect(result.container.textContent, contains('No tasks yet'));

      result.unmount();
    });

    test('renders task items', () {
      final tasks = [
        createMockTask({'id': '1', 'title': 'Task One', 'completed': false}),
        createMockTask({'id': '2', 'title': 'Task Two', 'completed': true}),
      ];

      final list = buildTaskList(tasks, (a, b) {}, (c) {});
      final wrapper = div(children: list);
      final result = render(wrapper);

      expect(result.container.textContent, contains('Task One'));
      expect(result.container.textContent, contains('Task Two'));

      result.unmount();
    });
  });

  group('Task Components - buildTaskItem', () {
    test('shows title and description', () {
      final task = createMockTask({
        'id': '123',
        'title': 'My Task',
        'description': 'Task description',
        'completed': false,
      });

      final item = buildTaskItem(task, (a, b) {}, (c) {});
      final result = render(item);

      expect(result.container.textContent, contains('My Task'));
      expect(result.container.textContent, contains('Task description'));

      result.unmount();
    });

    test('calls onToggle when checkbox clicked', () {
      final task = createMockTask({
        'id': 'task-1',
        'title': 'Toggle Test',
        'completed': false,
      });

      String? toggledId;
      bool? toggledCompleted;

      final item = buildTaskItem(task, (id, completed) {
        toggledId = id;
        toggledCompleted = completed;
      }, (c) {});
      final result = render(item);

      final checkbox = result.container.querySelector('.task-checkbox');
      expect(checkbox, isNotNull);
      fireClick(checkbox!);

      expect(toggledId, equals('task-1'));
      expect(toggledCompleted, isFalse);

      result.unmount();
    });

    test('calls onDelete when delete button clicked', () {
      final task = createMockTask({
        'id': 'task-2',
        'title': 'Delete Test',
        'completed': false,
      });

      String? deletedId;

      final item = buildTaskItem(task, (a, b) {}, (id) => deletedId = id);
      final result = render(item);

      final deleteBtn = result.container.querySelector('.btn-delete');
      expect(deleteBtn, isNotNull);
      fireClick(deleteBtn!);

      expect(deletedId, equals('task-2'));

      result.unmount();
    });

    test('shows checkmark when completed', () {
      final task = createMockTask({
        'id': '1',
        'title': 'Completed Task',
        'completed': true,
      });

      final item = buildTaskItem(task, (a, b) {}, (c) {});
      final result = render(item);

      expect(result.container.textContent, contains('\u2713'));

      result.unmount();
    });

    test('applies completed class when task is done', () {
      final task = createMockTask({
        'id': '1',
        'title': 'Done Task',
        'completed': true,
      });

      final item = buildTaskItem(task, (a, b) {}, (c) {});
      final result = render(item);

      final taskDiv = result.container.querySelector('.task-item');
      expect(taskDiv, isNotNull);
      final className = taskDiv!.className;
      expect(className, contains('completed'));

      result.unmount();
    });
  });

  group('handleTaskEvent', () {
    test('task_created adds task to list', () {
      final component = registerFunctionComponent((props) {
        final tasksState = useStateJSArray<JSTask>(<JSTask>[].toJS);

        return div(
          children: [
            span(
              'Count: ${tasksState.value.length}',
              props: {'data-testid': 'count'},
            ),
            button(
              text: 'Add',
              onClick: () {
                final newTask = createMockTask({'id': 'new-1', 'title': 'New'});
                tasksState.setWithUpdater(
                  (current) =>
                      handleTaskEvent('task_created', newTask, current),
                );
              },
              props: {'data-testid': 'add-btn'},
            ),
          ],
        );
      });

      final result = render(fc(component));

      expect(result.getByTestId('count').textContent, equals('Count: 0'));

      fireClick(result.getByTestId('add-btn'));

      expect(result.getByTestId('count').textContent, equals('Count: 1'));

      result.unmount();
    });

    test('task_deleted removes task from list', () {
      final component = registerFunctionComponent((props) {
        final tasksState = useStateJSArray<JSTask>(
          [
            createMockTask({'id': 'task-1', 'title': 'First'}),
            createMockTask({'id': 'task-2', 'title': 'Second'}),
          ].toJS,
        );

        return div(
          children: [
            span(
              'Count: ${tasksState.value.length}',
              props: {'data-testid': 'count'},
            ),
            button(
              text: 'Delete',
              onClick: () {
                final toDelete = createMockTask({'id': 'task-1'});
                tasksState.setWithUpdater(
                  (current) =>
                      handleTaskEvent('task_deleted', toDelete, current),
                );
              },
              props: {'data-testid': 'delete-btn'},
            ),
          ],
        );
      });

      final result = render(fc(component));

      expect(result.getByTestId('count').textContent, equals('Count: 2'));

      fireClick(result.getByTestId('delete-btn'));

      expect(result.getByTestId('count').textContent, equals('Count: 1'));

      result.unmount();
    });

    test('task_updated replaces task in list', () {
      final component = registerFunctionComponent((props) {
        final tasksState = useStateJSArray<JSTask>(
          [
            createMockTask({
              'id': 'task-1',
              'title': 'Original',
              'completed': false,
            }),
          ].toJS,
        );

        String getTitle() {
          final task = tasksState.value.first;
          return task.title;
        }

        return div(
          children: [
            span(getTitle(), props: {'data-testid': 'title'}),
            button(
              text: 'Update',
              onClick: () {
                final updated = createMockTask({
                  'id': 'task-1',
                  'title': 'Updated',
                  'completed': true,
                });
                tasksState.setWithUpdater(
                  (current) =>
                      handleTaskEvent('task_updated', updated, current),
                );
              },
              props: {'data-testid': 'update-btn'},
            ),
          ],
        );
      });

      final result = render(fc(component));

      expect(result.getByTestId('title').textContent, equals('Original'));

      fireClick(result.getByTestId('update-btn'));

      expect(result.getByTestId('title').textContent, equals('Updated'));

      result.unmount();
    });

    test('unknown event type leaves list unchanged', () {
      final component = registerFunctionComponent((props) {
        final tasksState = useStateJSArray<JSTask>(
          [
            createMockTask({'id': '1', 'title': 'Task'}),
          ].toJS,
        );

        return div(
          children: [
            span(
              'Count: ${tasksState.value.length}',
              props: {'data-testid': 'count'},
            ),
            button(
              text: 'Unknown',
              onClick: () {
                final task = createMockTask({'id': '99'});
                tasksState.setWithUpdater(
                  (current) => handleTaskEvent('unknown_event', task, current),
                );
              },
              props: {'data-testid': 'unknown-btn'},
            ),
          ],
        );
      });

      final result = render(fc(component));

      expect(result.getByTestId('count').textContent, equals('Count: 1'));

      fireClick(result.getByTestId('unknown-btn'));

      expect(result.getByTestId('count').textContent, equals('Count: 1'));

      result.unmount();
    });
  });

  group('Form Helpers - Error Cases', () {
    test('getInputValue throws when value is not a string', () {
      final event = JSObject();
      final target = JSObject();
      target['value'] = 123.toJS;
      event['target'] = target;

      expect(() => getInputValue(event), throwsStateError);
    });

    test('getInputValue throws when target is not an object', () {
      final event = JSObject();
      event['target'] = null;

      expect(() => getInputValue(event), throwsStateError);
    });
  });
}
