import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:dart_node_react/dart_node_react.dart';
import 'package:nadz/nadz.dart';
import 'package:shared/http/http_client.dart';

import 'types.dart';
import 'websocket.dart';

/// Creates a SetToken function that converts JSString to String for storage
SetToken _createSetToken(StateHook<String?> tokenState) =>
    (t) => tokenState.set(t?.toDart);

const apiUrl = 'http://localhost:3000';

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
        _buildHeader(userState.value, () {
          tokenState.set(null);
          userState.set(null);
          viewState.set('login');
        }),
        mainEl(
          className: 'main-content',
          child: (tokenState.value == null)
              ? (viewState.value == 'register')
                    ? _buildRegisterForm(auth)
                    : _buildLoginForm(auth)
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

HeaderElement _buildHeader(JSAny? user, void Function() onLogout) {
  final userObj = user as JSObject?;
  final userName = userObj?['name']?.toString();
  return header(
    className: 'header',
    children: [
      div(
        className: 'header-content',
        children: [
          h1('TaskFlow', className: 'logo'),
          if (userName != null)
            div(
              className: 'user-info',
              children: [
                span('Welcome, $userName', className: 'user-name'),
                button(
                  text: 'Logout',
                  className: 'btn btn-ghost',
                  onClick: onLogout,
                ),
              ],
            )
          else
            span('', className: 'spacer'),
        ],
      ),
    ],
  );
}

ReactElement _buildLoginForm(AuthEffects auth) => createElement(
  ((JSAny props) {
    final emailState = useState('');
    final passState = useState('');
    final errorState = useState<String?>(null);
    final loadingState = useState(false);

    void handleSubmit() {
      loadingState.set(true);
      errorState.set(null);

      unawaited(
        fetchJson(
              '$apiUrl/auth/login',
              method: 'POST',
              body: {'email': emailState.value, 'password': passState.value},
            )
            .then((result) {
              result.match(
                onSuccess: (response) {
                  final data = response['data'];
                  switch (data) {
                    case null:
                      errorState.set('Login failed');
                    case final JSObject details:
                      switch (details['token']) {
                        case final JSString token:
                          auth.setToken(token);
                        default:
                          errorState.set('No token');
                      }
                      auth.setUser(details['user'] as JSObject?);
                  }
                },
                onError: errorState.set,
              );
            })
            .catchError((Object e) {
              errorState.set(e.toString());
            })
            .whenComplete(() => loadingState.set(false)),
      );
    }

    return div(
      className: 'auth-card',
      children: [
        h2('Sign In', className: 'auth-title'),
        if (errorState.value != null)
          div(className: 'error-msg', child: span(errorState.value!))
        else
          span(''),
        div(
          className: 'form-group',
          children: [
            _labelEl('Email'),
            input(
              type: 'email',
              placeholder: 'you@example.com',
              value: emailState.value,
              className: 'input',
              onChange: (e) => emailState.set(_getInputValue(e).toDart),
            ),
          ],
        ),
        div(
          className: 'form-group',
          children: [
            _labelEl('Password'),
            input(
              type: 'password',
              placeholder: '••••••••',
              value: passState.value,
              className: 'input',
              onChange: (e) => passState.set(_getInputValue(e).toDart),
            ),
          ],
        ),
        button(
          text: loadingState.value ? 'Signing in...' : 'Sign In',
          className: 'btn btn-primary btn-full',
          onClick: loadingState.value ? null : handleSubmit,
        ),
        div(
          className: 'auth-footer',
          children: [
            span("Don't have an account? "),
            button(
              text: 'Register',
              className: 'btn-link',
              onClick: () => auth.setView('register'),
            ),
          ],
        ),
      ],
    );
  }).toJS,
);

ReactElement _buildRegisterForm(AuthEffects auth) => createElement(
  ((JSAny props) {
    final nameState = useState('');
    final emailState = useState('');
    final passState = useState('');
    final errorState = useState<String?>(null);
    final loadingState = useState(false);

    void handleSubmit() {
      loadingState.set(true);
      errorState.set(null);

      unawaited(
        fetchJson(
              '$apiUrl/auth/register',
              method: 'POST',
              body: {
                'email': emailState.value,
                'password': passState.value,
                'name': nameState.value,
              },
            )
            .then((result) {
              result.match(
                onSuccess: (response) {
                  final data = response['data'];
                  switch (data) {
                    case null:
                      errorState.set('Registration failed');
                    case final JSObject details:
                      switch (details['token']) {
                        case final JSString token:
                          auth.setToken(token);
                        default:
                          errorState.set('No token');
                      }
                      auth.setUser(details['user'] as JSObject?);
                  }
                },
                onError: errorState.set,
              );
            })
            .catchError((Object e) {
              errorState.set(e.toString());
            })
            .whenComplete(() => loadingState.set(false)),
      );
    }

    return div(
      className: 'auth-card',
      children: [
        h2('Create Account', className: 'auth-title'),
        if (errorState.value != null)
          div(className: 'error-msg', child: span(errorState.value!))
        else
          span(''),
        div(
          className: 'form-group',
          children: [
            _labelEl('Name'),
            input(
              type: 'text',
              placeholder: 'Your name',
              value: nameState.value,
              className: 'input',
              onChange: (e) => nameState.set(_getInputValue(e).toDart),
            ),
          ],
        ),
        div(
          className: 'form-group',
          children: [
            _labelEl('Email'),
            input(
              type: 'email',
              placeholder: 'you@example.com',
              value: emailState.value,
              className: 'input',
              onChange: (e) => emailState.set(_getInputValue(e).toDart),
            ),
          ],
        ),
        div(
          className: 'form-group',
          children: [
            _labelEl('Password'),
            input(
              type: 'password',
              placeholder: '••••••••',
              value: passState.value,
              className: 'input',
              onChange: (e) => passState.set(_getInputValue(e).toDart),
            ),
          ],
        ),
        button(
          text: loadingState.value ? 'Creating...' : 'Create Account',
          className: 'btn btn-primary btn-full',
          onClick: loadingState.value ? null : handleSubmit,
        ),
        div(
          className: 'auth-footer',
          children: [
            span('Already have an account? '),
            button(
              text: 'Sign In',
              className: 'btn-link',
              onClick: () => auth.setView('login'),
            ),
          ],
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
    useEffect(
      () {
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
              .catchError((Object e) {
                errorState.set(e.toString());
              })
              .whenComplete(() => loadingState.set(false)),
        );
        return null;
      },
      [],
    );

    // WebSocket connection for real-time updates
    useEffect(
      () {
        final ws = connectWebSocket(
          token: token,
          onTaskEvent: (event) {
            final type = (event['type'] as JSString?)?.toDart;
            final data = event['data'] as JSObject?;
            switch (data) {
              case final JSObject d:
                _handleTaskEvent(type, d, tasksState);
              case null:
                break;
            }
          },
        );
        return () => ws?.close();
      },
      [token],
    );

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
                })
                .catchError((Object e) {
                  errorState.set(e.toString());
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
            })
            .catchError((Object e) {
              errorState.set(e.toString());
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
            })
            .catchError((Object e) {
              errorState.set(e.toString());
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
            _buildStats(tasksState.value),
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
                  onChange: (e) => newTaskState.set(_getInputValue(e).toDart),
                ),
                input(
                  type: 'text',
                  placeholder: 'Description (optional)',
                  value: descState.value,
                  className: 'input',
                  onChange: (e) => descState.set(_getInputValue(e).toDart),
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
            children: _buildTaskList(tasksState.value, toggleTask, deleteTask),
          ),
      ],
    );
  }).toJS,
);

