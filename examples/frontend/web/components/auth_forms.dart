import 'dart:async';
import 'dart:js_interop';

import 'package:dart_node_react/dart_node_react.dart';
import 'package:nadz/nadz.dart';
import 'package:shared/http/http_client.dart';
import 'package:shared/theme/theme.dart';

import '../types.dart';
import 'form_helpers.dart';

/// Build login form component
ReactElement buildLoginForm(AuthEffects auth) => createElement(
  ((JSAny props) {
    final (emailState, setEmail) = useState(''.toJS);
    final (passState, setPass) = useState(''.toJS);
    final (errorState, setError) = useState(null);
    final (loadingState, setLoading) = useState(false.toJS);

    final email = (emailState as JSString?)?.toDart ?? '';
    final password = (passState as JSString?)?.toDart ?? '';
    final error = (errorState as JSString?)?.toDart;
    final loading = (loadingState as JSBoolean?)?.toDart ?? false;

    void handleSubmit() {
      setLoading.callAsFunction(null, true.toJS);
      setError.callAsFunction();

      unawaited(
        fetchJson(
              '$apiUrl/auth/login',
              method: 'POST',
              body: {'email': email, 'password': password},
            )
            .then((result) {
              result.match(
                onSuccess: (response) {
                  final data = getProp(response, 'data') as JSObject?;
                  switch (data) {
                    case null:
                      setError.callAsFunction(null, 'Login failed'.toJS);
                    case final d:
                      switch (getProp(d, 'token')) {
                        case final JSString token:
                          auth.setToken(token);
                        default:
                          setError.callAsFunction(null, 'No token'.toJS);
                      }
                      auth.setUser(getProp(d, 'user') as JSObject?);
                  }
                },
                onError: (message) =>
                    setError.callAsFunction(null, message.toJS),
              );
            })
            .catchError((Object e) {
              setError.callAsFunction(null, e.toString().toJS);
            })
            .whenComplete(() => setLoading.callAsFunction(null, false.toJS)),
      );
    }

    return div(
      className: 'auth-card',
      style: AppStyles.authCard,
      children: [
        h2('Sign In', className: 'auth-title', style: AppStyles.authTitle),
        if (error != null)
          div(
            className: 'error-msg',
            style: AppStyles.errorMsg,
            child: span(error),
          )
        else
          span(''),
        formGroup(
          'Email',
          input(
            type: 'email',
            placeholder: 'you@example.com',
            value: email,
            className: 'input',
            style: AppStyles.input,
            onChange: (e) => setEmail.callAsFunction(null, getInputValue(e)),
          ),
        ),
        formGroup(
          'Password',
          input(
            type: 'password',
            placeholder: '••••••••',
            value: password,
            className: 'input',
            style: AppStyles.input,
            onChange: (e) => setPass.callAsFunction(null, getInputValue(e)),
          ),
        ),
        button(
          text: loading ? 'Signing in...' : 'Sign In',
          className: 'btn btn-primary',
          style: AppStyles.btnPrimary,
          onClick: loading ? null : handleSubmit,
        ),
        div(
          className: 'auth-footer',
          style: AppStyles.authFooter,
          children: [
            span("Don't have an account? "),
            button(
              text: 'Register',
              className: 'btn-link',
              style: AppStyles.btnLink,
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
    final (nameState, setName) = useState(''.toJS);
    final (emailState, setEmail) = useState(''.toJS);
    final (passState, setPass) = useState(''.toJS);
    final (errorState, setError) = useState(null);
    final (loadingState, setLoading) = useState(false.toJS);

    final name = (nameState as JSString?)?.toDart ?? '';
    final email = (emailState as JSString?)?.toDart ?? '';
    final password = (passState as JSString?)?.toDart ?? '';
    final error = (errorState as JSString?)?.toDart;
    final loading = (loadingState as JSBoolean?)?.toDart ?? false;

    void handleSubmit() {
      setLoading.callAsFunction(null, true.toJS);
      setError.callAsFunction();

      unawaited(
        fetchJson(
              '$apiUrl/auth/register',
              method: 'POST',
              body: {'email': email, 'password': password, 'name': name},
            )
            .then((result) {
              result.match(
                onSuccess: (response) {
                  final data = getProp(response, 'data') as JSObject?;
                  switch (data) {
                    case null:
                      setError.callAsFunction(null, 'Registration failed'.toJS);
                    case final d:
                      switch (getProp(d, 'token')) {
                        case final JSString token:
                          auth.setToken(token);
                        default:
                          setError.callAsFunction(null, 'No token'.toJS);
                      }
                      auth.setUser(getProp(d, 'user') as JSObject?);
                  }
                },
                onError: (message) =>
                    setError.callAsFunction(null, message.toJS),
              );
            })
            .catchError((Object e) {
              setError.callAsFunction(null, e.toString().toJS);
            })
            .whenComplete(() => setLoading.callAsFunction(null, false.toJS)),
      );
    }

    return div(
      className: 'auth-card',
      style: AppStyles.authCard,
      children: [
        h2(
          'Create Account',
          className: 'auth-title',
          style: AppStyles.authTitle,
        ),
        if (error != null)
          div(
            className: 'error-msg',
            style: AppStyles.errorMsg,
            child: span(error),
          )
        else
          span(''),
        formGroup(
          'Name',
          input(
            type: 'text',
            placeholder: 'Your name',
            value: name,
            className: 'input',
            style: AppStyles.input,
            onChange: (e) => setName.callAsFunction(null, getInputValue(e)),
          ),
        ),
        formGroup(
          'Email',
          input(
            type: 'email',
            placeholder: 'you@example.com',
            value: email,
            className: 'input',
            style: AppStyles.input,
            onChange: (e) => setEmail.callAsFunction(null, getInputValue(e)),
          ),
        ),
        formGroup(
          'Password',
          input(
            type: 'password',
            placeholder: '••••••••',
            value: password,
            className: 'input',
            style: AppStyles.input,
            onChange: (e) => setPass.callAsFunction(null, getInputValue(e)),
          ),
        ),
        button(
          text: loading ? 'Creating...' : 'Create Account',
          className: 'btn btn-primary',
          style: AppStyles.btnPrimary,
          onClick: loading ? null : handleSubmit,
        ),
        div(
          className: 'auth-footer',
          style: AppStyles.authFooter,
          children: [
            span('Already have an account? '),
            button(
              text: 'Sign In',
              className: 'btn-link',
              style: AppStyles.btnLink,
              onClick: () => auth.setView('login'),
            ),
          ],
        ),
      ],
    );
  }).toJS,
);
