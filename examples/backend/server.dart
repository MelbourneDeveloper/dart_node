import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:backend/schemas.dart';
import 'package:backend/services/task_service.dart';
import 'package:backend/services/token_service.dart';
import 'package:backend/services/user_service.dart';
import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_express/dart_node_express.dart';
import 'package:shared/models/task.dart';
import 'package:shared/models/user.dart';

void main() {
  final tokenService = TokenService('super-secret-jwt-key-change-in-prod');
  final userService = UserService();
  final taskService = TaskService();

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
        final data = getValidatedBody<CreateUserData>(req);
        if (userService.findByEmail(data.email) != null) {
          throw const ConflictError('Email already registered');
        }
        final user = userService.create(
          email: data.email,
          password: data.password,
          name: data.name,
        );
        final token = tokenService.generate(user.id);
        res
          ..status(201)
          ..jsonMap({
            'success': true,
            'data': {'user': user.toJson(), 'token': token},
          });
      }),
    ])
    ..postWithMiddleware('/auth/login', [
      validateBody(loginSchema),
      asyncHandler((req, res) async {
        final data = getValidatedBody<LoginData>(req);
        final user = userService.findByEmail(data.email);
        if (user == null || !userService.verifyPassword(user, data.password)) {
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
      }),
    ])
    ..getWithMiddleware('/tasks', [
      authenticate(tokenService, userService),
      asyncHandler((req, res) async {
        final auth = getAuthContext(req);
        res.jsonMap({
          'success': true,
          'data': taskService
              .findByUser(auth.user.id)
              .map((t) => t.toJson())
              .toList(),
        });
      }),
    ])
    ..postWithMiddleware('/tasks', [
      authenticate(tokenService, userService),
      validateBody(createTaskSchema),
      asyncHandler((req, res) async {
        final auth = getAuthContext(req);
        final data = getValidatedBody<CreateTaskData>(req);
        final task = taskService.create(
          userId: auth.user.id,
          title: data.title,
          description: data.description,
        );
        res
          ..status(201)
          ..jsonMap({'success': true, 'data': task.toJson()});
      }),
    ])
    ..getWithMiddleware('/tasks/:id', [
      authenticate(tokenService, userService),
      asyncHandler((req, res) async {
        final auth = getAuthContext(req);
        final task = taskService.findById(getParam(req, 'id'));
        switch (task) {
          case null:
            throw const NotFoundError('Task');
          case Task(:final userId) when userId != auth.user.id:
            throw const ForbiddenError('Cannot access this task');
          case final Task t:
            res.jsonMap({'success': true, 'data': t.toJson()});
        }
      }),
    ])
    ..putWithMiddleware('/tasks/:id', [
      authenticate(tokenService, userService),
      validateBody(updateTaskSchema),
      asyncHandler((req, res) async {
        final auth = getAuthContext(req);
        final taskId = getParam(req, 'id');
        final data = getValidatedBody<UpdateTaskData>(req);
        final task = taskService.findById(taskId);
        switch (task) {
          case null:
            throw const NotFoundError('Task');
          case Task(:final userId) when userId != auth.user.id:
            throw const ForbiddenError('Cannot modify this task');
          case Task():
            final updated = taskService.update(
              taskId,
              title: data.title,
              description: data.description,
              completed: data.completed,
            );
            res.jsonMap({'success': true, 'data': updated!.toJson()});
        }
      }),
    ])
    ..deleteWithMiddleware('/tasks/:id', [
      authenticate(tokenService, userService),
      asyncHandler((req, res) async {
        final auth = getAuthContext(req);
        final taskId = getParam(req, 'id');
        final task = taskService.findById(taskId);
        switch (task) {
          case null:
            throw const NotFoundError('Task');
          case Task(:final userId) when userId != auth.user.id:
            throw const ForbiddenError('Cannot delete this task');
          case Task():
            taskService.delete(taskId);
            res.jsonMap({'success': true, 'message': 'Task deleted'});
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
  final express = requireModule('express') as JSObject;
  final jsonFn = express['json']! as JSFunction;
  return jsonFn.callAsFunction()! as JSFunction;
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

/// Authentication context
typedef AuthContext = ({User user, String token});

/// Storage for auth contexts (keyed by request object identity via hash)
final _authContexts = <int, AuthContext>{};

/// Auth middleware
JSFunction authenticate(
  TokenService tokenService,
  UserService userService,
) =>
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
          final payload = tokenService.verify(token);
          switch (payload) {
            case null:
              res
                ..status(401)
                ..jsonMap({'error': 'Invalid or expired token'});
              return;
            case final p:
              final user = userService.findById(p.userId);
              switch (user) {
                case null:
                  res
                    ..status(401)
                    ..jsonMap({'error': 'User not found'});
                  return;
                case final u:
                  _authContexts[(req as JSObject).hashCode] =
                      (user: u, token: token);
                  next();
              }
          }
      }
    }).toJS;

/// Get auth context
AuthContext getAuthContext(Request req) {
  final ctx = _authContexts[(req as JSObject).hashCode];
  return ctx ?? (throw StateError('No auth context'));
}
