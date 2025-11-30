import 'dart:js_interop';
import 'dart:js_interop_unsafe';

extension type _GlobalContext(JSObject _) implements JSObject {
  external JSFunction get require;
  external JSObject get console;
}

extension type _Console(JSObject _) implements JSObject {
  external JSFunction get log;
}

_GlobalContext get _context => _GlobalContext(globalContext);

/// Get a value from the global JavaScript context
JSAny? getGlobal(String name) => globalContext[name];

/// Get Node's require function
JSFunction get require => _context.require;

/// Get the console object
JSObject get console => _context.console;

/// Log to console
void consoleLog(String message) {
  _Console(console).log.callAsFunction(null, message.toJS);
}
