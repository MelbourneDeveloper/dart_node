import 'dart:async';
import 'dart:js_interop';

import 'package:dart_node_react/dart_node_react.dart';
import 'package:nadz/nadz.dart';
import 'package:shared/http/http_client.dart';

import '../types.dart';
import 'form_helpers.dart';

/// Build login form component
ReactElement buildLoginForm(AuthEffects auth) => createElement(
  ((JSAny props) {
    final emailState = useState('');
    final passState = useState('');
    final errorState = useState<String?>(null);
    final loadingState = useState(false);

    void handleSubmit() {
      loadingState.set(true);
      errorState.set(null);

      unawaited(
        fetchJson(
              '$apiUrl/auth/login',
              method: 'POST',
              body: {'email': emailState.value, 'password': passState.value},
            )
            .then((result) {
              result.match(
                onSuccess: (response) {
                  final data = getProp(response, 'data') as JSObject?;
                  switch (data) {
                    case null:
                      errorState.set('Login failed');
                    case final d:
                      switch (getProp(d, 'token')) {
                        case final JSString token:
                          auth.setToken(token);
                        default:
                          errorState.set('No token');
                      }
                      auth.setUser(getProp(d, 'user') as JSObject?);
                  }
                },
                onError: errorState.set,
              );
            })
            .catchError((Object e) {
              errorState.set(e.toString());
            })
            .whenComplete(() => loadingState.set(false)),
      );
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

/// Build register form component
ReactElement buildRegisterForm(AuthEffects auth) => createElement(
  ((JSAny props) {
    final nameState = useState('');
    final emailState = useState('');
    final passState = useState('');
    final errorState = useState<String?>(null);
    final loadingState = useState(false);

    void handleSubmit() {
      loadingState.set(true);
      errorState.set(null);

      unawaited(
        fetchJson(
              '$apiUrl/auth/register',
              method: 'POST',
              body: {
                'email': emailState.value,
                'password': passState.value,
                'name': nameState.value,
              },
            )
            .then((result) {
              result.match(
                onSuccess: (response) {
                  final data = getProp(response, 'data') as JSObject?;
                  switch (data) {
                    case null:
                      errorState.set('Registration failed');
                    case final d:
                      switch (getProp(d, 'token')) {
                        case final JSString token:
                          auth.setToken(token);
                        default:
                          errorState.set('No token');
                      }
                      auth.setUser(getProp(d, 'user') as JSObject?);
                  }
                },
                onError: errorState.set,
              );
            })
            .catchError((Object e) {
              errorState.set(e.toString());
            })
            .whenComplete(() => loadingState.set(false)),
      );
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
