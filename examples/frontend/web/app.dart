import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart';
import 'package:frontend/frontend.dart';
import 'package:nadz/nadz.dart';
import 'package:shared/http/http_client.dart';

/// Creates a SetToken function that converts JSString to String for storage
SetToken _createSetToken(StateHook<String?> tokenState) =>
    (t) => tokenState.set(t?.toDart);

void main() {
  final root = Document.getElementById('root');
  (root != null)
      ? ReactDOM.createRoot(root).render(App())
      : throw StateError('Root element not found');
}

// React component functions follow PascalCase naming convention
// ignore: non_constant_identifier_names
ReactElement App({Fetch? fetchFn}) => createElement(
  ((JSAny props) {
    final tokenState = useState<String?>(null);
    final userState = useStateJS(null);
    final viewState = useState('login');
    final doFetch = fetchFn ?? fetch;

    final auth = (
      setToken: _createSetToken(tokenState),
      setUser: userState.set,
      setView: viewState.set,
    );

    return div(
      className: 'app',
      children: [
        buildHeader(
          switch (userState.value) {
            final JSObject user => user,
            _ => null,
          },
          () {
            tokenState.set(null);
            userState.set(null);
            viewState.set('login');
          },
        ),
        mainEl(
          className: 'main-content',
          child: (tokenState.value == null)
              ? (viewState.value == 'register')
                    ? buildRegisterForm(auth, fetchFn: doFetch)
                    : buildLoginForm(auth, fetchFn: doFetch)
              : _buildTaskManager(
                  tokenState.value!,
                  userState,
                  viewState,
                  doFetch,
                ),
        ),
        footer(
          className: 'footer',
          child: pEl('Powered by Dart + React + Express'),
        ),
      ],
    );
  }).toJS,
);

ReactElement _buildTaskManager(
  String token,
  StateHookJS userState,
  StateHook<String> viewState,
  Fetch doFetch,
) => createElement(
  ((JSAny props) {
    final tasksState = useStateJSArray<JSTask>(null);
    final newTaskState = useState('');
    final descState = useState('');
    final loadingState = useState(true);
    final errorState = useState<String?>(null);

    // Fetch tasks on mount
    useEffect(() {
      Future<void> loadTasks() async {
        try {
          final result = await doFetch('$apiUrl/tasks', token: token);
          result.match(
            onSuccess: (response) {
              switch (response['data']) {
                case final JSArray tasks:
                  final taskList = <JSTask>[
                    for (final item in tasks.toDart)
                      if (item case final JSObject task) JSTask.fromJS(task),
                  ];
                  tasksState.set(taskList);
                  errorState.set(null);
                default:
                  tasksState.set(<JSTask>[]);
              }
            },
            onError: errorState.set,
          );
        } on Object catch (e) {
          errorState.set(e.toString());
        } finally {
          loadingState.set(false);
        }
      }

      unawaited(loadTasks());
      return null;
    }, []);

    // WebSocket connection for real-time updates
    useEffect(() {
      final ws = connectWebSocket(
        token: token,
        onTaskEvent: (event) {
          final type = switch (event['type']) {
            final JSString t => t.toDart,
            _ => null,
          };
          switch (event['data']) {
            case final JSObject data:
              tasksState.setWithUpdater(
                (current) =>
                    handleTaskEvent(type, JSTask.fromJS(data), current),
              );
            default:
              break;
          }
        },
      );
      return () => ws?.close();
    }, [token]);

    Future<void> addTask() async {
      switch (newTaskState.value.trim().isEmpty) {
        case true:
          return;
        case false:
          errorState.set(null);
          final result = await doFetch(
            '$apiUrl/tasks',
            method: 'POST',
            token: token,
            body: {
              'title': newTaskState.value,
              'description': descState.value,
            },
          );
          result.match(
            onSuccess: (response) {
              switch (response['data']) {
                case final JSObject created:
                  final newTask = JSTask.fromJS(created);
                  tasksState.setWithUpdater(
                    (prev) => addTaskIfNotExists(prev, newTask),
                  );
                  newTaskState.set('');
                  descState.set('');
                default:
                  errorState.set('Invalid task payload');
              }
            },
            onError: errorState.set,
          );
      }
    }

    Future<void> toggleTask(String id, bool completed) async {
      final result = await doFetch(
        '$apiUrl/tasks/$id',
        method: 'PUT',
        token: token,
        body: {'completed': !completed},
      );
      result.match(
        onSuccess: (response) {
          switch (response['data']) {
            case final JSObject updatedTask:
              tasksState.setWithUpdater(
                (prev) => updateTaskById(prev, JSTask.fromJS(updatedTask)),
              );
            default:
              errorState.set('Invalid task payload');
          }
        },
        onError: errorState.set,
      );
    }

    Future<void> deleteTask(String id) async {
      final result = await doFetch(
        '$apiUrl/tasks/$id',
        method: 'DELETE',
        token: token,
      );
      result.match(
        onSuccess: (_) {
          tasksState.setWithUpdater((prev) => removeTaskById(prev, id));
        },
        onError: errorState.set,
      );
    }

    return div(
      className: 'task-container',
      children: [
        div(
          className: 'task-header',
          children: [
            h2('Your Tasks', className: 'section-title'),
            buildStats(tasksState.value),
          ],
        ),
        div(
          className: 'add-task-card',
          children: [
            div(
              className: 'add-task-form',
              children: [
                input(
                  type: 'text',
                  placeholder: 'What needs to be done?',
                  value: newTaskState.value,
                  className: 'input input-lg',
                  onChange: (e) => newTaskState.set(getInputValue(e).toDart),
                ),
                input(
                  type: 'text',
                  placeholder: 'Description (optional)',
                  value: descState.value,
                  className: 'input',
                  onChange: (e) => descState.set(getInputValue(e).toDart),
                ),
                button(
                  text: '+ Add Task',
                  className: 'btn btn-primary',
                  onClick: addTask,
                ),
              ],
            ),
          ],
        ),
        if (errorState.value != null)
          div(className: 'error-msg', child: span(errorState.value!))
        else if (loadingState.value)
          div(className: 'loading', child: span('Loading...'))
        else
          div(
            className: 'task-list',
            children: buildTaskList(tasksState.value, toggleTask, deleteTask),
          ),
      ],
    );
  }).toJS,
);
