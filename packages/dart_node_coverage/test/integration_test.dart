/// Integration test for parser and instrumenter working together.
library;

import 'package:dart_node_coverage/src/instrumenter.dart';
import 'package:dart_node_coverage/src/parser.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

void main() {
  test('parse and instrument workflow', () {
    const source = '''
void main() {
  print('hello');
  final x = 42;
  if (x > 0) {
    print('positive');
  }
}
''';

    // Parse to find executable lines
    final parseResult = parseExecutableLines(source, 'example.dart');
    expect(parseResult.isSuccess, isTrue);

    final executableLines = switch (parseResult) {
      Success(value: final v) => v,
      Error() => throw Exception('Parse should not fail'),
    };

    // Should identify the executable lines
    expect(executableLines, contains(2)); // print('hello')
    expect(executableLines, contains(3)); // final x = 42
    expect(executableLines, contains(4)); // if statement
    expect(executableLines, contains(5)); // print('positive')

    // Instrument the source
    final instrumentResult = instrumentSource(
      sourceCode: source,
      filePath: 'example.dart',
      executableLines: executableLines,
    );
    expect(instrumentResult.isSuccess, isTrue);

    final instrumented = switch (instrumentResult) {
      Success(value: final v) => v,
      Error() => throw Exception('Instrument should not fail'),
    };

    // Verify instrumentation
    expect(instrumented, contains("cov('example.dart', 2); print('hello');"));
    expect(instrumented, contains("cov('example.dart', 3); final x = 42;"));
    expect(instrumented, contains("cov('example.dart', 4); if (x > 0) {"));
    expect(
      instrumented,
      contains("cov('example.dart', 5); print('positive');"),
    );
  });

  test('parse and instrument preserves code structure', () {
    const source = '''
/// Documentation comment
void fibonacci(int n) {
  if (n <= 1) {
    return n;
  }
  return fibonacci(n - 1) + fibonacci(n - 2);
}
''';

    final parseResult = parseExecutableLines(source, 'test.dart');
    final executableLines = switch (parseResult) {
      Success(value: final v) => v,
      Error() => throw Exception('Parse should not fail'),
    };

    final instrumentResult = instrumentSource(
      sourceCode: source,
      filePath: 'test.dart',
      executableLines: executableLines,
    );

    final instrumented = switch (instrumentResult) {
      Success(value: final v) => v,
      Error() => throw Exception('Instrument should not fail'),
    };

    // Documentation should be preserved
    expect(instrumented, contains('/// Documentation comment'));

    // Function signature should be preserved (not instrumented)
    expect(instrumented, contains('void fibonacci(int n) {'));

    // Executable lines should be instrumented
    expect(instrumented, contains("cov('test.dart',"));
  });

  test('handle complex nested code', () {
    const source = '''
void process(List<int> items) {
  for (final item in items) {
    switch (item) {
      case 0:
        print('zero');
        break;
      case 1:
        print('one');
        break;
      default:
        print('other');
    }
  }
}
''';

    final parseResult = parseExecutableLines(source, 'complex.dart');
    final executableLines = switch (parseResult) {
      Success(value: final v) => v,
      Error() => throw Exception('Parse should not fail'),
    };

    final instrumentResult = instrumentSource(
      sourceCode: source,
      filePath: 'complex.dart',
      executableLines: executableLines,
    );

    expect(instrumentResult.isSuccess, isTrue);

    final instrumented = switch (instrumentResult) {
      Success(value: final v) => v,
      Error() => throw Exception('Instrument should not fail'),
    };

    // Verify all instrumented lines maintain proper indentation
    final lines = instrumented.split('\n');
    for (final line in lines) {
      if (line.contains('cov(')) {
        // If a line is instrumented, it should have the probe followed by code
        expect(line, matches(r"^\s*cov\('complex\.dart', \d+\);"));
      }
    }
  });
}
