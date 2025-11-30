import 'package:dart_node_express/dart_node_express.dart';
import 'package:shared/models/task.dart';
import 'package:shared/models/user.dart';

/// Validation schema for creating task
final createTaskSchema = schema<CreateTaskData>(
  {
    'title': string().notEmpty().maxLength(200),
    'description': optional(string().maxLength(2000)),
  },
  (map) => (
    title: map['title'] as String,
    description: map['description'] as String?,
  ),
);

/// Validation schema for updating task
final updateTaskSchema = schema<UpdateTaskData>(
  {
    'title': optional(string().notEmpty().maxLength(200)),
    'description': optional(string().maxLength(2000)),
    'completed': optional(bool_()),
  },
  (map) => (
    title: map['title'] as String?,
    description: map['description'] as String?,
    completed: map['completed'] as bool?,
  ),
);

/// Validation schema for user registration
final createUserSchema = schema<CreateUserData>(
  {
    'email': string().email().maxLength(255),
    'password': string().minLength(8).maxLength(100),
    'name': string().notEmpty().maxLength(100),
  },
  (map) => (
    email: map['email'] as String,
    password: map['password'] as String,
    name: map['name'] as String,
  ),
);

/// Validation schema for login
final loginSchema = schema<LoginData>(
  {
    'email': string().email(),
    'password': string().notEmpty(),
  },
  (map) => (
    email: map['email'] as String,
    password: map['password'] as String,
  ),
);
