import 'package:dart_logging/dart_logging.dart';
import 'package:test/test.dart';

void main() {
  test('createLogger logs messages correctly', () {
    final capturedMessages = <LogMessage>[];
    final transport = logTransport((message, _) {
      capturedMessages.add(message);
    });
    final context = createLoggingContext(
      transports: [transport],
      minimumLogLevel: LogLevel.trace,
    );

    final logger = createLogger(context);

    logger('test message', level: LogLevel.info);

    expect(capturedMessages, hasLength(1));
    expect(capturedMessages.first.message, 'test message');
    expect(capturedMessages.first.logLevel, LogLevel.info);
  });

  test('createLogger passes structuredData and tags', () {
    final capturedMessages = <LogMessage>[];
    final transport = logTransport((message, _) {
      capturedMessages.add(message);
    });
    final context = createLoggingContext(
      transports: [transport],
      minimumLogLevel: LogLevel.trace,
    );

    final logger = createLogger(context);

    logger(
      'test',
      level: LogLevel.debug,
      structuredData: {'key': 'value'},
      tags: ['tag1'],
    );

    expect(capturedMessages.first.structuredData, {'key': 'value'});
    expect(capturedMessages.first.tags, ['tag1']);
  });

  test('child throws StateError when called on createLogger result', () {
    final transport = logTransport((message, level) {});
    final context = createLoggingContext(
      transports: [transport],
      minimumLogLevel: LogLevel.trace,
    );

    final logger = createLogger(context);

    expect(() => logger.child({'key': 'value'}), throwsA(isA<StateError>()));
  });
}
