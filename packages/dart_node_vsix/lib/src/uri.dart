import 'dart:js_interop';

/// A URI in VSCode.
extension type VsUri._(JSObject _) implements JSObject {
  /// Creates a URI from a file path.
  factory VsUri.file(String path) => _vsUriFile(path.toJS);

  /// Creates a URI by parsing a string.
  factory VsUri.parse(String value) => _vsUriParse(value.toJS);

  /// The scheme (e.g., 'file', 'http').
  external String get scheme;

  /// The authority (e.g., host and port).
  external String get authority;

  /// The path.
  external String get path;

  /// The query string.
  external String get query;

  /// The fragment.
  external String get fragment;

  /// The file system path (only for file URIs).
  external String get fsPath;

  /// Returns the string representation.
  String toStringValue() => _vsUriToString(_);
}

@JS('vscode.Uri.file')
external VsUri _vsUriFile(JSString path);

@JS('vscode.Uri.parse')
external VsUri _vsUriParse(JSString value);

@JS()
external String _vsUriToString(JSObject uri);
