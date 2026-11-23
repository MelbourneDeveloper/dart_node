import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart';
import 'package:frontend/src/form_helpers.dart';
import 'package:frontend/src/types.dart';
import 'package:nadz/nadz.dart';
import 'package:shared/http/http_client.dart';

/// Build login form component
ReactElement buildLoginForm(
  AuthEffects auth, {
  String baseUrl = apiUrl,
  Fetch? fetchFn,
}) {
  final doFetch = fetchFn ?? fetch;
  return createElement(
    ((JSAny props) {
      final emailState = useState('');
      final passState = useState('');
      final errorState = useState<String?>(null);
      final loadingState = useState(false);

      Future<void> handleSubmit() async {
        loadingState.set(true);
        errorState.set(null);

        try {
          final result = await doFetch(
            '$baseUrl/auth/login',
            method: 'POST',
            body: {'email': emailState.value, 'password': passState.value},
          );
          result.match(
            onSuccess: (response) {
              final data = response['data'];
              switch (data) {
                case null:
                  errorState.set('Login failed');
                case final JSObject details:
                  switch (details['token']) {
                    case final JSString token:
                      auth.setToken(token);
                      final user = switch (details['user']) {
                        final JSObject u => u,
                        _ => null,
                      };
                      auth.setUser(user);
                    default:
                      errorState.set('No token');
                  }
              }
            },
            onError: errorState.set,
          );
        } on Object catch (e) {
          errorState.set(e.toString());
        } finally {
          loadingState.set(false);
        }
      }

      return div(
        className: 'auth-card',
        children: [
          h2('Sign In', className: 'auth-title'),
          if (errorState.value != null)
            div(className: 'error-msg', child: span(errorState.value!))
          else
            span(''),
          formGroup(
            'Email',
            input(
              type: 'email',
              placeholder: 'you@example.com',
              value: emailState.value,
              className: 'input',
              onChange: (e) => emailState.set(getInputValue(e).toDart),
            ),
          ),
          formGroup(
            'Password',
            input(
              type: 'password',
              placeholder: '••••••••',
              value: passState.value,
              className: 'input',
              onChange: (e) => passState.set(getInputValue(e).toDart),
            ),
          ),
          button(
            text: loadingState.value ? 'Signing in...' : 'Sign In',
            className: 'btn btn-primary btn-full',
            onClick: loadingState.value ? null : handleSubmit,
          ),
          div(
            className: 'auth-footer',
            children: [
              span("Don't have an account? "),
              button(
                text: 'Register',
                className: 'btn-link',
                onClick: () => auth.setView('register'),
              ),
            ],
          ),
        ],
      );
    }).toJS,
  );
}
