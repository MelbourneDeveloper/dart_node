/// Tests proving npmComponent() can use ANY npm package directly.
///
/// These tests use 'react' (installed via package.json) to test the npm
/// module loading infrastructure. react-native cannot be tested here as
/// it requires a native runtime environment (Expo/RN CLI).
@TestOn('js')
library;

import 'dart:js_interop';

import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:dart_node_react_native/dart_node_react_native.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

void main() {
  setUp(initCoverage);
  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));
  test('loadNpmModule loads react successfully', () {
    final result = loadNpmModule('react');
    expect(result.isSuccess, isTrue);
  });

  test('loadNpmModule caches modules', () {
    clearNpmModuleCache();
    expect(isModuleCached('react'), isFalse);

    loadNpmModule('react');
    expect(isModuleCached('react'), isTrue);

    // Second call uses cache
    final result2 = loadNpmModule('react');
    expect(result2.isSuccess, isTrue);
  });

  test('loadNpmModule returns error for nonexistent package', () {
    final result = loadNpmModule('nonexistent-package-xyz-123');
    expect(result.isSuccess, isFalse);
  });

  test('getComponentFromModule gets createElement from react', () {
    final moduleResult = loadNpmModule('react');
    expect(moduleResult.isSuccess, isTrue);

    final module = (moduleResult as Success<JSObject, String>).value;
    final result = getComponentFromModule(module, 'createElement');
    expect(result.isSuccess, isTrue);
  });

  test('getComponentFromModule returns error for nonexistent component', () {
    final moduleResult = loadNpmModule('react');
    expect(moduleResult.isSuccess, isTrue);

    final module = (moduleResult as Success<JSObject, String>).value;
    final result = getComponentFromModule(module, 'NonExistentComponent');
    expect(result.isSuccess, isFalse);
  });

  test('npmComponentSafe returns Error for invalid package', () {
    final result = npmComponentSafe('nonexistent-package-xyz', 'Component');
    expect(result.isSuccess, isFalse);
  });

  test('npmFactory gets createElement from react', () {
    final result = npmFactory<JSFunction>('react', 'createElement');
    expect(result.isSuccess, isTrue);
  });

  test('clearNpmModuleCache clears all cached modules', () {
    loadNpmModule('react');
    expect(isModuleCached('react'), isTrue);

    clearNpmModuleCache();
    expect(isModuleCached('react'), isFalse);
  });
}
