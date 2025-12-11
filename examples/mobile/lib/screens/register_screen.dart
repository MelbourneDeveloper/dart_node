import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart' hide view;
import 'package:dart_node_react_native/dart_node_react_native.dart';
import 'package:nadz/nadz.dart';
import 'package:shared/http/http_client.dart';
import 'package:shared/theme/theme.dart';

import '../types.dart';

/// Register screen component
ReactElement registerScreen({
  required AuthEffects authEffects,
  Fetch? fetchFn,
}) => functionalComponent('RegisterScreen', (JSObject props) {
  final nameState = useState('');
  final emailState = useState('');
  final passwordState = useState('');
  final loadingState = useState(false);
  final errorState = useState<String?>(null);

  final name = nameState.value;
  final email = emailState.value;
  final password = passwordState.value;
  final loading = loadingState.value;
  final error = errorState.value;

  void handleRegister() {
    loadingState.set(true);
    errorState.set(null);
    _performRegister(
      name: name,
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
        text('Create Account', style: AppStyles.authTitle),
        (error?.isNotEmpty ?? false)
            ? view(
                style: AppStyles.errorMsg,
                child: text(error ?? '', style: AppStyles.errorText),
              )
            : view(),
        view(
          style: AppStyles.formGroup,
          children: [
            text('Name', style: AppStyles.label),
            textInput(
              placeholder: 'Enter your name',
              value: name,
              onChangeText: nameState.set,
              style: AppStyles.input,
              props: {'placeholderTextColor': AppColors.textMuted},
            ),
          ],
        ),
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
          onPress: loading ? null : handleRegister,
          style: AppStyles.btnPrimary,
          child: text(
            loading ? 'Creating account...' : 'Register',
            style: AppStyles.btnPrimaryText,
          ),
        ),
        view(
          style: AppStyles.linkContainer,
          children: [
            text('Already have an account? ', style: AppStyles.linkText),
            touchableOpacity(
              onPress: () => authEffects.setView('login'),
              child: text('Sign In', style: AppStyles.linkHighlight),
            ),
          ],
        ),
      ],
    ),
  );
});

Future<void> _performRegister({
  required String name,
  required String email,
  required String password,
  required AuthEffects authEffects,
  required FormEffects formEffects,
  Fetch? fetchFn,
}) async {
  final doFetch = fetchFn ?? fetchJson;
  try {
    final result = await doFetch(
      '$apiUrl/auth/register',
      method: 'POST',
      body: {'name': name, 'email': email, 'password': password},
    );
    result.match(
      onSuccess: (response) {
        final data = response['data'];
        switch (data) {
          case final JSObject d:
            final token = switch (d['token']) {
              final JSString t => t,
              _ => null,
            };
            final user = switch (d['user']) {
              final JSObject u => u,
              _ => null,
            };
            authEffects.setToken(token);
            authEffects.setUser(user);
            authEffects.setView('tasks');
          case _:
            authEffects.setToken(null);
            authEffects.setUser(null);
            authEffects.setView('tasks');
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
