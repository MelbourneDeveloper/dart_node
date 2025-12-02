import 'dart:js_interop';

import 'package:dart_node_react/dart_node_react.dart';
import 'package:dart_node_react_native/dart_node_react_native.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/task_list_screen.dart';
import 'types.dart';

/// Main App component
JSFunction app() => createFunctionalComponent((JSObject props) {
      final tokenState = useState<JSString?>(null);
      final userState = useState<JSObject?>(null);
      final viewState = useState('login');

      final token = tokenState.value;
      final user = userState.value;
      final view = viewState.value;

      final authEffects = (
        setToken: (JSString? t) => tokenState.set(t),
        setUser: (JSObject? u) => userState.set(u),
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
  required JSObject? user,
  required AuthEffects authEffects,
}) =>
    switch (view) {
      'login' => loginScreen(authEffects: authEffects),
      'register' => registerScreen(authEffects: authEffects),
      'tasks' => taskListScreen(
          token: token?.toDart ?? '',
          user: user,
          authEffects: authEffects,
        ),
      _ => loginScreen(authEffects: authEffects),
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
