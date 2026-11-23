import 'package:dart_logging/dart_logging.dart';
import 'package:test/test.dart';

void main() {
  group('LogLevel', () {
    test('has correct ordering', () {
      expect(LogLevel.trace.index, lessThan(LogLevel.debug.index));
      expect(LogLevel.debug.index, lessThan(LogLevel.info.index));
      expect(LogLevel.info.index, lessThan(LogLevel.warn.index));
      expect(LogLevel.warn.index, lessThan(LogLevel.error.index));
      expect(LogLevel.error.index, lessThan(LogLevel.fatal.index));
    });
  });

  group('processTemplate', () {
    test('replaces placeholders with values', () {
      final result = processTemplate('User {id} logged in from {ip}', {
        'id': '123',
        'ip': '192.168.1.1',
      });
      expect(result, 'User 123 logged in from 192.168.1.1');
    });

    test('returns original message when no structuredData', () {
      expect(processTemplate('Hello world', null), 'Hello world');
      expect(processTemplate('Hello world', {}), 'Hello world');
    });

    test('leaves unmatched placeholders', () {
      final result = processTemplate('User {id} from {ip}', {'id': '123'});
      expect(result, 'User 123 from {ip}');
    });
  });

  group('LoggingContext', () {
    test('createLoggingContext uses defaults', () {
      final context = createLoggingContext();
      expect(context.transports, isEmpty);
      expect(context.minimumLogLevel, LogLevel.info);
      expect(context.extraTags, isEmpty);
      expect(context.bindings, isEmpty);
    });

    test('copyWith creates new context with updated values', () {
      final context = createLoggingContext(
        minimumLogLevel: LogLevel.debug,
        extraTags: ['tag1'],
        bindings: {'key': 'value'},
      );

      final copied = context.copyWith(
        minimumLogLevel: LogLevel.error,
        bindings: {'newKey': 'newValue'},
      );

      expect(copied.minimumLogLevel, LogLevel.error);
      expect(copied.extraTags, ['tag1']);
      expect(copied.bindings, {'newKey': 'newValue'});
    });
  });

  group('Logger', () {
    late List<LogMessage> capturedMessages;
    late Logger logger;

    setUp(() {
      capturedMessages = [];
      final transport = logTransport((message, _) {
        capturedMessages.add(message);
      });
      final context = createLoggingContext(
        transports: [transport],
        minimumLogLevel: LogLevel.trace,
      );
      logger = createLoggerWithContext(context);
    });

    test('info logs with correct level', () {
      logger.info('test message');

      expect(capturedMessages, hasLength(1));
      expect(capturedMessages.first.logLevel, LogLevel.info);
      expect(capturedMessages.first.message, 'test message');
    });

    test('debug logs with correct level', () {
      logger.debug('debug message');

      expect(capturedMessages, hasLength(1));
      expect(capturedMessages.first.logLevel, LogLevel.debug);
    });

    test('warn logs with correct level', () {
      logger.warn('warning message');

      expect(capturedMessages, hasLength(1));
      expect(capturedMessages.first.logLevel, LogLevel.warn);
    });

    test('error logs with correct level', () {
      logger.error('error message');

      expect(capturedMessages, hasLength(1));
      expect(capturedMessages.first.logLevel, LogLevel.error);
    });

    test('fatal logs with correct level', () {
      logger.fatal('fatal message');

      expect(capturedMessages, hasLength(1));
      expect(capturedMessages.first.logLevel, LogLevel.fatal);
    });

    test('trace logs with correct level', () {
      logger.trace('trace message');

      expect(capturedMessages, hasLength(1));
      expect(capturedMessages.first.logLevel, LogLevel.trace);
    });

    test('includes structuredData in log', () {
      logger.info('test', structuredData: {'userId': '123'});

      expect(capturedMessages.first.structuredData, {'userId': '123'});
    });

    test('includes tags in log', () {
      logger.info('test', tags: ['auth', 'user']);

      expect(capturedMessages.first.tags, ['auth', 'user']);
    });
  });

  group('Logger.child', () {
    late List<LogMessage> capturedMessages;
    late Logger logger;

    setUp(() {
      capturedMessages = [];
      final transport = logTransport((message, _) {
        capturedMessages.add(message);
      });
      final context = createLoggingContext(
        transports: [transport],
        minimumLogLevel: LogLevel.trace,
      );
      logger = createLoggerWithContext(context);
    });

    test('child logger includes parent bindings', () {
      logger.child({'requestId': 'abc-123'}).info('test message');

      expect(capturedMessages, hasLength(1));
      expect(capturedMessages.first.structuredData, {'requestId': 'abc-123'});
    });

    test('child logger merges bindings with structuredData', () {
      logger
          .child({'requestId': 'abc-123'})
          .info('test', structuredData: {'userId': '456'});

      expect(capturedMessages.first.structuredData, {
        'requestId': 'abc-123',
        'userId': '456',
      });
    });

    test('structuredData overrides bindings with same key', () {
      logger
          .child({'key': 'binding-value'})
          .info('test', structuredData: {'key': 'override-value'});

      expect(capturedMessages.first.structuredData, {'key': 'override-value'});
    });

    test('nested child loggers accumulate bindings', () {
      logger.child({'level1': 'a'}).child({'level2': 'b'}).info('test');

      expect(capturedMessages.first.structuredData, {
        'level1': 'a',
        'level2': 'b',
      });
    });

    test('parent logger is not affected by child', () {
      logger.child({'childKey': 'childValue'}).info('child message');
      logger.info('parent message');

      expect(capturedMessages[0].structuredData, {'childKey': 'childValue'});
      expect(capturedMessages[1].structuredData, isNull);
    });
  });

  group('Fault', () {
    test('fromObjectAndStackTrace creates ExceptionFault for Exception', () {
      final fault = Fault.fromObjectAndStackTrace(
        Exception('test'),
        StackTrace.current,
      );
      expect(fault, isA<ExceptionFault>());
    });

    test('fromObjectAndStackTrace creates ErrorFault for Error', () {
      final fault = Fault.fromObjectAndStackTrace(
        StateError('test'),
        StackTrace.current,
      );
      expect(fault, isA<ErrorFault>());
    });

    test('fromObjectAndStackTrace creates MessageFault for String', () {
      final fault = Fault.fromObjectAndStackTrace(
        'test message',
        StackTrace.current,
      );
      expect(fault, isA<MessageFault>());
    });

    test('fromObjectAndStackTrace creates UnknownFault for other types', () {
      final fault = Fault.fromObjectAndStackTrace(42, StackTrace.current);
      expect(fault, isA<UnknownFault>());
    });
  });

  group('LogTransport', () {
    test('logTransport creates transport with defaults', () {
      var called = false;
      final transport = logTransport((_, _) => called = true);

      expect(transport.initialize, isNotNull);

      final message = (
        message: 'test',
        logLevel: LogLevel.info,
        structuredData: null,
        stackTrace: null,
        fault: null,
        tags: null,
        timestamp: DateTime.now(),
      );
      transport.log(message, LogLevel.info);
      expect(called, isTrue);
    });
  });
}
