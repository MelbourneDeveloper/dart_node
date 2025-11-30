import 'dart:js_interop';

import 'package:dart_node_express/src/async_handler.dart';
import 'package:dart_node_express/src/request.dart';
import 'package:dart_node_express/src/response.dart';

/// Base class for all application errors.
///
/// Uses sealed class hierarchy for exhaustive pattern matching.
sealed class AppError implements Exception {
  /// Creates an app error with message and status code.
  const AppError(this.message, this.statusCode);

  /// Error message
  final String message;

  /// HTTP status code
  final int statusCode;

  /// Convert to JSON response format
  Map<String, dynamic> toJson() => {
        'success': false,
        'error': {'message': message, 'statusCode': statusCode},
      };
}

/// 400 Bad Request - validation or malformed request
class ValidationError extends AppError {
  /// Creates a validation error.
  const ValidationError(String message) : super(message, 400);

  /// Field-specific errors
  final Map<String, String> fieldErrors = const {};

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        if (fieldErrors.isNotEmpty) 'fieldErrors': fieldErrors,
      };
}

/// 401 Unauthorized - missing or invalid authentication
class UnauthorizedError extends AppError {
  /// Creates an unauthorized error.
  const UnauthorizedError([String message = 'Unauthorized'])
      : super(message, 401);
}

/// 403 Forbidden - authenticated but not allowed
class ForbiddenError extends AppError {
  /// Creates a forbidden error.
  const ForbiddenError([String message = 'Forbidden']) : super(message, 403);
}

/// 404 Not Found - resource doesn't exist
class NotFoundError extends AppError {
  /// Creates a not found error.
  const NotFoundError([String resource = 'Resource'])
      : super('$resource not found', 404);
}

/// 409 Conflict - resource already exists or state conflict
class ConflictError extends AppError {
  /// Creates a conflict error.
  const ConflictError([String message = 'Resource conflict'])
      : super(message, 409);
}

/// 500 Internal Server Error - unexpected server error
class InternalError extends AppError {
  /// Creates an internal error.
  const InternalError([String message = 'Internal server error'])
      : super(message, 500);
}

/// Express error handler middleware.
///
/// Catches all [AppError] instances and sends appropriate JSON responses.
/// Unknown errors are logged and returned as 500 Internal Server Error.
JSFunction errorHandler() =>
    ((JSAny? err, Request req, Response res, JSNextFunction next) {
      if (err == null) {
        next.call();
        return;
      }

      // Try to extract the Dart error
      final dartError = err.dartify();

      final (int status, Map<String, dynamic> body) = switch (dartError) {
        AppError e => (e.statusCode, e.toJson()),
        _ => (
            500,
            {
              'success': false,
              'error': {
                'message': 'Internal server error',
                'statusCode': 500,
              },
            },
          ),
      };

      res
        ..status(status)
        ..jsonMap(body);
    }).toJS;
