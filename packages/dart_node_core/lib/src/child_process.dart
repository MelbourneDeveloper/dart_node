/// Node.js child_process bindings for dart2js.
///
/// dart:io doesn't work in dart2js, so we use JS interop to access
/// Node.js child_process.spawn directly.
library;

import 'dart:async';
import 'dart:js_interop';

// Use require - dart2js already accesses via globalThis
@JS('require')
external JSAny _require(JSString module);

/// A spawned child process with typed streams.
///
/// Wraps the Node.js ChildProcess object without exposing JS types.
final class Process {
  Process._(this._jsProcess);

  final _ChildProcess _jsProcess;

  /// Stream of stdout data.
  Stream<String> get stdout => _stdoutController.stream;

  /// Stream of stderr data.
  Stream<String> get stderr => _stderrController.stream;

  // Closed by Node.js 'end' events via _createStringStreamFromReadable.
  // ignore: close_sinks
  late final StreamController<String> _stdoutController =
      _createStringStreamFromReadable(_jsProcess._stdout);

  // Closed by Node.js 'end' events via _createStringStreamFromReadable.
  // ignore: close_sinks
  late final StreamController<String> _stderrController =
      _createStringStreamFromReadable(_jsProcess._stderr);

  /// Write data to the process stdin.
  void write(String data) => _writeToStream(_jsProcess._stdin, data);

  /// Kill the process with an optional signal.
  void kill([String? signal]) => _jsProcess.kill(signal);

  /// Listen for process exit. Returns the exit code (null if killed).
  void onExit(void Function(int? code) callback) {
    _jsProcess._onClose(callback);
  }

  /// Wait for the process to exit and return the exit code.
  Future<int?> get exitCode {
    final completer = Completer<int?>();
    onExit(completer.complete);
    return completer.future;
  }
}

/// Spawn a child process.
///
/// [command] - The command to run.
/// [args] - Arguments to pass to the command.
/// [shell] - Whether to run the command in a shell.
Process spawn(String command, List<String> args, {bool shell = false}) {
  final cp = _require('child_process'.toJS) as JSObject;
  final jsArgs = args.map((a) => a.toJS).toList().toJS;
  final options = _createObject();
  _setProperty(options, 'shell'.toJS, shell.toJS);
  final spawnFn = _getProperty(cp, 'spawn'.toJS);
  final result = _callApply(spawnFn, cp, [command.toJS, jsArgs, options].toJS);
  final jsProcess = _ChildProcess._(result as JSObject);
  return Process._(jsProcess);
}

// Internal JS interop types - not exposed publicly

extension type _ChildProcess._(JSObject _) implements JSObject {
  external JSObject get stdin;
  external JSObject get stdout;
  external JSObject get stderr;
  external void kill([String? signal]);

  JSObject get _stdin => stdin;
  JSObject get _stdout => stdout;
  JSObject get _stderr => stderr;

  void _onClose(void Function(int? code) callback) {
    _on(
      this,
      'close'.toJS,
      ((JSNumber? code) {
        callback(code?.toDartInt);
      }).toJS,
    );
  }
}

StreamController<String> _createStringStreamFromReadable(JSObject readable) {
  final controller = StreamController<String>.broadcast();

  // Set encoding to utf8
  _call(readable, 'setEncoding'.toJS, ['utf8'.toJS].toJS);

  // Listen to 'data' event
  _on(
    readable,
    'data'.toJS,
    ((JSString chunk) {
      controller.add(chunk.toDart);
    }).toJS,
  );

  // Listen to 'error' event
  void handleError(JSObject err) => controller.addError(err);
  _on(readable, 'error'.toJS, handleError.toJS);

  // Listen to 'end' event
  _on(
    readable,
    'end'.toJS,
    (() {
      unawaited(controller.close());
    }).toJS,
  );

  return controller;
}

void _writeToStream(JSObject writable, String data) {
  _call(writable, 'write'.toJS, [data.toJS].toJS);
}

@JS('Object.create')
external JSObject _createObject();

@JS('Reflect.set')
external void _setProperty(JSObject obj, JSString key, JSAny? value);

void _on(JSObject emitter, JSString event, JSFunction callback) {
  final onMethod = _getProperty(emitter, 'on'.toJS);
  _callApply(onMethod, emitter, [event, callback].toJS);
}

void _call(JSObject obj, JSString method, JSArray args) {
  final fn = _getProperty(obj, method);
  _callApply(fn, obj, args);
}

@JS('Reflect.get')
external JSFunction _getProperty(JSObject obj, JSString key);

@JS('Reflect.apply')
external JSAny _callApply(JSFunction fn, JSObject thisArg, JSArray args);
