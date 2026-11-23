import 'package:dart_logging/dart_logging.dart';
import 'package:test/test.dart';

void main() {
  test('child throws StateError when called on logger without context', () {
    final capturedMessages = <LogMessage>[];
    final transport = logTransport((message, _) {
      capturedMessages.add(message);
    });
    final context = createLoggingContext(
      transports: [transport],
      minimumLogLevel: LogLevel.trace,
    );

    // Use createLogger instead of createLoggerWithContext
    final logger = createLogger(context);

    expect(
      () => logger.child({'key': 'value'}),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('createLoggerWithContext'),
        ),
      ),
    );
  });
}
