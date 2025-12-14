import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('jsx_demo example transpiles, compiles, and produces valid JS', () async {
    final projectRoot = Directory.current.parent.parent.path;
    final testDir = Directory.systemTemp.createTempSync('jsx_integration_test');

    try {
      final jsxSourcePath = '${testDir.path}/test_component.jsx';
      final transpiledPath = '${testDir.path}/test_component.g.dart';
      final appPath = '${testDir.path}/app.dart';
      final pubspecPath = '${testDir.path}/pubspec.yaml';

      File(jsxSourcePath).writeAsStringSync('''
/// Test component.
library;

import 'package:dart_node_react/dart_node_react.dart';

ReactElement TestComponent() {
  final count = useState(0);

  return <div className="test">
    <h1>Test JSX</h1>
    <div className="value">{count.value}</div>
    <button onClick={() => count.set(count.value + 1)}>
      Increment
    </button>
  </div>;
}
''');

      File(appPath).writeAsStringSync('''
import 'dart:js_interop';
import 'package:dart_node_react/dart_node_react.dart';
import 'test_component.g.dart';

void main() {
  final root = createRoot(document.getElementById('root')!);
  root.render(TestComponent());
}

@JS('document')
external JSObject get document;

extension on JSObject {
  external JSObject? getElementById(String id);
}
''');

      File(pubspecPath).writeAsStringSync('''
name: jsx_integration_test
description: Integration test for JSX
version: 0.1.0
publish_to: none

environment:
  sdk: ^3.10.0

dependencies:
  dart_node_react:
    path: $projectRoot/packages/dart_node_react
''');

      final pubGetResult = Process.runSync('dart', [
        'pub',
        'get',
      ], workingDirectory: testDir.path);
      expect(
        pubGetResult.exitCode,
        equals(0),
        reason: 'pub get must succeed: ${pubGetResult.stderr}',
      );

      final transpileResult = Process.runSync('dart', [
        'run',
        '$projectRoot/packages/dart_jsx/bin/jsx.dart',
        jsxSourcePath,
        transpiledPath,
      ]);
      expect(
        transpileResult.exitCode,
        equals(0),
        reason: 'JSX transpilation must succeed: ${transpileResult.stderr}',
      );

      final transpiledExists = File(transpiledPath).existsSync();
      expect(transpiledExists, isTrue, reason: 'Transpiled file must exist');

      final transpiledContent = File(transpiledPath).readAsStringSync();
      expect(
        transpiledContent,
        contains('\$div(className: \'test\')'),
        reason: 'Transpiled output must contain div with className',
      );
      expect(
        transpiledContent,
        contains('\$h1 >> \'Test JSX\''),
        reason: 'Transpiled output must contain h1 element',
      );
      expect(
        transpiledContent,
        contains('\$button(onClick:'),
        reason: 'Transpiled output must contain button with onClick',
      );
      expect(
        transpiledContent,
        contains('count.value'),
        reason: 'Transpiled output must reference count.value',
      );
      expect(
        transpiledContent,
        contains('useState'),
        reason: 'Transpiled output must use useState',
      );

      final compileResult = Process.runSync('dart', [
        'compile',
        'js',
        'app.dart',
        '-o',
        'app.js',
      ], workingDirectory: testDir.path);
      expect(
        compileResult.exitCode,
        equals(0),
        reason:
            'Dart to JS compilation must succeed: ${compileResult.stdout}\n${compileResult.stderr}',
      );

      final jsExists = File('${testDir.path}/app.js').existsSync();
      expect(
        jsExists,
        isTrue,
        reason: 'Compiled JS file must exist at ${testDir.path}/app.js',
      );

      final jsContent = File('${testDir.path}/app.js').readAsStringSync();
      expect(
        jsContent.isNotEmpty,
        isTrue,
        reason: 'Compiled JS must not be empty',
      );
      expect(
        jsContent,
        contains('function'),
        reason: 'Compiled JS must contain function declarations',
      );
      expect(
        jsContent,
        contains('main'),
        reason: 'Compiled JS must contain main function',
      );

      final jsLines = jsContent.split('\n').length;
      expect(
        jsLines,
        greaterThan(10),
        reason: 'Compiled JS should have substantial content',
      );
    } finally {
      testDir.deleteSync(recursive: true);
    }
  });

  test('counter.jsx from jsx_demo transpiles and compiles successfully', () async {
    final projectRoot = Directory.current.parent.parent.path;
    final exampleDir = '$projectRoot/examples/jsx_demo';
    final jsxFile = '$exampleDir/lib/counter.jsx';
    final gDartFile = '$exampleDir/lib/counter.g.dart';

    final jsxExists = File(jsxFile).existsSync();
    expect(
      jsxExists,
      isTrue,
      reason: 'counter.jsx must exist in jsx_demo example',
    );

    final transpileResult = Process.runSync('dart', [
      'run',
      '$projectRoot/packages/dart_jsx/bin/jsx.dart',
      jsxFile,
      gDartFile,
    ]);
    expect(
      transpileResult.exitCode,
      equals(0),
      reason:
          'counter.jsx transpilation must succeed: ${transpileResult.stderr}',
    );

    final gDartExists = File(gDartFile).existsSync();
    expect(gDartExists, isTrue, reason: 'counter.g.dart must be generated');

    final gDartContent = File(gDartFile).readAsStringSync();
    expect(
      gDartContent,
      contains('ReactElement Counter()'),
      reason: 'Generated file must contain Counter function',
    );
    expect(
      gDartContent,
      contains('useState'),
      reason: 'Generated file must use useState',
    );
    expect(
      gDartContent,
      contains('\$div(className: \'counter\')'),
      reason: 'Generated file must contain counter div',
    );
    expect(
      gDartContent,
      contains('\$button'),
      reason: 'Generated file must contain buttons',
    );
    expect(
      gDartContent,
      contains('onClick:'),
      reason: 'Generated file must have onClick handlers',
    );
    expect(
      gDartContent,
      contains('count.value'),
      reason: 'Generated file must reference count.value',
    );

    final testDir = Directory.systemTemp.createTempSync(
      'jsx_demo_compile_test',
    );

    try {
      final testJsxPath = '${testDir.path}/test_counter.jsx';
      final testGDartPath = '${testDir.path}/test_counter.g.dart';
      final testAppPath = '${testDir.path}/app.dart';
      final testPubspecPath = '${testDir.path}/pubspec.yaml';

      File(testJsxPath).writeAsStringSync(File(jsxFile).readAsStringSync());

      File(testPubspecPath).writeAsStringSync('''
name: jsx_demo_test
description: Test compilation of jsx_demo counter
version: 0.1.0
publish_to: none

environment:
  sdk: ^3.10.0

dependencies:
  dart_node_react:
    path: $projectRoot/packages/dart_node_react
''');

      final transpileTest = Process.runSync('dart', [
        'run',
        '$projectRoot/packages/dart_jsx/bin/jsx.dart',
        testJsxPath,
        testGDartPath,
      ]);
      expect(
        transpileTest.exitCode,
        equals(0),
        reason:
            'Test counter transpilation must succeed: ${transpileTest.stderr}',
      );

      File(testAppPath).writeAsStringSync('''
import 'dart:js_interop';
import 'package:dart_node_react/dart_node_react.dart';
import 'test_counter.g.dart';

void main() {
  final root = createRoot(document.getElementById('root')!);
  root.render(Counter());
}

@JS('document')
external JSObject get document;

extension on JSObject {
  external JSObject? getElementById(String id);
}
''');

      final pubGet = Process.runSync('dart', [
        'pub',
        'get',
      ], workingDirectory: testDir.path);
      expect(
        pubGet.exitCode,
        equals(0),
        reason: 'pub get must succeed: ${pubGet.stderr}',
      );

      final compile = Process.runSync('dart', [
        'compile',
        'js',
        'app.dart',
        '-o',
        'app.js',
      ], workingDirectory: testDir.path);
      expect(
        compile.exitCode,
        equals(0),
        reason:
            'Counter app must compile to JS:\nSTDOUT: ${compile.stdout}\nSTDERR: ${compile.stderr}',
      );

      final jsFile = File('${testDir.path}/app.js');
      expect(
        jsFile.existsSync(),
        isTrue,
        reason: 'Compiled JS file must exist',
      );

      final jsContent = jsFile.readAsStringSync();
      expect(
        jsContent.isNotEmpty,
        isTrue,
        reason: 'Compiled JS must not be empty',
      );
      expect(
        jsContent,
        contains('function'),
        reason: 'Compiled JS must contain functions',
      );

      final jsLines = jsContent.split('\n').length;
      expect(
        jsLines,
        greaterThan(50),
        reason: 'Compiled JS should have substantial content',
      );
    } finally {
      testDir.deleteSync(recursive: true);
    }
  });
}
