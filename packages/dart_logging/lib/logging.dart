import 'dart:async';

/// Represents a fault that occurred during program execution
sealed class Fault {
  const Fault._internal(this.stackTrace);

  /// Creates a [Fault] from an object and stack trace
  factory Fault.fromObjectAndStackTrace(Object object, StackTrace stackTrace) =>
      switch (object) {
        final Exception ex => ExceptionFault(ex, stackTrace),
        final Error err => ErrorFault(err, stackTrace),
        final String text => MessageFault(text, stackTrace),
        _ => UnknownFault(object.toString(), stackTrace),
      };

  /// The stack trace associated with this fault
  final StackTrace stackTrace;

  @override
  String toString() => switch (this) {
    final ExceptionFault f => 'Exception: ${f.exception}',
    final ErrorFault f => 'Error: ${f.error}',
    final MessageFault f => 'Message: ${f.text}',
    final UnknownFault f => 'Unknown: ${f.object}',
  };
}

/// Represents a fault caused by an [Exception]
final class ExceptionFault extends Fault {
  /// Creates an [ExceptionFault] with the given [exception] and [stackTrace]
  const ExceptionFault(this.exception, StackTrace stackTrace)
    : super._internal(stackTrace);

  /// The underlying exception
  final Exception exception;
}

/// Represents a fault caused by an [Error]
final class ErrorFault extends Fault {
  /// Creates an [ErrorFault] with the given [error] and [stackTrace]
  const ErrorFault(this.error, StackTrace stackTrace)
    : super._internal(stackTrace);

  /// The underlying error
  final Object error;
}

/// Represents a fault with a text message
final class MessageFault extends Fault {
  /// Creates a [MessageFault] with the given [text] and [stackTrace]
  const MessageFault(this.text, StackTrace stackTrace)
    : super._internal(stackTrace);

  /// The fault message
  final String text;
}

/// Represents an unknown fault type
final class UnknownFault extends Fault {
  /// Creates an [UnknownFault] with the given [object] and [stackTrace]
  const UnknownFault(this.object, StackTrace stackTrace)
    : super._internal(stackTrace);

  /// The unknown object that caused the fault
  final Object? object;
}

/// The ANSI color codes for the log levels
const String _red = '\x1B[31m';
const String _green = '\x1B[32m';
const String _deepBlue = '\x1B[38;5;27m';
const String _orange = '\x1B[38;5;214m';

/// The severity of the log message
enum LogLevel {
  /// Trace message (very detailed)
  trace(_deepBlue),

  /// Debug message (detailed)
  debug(_deepBlue),

  /// Informational message (important information)
  info(_green),

  /// Warning message
  warn(_orange),

  /// Error message
  error(_red),

  /// Fatal message
  fatal(_red);

  const LogLevel(this.ansiColor);

  /// The ANSI color code for the severity
  final String ansiColor;
}

/// A log message
typedef LogMessage =
    ({
      String message,
      LogLevel logLevel,
      Map<String, dynamic>? structuredData,
      StackTrace? stackTrace,
      Fault? fault,
      List<String>? tags,
      DateTime timestamp,
    });

/// A function that logs a [LogMessage]
typedef LogFunction = void Function(LogMessage, LogLevel minimumlogLevel);

/// A log transport (e.g., console, file, etc.)
typedef LogTransport = ({LogFunction log, Future<void> Function() initialize});

/// Creates a log transport with the specified log function and optional
/// initialization
LogTransport logTransport(
  LogFunction log, {
  Future<void> Function()? initialize,
}) => (log: log, initialize: initialize ?? () async {});

/// The context that keeps track of the transports and configuration
typedef LoggingContext =
    ({
      List<LogTransport> transports,
      LogLevel minimumLogLevel,
      List<String> extraTags,
      Map<String, dynamic> bindings,
    });

/// Creates a logging context
LoggingContext createLoggingContext({
  List<LogTransport>? transports,
  LogLevel? minimumLogLevel,
  List<String>? extraTags,
  Map<String, dynamic>? bindings,
}) => (
  transports: transports ?? [],
  minimumLogLevel: minimumLogLevel ?? LogLevel.info,
  extraTags: extraTags ?? [],
  bindings: bindings ?? {},
);

/// Processes a message template by replacing placeholders with values from
/// structured data
///
/// Template format: "Text with {placeholder}" where placeholder is a key in
/// structuredData
/// Example: processTemplate("User {id} logged in", {"id": "123"}) =>
/// "User 123 logged in"
String processTemplate(String template, Map<String, dynamic>? structuredData) {
  if (structuredData == null || structuredData.isEmpty) {
    return template;
  }

  var result = template;
  for (final entry in structuredData.entries) {
    result = result.replaceAll('{${entry.key}}', '${entry.value}');
  }

  return result;
}

/// Extensions for the [LoggingContext]
extension LoggingContextExtensions on LoggingContext {
  /// Iterates through transports and logs the message
  void log(
    String message, {
    LogLevel logLevel = LogLevel.trace,
    Fault? fault,
    Map<String, dynamic>? structuredData,
    StackTrace? stackTrace,
    List<String>? tags,
  }) {
    final mergedData = {...bindings, ...?structuredData};
    final processedMessage = processTemplate(message, mergedData);

    final logMessage = (
      message: processedMessage,
      logLevel: logLevel,
      fault: fault,
      tags: [...extraTags, ...?tags],
      structuredData: mergedData.isEmpty ? null : mergedData,
      stackTrace: stackTrace,
      timestamp: DateTime.now().toUtc(),
    );

    for (final transport in transports) {
      transport.log(logMessage, minimumLogLevel);
    }
  }

