import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart';
import 'package:dart_node_react_native/dart_node_react_native.dart';
import 'package:nadz/nadz.dart';
import 'package:shared/http/http_client.dart';
import 'package:shared/theme/theme.dart';

import '../types.dart';

/// Task list screen component
ReactElement taskListScreen({
  required String token,
  required JSObject? user,
  required AuthEffects authEffects,
}) =>
    functionalComponent('TaskListScreen', (JSObject props) {
      final tasksState = useState(<JSAny>[].toJS);
      final loadingState = useState(true.toJS);
      final errorState = useState(null);

      final tasks = (tasksState.$1 as JSArray?)?.toDart ?? [];
      final loading = (loadingState.$1 as JSBoolean?)?.toDart ?? true;
      final error = (errorState.$1 as JSString?)?.toDart;

      final setTasks = tasksState.$2;
      final setLoading = wrapSetState<bool>(loadingState.$2);
      final setError = wrapSetState<String?>(errorState.$2);

      useEffect(
        (() {
          _loadTasks(token, setTasks, setLoading, setError);
        }).toJS,
        [token.toJS].toJS,
      );

      void handleLogout() {
        authEffects.setToken(null);
        authEffects.setUser(null);
        authEffects.setView('login');
      }

      void handleToggle(String id, bool completed) {
        _toggleTask(token, id, completed, setTasks, tasks, setError);
      }

      void handleDelete(String id) {
        _deleteTask(token, id, setTasks, tasks, setError);
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
                  : _buildTaskList(
                      tasks,
                      (onToggle: handleToggle, onDelete: handleDelete),
                    ),
        ],
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

ReactElement _buildTaskList(List<JSAny?> tasks, TaskEffects effects) =>
    tasks.isEmpty
        ? view(
            style: AppStyles.content,
            child: view(
              style: AppStyles.emptyState,
              children: [
                text('📝', style: AppStyles.emptyIcon),
                text('No tasks yet. Add one to get started!',
                    style: AppStyles.emptyText),
              ],
            ),
          )
        : scrollView(
            style: AppStyles.content,
            children:
                tasks.map((task) => _buildTaskItem(task, effects)).toList(),
          );

RNViewElement _buildTaskItem(JSAny? task, TaskEffects effects) {
  final taskObj = task as JSObject?;
  final id = (taskObj?['id'] as JSString?)?.toDart ?? '';
  final title = (taskObj?['title'] as JSString?)?.toDart ?? '';
  final completed = (taskObj?['completed'] as JSBoolean?)?.toDart ?? false;

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
  JSFunction setTasks,
  SetLoading setLoading,
  SetError setError,
) {
  fetchTasks(token: token, apiUrl: apiUrl).then((result) {
    result.match(
      onSuccess: (tasks) {
        setTasks.callAsFunction(null, tasks);
        setError(null);
      },
      onError: (message) => setError(message),
    );
  }).catchError((Object e) {
    setError(e.toString());
  }).whenComplete(() {
    setLoading(false);
  });
}

void _toggleTask(
  String token,
  String id,
  bool completed,
  JSFunction setTasks,
  List<JSAny?> tasks,
  SetError setError,
) {
  fetchJson(
    '$apiUrl/tasks/$id',
    method: 'PUT',
    token: token,
    body: {'completed': completed},
  ).then((result) {
    result.match(
      onSuccess: (_) {
        final updated = tasks.map((t) {
          final obj = t as JSObject?;
          final taskId = (obj?['id'] as JSString?)?.toDart;
          return (taskId == id) ? _updateTaskCompleted(obj, completed) : t;
        }).toList();
        setTasks.callAsFunction(null, updated.toJS);
        setError(null);
      },
      onError: (message) => setError(message),
    );
  }).catchError((Object e) {
    setError(e.toString());
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
  JSFunction setTasks,
  List<JSAny?> tasks,
  SetError setError,
) {
  fetchJson('$apiUrl/tasks/$id', method: 'DELETE', token: token).then((result) {
    result.match(
      onSuccess: (_) {
        final filtered = tasks.where((t) {
          final obj = t as JSObject?;
          final taskId = (obj?['id'] as JSString?)?.toDart;
          return taskId != id;
        }).toList();
        setTasks.callAsFunction(null, filtered.toJS);
        setError(null);
      },
      onError: (message) => setError(message),
    );
  }).catchError((Object e) {
    setError(e.toString());
  });
}
