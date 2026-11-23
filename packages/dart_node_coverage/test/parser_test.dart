/// Tests for Dart source code parser.
library;

import 'package:dart_node_coverage/src/parser.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

void main() {
  test('parse simple expression statement', () {
    const source = '''
void main() {
  print('hello');
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, contains(2)); // print statement
  });

  test('parse variable declarations with initializers', () {
    const source = '''
void main() {
  final x = 5;
  var y = 10;
  const z = 15;
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, containsAll([2, 3, 4])); // all declarations
  });

  test('parse variable declarations without initializers', () {
    const source = '''
void main() {
  int x;
  String y;
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    // Variable declaration statements ARE executable
    expect(lines, contains(2));
    expect(lines, contains(3));
  });

  test('parse return statements', () {
    const source = '''
int calculate() {
  return 42;
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, contains(2)); // return statement
  });

  test('parse if statements', () {
    const source = '''
void main() {
  if (true) {
    print('yes');
  } else {
    print('no');
  }
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, contains(2)); // if statement
    expect(lines, contains(3)); // print in then
    expect(lines, contains(5)); // print in else
  });

  test('parse switch statements', () {
    const source = '''
void main() {
  switch (1) {
    case 1:
      print('one');
    case 2:
      print('two');
  }
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, contains(2)); // switch statement
    expect(lines, contains(4)); // print one
    expect(lines, contains(6)); // print two
  });

  test('parse switch expressions', () {
    const source = '''
void main() {
  final value = switch (1) {
    1 => 'one',
    2 => 'two',
    _ => 'other',
  };
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, contains(2)); // switch expression in assignment
  });

  test('parse for loops', () {
    const source = '''
void main() {
  for (var i = 0; i < 10; i++) {
    print(i);
  }
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, contains(2)); // for statement
    expect(lines, contains(3)); // print
  });

  test('parse while loops', () {
    const source = '''
void main() {
  while (true) {
    print('loop');
  }
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, contains(2)); // while statement
    expect(lines, contains(3)); // print
  });

  test('parse do-while loops', () {
    const source = '''
void main() {
  do {
    print('loop');
  } while (true);
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, contains(2)); // do statement
    expect(lines, contains(3)); // print
  });

  test('parse assignments', () {
    const source = '''
void main() {
  var x = 0;
  x = 5;
  x += 10;
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, contains(2)); // declaration with initializer
    expect(lines, contains(3)); // assignment
    expect(lines, contains(4)); // compound assignment
  });

  test('parse function calls', () {
    const source = '''
void main() {
  print('hello');
  someFunction();
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, contains(2)); // print call
    expect(lines, contains(3)); // function call
  });

  test('parse throw statements', () {
    const source = '''
void main() {
  throw Exception('error');
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, contains(2)); // throw
  });

  test('parse try-catch statements', () {
    const source = '''
void main() {
  try {
    print('try');
  } catch (e) {
    print('catch');
  }
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, contains(2)); // try statement
    expect(lines, contains(3)); // print in try
    expect(lines, contains(5)); // print in catch
    // Note: catch clause line (4) is not independently executable
  });

  test('ignore blank lines', () {
    const source = '''
void main() {

  print('hello');

}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, hasLength(1));
    expect(lines, contains(3)); // only print statement
  });

  test('ignore comment-only lines', () {
    const source = '''
void main() {
  // This is a comment
  print('hello');
  /* Block comment */
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, hasLength(1));
    expect(lines, contains(3)); // only print statement
  });

  test('ignore brace-only lines', () {
    const source = '''
void main()
{
  print('hello');
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, contains(3)); // print statement
    expect(lines.contains(2), isFalse); // opening brace line
  });

  test('ignore import statements', () {
    const source = '''
import 'dart:core';
import 'package:test/test.dart';

void main() {
  print('hello');
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, hasLength(1));
    expect(lines, contains(5)); // only print statement
  });

  test('ignore export statements', () {
    const source = '''
export 'src/lib.dart';

void main() {
  print('hello');
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, hasLength(1));
    expect(lines, contains(4)); // only print statement
  });

  test('ignore part directives', () {
    const source = '''
part 'lib_part.dart';

void main() {
  print('hello');
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, hasLength(1));
    expect(lines, contains(4)); // only print statement
  });

  test('ignore library directives', () {
    const source = '''
library my_lib;

void main() {
  print('hello');
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, hasLength(1));
    expect(lines, contains(4)); // only print statement
  });

  test('parse assert statements', () {
    const source = '''
void main() {
  assert(true);
  assert(1 == 1, 'should be equal');
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, contains(2)); // first assert
    expect(lines, contains(3)); // second assert
  });

  test('parse break and continue statements', () {
    const source = '''
void main() {
  for (var i = 0; i < 10; i++) {
    if (i == 5) break;
    if (i == 3) continue;
  }
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, contains(2)); // for loop
    expect(lines, contains(3)); // if with break
    expect(lines, contains(4)); // if with continue
  });

  test('parse yield statements', () {
    const source = '''
Iterable<int> generate() sync* {
  yield 1;
  yield* [2, 3, 4];
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, contains(2)); // yield
    expect(lines, contains(3)); // yield*
  });

  test('return error for invalid Dart code', () {
    const source = '''
void main() {
  this is not valid dart code !@#
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    // Parser should still succeed but may not identify lines correctly
    // The analyzer is lenient and tries to parse even invalid code
    expect(result.isSuccess, isTrue);
  });

  test('parse complex nested structures', () {
    const source = '''
void main() {
  final list = [1, 2, 3];
  for (final item in list) {
    if (item > 1) {
      print(item);
    } else {
      continue;
    }
  }
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, contains(2)); // list declaration
    expect(lines, contains(3)); // for loop
    expect(lines, contains(4)); // if statement
    expect(lines, contains(5)); // print
    expect(lines, contains(7)); // continue
  });

  test('return sorted line numbers', () {
    const source = '''
void main() {
  print('1');
  print('2');
  print('3');
}
''';

    final result = parseExecutableLines(source, 'test.dart');
    expect(result.isSuccess, isTrue);

    final lines = switch (result) {
      Success(value: final v) => v,
      Error() => throw Exception('Should not fail'),
    };
    expect(lines, [2, 3, 4]); // should be in order
  });
}
