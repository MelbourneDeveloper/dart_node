import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Type-safe wrapper for JS user objects
extension type JSUser._(JSObject _) implements JSObject {
  /// Wrap a JSObject as a JSUser
  factory JSUser.fromJS(JSObject js) = JSUser._;

  /// Get the user name safely
  String get name => switch (_['name']) {
    final JSString s => s.toDart,
    _ => '',
  };

  /// Get the user email safely
  String get email => switch (_['email']) {
    final JSString s => s.toDart,
    _ => '',
  };
}

/// Get display name with fallback to "User"
String getUserDisplayName(JSUser? user) {
  final name = user?.name ?? '';
  return name.isEmpty ? 'User' : name;
}
