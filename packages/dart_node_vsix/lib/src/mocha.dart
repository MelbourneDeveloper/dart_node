import 'dart:async';
import 'dart:js_interop';

/// Mocha test framework bindings for Dart.
/// Used to write VSCode extension tests that compile to JavaScript.
///
/// IMPORTANT: These tests can ONLY run via `npm test` (VSCode Extension Host).
/// Do NOT run test/suite/*.dart with `dart test` - Mocha is not available.

/// Check if Mocha TDD globals are available.
@JS('globalThis.suite')
external JSFunction? get _mochaSuite;

/// Throws a helpful error if Mocha is not available.
void _requireMocha() {
  if (_mochaSuite == null) {
    throw StateError(
      '\n'
      '╔══════════════════════════════════════════════════════════════════╗\n'
      '║  ERROR: Mocha TDD globals not available!                         ║\n'
      '║                                                                  ║\n'
      '║  This test file uses Mocha and can ONLY run via:                 ║\n'
      '║    cd examples/too_many_cooks_vscode_extension                   ║\n'
      '║    npm test                                                      ║\n'
      '║                                                                  ║\n'
      '║  Do NOT use `dart test` on test/suite/*.dart files.              ║\n'
      '║  Use `dart test` only for test/*.dart files (not in suite/).     ║\n'
      '╚══════════════════════════════════════════════════════════════════╝\n',
    );
  }
}

/// Raw Mocha bindings (internal).
@JS('suite')
external void _suiteRaw(String name, JSFunction callback);

@JS('test')
external void _testRaw(String name, JSFunction callback);

@JS('suiteSetup')
external void _suiteSetupRaw(JSFunction callback);

@JS('suiteTeardown')
external void _suiteTeardownRaw(JSFunction callback);

@JS('setup')
external void _setupRaw(JSFunction callback);

@JS('teardown')
external void _teardownRaw(JSFunction callback);

/// Defines a test suite.
void suite(String name, JSFunction callback) {
  _requireMocha();
  _suiteRaw(name, callback);
}

/// Defines a test case.
void test(String name, JSFunction callback) {
  _requireMocha();
  _testRaw(name, callback);
}

/// Setup that runs once before all tests in a suite.
void suiteSetup(JSFunction callback) {
  _requireMocha();
  _suiteSetupRaw(callback);
}

/// Teardown that runs once after all tests in a suite.
void suiteTeardown(JSFunction callback) {
  _requireMocha();
  _suiteTeardownRaw(callback);
}

/// Setup that runs before each test.
void setup(JSFunction callback) {
  _requireMocha();
  _setupRaw(callback);
}

/// Teardown that runs after each test.
void teardown(JSFunction callback) {
  _requireMocha();
  _teardownRaw(callback);
}

/// Helper to create a sync test function for Mocha.
JSFunction syncTest(void Function() fn) => fn.toJS;

/// setTimeout for scheduling.
@JS('setTimeout')
external void _setTimeout(JSFunction callback, int delay);

/// console.error for logging.
@JS('console.error')
external void _consoleError(String msg);

/// Create a JS Error object.
@JS('Error')
external JSObject _createJSError(String message);

/// Helper to create an async test function for Mocha.
/// Uses the Mocha done() callback pattern with setTimeout to escape
/// Dart's async zone and properly signal completion to Mocha.
JSFunction asyncTest(Future<void> Function() fn) => ((JSFunction done) {
  unawaited(_runAsync(fn, done));
}).toJS;

/// Runs an async function and calls done when complete.
Future<void> _runAsync(Future<void> Function() fn, JSFunction done) async {
  try {
    await fn();
    _setTimeout(done, 0);
  } on Object catch (e, st) {
    // Log the actual error for debugging
    _consoleError('[ASYNC TEST ERROR] $e');
    _consoleError('[ASYNC TEST STACK] $st');
    // Create a proper JS Error object for Mocha
    final jsError = _createJSError('$e\n$st');
    _setTimeout((() => done.callAsFunction(null, jsError)).toJS, 0);
  }
}
