import 'package:dart_logging/dart_logging.dart';
import 'package:test/test.dart';

void main() {
  test('ExceptionFault toString returns correct format', () {
    final fault = Fault.fromObjectAndStackTrace(
      Exception('test exception'),
      StackTrace.current,
    );
    expect(fault.toString(), contains('Exception:'));
    expect(fault.toString(), contains('test exception'));
  });

  test('ErrorFault toString returns correct format', () {
    final fault = Fault.fromObjectAndStackTrace(
      StateError('test error'),
      StackTrace.current,
    );
    expect(fault.toString(), contains('Error:'));
    expect(fault.toString(), contains('test error'));
  });

  test('MessageFault toString returns correct format', () {
    final fault = Fault.fromObjectAndStackTrace(
      'test message',
      StackTrace.current,
    );
    expect(fault.toString(), equals('Message: test message'));
  });

  test('UnknownFault toString returns correct format', () {
    final fault = Fault.fromObjectAndStackTrace(42, StackTrace.current);
    expect(fault.toString(), equals('Unknown: 42'));
  });
}
