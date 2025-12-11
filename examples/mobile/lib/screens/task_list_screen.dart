import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart' hide view;
import 'package:dart_node_react_native/dart_node_react_native.dart';
import 'package:nadz/nadz.dart';
import 'package:shared/http/http_client.dart';
import 'package:shared/theme/theme.dart';

import '../types.dart';
import '../websocket.dart';

/// Type-safe wrapper for WebSocket task events
extension type JSTaskEvent._(JSObject _) implements JSObject {
  /// Get the event type safely
  String? get type => switch (_['type']) {
    final JSString s => s.toDart,
    _ => null,
  };

  /// Get the task data safely
  JSTask? get data => switch (_['data']) {
    final JSObject d => JSTask.fromJS(d),
    _ => null,
  };
}

/// Task list screen component
ReactElement taskListScreen({
  required String token,
  required JSUser? user,
  required AuthEffects authEffects,
  Fetch? fetchFn,
}) => functionalComponent('TaskListScreen', (JSObject props) {
  final tasksState = useStateJSArray<JSTask>(null);
  final loadingState = useState(true);
  final errorState = useState<String?>(null);
  final showAddFormState = useState(false);
  final newTaskTitleState = useState('');

  final tasks = tasksState.value;
  final loading = loadingState.value;
  final error = errorState.value;
  final showAddForm = showAddFormState.value;
  final newTaskTitle = newTaskTitleState.value;

  useEffect(() {
    _loadTasks(token, tasksState, loadingState, errorState, fetchFn);
    return null;
  }, [token]);

  // WebSocket connection for real-time updates
  useEffect(() {
    final ws = connectWebSocket(
      token: token,
      onTaskEvent: (jsEvent) {
        final event = JSTaskEvent._(jsEvent);
        switch (event.data) {
          case final JSTask task:
            _handleTaskEvent(event.type, task, tasksState);
          case null:
            break;
        }
      },
    );
    return () => ws?.close();
  }, [token]);

  void handleLogout() {
    authEffects.setToken(null);
    authEffects.setUser(null);
    authEffects.setView('login');
  }

  void handleToggle(String id, bool completed) {
    _toggleTask(token, id, completed, tasksState, errorState, fetchFn);
  }

  void handleDelete(String id) {
    _deleteTask(token, id, tasksState, errorState, fetchFn);
  }

  void handleAddTask() {
    final title = newTaskTitle.trim();
    (title.isEmpty)
        ? null
        : _createTask(token, title, tasksState, errorState, fetchFn, () {
            newTaskTitleState.set('');
            showAddFormState.set(false);
          });
  }

  return view(
    style: AppStyles.container,
    children: [
      _buildHeader(getUserDisplayName(user), handleLogout),
      loading
          ? view(
              style: {'flex': 1, 'justifyContent': 'center'},
              child: activityIndicator(
                size: 'large',
                color: AppColors.accentPrimary,
              ),
            )
          : (error?.isNotEmpty ?? false)
          ? view(
              style: {...AppStyles.errorMsg, 'margin': AppSpacing.xl},
              child: text(error ?? '', style: AppStyles.errorText),
            )
          : _buildTaskContent(
              tasks: tasks,
              effects: (onToggle: handleToggle, onDelete: handleDelete),
              showAddForm: showAddForm,
              newTaskTitle: newTaskTitle,
              setNewTaskTitle: newTaskTitleState.set,
              onAddTask: handleAddTask,
              onCancelAdd: () => showAddFormState.set(false),
            ),
      showAddForm
          ? null
          : touchableOpacity(
              onPress: () => showAddFormState.set(true),
              style: AppStyles.fab,
              child: text('+', style: AppStyles.fabText),
            ),
    ].whereType<ReactElement>().toList(),
  );
});

RNViewElement _buildHeader(String userName, void Function() onLogout) => view(
  style: AppStyles.header,
  children: [
    text('TaskFlow', style: AppStyles.headerTitle),
    view(
      style: {'flexDirection': 'row', 'alignItems': 'center', 'gap': 16},
      children: [
        text('Hi, $userName', style: AppStyles.headerUserName),
        touchableOpacity(
          onPress: onLogout,
          child: text('Logout', style: AppStyles.logoutText),
        ),
      ],
    ),
  ],
);

ReactElement _buildTaskContent({
  required List<JSTask> tasks,
  required TaskEffects effects,
  required bool showAddForm,
  required String newTaskTitle,
  required void Function(String) setNewTaskTitle,
  required void Function() onAddTask,
  required void Function() onCancelAdd,
}) => scrollView(
  style: AppStyles.content,
  children: [
    showAddForm
        ? _buildAddTaskForm(
            newTaskTitle,
            setNewTaskTitle,
            onAddTask,
            onCancelAdd,
          )
        : null,
    ...(tasks.isEmpty
        ? [_buildEmptyState()]
        : tasks.map((task) => _buildTaskItem(task, effects))),
  ].whereType<ReactElement>().toList(),
);

