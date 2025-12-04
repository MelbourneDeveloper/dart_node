import 'dart:js_interop';
import 'dart:js_interop_unsafe';

// Re-export shared JS types
export 'package:shared/js_types/js_types.dart';

/// API configuration - reads from global set by build preamble
String get apiUrl =>
    (globalContext['__API_URL__'] as JSString?)?.toDart ??
    'http://localhost:3000';

/// WebSocket URL - derives from API URL (port 3001)
String get wsUrl {
  final api = apiUrl;
  final uri = Uri.parse(api);
  return 'ws://${uri.host}:3001';
}

/// Auth state - immutable record
typedef AuthState = ({JSString? token, JSObject? user, String view});

/// Auth actions
typedef SetToken = void Function(JSString?);
typedef SetUser = void Function(JSObject?);
typedef SetView = void Function(String);

/// Auth effects bundle
typedef AuthEffects = ({SetToken setToken, SetUser setUser, SetView setView});

/// Form state setter
typedef SetFormValue<T> = void Function(T);

/// Loading/error effects
typedef SetLoading = void Function(bool);
typedef SetError = void Function(String?);

/// Form effects bundle
typedef FormEffects = ({SetLoading setLoading, SetError setError});

/// Task operations
typedef OnToggleTask = void Function(String id, bool completed);
typedef OnDeleteTask = void Function(String id);

/// Task effects bundle
typedef TaskEffects = ({OnToggleTask onToggle, OnDeleteTask onDelete});
