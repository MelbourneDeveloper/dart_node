import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:backend/schemas.dart';
import 'package:backend/services/pomodoro_service.dart';
import 'package:backend/services/task_service.dart';
import 'package:backend/services/token_service.dart';
import 'package:backend/services/user_service.dart';
import 'package:backend/services/websocket_service.dart';
import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_express/dart_node_express.dart';
import 'package:nadz/nadz.dart';
import 'package:shared/models/task.dart';
import 'package:shared/models/user.dart';

void main() {
  final tokenService = TokenService('super-secret-jwt-key-change-in-prod');
  final userService = UserService();
  final taskService = TaskService();
  final pomodoroService = PomodoroService();
  final wsService = WebSocketService(tokenService)..start(port: 3001);

  express()
    ..use(cors())
    ..use(jsonParser())
    ..get('/api', handler((req, res) => res.send('Hello from Dart API!')))
    ..get(
      '/health',
      handler((req, res) {
        res.jsonMap({
          'status': 'healthy',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }),
    )
    ..postWithMiddleware('/auth/register', [
      validateBody(createUserSchema),
      asyncHandler((req, res) async {
        switch (getValidatedBody<CreateUserData>(req)) {
          case Error(:final error):
            res
              ..status(400)
              ..jsonMap({'error': error});
          case Success(:final value):
            if (userService.findByEmail(value.email) != null) {
              throw const ConflictError('Email already registered');
            }
            final user = userService.create(
              email: value.email,
              password: value.password,
              name: value.name,
            );
            final token = tokenService.generate(user.id);
            res
              ..status(201)
              ..jsonMap({
                'success': true,
                'data': {'user': user.toJson(), 'token': token},
              });
        }
      }),
    ])
    ..postWithMiddleware('/auth/login', [
      validateBody(loginSchema),
      asyncHandler((req, res) async {
        switch (getValidatedBody<LoginData>(req)) {
          case Error(:final error):
            res
              ..status(400)
              ..jsonMap({'error': error});
          case Success(:final value):
            final user = userService.findByEmail(value.email);
            if (user == null) {
              throw const UnauthorizedError('Invalid email or password');
            }
            if (!userService.verifyPassword(user, value.password)) {
              throw const UnauthorizedError('Invalid email or password');
            }
            userService.updateLastLogin(user.id);
            res.jsonMap({
              'success': true,
              'data': {
                'user': user.toJson(),
                'token': tokenService.generate(user.id),
              },
            });
        }
      }),
    ])
    ..getWithMiddleware('/tasks', [
      authenticate(tokenService, userService),
      asyncHandler((req, res) async {
        switch (getAuthContextWithService(req, userService)) {
          case Error(:final error):
            throw UnauthorizedError(error);
          case Success(:final value):
            res.jsonMap({
              'success': true,
              'data': taskService
                  .findByUser(value.user.id)
                  .map((t) => t.toJson())
                  .toList(),
            });
        }
      }),
    ])
    ..postWithMiddleware('/tasks', [
      authenticate(tokenService, userService),
      validateBody(createTaskSchema),
      asyncHandler((req, res) async {
        switch (getAuthContextWithService(req, userService)) {
          case Error(:final error):
            throw UnauthorizedError(error);
          case Success(value: final auth):
            switch (getValidatedBody<CreateTaskData>(req)) {
              case Error(:final error):
                res
                  ..status(400)
                  ..jsonMap({'error': error});
              case Success(:final value):
                final task = taskService.create(
                  userId: auth.user.id,
                  title: value.title,
                  description: value.description,
                );
                wsService.notifyTaskChange(
                  auth.user.id,
                  TaskEventType.created,
                  task,
                );
                res
                  ..status(201)
                  ..jsonMap({'success': true, 'data': task.toJson()});
            }
        }
      }),
    ])
    ..getWithMiddleware('/tasks/:id', [
      authenticate(tokenService, userService),
      asyncHandler((req, res) async {
        switch (getAuthContextWithService(req, userService)) {
          case Error(:final error):
            throw UnauthorizedError(error);
          case Success(value: final auth):
            final task = taskService.findById(getParam(req, 'id'));
            switch (task) {
              case null:
                throw const NotFoundError('Task');
              case Task(:final userId) when userId != auth.user.id:
                throw const ForbiddenError('Cannot access this task');
              case final Task t:
                res.jsonMap({'success': true, 'data': t.toJson()});
            }
        }
      }),
    ])
    ..putWithMiddleware('/tasks/:id', [
      authenticate(tokenService, userService),
      validateBody(updateTaskSchema),
      asyncHandler((req, res) async {
        switch (getAuthContextWithService(req, userService)) {
          case Error(:final error):
            throw UnauthorizedError(error);
          case Success(value: final auth):
            final taskId = getParam(req, 'id');
            switch (getValidatedBody<UpdateTaskData>(req)) {
              case Error(:final error):
                res
                  ..status(400)
                  ..jsonMap({'error': error});
              case Success(:final value):
                final task = taskService.findById(taskId);
                switch (task) {
                  case null:
                    throw const NotFoundError('Task');
                  case Task(:final userId) when userId != auth.user.id:
                    throw const ForbiddenError('Cannot modify this task');
                  case Task():
                    switch (taskService.update(
                      taskId,
                      title: value.title,
                      description: value.description,
                      completed: value.completed,
                    )) {
                      case Error(:final error):
                        throw NotFoundError(error);
                      case Success(value: final updated):
                        wsService.notifyTaskChange(
                          auth.user.id,
                          TaskEventType.updated,
                          updated,
                        );
                        res.jsonMap({
                          'success': true,
                          'data': updated.toJson(),
                        });
                    }
                }
            }
        }
      }),
    ])
    ..deleteWithMiddleware('/tasks/:id', [
      authenticate(tokenService, userService),
      asyncHandler((req, res) async {
        switch (getAuthContextWithService(req, userService)) {
          case Error(:final error):
            throw UnauthorizedError(error);
          case Success(value: final auth):
            final taskId = getParam(req, 'id');
            final task = taskService.findById(taskId);
            switch (task) {
              case null:
                throw const NotFoundError('Task');
              case Task(:final userId) when userId != auth.user.id:
                throw const ForbiddenError('Cannot delete this task');
              case final Task t:
                switch (taskService.delete(taskId)) {
                  case Error(:final error):
                    throw NotFoundError(error);
                  case Success():
                    wsService.notifyTaskChange(
                      auth.user.id,
                      TaskEventType.deleted,
                      t,
                    );
                    res.jsonMap({'success': true, 'message': 'Task deleted'});
                }
            }
        }
      }),
    ])
    ..getWithMiddleware('/pomodoro/active', [
      authenticate(tokenService, userService),
      asyncHandler((req, res) async {
        final auth = getAuthContext(req);
        final activeSession = pomodoroService.getActiveSession(auth.user.id);
        res.jsonMap({
          'success': true,
          'data': activeSession?.toJson(),
        });
      }),
    ])
    ..postWithMiddleware('/pomodoro/start', [
      authenticate(tokenService, userService),
      validateBody(createPomodoroSessionSchema),
      asyncHandler((req, res) async {
        final auth = getAuthContext(req);
        final data = getValidatedBody<CreatePomodoroSessionData>(req);
        final session = pomodoroService.create(
          userId: auth.user.id,
          title: data.title,
          duration: data.duration ?? 25,
          breakDuration: data.breakDuration ?? 5,
          linkedTaskId: data.linkedTaskId,
        );
        final started = pomodoroService.start(session.id);
        res
          ..status(201)
          ..jsonMap({'success': true, 'data': started?.toJson()});
      }),
    ])
    ..getWithMiddleware('/pomodoro', [
      authenticate(tokenService, userService),
      asyncHandler((req, res) async {
        final auth = getAuthContext(req);
        res.jsonMap({
          'success': true,
          'data': pomodoroService
              .findByUser(auth.user.id)
              .map((s) => s.toJson())
              .toList(),
        });
      }),
    ])
    ..postWithMiddleware('/pomodoro', [
      authenticate(tokenService, userService),
      validateBody(createPomodoroSessionSchema),
      asyncHandler((req, res) async {
        final auth = getAuthContext(req);
        final data = getValidatedBody<CreatePomodoroSessionData>(req);
        final session = pomodoroService.create(
          userId: auth.user.id,
          title: data.title,
          duration: data.duration ?? 25,
          breakDuration: data.breakDuration ?? 5,
          linkedTaskId: data.linkedTaskId,
        );
        res
          ..status(201)
          ..jsonMap({'success': true, 'data': session.toJson()});
      }),
    ])
    ..postWithMiddleware('/pomodoro/:id/start', [
      authenticate(tokenService, userService),
      asyncHandler((req, res) async {
        final auth = getAuthContext(req);
        final sessionId = getParam(req, 'id');
        final session = pomodoroService.findById(sessionId);
        switch (session) {
          case null:
            throw const NotFoundError('Pomodoro session');
          case final s when s.userId != auth.user.id:
            throw const ForbiddenError('Cannot start this session');
          case final s:
            final started = pomodoroService.start(s.id);
            res.jsonMap({'success': true, 'data': started?.toJson()});
        }
      }),
    ])
    ..postWithMiddleware('/pomodoro/:id/pause', [
      authenticate(tokenService, userService),
      asyncHandler((req, res) async {
        final auth = getAuthContext(req);
        final sessionId = getParam(req, 'id');
        final session = pomodoroService.findById(sessionId);
        switch (session) {
          case null:
            throw const NotFoundError('Pomodoro session');
          case final s when s.userId != auth.user.id:
            throw const ForbiddenError('Cannot pause this session');
          case final s:
            final paused = pomodoroService.pauseSession(s.id);
            res.jsonMap({'success': true, 'data': paused?.toJson()});
        }
      }),
    ])
    ..postWithMiddleware('/pomodoro/:id/resume', [
      authenticate(tokenService, userService),
      asyncHandler((req, res) async {
        final auth = getAuthContext(req);
        final sessionId = getParam(req, 'id');
        final session = pomodoroService.findById(sessionId);
        switch (session) {
          case null:
            throw const NotFoundError('Pomodoro session');
          case final s when s.userId != auth.user.id:
            throw const ForbiddenError('Cannot resume this session');
          case final s:
            final resumed = pomodoroService.resumeSession(s.id);
            res.jsonMap({'success': true, 'data': resumed?.toJson()});
        }
      }),
    ])
    ..postWithMiddleware('/pomodoro/:id/complete', [
      authenticate(tokenService, userService),
      asyncHandler((req, res) async {
        final auth = getAuthContext(req);
        final sessionId = getParam(req, 'id');
        final session = pomodoroService.findById(sessionId);
        switch (session) {
          case null:
            throw const NotFoundError('Pomodoro session');
          case final s when s.userId != auth.user.id:
            throw const ForbiddenError('Cannot complete this session');
          case final s:
            final completed = pomodoroService.completeSession(s.id);
            res.jsonMap({'success': true, 'data': completed?.toJson()});
        }
      }),
    ])
    ..getWithMiddleware('/pomodoro/:id', [
      authenticate(tokenService, userService),
      asyncHandler((req, res) async {
        final auth = getAuthContext(req);
        final sessionId = getParam(req, 'id');
        final session = pomodoroService.findById(sessionId);
        switch (session) {
          case null:
            throw const NotFoundError('Pomodoro session');
          case final s when s.userId != auth.user.id:
            throw const ForbiddenError('Cannot access this session');
          case final s:
            res.jsonMap({'success': true, 'data': s.toJson()});
        }
      }),
    ])
    ..deleteWithMiddleware('/pomodoro/:id', [
      authenticate(tokenService, userService),
      asyncHandler((req, res) async {
        final auth = getAuthContext(req);
        final sessionId = getParam(req, 'id');
        final session = pomodoroService.findById(sessionId);
        switch (session) {
          case null:
            throw const NotFoundError('Pomodoro session');
          case final s when s.userId != auth.user.id:
            throw const ForbiddenError('Cannot delete this session');
          case final s:
            pomodoroService.delete(s.id);
            res.jsonMap({'success': true, 'message': 'Session deleted'});
        }
      }),
    ])
    ..use(errorHandler())
    ..listen(
      3000,
      (() {
        consoleLog('Server running on http://localhost:3000');
      }).toJS,
    );
}

/// Get URL parameter from request
String getParam(Request req, String name) => req.params[name].toString();

/// JSON body parser middleware
JSFunction jsonParser() {
  final express = switch (requireModule('express')) {
    final JSObject o => o,
    _ => throw StateError('Express module not found'),
  };
  final jsonFn = switch (express['json']) {
    final JSFunction f => f,
    _ => throw StateError('Express json function not found'),
  };
  return switch (jsonFn.callAsFunction()) {
    final JSFunction f => f,
    _ => throw StateError('Failed to create JSON parser'),
  };
}

/// CORS middleware
JSFunction cors() => ((Request req, Response res, JSNextFunction next) {
  res
    ..set('Access-Control-Allow-Origin', '*')
    ..set('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS')
    ..set('Access-Control-Allow-Headers', 'Content-Type,Authorization');
  if (req.method == 'OPTIONS') {
    res
      ..status(204)
      ..end();
    return;
  }
  next();
}).toJS;

/// Authentication context stored in request
typedef AuthContext = ({User user, String token});

/// Internal storage key for user ID
const _authUserIdKey = '__auth_user_id__';
const _authTokenKey = '__auth_token__';

/// Auth middleware
JSFunction authenticate(TokenService tokenService, UserService userService) =>
    ((Request req, Response res, JSNextFunction next) {
      final authHeader = req.headers['authorization'];
      switch (authHeader) {
        case null:
          res
            ..status(401)
            ..jsonMap({'error': 'Missing authorization header'});
          return;
        case final header when !header.toString().startsWith('Bearer '):
          res
            ..status(401)
            ..jsonMap({'error': 'Invalid authorization format'});
          return;
        case final header:
          final token = header.toString().substring(7);
          final verifyResult = tokenService.verify(token);
          switch (verifyResult) {
            case Error(:final error):
              res
                ..status(401)
                ..jsonMap({'error': error.message});
              return;
            case Success(:final value):
              final user = userService.findById(value.userId);
              switch (user) {
                case null:
                  res
                    ..status(401)
                    ..jsonMap({'error': 'User not found'});
                  return;
                case final u:
                  // Store user ID and token in request object
                  req[_authUserIdKey] = u.id.toJS;
                  req[_authTokenKey] = token.toJS;
                  next();
              }
          }
      }
    }).toJS;

/// Get auth context from request - requires userService to look up user
Result<AuthContext, String> getAuthContextWithService(
  Request req,
  UserService userService,
) {
  final userId = switch (req[_authUserIdKey]) {
    final JSString s => s.toDart,
    _ => null,
  };
  final token = switch (req[_authTokenKey]) {
    final JSString s => s.toDart,
    _ => null,
  };
  if (userId == null || token == null) {
    return const Error('No auth context found');
  }
  final user = userService.findById(userId);
  if (user == null) {
    return const Error('User not found');
  }
  return Success((user: user, token: token));
}
