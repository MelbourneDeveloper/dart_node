import 'package:dart_logging/dart_logging.dart';
import 'package:test/test.dart';

void main() {
  test('logged completes successfully and logs start/end', () async {
    final messages = <LogMessage>[];
    final transport = logTransport((message, _) => messages.add(message));
    final context = createLoggingContext(
      transports: [transport],
      minimumLogLevel: LogLevel.trace,
    );

    final result = await context.logged(Future.value(42), 'test action');

    expect(result, 42);
    expect(messages.length, 2);
    expect(messages[0].message, 'Start test action');
    expect(messages[1].message, contains('Completed test action'));
    expect(messages[1].message, contains('ms'));
  });

  test('logged logs failure with fault on exception', () async {
    final messages = <LogMessage>[];
    final transport = logTransport((message, _) => messages.add(message));
    final context = createLoggingContext(
      transports: [transport],
      minimumLogLevel: LogLevel.trace,
    );

    await expectLater(
      context.logged(
        Future<void>.error(Exception('test error')),
        'failing action',
      ),
      throwsException,
    );

    expect(messages.length, 2);
    expect(messages[0].message, 'Start failing action');
    expect(messages[1].message, contains('Failed failing action'));
    expect(messages[1].logLevel, LogLevel.error);
    expect(messages[1].fault, isA<ExceptionFault>());
  });

  test('logged logs call stack when logCallStack is true', () async {
    final messages = <LogMessage>[];
    final transport = logTransport((message, _) => messages.add(message));
    final context = createLoggingContext(
      transports: [transport],
      minimumLogLevel: LogLevel.trace,
    );

    await context.logged(
      Future.value('done'),
      'stack action',
      logCallStack: true,
    );

    expect(messages.length, 3);
    expect(messages[0].message, 'Start stack action');
    expect(messages[1].message, contains('Call Stack'));
  });

  test('logged uses resultFormatter when provided', () async {
    final messages = <LogMessage>[];
    final transport = logTransport((message, _) => messages.add(message));
    final context = createLoggingContext(
      transports: [transport],
      minimumLogLevel: LogLevel.trace,
    );

    await context.logged(
      Future.value(100),
      'formatted action',
      resultFormatter:
          (result, elapsed) => (
            message: 'Got $result',
            structuredData: {'elapsed': elapsed},
            level: LogLevel.info,
          ),
    );

    expect(messages.length, 2);
    expect(messages[1].message, contains('Got 100'));
    expect(messages[1].logLevel, LogLevel.info);
    expect(messages[1].structuredData, containsPair('elapsed', isA<int>()));
  });

  test('logged passes tags to completion log', () async {
    final messages = <LogMessage>[];
    final transport = logTransport((message, _) => messages.add(message));
    final context = createLoggingContext(
      transports: [transport],
      minimumLogLevel: LogLevel.trace,
    );

    await context.logged(
      Future.value('ok'),
      'tagged action',
      tags: ['perf', 'api'],
    );

    expect(messages[1].tags, contains('perf'));
    expect(messages[1].tags, contains('api'));
  });
}
