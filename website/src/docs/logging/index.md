---
layout: layouts/docs.njk
title: dart_logging
description: Pino-style structured logging with child loggers for Dart on Node.js.
eleventyNavigation:
  key: dart_logging
  parent: Packages
  order: 8
---

Pino-style structured logging with child loggers. Provides hierarchical logging with automatic context inheritance.

## Installation

```yaml
dependencies:
  dart_logging: ^0.2.0
```

## Quick Start

```dart
import 'package:dart_logging/dart_logging.dart';

void main() {
  final context = createLoggingContext(
    transports: [logTransport(logToConsole)],
  );
  final logger = createLoggerWithContext(context);

  logger.info('Hello world');
  logger.warn('Something might be wrong');
  logger.error('Something went wrong');

  // Child logger with inherited context
  final childLogger = logger.child({'requestId': 'abc-123'});
  childLogger.info('Processing request'); // requestId auto-included
}
```

## Core Concepts

### Logging Context

Create a logging context with one or more transports:

```dart
final context = createLoggingContext(
  transports: [logTransport(logToConsole)],
);
```

### Log Levels

Standard log levels are available:

```dart
logger.debug('Debugging info');
logger.info('Information');
logger.warn('Warning');
logger.error('Error occurred');
```

### Structured Data

Pass structured data with log messages:

```dart
logger.info('User logged in', {'userId': 123, 'email': 'user@example.com'});
```

### Child Loggers

Create child loggers that inherit and extend context:

```dart
final requestLogger = logger.child({'requestId': 'abc-123'});
requestLogger.info('Start'); // Includes requestId

final userLogger = requestLogger.child({'userId': 456});
userLogger.info('Action'); // Includes both requestId and userId
```

This is useful for adding context that applies to a scope (like a request handler).

### Custom Transports

Create custom transports to send logs to different destinations:

```dart
void myTransport(LogEntry entry) {
  // Send to external service, file, etc.
  print('${entry.level}: ${entry.message}');
}

final context = createLoggingContext(
  transports: [logTransport(myTransport)],
);
```

## Example: Express Server Logging

```dart
import 'package:dart_node_express/dart_node_express.dart';
import 'package:dart_logging/dart_logging.dart';

void main() {
  final logger = createLoggerWithContext(
    createLoggingContext(transports: [logTransport(logToConsole)]),
  );

  final app = createExpressApp();

  app.use((req, res, next) {
    final reqLogger = logger.child({'path': req.path, 'method': req.method});
    reqLogger.info('Request received');
    next();
  });

  app.listen(3000, () {
    logger.info('Server started', {'port': 3000});
  });
}
```

## Source Code

The source code is available on [GitHub](https://github.com/melbournedeveloper/dart_node/tree/main/packages/dart_logging).
