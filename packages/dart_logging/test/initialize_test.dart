import 'package:dart_logging/dart_logging.dart';
import 'package:test/test.dart';

void main() {
  test('initialize calls all transport initialize functions', () async {
    var initCount = 0;

    final transport1 = logTransport(
      (message, level) {},
      initialize: () async {
        initCount++;
      },
    );

    final transport2 = logTransport(
      (message, level) {},
      initialize: () async {
        initCount++;
      },
    );

    final context = createLoggingContext(transports: [transport1, transport2]);

    await context.initialize();

    // Give async operations time to complete
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(initCount, 2);
  });

  test('initialize works with default transport initialize', () async {
    final transport = logTransport((message, level) {});

    final context = createLoggingContext(transports: [transport]);

    // Should not throw
    await context.initialize();
  });

  test('initialize works with empty transports', () async {
    final context = createLoggingContext();

    // Should not throw
    await context.initialize();
  });
}
