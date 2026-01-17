import 'dart:async';
import 'dart:js_interop';

/// Mocha test framework bindings for Dart.
/// Used to write VSCode extension tests that compile to JavaScript.

/// Defines a test suite.
@JS('suite')
external void suite(String name, JSFunction callback);

/// Defines a test case.
@JS('test')
external void test(String name, JSFunction callback);

/// Setup that runs once before all tests in a suite.
@JS('suiteSetup')
external void suiteSetup(JSFunction callback);

/// Teardown that runs once after all tests in a suite.
@JS('suiteTeardown')
external void suiteTeardown(JSFunction callback);

/// Setup that runs before each test.
@JS('setup')
external void setup(JSFunction callback);

/// Teardown that runs after each test.
@JS('teardown')
external void teardown(JSFunction callback);

/// Helper to create a sync test function for Mocha.
JSFunction syncTest(void Function() fn) => fn.toJS;

/// setTimeout for scheduling.
@JS('setTimeout')
external void _setTimeout(JSFunction callback, int delay);

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
  } on Object catch (e) {
    _setTimeout(
      (() => done.callAsFunction(null, e.toString().toJS)).toJS,
      0,
    );
  }
}
