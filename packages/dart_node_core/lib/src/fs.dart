/// Node.js `fs` module interop.
///
/// Provides synchronous file system operations for logging
/// and other use cases where async is unnecessary.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/src/node.dart';

final JSObject _fs = requireModule('fs') as JSObject;
final JSObject _path = requireModule('path') as JSObject;

/// Check whether a path exists (file or directory).
bool existsSync(String filePath) {
  final result = _fs.callMethod('existsSync'.toJS, filePath.toJS);
  if (result == null) return false;
  return (result as JSBoolean).toDart;
}

/// Create a directory (and parents) synchronously.
void mkdirSync(String dirPath, {bool recursive = false}) {
  final options = JSObject();
  options['recursive'] = recursive.toJS;
  _fs.callMethod('mkdirSync'.toJS, dirPath.toJS, options);
}

/// Append a string to a file synchronously. Creates the file if missing.
void appendFileSync(String filePath, String data) {
  _fs.callMethod('appendFileSync'.toJS, filePath.toJS, data.toJS);
}

/// Write a string to a file synchronously. Overwrites if exists.
void writeFileSync(String filePath, String data) {
  _fs.callMethod('writeFileSync'.toJS, filePath.toJS, data.toJS);
}

/// Read a file synchronously and return its contents as a string.
String readFileSync(String filePath) {
  final result = _fs.callMethod(
    'readFileSync'.toJS,
    filePath.toJS,
    'utf8'.toJS,
  );
  if (result == null) return '';
  return (result as JSString).toDart;
}

/// Join path segments using Node.js `path.join`.
String pathJoin(List<String> segments) {
  final jsArgs = segments.map((s) => s.toJS as JSAny).toList();
  final result = _path.callMethodVarArgs('join'.toJS, jsArgs);
  if (result == null) return '';
  return (result as JSString).toDart;
}

/// Get the directory name from a path.
String dirname(String filePath) {
  final result = _path.callMethod('dirname'.toJS, filePath.toJS);
  if (result == null) return '';
  return (result as JSString).toDart;
}
