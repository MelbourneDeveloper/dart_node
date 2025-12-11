import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart';
import 'package:frontend/src/form_helpers.dart';
import 'package:frontend/src/types.dart';
import 'package:nadz/nadz.dart';
import 'package:shared/http/http_client.dart';

/// Build register form component
ReactElement buildRegisterForm(
  AuthEffects auth, {
  String baseUrl = apiUrl,
  Fetch? fetchFn,
}) {
  final doFetch = fetchFn ?? fetch;
  return createElement(
    ((JSAny props) {
      final nameState = useState('');
      final emailState = useState('');
      final passState = useState('');
      final errorState = useState<String?>(null);
      final loadingState = useState(false);

      Future<void> handleSubmit() async {
        loadingState.set(true);
        errorState.set(null);

        try {
          final result = await doFetch(
            '$baseUrl/auth/register',
            method: 'POST',
            body: {
              'email': emailState.value,
              'password': passState.value,
              'name': nameState.value,
            },
          );
          result.match(
            onSuccess: (response) {
              final data = response['data'];
              switch (data) {
                case null:
                  errorState.set('Registration failed');
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
          h2('Create Account', className: 'auth-title'),
          if (errorState.value != null)
            div(className: 'error-msg', child: span(errorState.value!))
          else
            span(''),
          formGroup(
            'Name',
            input(
              type: 'text',
              placeholder: 'Your name',
              value: nameState.value,
              className: 'input',
              onChange: (e) => nameState.set(getInputValue(e).toDart),
            ),
          ),
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
            text: loadingState.value ? 'Creating...' : 'Create Account',
            className: 'btn btn-primary btn-full',
            onClick: loadingState.value ? null : handleSubmit,
          ),
          div(
            className: 'auth-footer',
            children: [
              span('Already have an account? '),
              button(
                text: 'Sign In',
                className: 'btn-link',
                onClick: () => auth.setView('login'),
              ),
            ],
          ),
        ],
      );
    }).toJS,
  );
}
