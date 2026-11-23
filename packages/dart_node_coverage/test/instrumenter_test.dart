/// Tests for source code instrumenter.
library;

import 'package:dart_node_coverage/src/instrumenter.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

void main() {
  test('instrument simple expression statement', () {
    const source = '''
void main() {
  print('hello');
}
''';

    final result = instrumentSource(
      sourceCode: source,
      filePath: 'test.dart',
      executableLines: [2],
    );

    expect(result.isSuccess, isTrue);

    final instrumented = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(instrumented, contains("cov('test.dart', 2); print('hello');"));
  });

  test('instrument multiple lines', () {
    const source = '''
void main() {
  print('hello');
  final x = 42;
}
''';

    final result = instrumentSource(
      sourceCode: source,
      filePath: 'test.dart',
      executableLines: [2, 3],
    );

    expect(result.isSuccess, isTrue);

    final instrumented = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(instrumented, contains("cov('test.dart', 2); print('hello');"));
    expect(instrumented, contains("cov('test.dart', 3); final x = 42;"));
  });

  test('preserve indentation', () {
    const source = '''
void main() {
  if (true) {
    print('nested');
  }
}
''';

    final result = instrumentSource(
      sourceCode: source,
      filePath: 'test.dart',
      executableLines: [3],
    );

    expect(result.isSuccess, isTrue);

    final instrumented = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(instrumented, contains("    cov('test.dart', 3); print('nested');"));
  });

  test('skip non-executable lines', () {
    const source = '''
void main() {
  print('hello');
  final x = 42;
}
''';

    final result = instrumentSource(
      sourceCode: source,
      filePath: 'test.dart',
      executableLines: [2],
    );

    expect(result.isSuccess, isTrue);

    final instrumented = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(instrumented, contains("cov('test.dart', 2); print('hello');"));
    expect(instrumented, isNot(contains("cov('test.dart', 3);")));
    expect(instrumented, contains('final x = 42;')); // unchanged
  });

  test('handle empty executable lines', () {
    const source = '''
void main() {
  print('hello');
}
''';

    final result = instrumentSource(
      sourceCode: source,
      filePath: 'test.dart',
      executableLines: [],
    );

    expect(result.isSuccess, isTrue);

    final instrumented = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    // Import is still added even when no lines are instrumented
    expect(instrumented, contains("import 'package:dart_node_coverage"));
    expect(instrumented, contains('void main() {'));
    expect(instrumented, isNot(contains('cov(')));
  });

  test('handle single line source', () {
    const source = "void main() => print('hello');";

    final result = instrumentSource(
      sourceCode: source,
      filePath: 'test.dart',
      executableLines: [1],
    );

    expect(result.isSuccess, isTrue);

    final instrumented = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    // Import added at line 0, original content becomes line 1
    expect(instrumented, contains("import 'package:dart_node_coverage"));
    expect(
      instrumented,
      contains("cov('test.dart', 1); void main() => print('hello');"),
    );
  });

  test('escape quotes in file path', () {
    const source = '''
void main() {
  print('hello');
}
''';

    final result = instrumentSource(
      sourceCode: source,
      filePath: "test's_file.dart",
      executableLines: [2],
    );

    expect(result.isSuccess, isTrue);

    final instrumented = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(instrumented, contains("cov('test's_file.dart', 2);"));
  });

  test('preserve tabs in indentation', () {
    const source = '''
void main() {
\t\tprint('hello');
}
''';

    final result = instrumentSource(
      sourceCode: source,
      filePath: 'test.dart',
      executableLines: [2],
    );

    expect(result.isSuccess, isTrue);

    final instrumented = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(instrumented, contains("\t\tcov('test.dart', 2); print('hello');"));
  });

  test('handle consecutive executable lines', () {
    const source = '''
void main() {
  final x = 1;
  final y = 2;
  final z = 3;
}
''';

    final result = instrumentSource(
      sourceCode: source,
      filePath: 'test.dart',
      executableLines: [2, 3, 4],
    );

    expect(result.isSuccess, isTrue);

    final instrumented = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(instrumented, contains("cov('test.dart', 2); final x = 1;"));
    expect(instrumented, contains("cov('test.dart', 3); final y = 2;"));
    expect(instrumented, contains("cov('test.dart', 4); final z = 3;"));
  });

  test('handle mixed spaces and content', () {
    const source = '''
void main() {

  print('hello');

}
''';

    final result = instrumentSource(
      sourceCode: source,
      filePath: 'test.dart',
      executableLines: [3],
    );

    expect(result.isSuccess, isTrue);

    final instrumented = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    // Verify structure using contains (avoids index sensitivity)
    expect(instrumented, contains("import 'package:dart_node_coverage"));
    expect(instrumented, contains('void main() {'));
    expect(instrumented, contains("cov('test.dart', 3); print('hello');"));
    expect(instrumented, contains('}'));
  });
}
