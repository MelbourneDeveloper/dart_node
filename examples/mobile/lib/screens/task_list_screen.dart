import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart' hide view;
import 'package:dart_node_react_native/dart_node_react_native.dart';
import 'package:nadz/nadz.dart';
import 'package:shared/http/http_client.dart';
import 'package:shared/theme/theme.dart';

import '../types.dart';
import '../websocket.dart';

/// Task list screen component
ReactElement taskListScreen({
  required String token,
  required JSObject? user,
  required AuthEffects authEffects,
}) =>
    functionalComponent('TaskListScreen', (JSObject props) {
      final tasksState = useState<List<JSObject>>([]);
      final loadingState = useState(true);
      final errorState = useState<String?>(null);
      final showAddFormState = useState(false);
      final newTaskTitleState = useState('');

      final tasks = tasksState.value;
      final loading = loadingState.value;
      final error = errorState.value;
      final showAddForm = showAddFormState.value;
      final newTaskTitle = newTaskTitleState.value;

      useEffect(
        () {
          _loadTasks(token, tasksState, loadingState, errorState);
          return null;
        },
        [token],
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

      void handleLogout() {
        authEffects.setToken(null);
        authEffects.setUser(null);
        authEffects.setView('login');
      }

      void handleToggle(String id, bool completed) {
        _toggleTask(token, id, completed, tasksState, errorState);
      }

      void handleDelete(String id) {
        _deleteTask(token, id, tasksState, errorState);
      }

      void handleAddTask() {
        final title = newTaskTitle.trim();
        (title.isEmpty)
            ? null
            : _createTask(token, title, tasksState, errorState, () {
                newTaskTitleState.set('');
                showAddFormState.set(false);
              });
      }

      final userName = user?['name'] as JSString?;

      return view(
        style: AppStyles.container,
        children: [
          _buildHeader(userName?.toDart ?? 'User', handleLogout),
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
  required List<JSObject> tasks,
  required TaskEffects effects,
  required bool showAddForm,
  required String newTaskTitle,
  required void Function(String) setNewTaskTitle,
  required void Function() onAddTask,
  required void Function() onCancelAdd,
}) =>
    scrollView(
      style: AppStyles.content,
      children: [
        showAddForm ? _buildAddTaskForm(newTaskTitle, setNewTaskTitle, onAddTask, onCancelAdd) : null,
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
) =>
    view(
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
      children: [
        text('No tasks yet', style: AppStyles.emptyText),
      ],
    );

RNViewElement _buildTaskItem(JSObject task, TaskEffects effects) {
  final id = (task['id'] as JSString?)?.toDart ?? '';
  final title = (task['title'] as JSString?)?.toDart ?? '';
  final completed = (task['completed'] as JSBoolean?)?.toDart ?? false;

  return view(
    style: AppStyles.taskItem,
    props: {'key': id},
    children: [
      touchableOpacity(
        onPress: () => effects.onToggle(id, !completed),
        child: view(
          style: completed
              ? AppStyles.checkboxChecked
              : AppStyles.checkboxUnchecked,
          child: completed ? text('✓', style: AppStyles.checkIcon) : null,
        ),
      ),
      view(
        style: {'flex': 1},
        child: touchableOpacity(
          onPress: () => effects.onToggle(id, !completed),
          child: text(
            title,
            style:
                completed ? AppStyles.taskTitleCompleted : AppStyles.taskTitle,
          ),
        ),
      ),
      touchableOpacity(
        onPress: () => effects.onDelete(id),
        style: AppStyles.deleteBtn,
        child: text('×', style: AppStyles.deleteBtnText),
      ),
    ],
  );
}

void _loadTasks(
  String token,
  StateHook<List<JSObject>> tasksState,
  StateHook<bool> loadingState,
  StateHook<String?> errorState,
) {
  fetchTasks(token: token, apiUrl: apiUrl).then((result) {
    result.match(
      onSuccess: (tasks) {
        tasksState.set(tasks.toDart.cast<JSObject>());
        errorState.set(null);
      },
      onError: (message) => errorState.set(message),
    );
  }).catchError((Object e) {
    errorState.set(e.toString());
  }).whenComplete(() {
    loadingState.set(false);
  });
}

void _toggleTask(
  String token,
  String id,
  bool completed,
  StateHook<List<JSObject>> tasksState,
  StateHook<String?> errorState,
) {
  fetchJson(
    '$apiUrl/tasks/$id',
    method: 'PUT',
    token: token,
    body: {'completed': completed},
  ).then((result) {
    result.match(
      onSuccess: (_) {
        tasksState.setWithUpdater((tasks) {
          return tasks.map((t) {
            final taskId = (t['id'] as JSString?)?.toDart;
            return (taskId == id) ? _updateTaskCompleted(t, completed) : t;
          }).toList();
        });
        errorState.set(null);
      },
      onError: (message) => errorState.set(message),
    );
  }).catchError((Object e) {
    errorState.set(e.toString());
  });
}

JSObject _updateTaskCompleted(JSObject? task, bool completed) {
  final newTask = JSObject();
  final keys = getObjectKeys(task ?? JSObject());
  for (final key in keys) {
    newTask.setProperty(key.toJS, task?[key]);
  }
  newTask.setProperty('completed'.toJS, completed.toJS);
  return newTask;
}

void _deleteTask(
  String token,
  String id,
  StateHook<List<JSObject>> tasksState,
  StateHook<String?> errorState,
) {
  fetchJson('$apiUrl/tasks/$id', method: 'DELETE', token: token).then((result) {
    result.match(
      onSuccess: (_) {
        tasksState.setWithUpdater((tasks) {
          return tasks.where((t) {
            final taskId = (t['id'] as JSString?)?.toDart;
            return taskId != id;
          }).toList();
        });
        errorState.set(null);
      },
      onError: (message) => errorState.set(message),
    );
  }).catchError((Object e) {
    errorState.set(e.toString());
  });
}

void _createTask(
  String token,
  String title,
  StateHook<List<JSObject>> tasksState,
  StateHook<String?> errorState,
  void Function() onSuccess,
) {
  fetchJson(
    '$apiUrl/tasks',
    method: 'POST',
    token: token,
    body: {'title': title},
  ).then((result) {
    result.match(
      onSuccess: (data) {
        final task = data as JSObject?;
        (task != null)
            ? tasksState.setWithUpdater((tasks) => [...tasks, task])
            : null;
        errorState.set(null);
        onSuccess();
      },
      onError: (message) => errorState.set(message),
    );
  }).catchError((Object e) {
    errorState.set(e.toString());
  });
}

/// Handle incoming WebSocket task events using functional updater
void _handleTaskEvent(
  String? type,
  JSObject task,
  StateHook<List<JSObject>> tasksState,
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
