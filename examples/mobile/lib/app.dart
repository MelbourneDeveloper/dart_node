import 'dart:js_interop';

import 'package:dart_node_react/dart_node_react.dart';
import 'package:dart_node_react_native/dart_node_react_native.dart';
import 'package:shared/http/http_client.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/task_list_screen.dart';
import 'types.dart';

/// Main App component - renders as a ReactElement for testing
// React component functions follow PascalCase naming convention
// ignore: non_constant_identifier_names
ReactElement MobileApp({Fetch? fetchFn}) =>
    functionalComponent('MobileApp', (JSObject props) {
      final tokenState = useStateJS(null);
      final userState = useStateJS(null);
      final viewState = useState('login');

      final token = switch (tokenState.value) {
        final JSString s => s,
        _ => null,
      };
      final user = switch (userState.value) {
        final JSObject o => JSUser.fromJS(o),
        _ => null,
      };
      final view = viewState.value;

      final authEffects = (
        setToken: (JSAny? t) => tokenState.set(t),
        setUser: (JSAny? u) => userState.set(u),
        setView: (String v) => viewState.set(v),
      );

      return _buildCurrentView(
        view: view,
        token: token,
        user: user,
        authEffects: authEffects,
        fetchFn: fetchFn,
      );
    });

/// Main App component as JSFunction for registration
JSFunction app() => createFunctionalComponent((JSObject props) {
  final tokenState = useStateJS(null);
  final userState = useStateJS(null);
  final viewState = useState('login');

  final token = switch (tokenState.value) {
    final JSString s => s,
    _ => null,
  };
  final user = switch (userState.value) {
    final JSObject o => JSUser.fromJS(o),
    _ => null,
  };
  final view = viewState.value;

  final authEffects = (
    setToken: (JSAny? t) => tokenState.set(t),
    setUser: (JSAny? u) => userState.set(u),
    setView: (String v) => viewState.set(v),
  );

  return _buildCurrentView(
    view: view,
    token: token,
    user: user,
    authEffects: authEffects,
  );
});

ReactElement _buildCurrentView({
  required String view,
  required JSString? token,
  required JSUser? user,
  required AuthEffects authEffects,
  Fetch? fetchFn,
}) => switch (view) {
  'login' => loginScreen(authEffects: authEffects, fetchFn: fetchFn),
  'register' => registerScreen(authEffects: authEffects, fetchFn: fetchFn),
  'tasks' => taskListScreen(
    token: token?.toDart ?? '',
    user: user,
    authEffects: authEffects,
    fetchFn: fetchFn,
  ),
  _ => loginScreen(authEffects: authEffects, fetchFn: fetchFn),
};

@JS('console.log')
external void _consoleLog(JSAny? message);

@JS('console.error')
external void _consoleError(JSAny? message);

/// Register the app with React Native
void registerMobileApp() {
  _consoleLog('=== registerMobileApp() STARTING ==='.toJS);
  _consoleLog('=== Checking global.reactNative ==='.toJS);
  try {
    _consoleLog('=== About to call app() ==='.toJS);
    final appComponent = app();
    _consoleLog('=== app() returned successfully ==='.toJS);
    _consoleLog('=== appComponent type: ${appComponent.runtimeType} ==='.toJS);
    _consoleLog('=== About to call registerApp() ==='.toJS);
    registerApp('main', appComponent);
    _consoleLog('=== registerApp() completed successfully ==='.toJS);
  } catch (e, st) {
    _consoleError('=== ERROR in registerMobileApp ==='.toJS);
    _consoleError('Error: $e'.toJS);
    _consoleError('Stack: $st'.toJS);
  }
}