RNViewElement _buildAddTaskForm(
  String value,
  void Function(String) onChangeText,
  void Function() onSubmit,
  void Function() onCancel,
) => view(
  style: AppStyles.addTaskInline,
  children: [
    textInput(
      value: value,
      placeholder: 'What needs to be done?',
      onChangeText: onChangeText,
      style: AppStyles.addTaskInput,
      props: {'placeholderTextColor': AppColors.textMuted, 'autoFocus': true},
    ),
    touchableOpacity(
      onPress: onSubmit,
      style: AppStyles.addTaskBtn,
      child: text('Add', style: AppStyles.addTaskBtnText),
    ),
    touchableOpacity(
      onPress: onCancel,
      style: AppStyles.cancelBtn,
      child: text('Cancel', style: AppStyles.cancelBtnText),
    ),
  ],
);

RNViewElement _buildEmptyState() => view(
  style: AppStyles.emptyState,
  children: [text('No tasks yet', style: AppStyles.emptyText)],
);

RNViewElement _buildTaskItem(JSTask task, TaskEffects effects) => view(
  style: AppStyles.taskItem,
  props: {'key': task.id},
  children: [
    touchableOpacity(
      onPress: () => effects.onToggle(task.id, !task.completed),
      child: view(
        style: task.completed
            ? AppStyles.checkboxChecked
            : AppStyles.checkboxUnchecked,
        child: task.completed ? text('✓', style: AppStyles.checkIcon) : null,
      ),
    ),
    view(
      style: {'flex': 1},
      child: touchableOpacity(
        onPress: () => effects.onToggle(task.id, !task.completed),
        child: text(
          task.title,
          style: task.completed
              ? AppStyles.taskTitleCompleted
              : AppStyles.taskTitle,
        ),
      ),
    ),
    touchableOpacity(
      onPress: () => effects.onDelete(task.id),
      style: AppStyles.deleteBtn,
      child: text('×', style: AppStyles.deleteBtnText),
    ),
  ],
);

Future<void> _loadTasks(
  String token,
  StateHookJSArray<JSTask> tasksState,
  StateHook<bool> loadingState,
  StateHook<String?> errorState,
  Fetch? fetchFn,
) async {
  final doFetch = fetchFn ?? fetchJson;
  try {
    final result = await doFetch('$apiUrl/tasks', token: token);
    result.match(
      onSuccess: (response) {
        final data = response['data'];
        switch (data) {
          case final JSArray arr:
            tasksState.set(_jsArrayToTasks(arr));
          case _:
            tasksState.set([]);
        }
        errorState.set(null);
      },
      onError: (message) => errorState.set(message),
    );
  } on Object catch (e) {
    errorState.set(e.toString());
  } finally {
    loadingState.set(false);
  }
}

List<JSTask> _jsArrayToTasks(JSArray arr) {
  final result = <JSTask>[];
  for (var i = 0; i < arr.length; i++) {
    switch (arr[i]) {
      case final JSObject obj:
        result.add(JSTask.fromJS(obj));
      case null:
        break;
    }
  }
  return result;
}

Future<void> _toggleTask(
  String token,
  String id,
  bool completed,
  StateHookJSArray<JSTask> tasksState,
  StateHook<String?> errorState,
  Fetch? fetchFn,
) async {
  final doFetch = fetchFn ?? fetchJson;
  try {
    final result = await doFetch(
      '$apiUrl/tasks/$id',
      method: 'PUT',
      token: token,
      body: {'completed': completed},
    );
    result.match(
      onSuccess: (_) {
        tasksState.setWithUpdater((tasks) {
          return tasks.map((t) {
            return (t.id == id) ? t.withCompleted(completed) : t;
          }).toList();
        });
        errorState.set(null);
      },
      onError: (message) => errorState.set(message),
    );
  } on Object catch (e) {
    errorState.set(e.toString());
  }
}

Future<void> _deleteTask(
  String token,
  String id,
  StateHookJSArray<JSTask> tasksState,
  StateHook<String?> errorState,
  Fetch? fetchFn,
) async {
  final doFetch = fetchFn ?? fetchJson;
  try {
    final result = await doFetch(
      '$apiUrl/tasks/$id',
      method: 'DELETE',
      token: token,
    );
    result.match(
      onSuccess: (_) {
        tasksState.setWithUpdater((tasks) {
          return tasks.where((t) => t.id != id).toList();
        });
        errorState.set(null);
      },
      onError: (message) => errorState.set(message),
    );
  } on Object catch (e) {
    errorState.set(e.toString());
  }
}

Future<void> _createTask(
  String token,
  String title,
  StateHookJSArray<JSTask> tasksState,
  StateHook<String?> errorState,
  Fetch? fetchFn,
  void Function() onSuccess,
) async {
  final doFetch = fetchFn ?? fetchJson;
  try {
    final result = await doFetch(
      '$apiUrl/tasks',
      method: 'POST',
      token: token,
      body: {'title': title},
    );
    result.match(
      onSuccess: (response) {
        final data = response['data'];
        switch (data) {
          case final JSObject obj:
            final newTask = JSTask.fromJS(obj);
            // Deduplicate: only add if not already present (WS might have added it)
            tasksState.setWithUpdater(
              (tasks) => addTaskIfNotExists(tasks, newTask),
            );
          case _:
            break;
        }
        errorState.set(null);
        onSuccess();
      },
      onError: (message) => errorState.set(message),
    );
  } on Object catch (e) {
    errorState.set(e.toString());
  }
}

/// Handle incoming WebSocket task events using functional updater
void _handleTaskEvent(
  String? type,
  JSTask task,
  StateHookJSArray<JSTask> tasksState,
) {
  tasksState.setWithUpdater((current) => handleTaskEvent(type, task, current));
}