DivElement _buildStats(List<JSObject> tasks) {
  final total = tasks.length;
  final completed = tasks
      .where((t) => (t['completed'] as JSBoolean?)?.toDart ?? false)
      .length;
  final pct = total > 0 ? (completed / total * 100).round() : 0;
  return div(
    className: 'stats',
    children: [
      span('$completed/$total completed', className: 'stat-text'),
      div(
        className: 'progress-bar',
        child: div(
          className: 'progress-fill',
          props: {'style': {'width': '$pct%'}.jsify()},
        ),
      ),
    ],
  );
}

List<ReactElement> _buildTaskList(
  List<JSObject> tasks,
  void Function(String, bool) onToggle,
  void Function(String) onDelete,
) => tasks.isEmpty
      ? [
          div(
            className: 'empty-state',
            children: [
              span('🎯', className: 'empty-icon'),
              pEl('No tasks yet. Add one above!', className: 'empty-text'),
            ],
          ),
        ]
      : tasks.map((task) => _buildTaskItem(task, onToggle, onDelete)).toList();

DivElement _buildTaskItem(
  JSObject task,
  void Function(String, bool) onToggle,
  void Function(String) onDelete,
) {
  final id = (task['id'] as JSString?)?.toDart ?? '';
  final title = (task['title'] as JSString?)?.toDart ?? '';
  final description = (task['description'] as JSString?)?.toDart;
  final completed = (task['completed'] as JSBoolean?)?.toDart ?? false;
  final checkClass = completed ? 'task-checkbox completed' : 'task-checkbox';
  final titleClass = completed ? 'task-title completed' : 'task-title';
  final itemClass = completed ? 'task-item completed' : 'task-item';

  return div(
    className: itemClass,
    children: [
      div(
        className: checkClass,
        props: {'onClick': ((JSAny? _) => onToggle(id, completed)).toJS},
        child: completed ? span('✓', className: 'check-icon') : span(''),
      ),
      div(
        className: 'task-content',
        children: [
          span(title, className: titleClass),
          if (description != null && description.isNotEmpty)
            span(description, className: 'task-desc')
          else
            span(''),
        ],
      ),
      button(
        text: '×',
        className: 'btn-delete',
        onClick: () => onDelete(id),
      ),
    ],
  );
}

ReactElement _labelEl(String text) => createElement(
  'label'.toJS,
  createProps({'className': 'label'}),
  text.toJS,
);

JSString _getInputValue(JSAny event) {
  final obj = event as JSObject;
  final target = obj['target'];
  return switch (target) {
    final JSObject t => switch (t['value']) {
      final JSString v => v,
      _ => throw StateError('Input value is not a string'),
    },
    _ => throw StateError('Event target is not an object'),
  };
}

/// Handle incoming WebSocket task events using functional updater
void _handleTaskEvent(
  String? type,
  JSObject task,
  StateHookJSArray<JSObject> tasksState,
) {
  final taskId = (task['id'] as JSString?)?.toDart;

  tasksState.setWithUpdater((current) => switch (type) {
    'task_created' => [...current, task],
    'task_updated' => current.map((t) {
        final id = (t['id'] as JSString?)?.toDart;
        return (id == taskId) ? task : t;
      }).toList(),
    'task_deleted' => current.where((t) {
        final id = (t['id'] as JSString?)?.toDart;
        return id != taskId;
      }).toList(),
    _ => current,
  });
}
