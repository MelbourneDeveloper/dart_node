import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart';
import 'package:dart_node_react_native/dart_node_react_native.dart';
import 'package:nadz/nadz.dart';
import 'package:shared/http/http_client.dart';
import 'package:shared/theme/theme.dart';

import '../types.dart';

/// Login screen component
ReactElement loginScreen({required AuthEffects authEffects}) =>
    functionalComponent('LoginScreen', (JSObject props) {
      final emailState = useState(''.toJS);
      final passwordState = useState(''.toJS);
      final loadingState = useState(false.toJS);
      final errorState = useState(null);

      final email = (emailState.$1 as JSString?)?.toDart ?? '';
      final password = (passwordState.$1 as JSString?)?.toDart ?? '';
      final loading = (loadingState.$1 as JSBoolean?)?.toDart ?? false;
      final error = (errorState.$1 as JSString?)?.toDart;

      final setEmail = wrapSetState<String>(emailState.$2);
      final setPassword = wrapSetState<String>(passwordState.$2);
      final setLoading = wrapSetState<bool>(loadingState.$2);
      final setError = wrapSetState<String?>(errorState.$2);

      void handleLogin() {
        setLoading(true);
        setError(null);
        _performLogin(
          email: email,
          password: password,
          authEffects: authEffects,
          formEffects: (setLoading: setLoading, setError: setError),
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
                  onChangeText: setEmail,
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
                  onChangeText: setPassword,
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

void _performLogin({
  required String email,
  required String password,
  required AuthEffects authEffects,
  required FormEffects formEffects,
}) {
  fetchJson(
    '$apiUrl/auth/login',
    method: 'POST',
    body: {'email': email, 'password': password},
  ).then((result) {
    result.match(
      onSuccess: (response) {
        final data = response['data'] as JSObject?;
        final token = data?['token'] as JSString?;
        final user = data?['user'] as JSObject?;
        authEffects.setToken(token);
        authEffects.setUser(user);
        authEffects.setView('tasks');
      },
      onError: (message) => formEffects.setError(message),
    );
  }).catchError((Object e) {
    formEffects.setError(e.toString());
  }).whenComplete(() {
    formEffects.setLoading(false);
  });
}
