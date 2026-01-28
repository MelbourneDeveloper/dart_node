/// Runtime coverage probe for dart2js compiled code running on Node.js.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Extension type for accessing global coverage data
extension type _GlobalWithCoverage(JSObject _) implements JSObject {
  external JSObject? get __dartCoverage;
  external set __dartCoverage(JSObject value);
  external JSFunction get require;
}

/// Extension type for Node.js fs module
extension type _NodeFS(JSObject _) implements JSObject {
  external void writeFileSync(JSString path, JSString data);
  external void mkdirSync(JSString path, JSObject? options);
  external bool existsSync(JSString path);
}

/// Extension type for Node.js path module
extension type _NodePath(JSObject _) implements JSObject {
  external JSString dirname(JSString path);
}

/// Extension type for JSON static methods
@JS('JSON')
extension type _JSON._(JSObject _) implements JSObject {
  external static JSString stringify(JSAny obj);
}

/// Get the global context with coverage data access
_GlobalWithCoverage get _global => _GlobalWithCoverage(globalContext);

/// Get or initialize the coverage data object
JSObject _getCoverageData() {
  final existing = _global.__dartCoverage;
  if (existing != null) return existing;

  final newData = JSObject();
  _global.__dartCoverage = newData;
  return newData;
}

/// Get or create file coverage object
JSObject _getFileCoverage(String file) {
  final data = _getCoverageData();
  final fileJS = file.toJS;
  final existing = data.getProperty(fileJS);

  // Type-checked cast: safe after isA<T>() verification
  if (existing != null && existing.isA<JSObject>()) {
    return existing as JSObject; // Required for js_interop type narrowing
  }

  // Create new file coverage object if it doesn't exist or is wrong type
  final newFile = JSObject();
  data.setProperty(fileJS, newFile);
  return newFile;
}

/// Initialize coverage collection (call once at test startup)
void initCoverage() {
  _getCoverageData();
}

/// Record a line execution - called by instrumented code
/// CRITICAL: This function is called millions of times, must be fast
void cov(String file, int line) {
  final fileCov = _getFileCoverage(file);
  final lineKey = line.toString().toJS;
  final currentRaw = fileCov.getProperty(lineKey);

  // Fast path: increment existing count
  // Type-checked cast: safe after isA<T>() verification
  final double newCount;
  if (currentRaw != null && currentRaw.isA<JSNumber>()) {
    newCount =
        (currentRaw as JSNumber).toDartDouble + 1.0; // Required for js_interop
  } else {
    // First execution of this line
    newCount = 1.0;
  }

  fileCov.setProperty(lineKey, newCount.toJS);
}

/// Get coverage data as JSON string
String getCoverageJson() {
  final data = _getCoverageData();
  return _JSON.stringify(data).toDart;
}

/// Write coverage data to a file (Node.js only)
void writeCoverageFile(String outputPath) {
  // Load Node.js modules
  final fsResult = _global.require.callAsFunction(null, 'fs'.toJS);
  if (fsResult == null || !fsResult.isA<JSObject>()) {
    throw StateError('Failed to load fs module (Node.js required)');
  }

  final pathResult = _global.require.callAsFunction(null, 'path'.toJS);
  if (pathResult == null || !pathResult.isA<JSObject>()) {
    throw StateError('Failed to load path module (Node.js required)');
  }

  // Type-checked casts: safe after isA<JSObject>() verification
  // Extension type constructors require JSObject, casts are required for js_interop
  final fs = _NodeFS(fsResult as JSObject);
  final pathMod = _NodePath(pathResult as JSObject);

  // Create directory if it doesn't exist
  final dir = pathMod.dirname(outputPath.toJS);
  if (!fs.existsSync(dir)) {
    final options = JSObject()..setProperty('recursive'.toJS, true.toJS);
    fs.mkdirSync(dir, options);
  }

  // Write coverage data
  final jsonData = getCoverageJson();
  fs.writeFileSync(outputPath.toJS, jsonData.toJS);
}
