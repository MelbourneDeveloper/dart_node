import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// API configuration - reads from global set by build preamble
String get apiUrl =>
    (globalContext['__API_URL__'] as JSString?)?.toDart ?? 'http://localhost:3000';

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

/// Helper to wrap JSFunction setState calls
SetFormValue<T> wrapSetState<T>(JSFunction setState) =>
    (value) => setState.callAsFunction(
          null,
          switch (value) {
            final String s => s.toJS,
            final bool b => b.toJS,
            final int i => i.toJS,
            final double d => d.toJS,
            null => null,
            _ => value as JSAny,
          },
        );

/// Helper to wrap JSFunction setState for nullable JSAny
void Function(JSAny?) wrapSetStateJSAny(JSFunction setState) =>
    (value) => setState.callAsFunction(null, value);

/// Clear state helper
void Function() wrapClearState(JSFunction setState) =>
    () => setState.callAsFunction();
