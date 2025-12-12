import 'package:dart_logging/dart_logging.dart';
import 'package:test/test.dart';

void main() {
  test('logTransport with custom initialize function', () async {
    var initialized = false;

    final transport = logTransport(
      (message, level) {},
      initialize: () async {
        initialized = true;
      },
    );

    await transport.initialize();

    expect(initialized, isTrue);
  });

  test('logTransport default initialize does nothing', () async {
    final transport = logTransport((message, level) {});

    // Should complete without error
    await transport.initialize();
  });

  test('logTransport log function is called correctly', () {
    LogMessage? capturedMessage;
    LogLevel? capturedMinLevel;

    final transport = logTransport((message, minLevel) {
      capturedMessage = message;
      capturedMinLevel = minLevel;
    });

    final testMessage = (
      message: 'test',
      logLevel: LogLevel.info,
      structuredData: <String, dynamic>{'key': 'value'},
      stackTrace: null,
      fault: null,
      tags: <String>['tag1'],
      timestamp: DateTime.now(),
    );

    transport.log(testMessage, LogLevel.debug);

    expect(capturedMessage, testMessage);
    expect(capturedMinLevel, LogLevel.debug);
  });
}
