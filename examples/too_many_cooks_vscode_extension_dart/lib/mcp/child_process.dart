/// Node.js child_process bindings for dart2js in VSCode extension host.
///
/// dart:io doesn't work in dart2js, so we use JS interop to access
/// Node.js child_process.spawn directly.
library;

import 'dart:async';
import 'dart:js_interop';

// Node.js interop bindings - documenting every member is impractical.
// ignore_for_file: public_member_api_docs

@JS('console.log')
external void _consoleLog(JSAny? message);

void _log(String msg) => _consoleLog(msg.toJS);

/// Node.js ChildProcess object.
@JS()
extension type ChildProcess._(JSObject _) implements JSObject {
  external JSObject get stdin;
  external JSObject get stdout;
  external JSObject get stderr;
  external void kill([String? signal]);

  /// Listen to 'close' event.
  void onClose(void Function(int? code) callback) {
    _on(
      this,
      'close'.toJS,
      ((JSNumber? code) {
        callback(code?.toDartInt);
      }).toJS,
    );
  }
}

/// Require a Node.js module - dart2js already accesses via globalThis.
@JS('require')
external JSObject _require(JSString module);

/// Spawn a child process.
ChildProcess spawn(String command, List<String> args, {bool shell = false}) {
  _log('[SPAWN] spawn($command, $args, shell=$shell)');
  final cp = _require('child_process'.toJS);
  _log('[SPAWN] child_process module loaded');
  final jsArgs = args.map((a) => a.toJS).toList().toJS;
  // Use eval to create a plain JS object - Object.create needs prototype arg
  final options = _eval('({})'.toJS) as JSObject;
  _setProperty(options, 'shell'.toJS, shell.toJS);
  // Explicitly set stdio to pipe for stdin/stdout/stderr
  final stdio = ['pipe'.toJS, 'pipe'.toJS, 'pipe'.toJS].toJS;
  _setProperty(options, 'stdio'.toJS, stdio);
  _log('[SPAWN] Options configured with stdio:pipe');
  final spawnFn = _getProperty(cp, 'spawn'.toJS);
  _log('[SPAWN] Got spawn function');
  final proc = _callSpawn(spawnFn, cp, [command.toJS, jsArgs, options].toJS);
  _log('[SPAWN] Process spawned: $proc');
  return ChildProcess._(proc as JSObject);
}

@JS('Reflect.apply')
external JSAny _callSpawn(JSFunction fn, JSObject thisArg, JSArray args);

/// Create a stream controller that listens to a Node.js readable stream.
StreamController<String> createStringStreamFromReadable(JSObject readable) {
  _log('[STREAM] createStringStreamFromReadable called');
  final controller = StreamController<String>.broadcast();

  // Set encoding to utf8
  _call(readable, 'setEncoding'.toJS, ['utf8'.toJS].toJS);
  _log('[STREAM] Set encoding to utf8');

  // Listen to 'data' event
  _on(
    readable,
    'data'.toJS,
    ((JSString chunk) {
      _log('[STREAM] Data received: ${chunk.toDart.length} chars');
      controller.add(chunk.toDart);
    }).toJS,
  );
  _log('[STREAM] Registered data listener');

  // Listen to 'error' event
  void onError(JSAny error) {
    _log('[STREAM] Error: $error');
    controller.addError(error);
  }

  _on(readable, 'error'.toJS, onError.toJS);

  // Listen to 'end' event
  _on(
    readable,
    'end'.toJS,
    (() {
      _log('[STREAM] End event');
      unawaited(controller.close());
    }).toJS,
  );

  return controller;
}

/// Write to a Node.js writable stream.
void writeToStream(JSObject writable, String data) {
  _log('[STREAM] writeToStream: ${data.length} chars');
  _call(writable, 'write'.toJS, [data.toJS].toJS);
  _log('[STREAM] writeToStream completed');
}

@JS('eval')
external JSAny _eval(JSString code);

@JS('Reflect.set')
external void _setProperty(JSObject obj, JSString key, JSAny? value);

void _on(JSObject emitter, JSString event, JSFunction callback) {
  final onMethod = _getProperty(emitter, 'on'.toJS);
  _callMethod(onMethod, emitter, [event, callback].toJS);
}

void _call(JSObject obj, JSString method, JSArray args) {
  final fn = _getProperty(obj, method);
  _callMethod(fn, obj, args);
}

@JS('Reflect.get')
external JSFunction _getProperty(JSObject obj, JSString key);

@JS('Reflect.apply')
external void _callMethod(JSFunction fn, JSObject thisArg, JSArray args);
