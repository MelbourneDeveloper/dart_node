import 'dart:js_interop';

/// API configuration
const apiUrl = 'http://localhost:3000';

/// Auth state - immutable record
typedef AuthState = ({JSString? token, JSObject? user, String view});

/// Auth actions typeclass - Haskell style effect abstraction
typedef SetToken = void Function(JSString?);
typedef SetUser = void Function(JSObject?);
typedef SetView = void Function(String);

/// Auth effects bundle
typedef AuthEffects = ({SetToken setToken, SetUser setUser, SetView setView});

/// Form state setter typeclass
typedef SetFormValue<T> = void Function(T);

/// Loading effect
typedef SetLoading = void Function(bool);

/// Error effect
typedef SetError = void Function(String?);

/// Form effects bundle
typedef FormEffects = ({SetLoading setLoading, SetError setError});

/// Task operations typeclass
typedef OnToggleTask = void Function(String id, bool completed);
typedef OnDeleteTask = void Function(String id);

/// Task effects bundle
typedef TaskEffects = ({OnToggleTask onToggle, OnDeleteTask onDelete});

/// Generic async effect - represents any async operation
typedef AsyncEffect<T> = Future<T> Function();

/// Event handler effect
typedef OnClick = void Function();

/// Input change handler
typedef OnInputChange = void Function(JSAny event);

/// Helper to wrap JSFunction setState calls
SetFormValue<T> wrapSetState<T>(JSFunction setState) =>
    (value) => setState.callAsFunction(null, switch (value) {
      final String s => s.toJS,
      final bool b => b.toJS,
      final int i => i.toJS,
      final double d => d.toJS,
      null => null,
      _ => throw StateError('Unsupported type: ${value.runtimeType}'),
    });

/// Helper to wrap JSFunction setState for nullable JSAny
void Function(JSAny?) wrapSetStateJSAny(JSFunction setState) =>
    (value) => setState.callAsFunction(null, value);

/// Clear state helper
void Function() wrapClearState(JSFunction setState) =>
    () => setState.callAsFunction();
