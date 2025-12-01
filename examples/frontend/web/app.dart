import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:dart_node_react/dart_node_react.dart';
import 'package:nadz/nadz.dart';
import 'package:shared/http/http_client.dart';

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
    final (tokenState, setToken) = useState(null);
    final (userState, setUser) = useState(null);
    final (viewState, setView) = useState('login'.toJS);

    final token = tokenState as JSString?;
    final user = userState as JSObject?;
    final view = (viewState as JSString?)?.toDart ?? 'login';

    return div(
      className: 'app',
      children: [
        _buildHeader(user, () {
          setToken.callAsFunction();
          setUser.callAsFunction();
          setView.callAsFunction(null, 'login'.toJS);
        }),
        mainEl(
          className: 'main-content',
          child: (token == null)
              ? (view == 'register')
                    ? _buildRegisterForm(setToken, setUser, setView)
                    : _buildLoginForm(setToken, setUser, setView)
              : _buildTaskManager(token.toDart, setToken, setUser, setView),
        ),
        footer(
          className: 'footer',
          child: pEl('Powered by Dart + React + Express'),
        ),
      ],
    );
  }).toJS,
);

HeaderElement _buildHeader(JSObject? user, void Function() onLogout) {
  final userName = user?['name']?.toString();
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

ReactElement _buildLoginForm(
  JSFunction setToken,
  JSFunction setUser,
  JSFunction setView,
) => createElement(
  ((JSAny props) {
    final (emailState, setEmail) = useState(''.toJS);
    final (passState, setPass) = useState(''.toJS);
    final (errorState, setError) = useState(null);
    final (loadingState, setLoading) = useState(false.toJS);

    final email = (emailState as JSString?)?.toDart ?? '';
    final password = (passState as JSString?)?.toDart ?? '';
    final error = (errorState as JSString?)?.toDart;
    final loading = (loadingState as JSBoolean?)?.toDart ?? false;

    void handleSubmit() {
      setLoading.callAsFunction(null, true.toJS);
      setError.callAsFunction();

      unawaited(
        fetchJson(
              '$apiUrl/auth/login',
              method: 'POST',
              body: {'email': email, 'password': password},
            )
            .then((result) {
              result.match(
                onSuccess: (response) {
                  final data = response['data'];
                  switch (data) {
                    case null:
                      setError.callAsFunction(null, 'Login failed'.toJS);
                    case final JSObject details:
                      switch (details['token']) {
                        case final JSString token:
                          setToken.callAsFunction(null, token);
                        default:
                          setError.callAsFunction(null, 'No token'.toJS);
                      }
                      setUser.callAsFunction(null, details['user']);
                  }
                },
                onError: (message) =>
                    setError.callAsFunction(null, message.toJS),
              );
            })
            .catchError((Object e) {
              setError.callAsFunction(null, e.toString().toJS);
            })
            .whenComplete(() => setLoading.callAsFunction(null, false.toJS)),
      );
    }

    return div(
      className: 'auth-card',
      children: [
        h2('Sign In', className: 'auth-title'),
        if (error != null)
          div(className: 'error-msg', child: span(error))
        else
          span(''),
        div(
          className: 'form-group',
          children: [
            _labelEl('Email'),
            input(
              type: 'email',
              placeholder: 'you@example.com',
              value: email,
              className: 'input',
              onChange: (e) => setEmail.callAsFunction(null, _getInputValue(e)),
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
              value: password,
              className: 'input',
              onChange: (e) => setPass.callAsFunction(null, _getInputValue(e)),
            ),
          ],
        ),
        button(
          text: loading ? 'Signing in...' : 'Sign In',
          className: 'btn btn-primary btn-full',
          onClick: loading ? null : handleSubmit,
        ),
        div(
          className: 'auth-footer',
          children: [
            span("Don't have an account? "),
            button(
              text: 'Register',
              className: 'btn-link',
              onClick: () => setView.callAsFunction(null, 'register'.toJS),
            ),
          ],
        ),
      ],
    );
  }).toJS,
);

ReactElement _buildRegisterForm(
  JSFunction setToken,
  JSFunction setUser,
  JSFunction setView,
) => createElement(
  ((JSAny props) {
    final (nameState, setName) = useState(''.toJS);
    final (emailState, setEmail) = useState(''.toJS);
    final (passState, setPass) = useState(''.toJS);
    final (errorState, setError) = useState(null);
    final (loadingState, setLoading) = useState(false.toJS);

    final name = (nameState as JSString?)?.toDart ?? '';
    final email = (emailState as JSString?)?.toDart ?? '';
    final password = (passState as JSString?)?.toDart ?? '';
    final error = (errorState as JSString?)?.toDart;
    final loading = (loadingState as JSBoolean?)?.toDart ?? false;

    void handleSubmit() {
      setLoading.callAsFunction(null, true.toJS);
      setError.callAsFunction();

      unawaited(
        fetchJson(
              '$apiUrl/auth/register',
              method: 'POST',
              body: {'email': email, 'password': password, 'name': name},
            )
            .then((result) {
              result.match(
                onSuccess: (response) {
                  final data = response['data'];
                  switch (data) {
                    case null:
                      setError.callAsFunction(null, 'Registration failed'.toJS);
                    case final JSObject details:
                      switch (details['token']) {
                        case final JSString token:
                          setToken.callAsFunction(null, token);
                        default:
                          setError.callAsFunction(null, 'No token'.toJS);
                      }
                      setUser.callAsFunction(null, details['user']);
                  }
                },
                onError: (message) =>
                    setError.callAsFunction(null, message.toJS),
              );
            })
            .catchError((Object e) {
              setError.callAsFunction(null, e.toString().toJS);
            })
            .whenComplete(() => setLoading.callAsFunction(null, false.toJS)),
      );
    }

    return div(
      className: 'auth-card',
      children: [
        h2('Create Account', className: 'auth-title'),
        if (error != null)
          div(className: 'error-msg', child: span(error))
        else
          span(''),
        div(
          className: 'form-group',
          children: [
            _labelEl('Name'),
            input(
              type: 'text',
              placeholder: 'Your name',
              value: name,
              className: 'input',
              onChange: (e) => setName.callAsFunction(null, _getInputValue(e)),
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
              value: email,
              className: 'input',
              onChange: (e) => setEmail.callAsFunction(null, _getInputValue(e)),
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
              value: password,
              className: 'input',
              onChange: (e) => setPass.callAsFunction(null, _getInputValue(e)),
            ),
          ],
        ),
        button(
          text: loading ? 'Creating...' : 'Create Account',
          className: 'btn btn-primary btn-full',
          onClick: loading ? null : handleSubmit,
        ),
        div(
          className: 'auth-footer',
          children: [
            span('Already have an account? '),
            button(
              text: 'Sign In',
              className: 'btn-link',
              onClick: () => setView.callAsFunction(null, 'login'.toJS),
            ),
          ],
        ),
      ],
    );
  }).toJS,
);

ReactElement _buildTaskManager(
  String token,
  JSFunction setToken,
  JSFunction setUser,
  JSFunction setView,
) => createElement(
  ((JSAny props) {
    final (tasksState, setTasks) = useState(<JSAny>[].toJS);
    final (newTaskState, setNewTask) = useState(''.toJS);
    final (descState, setDesc) = useState(''.toJS);
    final (loadingState, setLoading) = useState(true.toJS);
    final (errorState, setError) = useState(null);

    final tasks = tasksState as JSArray?;
    final newTask = (newTaskState as JSString?)?.toDart ?? '';
    final desc = (descState as JSString?)?.toDart ?? '';
    final loading = (loadingState as JSBoolean?)?.toDart ?? false;
    final error = (errorState as JSString?)?.toDart;

    // Fetch tasks on mount
    useEffect(
      (() {
        unawaited(
          fetchTasks(token: token, apiUrl: apiUrl)
              .then((result) {
                result.match(
                  onSuccess: (list) {
                    setTasks.callAsFunction(null, list);
                    setError.callAsFunction();
                  },
                  onError: (message) =>
                      setError.callAsFunction(null, message.toJS),
                );
              })
              .catchError((Object e) {
                setError.callAsFunction(null, e.toString().toJS);
              })
              .whenComplete(() => setLoading.callAsFunction(null, false.toJS)),
        );
      }).toJS,
      <JSAny>[].toJS,
    );

    void addTask() {
      switch (newTask.trim().isEmpty) {
        case true:
          return;
        case false:
          setError.callAsFunction();
          unawaited(
            fetchJson(
                  '$apiUrl/tasks',
                  method: 'POST',
                  token: token,
                  body: {'title': newTask, 'description': desc},
                )
                .then((result) {
                  result.match(
                    onSuccess: (response) {
                      final task = response['data'];
                      switch (task) {
                        case final JSObject created:
                          final current = (tasks?.toDart ?? []).cast<JSAny>();
                          setTasks.callAsFunction(
                            null,
                            [...current, created].toJS,
                          );
                          setNewTask.callAsFunction(null, ''.toJS);
                          setDesc.callAsFunction(null, ''.toJS);
                        default:
                          setError.callAsFunction(
                            null,
                            'Invalid task payload'.toJS,
                          );
                      }
                    },
                    onError: (message) =>
                        setError.callAsFunction(null, message.toJS),
                  );
                })
                .catchError((Object e) {
                  setError.callAsFunction(null, e.toString().toJS);
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
                      final current = (tasks?.toDart ?? []).cast<JSObject>();
                      final newList = current.map((t) {
                        final taskId = (t['id'] as JSString?)?.toDart;
                        return (taskId == id) ? task : t;
                      }).toList();
                      setTasks.callAsFunction(null, newList.toJS);
                    default:
                      setError.callAsFunction(
                        null,
                        'Invalid task payload'.toJS,
                      );
                  }
                },
                onError: (message) =>
                    setError.callAsFunction(null, message.toJS),
              );
            })
            .catchError((Object e) {
              setError.callAsFunction(null, e.toString().toJS);
            }),
      );
    }

    void deleteTask(String id) {
      unawaited(
        fetchJson('$apiUrl/tasks/$id', method: 'DELETE', token: token)
            .then((result) {
              result.match(
                onSuccess: (_) {
                  final current = (tasks?.toDart ?? []).cast<JSObject>();
                  final newList = current
                      .where((t) => (t['id'] as JSString?)?.toDart != id)
                      .toList();
                  setTasks.callAsFunction(null, newList.toJS);
                },
                onError: (message) =>
                    setError.callAsFunction(null, message.toJS),
              );
            })
            .catchError((Object e) {
              setError.callAsFunction(null, e.toString().toJS);
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
            _buildStats(tasks),
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
                  value: newTask,
                  className: 'input input-lg',
                  onChange: (e) =>
                      setNewTask.callAsFunction(null, _getInputValue(e)),
                ),
                input(
                  type: 'text',
                  placeholder: 'Description (optional)',
                  value: desc,
                  className: 'input',
                  onChange: (e) =>
                      setDesc.callAsFunction(null, _getInputValue(e)),
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
        if (error != null)
          div(className: 'error-msg', child: span(error))
        else if (loading)
          div(className: 'loading', child: span('Loading...'))
        else
          div(
            className: 'task-list',
            children: _buildTaskList(tasks, toggleTask, deleteTask),
          ),
      ],
    );
  }).toJS,
);

DivElement _buildStats(JSArray? tasks) {
  final list = (tasks?.toDart ?? []).cast<JSObject>();
  final total = list.length;
  final completed = list
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
  JSArray? tasks,
  void Function(String, bool) onToggle,
  void Function(String) onDelete,
) {
  final list = (tasks?.toDart ?? []).cast<JSObject>();
  return list.isEmpty
      ? [
          div(
            className: 'empty-state',
            children: [
              span('🎯', className: 'empty-icon'),
              pEl('No tasks yet. Add one above!', className: 'empty-text'),
            ],
          ),
        ]
      : list.map((task) => _buildTaskItem(task, onToggle, onDelete)).toList();
}

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
