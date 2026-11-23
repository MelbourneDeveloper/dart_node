---
layout: layouts/docs.njk
title: dart_logging
description: A structured logging framework for Dart applications.
eleventyNavigation:
  key: dart_logging
  parent: Packages
  order: 8
---

`dart_logging` is a Pino-style logging framework for Dart with structured logging, child loggers, and customizable transports.

## Installation

```yaml
dependencies:
  dart_logging: ^1.0.0
```

## Quick Start

```dart
import 'package:dart_logging/dart_logging.dart';

void main() {
  // Create a logging context with console output
  final context = createLoggingContext(
    transports: [logTransport(logToConsole)],
  );

  // Create a logger
  final logger = createLoggerWithContext(context);

  // Log messages at different levels
  logger.info('Application started');
  logger.warn('Configuration file not found, using defaults');
  logger.error('Failed to connect to database');
}
```

## Log Levels

The framework supports standard log levels:

```dart
logger.debug('Detailed debugging information');
logger.info('General information');
logger.warn('Warning messages');
logger.error('Error messages');
```

## Structured Logging

Add structured data to your logs:

```dart
logger.info('User logged in', {'userId': 123, 'ip': '192.168.1.1'});
logger.error('Request failed', {'statusCode': 500, 'endpoint': '/api/users'});
```

## Child Loggers

Create child loggers that inherit and extend context:

```dart
final logger = createLoggerWithContext(context);

// Create a child logger with request context
final requestLogger = logger.child({'requestId': 'abc-123'});

// All logs from this logger include requestId
requestLogger.info('Processing request');
requestLogger.info('Validating input');
requestLogger.info('Request complete');

// Create nested children
final dbLogger = requestLogger.child({'component': 'database'});
dbLogger.info('Executing query'); // Includes requestId and component
```

## Custom Transports

Transports define where log messages go:

```dart
// Console transport (built-in)
final consoleTransport = logTransport(logToConsole);

// Custom transport
void myTransport(LogEntry entry) {
  // Send to external service, write to file, etc.
  print('${entry.level}: ${entry.message}');
}

final context = createLoggingContext(
  transports: [
    logTransport(logToConsole),
    logTransport(myTransport),
  ],
);
```

## Log Entry Structure

Each log entry contains:

```dart
typedef LogEntry = ({
  String level,      // 'debug', 'info', 'warn', 'error'
  String message,    // The log message
  Map<String, dynamic> data,  // Structured data
  DateTime timestamp,
});
```

## Filtering by Level

Set minimum log level:

```dart
final context = createLoggingContext(
  transports: [logTransport(logToConsole)],
  minLevel: 'warn',  // Only warn and error messages
);
```

## Example: HTTP Server Logging

```dart
import 'package:dart_logging/dart_logging.dart';

final context = createLoggingContext(
  transports: [logTransport(logToConsole)],
);

final logger = createLoggerWithContext(context);

void handleRequest(Request req, Response res) {
  final requestLogger = logger.child({
    'requestId': generateId(),
    'method': req.method,
    'path': req.path,
  });

  requestLogger.info('Request received');

  try {
    // Process request...
    requestLogger.info('Request processed', {'statusCode': 200});
  } catch (e) {
    requestLogger.error('Request failed', {'error': e.toString()});
  }
}
```

## Example: Application with Components

```dart
import 'package:dart_logging/dart_logging.dart';

class Application {
  late final Logger _logger;
  late final DatabaseService _db;
  late final AuthService _auth;

  Application() {
    final context = createLoggingContext(
      transports: [logTransport(logToConsole)],
    );

    _logger = createLoggerWithContext(context);

    // Each service gets its own child logger
    _db = DatabaseService(_logger.child({'component': 'database'}));
    _auth = AuthService(_logger.child({'component': 'auth'}));
  }

  void start() {
    _logger.info('Application starting');
    _db.connect();
    _auth.initialize();
    _logger.info('Application ready');
  }
}

class DatabaseService {
  final Logger _logger;

  DatabaseService(this._logger);

  void connect() {
    _logger.info('Connecting to database');
    // ...
    _logger.info('Database connected');
  }

  void query(String sql) {
    _logger.debug('Executing query', {'sql': sql});
  }
}

class AuthService {
  final Logger _logger;

  AuthService(this._logger);

  void initialize() {
    _logger.info('Initializing auth service');
  }

  void login(String userId) {
    _logger.info('User login', {'userId': userId});
  }
}
```

## API Reference

See the [full API documentation](/api/dart_logging/) for all available functions and types.
