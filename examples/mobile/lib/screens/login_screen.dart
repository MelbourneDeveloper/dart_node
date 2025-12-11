import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart' hide view;
import 'package:dart_node_react_native/dart_node_react_native.dart';
import 'package:nadz/nadz.dart';
import 'package:shared/http/http_client.dart';
import 'package:shared/theme/theme.dart';

import '../types.dart';

/// Login screen component
ReactElement loginScreen({required AuthEffects authEffects, Fetch? fetchFn}) =>
    functionalComponent('LoginScreen', (JSObject props) {
      final emailState = useState('');
      final passwordState = useState('');
      final loadingState = useState(false);
      final errorState = useState<String?>(null);

      final email = emailState.value;
      final password = passwordState.value;
      final loading = loadingState.value;
      final error = errorState.value;

      void handleLogin() {
        loadingState.set(true);
        errorState.set(null);
        _performLogin(
          email: email,
          password: password,
          authEffects: authEffects,
          formEffects: (setLoading: loadingState.set, setError: errorState.set),
          fetchFn: fetchFn,
        );
      }

      return view(
        style: AppStyles.centeredContent,
        child: view(
          style: AppStyles.authCard,
          children: [
            text('Sign In', style: AppStyles.authTitle),
            (error?.isNotEmpty ?? false)
                ? view(
                    style: AppStyles.errorMsg,
                    child: text(error ?? '', style: AppStyles.errorText),
                  )
                : view(),
            view(
              style: AppStyles.formGroup,
              children: [
                text('Email', style: AppStyles.label),
                textInput(
                  placeholder: 'Enter your email',
                  value: email,
                  onChangeText: emailState.set,
                  style: AppStyles.input,
                  props: {'placeholderTextColor': AppColors.textMuted},
                ),
              ],
            ),
            view(
              style: AppStyles.formGroup,
              children: [
                text('Password', style: AppStyles.label),
                textInput(
                  placeholder: 'Enter your password',
                  value: password,
                  onChangeText: passwordState.set,
                  secureTextEntry: true,
                  style: AppStyles.input,
                  props: {'placeholderTextColor': AppColors.textMuted},
                ),
              ],
            ),
            touchableOpacity(
              onPress: loading ? null : handleLogin,
              style: AppStyles.btnPrimary,
              child: text(
                loading ? 'Signing in...' : 'Sign In',
                style: AppStyles.btnPrimaryText,
              ),
            ),
            view(
              style: AppStyles.linkContainer,
              children: [
                text("Don't have an account? ", style: AppStyles.linkText),
                touchableOpacity(
                  onPress: () => authEffects.setView('register'),
                  child: text('Register', style: AppStyles.linkHighlight),
                ),
              ],
            ),
          ],
        ),
      );
    });

Future<void> _performLogin({
  required String email,
  required String password,
  required AuthEffects authEffects,
  required FormEffects formEffects,
  Fetch? fetchFn,
}) async {
  final doFetch = fetchFn ?? fetchJson;
  try {
    final result = await doFetch(
      '$apiUrl/auth/login',
      method: 'POST',
      body: {'email': email, 'password': password},
    );
    result.match(
      onSuccess: (response) {
        final data = response['data'];
        switch (data) {
          case final JSObject d:
            final token = d['token'];
            final user = switch (d['user']) {
              final JSObject u => u,
              _ => null,
            };
            switch (token) {
              case final JSString t:
                authEffects.setToken(t);
                authEffects.setUser(user);
                authEffects.setView('tasks');
              case _:
                formEffects.setError('No token in response');
            }
          case _:
            formEffects.setError('Login failed');
        }
      },
      onError: (message) => formEffects.setError(message),
    );
  } on Object catch (e) {
    formEffects.setError(e.toString());
  } finally {
    formEffects.setLoading(false);
  }
}