  /// Makes a copy of the logging context
  LoggingContext copyWith({
    List<LogTransport>? transports,
    LogLevel? minimumLogLevel,
    List<String>? extraTags,
    Map<String, dynamic>? bindings,
  }) => (
    transports: transports ?? this.transports,
    minimumLogLevel: minimumLogLevel ?? this.minimumLogLevel,
    extraTags: extraTags ?? this.extraTags,
    bindings: bindings ?? this.bindings,
  );

  /// Executes an action, logs the start and end of the action, and returns the
  /// result of the action
  Future<T> logged<T>(
    Future<T> action,
    String actionName, {
    bool logCallStack = false,
    ({String message, Map<String, dynamic>? structuredData, LogLevel level})
    Function(T result, int elapsedMilliseconds)?
    resultFormatter,
    List<String>? tags,
  }) async {
    log('Start $actionName');
    if (logCallStack) {
      log('Call Stack\n${StackTrace.current}');
    }
    final stopwatch = Stopwatch()..start();
    try {
      final result = await action;

      final formatterResult =
          resultFormatter?.call(result, stopwatch.elapsedMilliseconds) ??
          (message: result, structuredData: {}, level: LogLevel.trace);

      log(
        logLevel: formatterResult.level,
        'Completed $actionName with no exceptions in '
        '${stopwatch.elapsedMilliseconds}ms with '
        '${formatterResult.message}',
        structuredData: formatterResult.structuredData,
        tags: tags,
      );

      return result;
    } catch (e, s) {
      log(
        'Failed $actionName in ${stopwatch.elapsedMilliseconds}ms',
        logLevel: LogLevel.error,
        fault: Fault.fromObjectAndStackTrace(e, s),
      );
      rethrow;
    }
  }

  /// Initializes all transports in the logging context
  Future<void> initialize() async {
    for (final transport in transports) {
      unawaited(transport.initialize());
    }
  }
}

// ============================================================================
// Logger typeclass - Pino-style API
// ============================================================================

/// A Logger is a curried function that captures the LoggingContext
/// Use extensions for .info(), .warn(), .error(), .child() etc.
typedef Logger =
    void Function(
      String message, {
      required LogLevel level,
      Map<String, dynamic>? structuredData,
      List<String>? tags,
    });

/// Creates a Logger from a LoggingContext (currying)
Logger createLogger(LoggingContext context) => (
  message, {
  required level,
  structuredData,
  tags,
}) {
  context.log(
    message,
    logLevel: level,
    structuredData: structuredData,
    tags: tags,
  );
};

/// Pino-style extensions for Logger
extension LoggerExtensions on Logger {
  /// Logs a trace-level message
  void trace(
    String message, {
    Map<String, dynamic>? structuredData,
    List<String>? tags,
  }) => this(
    message,
    level: LogLevel.trace,
    structuredData: structuredData,
    tags: tags,
  );

  /// Logs a debug-level message
  void debug(
    String message, {
    Map<String, dynamic>? structuredData,
    List<String>? tags,
  }) => this(
    message,
    level: LogLevel.debug,
    structuredData: structuredData,
    tags: tags,
  );

  /// Logs an info-level message
  void info(
    String message, {
    Map<String, dynamic>? structuredData,
    List<String>? tags,
  }) => this(
    message,
    level: LogLevel.info,
    structuredData: structuredData,
    tags: tags,
  );

  /// Logs a warning-level message
  void warn(
    String message, {
    Map<String, dynamic>? structuredData,
    List<String>? tags,
  }) => this(
    message,
    level: LogLevel.warn,
    structuredData: structuredData,
    tags: tags,
  );

  /// Logs an error-level message
  void error(
    String message, {
    Map<String, dynamic>? structuredData,
    List<String>? tags,
  }) => this(
    message,
    level: LogLevel.error,
    structuredData: structuredData,
    tags: tags,
  );

  /// Logs a fatal-level message
  void fatal(
    String message, {
    Map<String, dynamic>? structuredData,
    List<String>? tags,
  }) => this(
    message,
    level: LogLevel.fatal,
    structuredData: structuredData,
    tags: tags,
  );
}

/// Internal: stores the LoggingContext for a Logger to enable child()
final _loggerContexts = Expando<LoggingContext>('loggerContext');

/// Creates a Logger and stores its context for child() support
Logger createLoggerWithContext(LoggingContext context) {
  Logger logFn(LoggingContext ctx) => (
    message, {
    required level,
    structuredData,
    tags,
  }) {
    ctx.log(
      message,
      logLevel: level,
      structuredData: structuredData,
      tags: tags,
    );
  };

  final logger = logFn(context);
  _loggerContexts[logger] = context;
  return logger;
}

/// Extensions for child logger support
extension LoggerChildExtensions on Logger {
  /// Creates a child logger with additional bindings
  /// Bindings are automatically merged into structuredData for all log calls
  Logger child(Map<String, dynamic> bindings) {
    final context = _loggerContexts[this];
    if (context == null) {
      throw StateError(
        'Cannot create child logger: use createLoggerWithContext() '
        'instead of createLogger()',
      );
    }
    final childContext = context.copyWith(
      bindings: {...context.bindings, ...bindings},
    );
    return createLoggerWithContext(childContext);
  }
}
