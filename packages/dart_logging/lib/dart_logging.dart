/// A Pino-style logging framework for Dart
///
/// Usage:
/// ```dart
/// final context = createLoggingContext(
///   transports: [logTransport(logToConsole)],
/// );
/// final logger = createLoggerWithContext(context);
///
/// logger.info('Hello world');
/// logger.warn('Something might be wrong');
///
/// final childLogger = logger.child({'requestId': 'abc-123'});
/// childLogger.info('Processing request'); // requestId auto-included
/// ```
library;

export 'log_to_console.dart' show logToConsole;
export 'logging.dart';
