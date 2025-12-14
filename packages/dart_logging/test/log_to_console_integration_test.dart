import 'dart:async';

import 'package:dart_logging/dart_logging.dart';
import 'package:test/test.dart';

void main() {
  test('logToConsole filters messages below minimum level', () {
    final message = (
      message: 'debug message',
      logLevel: LogLevel.debug,
      structuredData: null,
      stackTrace: null,
      fault: null,
      tags: null,
      timestamp: DateTime.now(),
    );

    // Should not throw when filtered
    logToConsole(message, LogLevel.info);
  });

  test('logToConsole prints message at or above minimum level', () async {
    final output = await _captureStdout(() {
      final message = (
        message: 'info message',
        logLevel: LogLevel.info,
        structuredData: null,
        stackTrace: null,
        fault: null,
        tags: null,
        timestamp: DateTime.now(),
      );
      logToConsole(message, LogLevel.info);
    });

    expect(output, contains('info message'));
  });

  test('logToConsole prints all log levels with correct icons', () async {
    final levels = [
      (LogLevel.trace, '🔎'),
      (LogLevel.debug, '🔍'),
      (LogLevel.info, 'ℹ️'),
      (LogLevel.warn, '⚠️'),
      (LogLevel.error, '❌'),
      (LogLevel.fatal, '🚨'),
    ];

    for (final (level, icon) in levels) {
      final output = await _captureStdout(() {
        final message = (
          message: 'test',
          logLevel: level,
          structuredData: null,
          stackTrace: null,
          fault: null,
          tags: null,
          timestamp: DateTime.now(),
        );
        logToConsole(message, LogLevel.trace);
      });
      expect(output, contains(icon), reason: 'Level $level should have icon');
    }
  });

  test('logToConsole prints tags when present', () async {
    final output = await _captureStdout(() {
      final message = (
        message: 'tagged message',
        logLevel: LogLevel.info,
        structuredData: null,
        stackTrace: null,
        fault: null,
        tags: ['auth', 'api'],
        timestamp: DateTime.now(),
      );
      logToConsole(message, LogLevel.trace);
    });

    expect(output, contains('[auth,api]'));
  });

  test('logToConsole prints structured data', () async {
    final output = await _captureStdout(() {
      final message = (
        message: 'data message',
        logLevel: LogLevel.info,
        structuredData: <String, dynamic>{'userId': '123', 'action': 'login'},
        stackTrace: null,
        fault: null,
        tags: null,
        timestamp: DateTime.now(),
      );
      logToConsole(message, LogLevel.trace);
    });

    expect(output, contains('userId: 123'));
    expect(output, contains('action: login'));
  });

  test('logToConsole prints fault when present', () async {
    final fault = Fault.fromObjectAndStackTrace(
      Exception('test error'),
      StackTrace.current,
    );

    final output = await _captureStdout(() {
      final message = (
        message: 'error message',
        logLevel: LogLevel.error,
        structuredData: null,
        stackTrace: null,
        fault: fault,
        tags: null,
        timestamp: DateTime.now(),
      );
      logToConsole(message, LogLevel.trace);
    });

    expect(output, contains('Fault'));
    expect(output, contains('test error'));
  });

  test('logToConsole prints stack trace when present', () async {
    final stack = StackTrace.current;

    final output = await _captureStdout(() {
      final message = (
        message: 'trace message',
        logLevel: LogLevel.error,
        structuredData: null,
        stackTrace: stack,
        fault: null,
        tags: null,
        timestamp: DateTime.now(),
      );
      logToConsole(message, LogLevel.trace);
    });

    expect(output, contains('Stack Trace'));
  });

  test('logToConsole handles empty tags list', () async {
    final output = await _captureStdout(() {
      final message = (
        message: 'no tags',
        logLevel: LogLevel.info,
        structuredData: null,
        stackTrace: null,
        fault: null,
        tags: <String>[],
        timestamp: DateTime.now(),
      );
      logToConsole(message, LogLevel.trace);
    });

    expect(output, contains('no tags'));
    expect(output, isNot(contains('[]')));
  });

  test('logToConsole handles empty structured data', () async {
    final output = await _captureStdout(() {
      final message = (
        message: 'no data',
        logLevel: LogLevel.info,
        structuredData: <String, dynamic>{},
        stackTrace: null,
        fault: null,
        tags: null,
        timestamp: DateTime.now(),
      );
      logToConsole(message, LogLevel.trace);
    });

    expect(output, contains('no data'));
    expect(output, isNot(contains('└─')));
  });
}

Future<String> _captureStdout(void Function() action) async {
  final buffer = StringBuffer();
  final spec = ZoneSpecification(
    print: (self, parent, zone, line) {
      buffer.writeln(line);
    },
  );
  runZoned(() {
    action();
  }, zoneSpecification: spec);
  return buffer.toString();
}
