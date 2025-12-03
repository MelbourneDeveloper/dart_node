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
ReactElement App() => createElement(
  ((JSAny props) {
    final tokenState = useState<String?>(null);
    final userState = useStateJS(null);
    final viewState = useState('login');

    final auth = (
      setToken: _createSetToken(tokenState),
      setUser: userState.set,
      setView: viewState.set,
    );

    return div(
      className: 'app',
      children: [
        buildHeader(userState.value as JSObject?, () {
          tokenState.set(null);
          userState.set(null);
          viewState.set('login');
        }),
        mainEl(
          className: 'main-content',
          child: (tokenState.value == null)
              ? (viewState.value == 'register')
                    ? buildRegisterForm(auth)
                    : buildLoginForm(auth)
              : _buildTaskManager(tokenState.value!, userState, viewState),
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
) => createElement(
  ((JSAny props) {
    final tasksState = useStateJSArray<JSObject>(<JSObject>[].toJS);
    final newTaskState = useState('');
    final descState = useState('');
    final loadingState = useState(true);
    final errorState = useState<String?>(null);

    // Fetch tasks on mount
    useEffect(() {
      unawaited(
        fetchTasks(token: token, apiUrl: apiUrl)
            .then((result) {
              result.match(
                onSuccess: (list) {
                  tasksState.set(list.toDart.cast<JSObject>());
                  errorState.set(null);
                },
                onError: errorState.set,
              );
            })
            .whenComplete(() => loadingState.set(false)),
      );
      return null;
    }, []);

    // WebSocket connection for real-time updates
    useEffect(() {
      final ws = connectWebSocket(
        token: token,
        onTaskEvent: (event) {
          final type = (event['type'] as JSString?)?.toDart;
          final data = event['data'] as JSObject?;
          switch (data) {
            case final JSObject d:
              handleTaskEvent(type, d, tasksState);
            case null:
              break;
          }
        },
      );
      return () => ws?.close();
    }, [token]);

    void addTask() {
      switch (newTaskState.value.trim().isEmpty) {
        case true:
          return;
        case false:
          errorState.set(null);
          unawaited(
            fetchJson(
                  '$apiUrl/tasks',
                  method: 'POST',
                  token: token,
                  body: {
                    'title': newTaskState.value,
                    'description': descState.value,
                  },
                )
                .then((result) {
                  result.match(
                    onSuccess: (response) {
                      final task = response['data'];
                      switch (task) {
                        case final JSObject created:
                          tasksState.setWithUpdater(
                            (prev) => [...prev, created],
                          );
                          newTaskState.set('');
                          descState.set('');
                        default:
                          errorState.set('Invalid task payload');
                      }
                    },
                    onError: errorState.set,
                  );
                }),
          );
      }
    }

    void toggleTask(String id, bool completed) {
      unawaited(
        fetchJson(
              '$apiUrl/tasks/$id',
              method: 'PUT',
              token: token,
              body: {'completed': !completed},
            )
            .then((result) {
              result.match(
                onSuccess: (response) {
                  final updated = response['data'];
                  switch (updated) {
                    case final JSObject task:
                      tasksState.setWithUpdater(
                        (prev) => prev.map((t) {
                          final taskId = (t['id'] as JSString?)?.toDart;
                          return (taskId == id) ? task : t;
                        }).toList(),
                      );
                    default:
                      errorState.set('Invalid task payload');
                  }
                },
                onError: errorState.set,
              );
            }),
      );
    }

    void deleteTask(String id) {
      unawaited(
        fetchJson('$apiUrl/tasks/$id', method: 'DELETE', token: token)
            .then((result) {
              result.match(
                onSuccess: (_) {
                  tasksState.setWithUpdater(
                    (prev) => prev
                        .where((t) => (t['id'] as JSString?)?.toDart != id)
                        .toList(),
                  );
                },
                onError: errorState.set,
              );
            }),
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
