# dart_logging

Pino-style structured logging with child loggers.

## Getting Started

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

## Part of dart_node

[GitHub](https://github.com/MelbourneDeveloper/dart_node)
