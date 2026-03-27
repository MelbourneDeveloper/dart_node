/// Typed Dart bindings for sql.js (SQLite compiled to WebAssembly).
///
/// Provides synchronous SQLite3 access via WebAssembly.
/// Call [initializeSqlJs] once at startup, then use [openDatabase].
library;

export 'src/database.dart';
export 'src/statement.dart';
export 'src/types.dart';
