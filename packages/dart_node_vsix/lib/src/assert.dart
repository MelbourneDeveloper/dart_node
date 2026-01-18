import 'dart:js_interop';

/// Node.js assert module bindings.
@JS('require')
external _Assert _requireAssert(String module);

final _assert = _requireAssert('assert');

extension type _Assert._(JSObject _) implements JSObject {
  external void ok(JSAny? value, [String? message]);
  external void strictEqual(JSAny? actual, JSAny? expected, [String? message]);
  external void deepStrictEqual(
    JSAny? actual,
    JSAny? expected, [
    String? message,
  ]);
  external void fail([String? message]);
}

/// Asserts that value is truthy.
void assertOk(Object? value, [String? message]) {
  _assert.ok(value.jsify(), message);
}

/// Asserts strict equality (===).
void assertEqual<T>(T actual, T expected, [String? message]) {
  _assert.strictEqual(actual.jsify(), expected.jsify(), message);
}

/// Asserts deep equality for objects/arrays.
void assertDeepEqual(Object? actual, Object? expected, [String? message]) {
  _assert.deepStrictEqual(actual.jsify(), expected.jsify(), message);
}

/// Fails the test with a message.
void assertFail([String? message]) {
  _assert.fail(message);
}
