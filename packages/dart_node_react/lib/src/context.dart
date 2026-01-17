import 'dart:js_interop';

// =============================================================================
// React Context JS Bindings
// =============================================================================

@JS('React.createContext')
external JSObject _reactCreateContext([JSAny? defaultValue]);

@JS('React.useContext')
external JSAny? _reactUseContext(JSObject context);

/// A JavaScript context object returned by React.createContext().
extension type JsContext._(JSObject _) implements JSObject {
  /// Creates a JsContext from a raw JSObject.
  factory JsContext.fromJs(JSObject jsObject) = JsContext._;

  /// The Provider component for this context.
  @JS('Provider')
  external JSAny get provider;

  /// The Consumer component for this context (deprecated, use useContext).
  @JS('Consumer')
  external JSAny get consumer;
}

/// A Context object created by [createContext].
///
/// Every Context object comes with a Provider React component that allows
/// consuming components to subscribe to context changes.
///
/// - [createContext documentation](https://react.dev/reference/react/createContext)
/// - [使用 createContext 创建组件能够提供与读取的上下文（context）](https://zh-hans.react.dev/reference/react/createContext)
final class Context<T> {
  Context._(this._jsContext, this._defaultValue);

  final JsContext _jsContext;
  final T _defaultValue;

  /// The JavaScript context object.
  JsContext get jsContext => _jsContext;

  /// The default value provided to createContext.
  T get defaultValue => _defaultValue;

  /// The Provider component type for this context.
  ///
  /// Use this with createElement to wrap components that need access to
  /// this context.
  ///
  /// Example:
  /// ```dart
  /// final ThemeContext = createContext('light');
  ///
  /// // Create a provider
  /// createElement(
  ///   ThemeContext.providerType,
  ///   createProps({'value': 'dark'}),
  ///   childElement,
  /// );
  /// ```
  JSAny get providerType => _jsContext.provider;

  /// The Consumer component type for this context.
  ///
  /// Note: The Consumer component is considered legacy. Prefer [useContext]
  /// hook instead.
  JSAny get consumerType => _jsContext.consumer;
}

/// Creates a Context object with the specified [defaultValue].
///
/// When React renders a component that subscribes to this Context object
/// it will read the current context value from the closest matching Provider
/// above it in the tree.
///
/// The [defaultValue] argument is only used when a component does not have a
/// matching Provider above it in the tree.
///
/// Example:
/// ```dart
/// // Create a context with a default value
/// final ThemeContext = createContext('light');
///
/// // In a parent component, provide a value
/// final provider = createElement(
///   ThemeContext.providerType,
///   createProps({'value': 'dark'}),
///   MyComponent(),
/// );
///
/// // In a child function component, consume the value
/// final MyComponent = registerFunctionComponent((props) {
///   final theme = useContext(ThemeContext);
///   return div(children: [
///     pEl('Current theme: $theme'),
///   ]);
/// });
/// ```
///
/// - [createContext documentation](https://react.dev/reference/react/createContext)
/// - [使用 createContext 创建组件能够提供与读取的上下文（context）](https://zh-hans.react.dev/reference/react/createContext)
Context<T> createContext<T>(T defaultValue) {
  final jsDefault = switch (defaultValue) {
    null => null,
    final Object obj => obj.jsify(),
  };
  final jsContext = JsContext.fromJs(_reactCreateContext(jsDefault));
  return Context._(jsContext, defaultValue);
}

/// Accepts a [Context] object and returns the current context value for that
/// context.
///
/// The current context value is determined by the value prop of the nearest
/// `<Context.Provider>` above the calling component in the tree.
///
/// When the nearest `<Context.Provider>` above the component updates, this
/// Hook will trigger a rerender with the latest context value passed to that
/// provider.
///
/// Note: there are two rules for using Hooks:
/// - Only call Hooks at the top level.
/// - Only call Hooks from inside a function component.
///
/// Example:
/// ```dart
/// final ThemeContext = createContext('light');
///
/// final ThemedButton = registerFunctionComponent((props) {
///   final theme = useContext(ThemeContext);
///   return button(
///     text: 'Click me',
///     style: {'background': theme == 'dark' ? '#333' : '#fff'},
///   );
/// });
/// ```
///
/// - [useContext documentation](https://react.dev/reference/react/useContext)
/// - [useContext 是一个 React Hook，可以让你读取和订阅组件中的 context](https://zh-hans.react.dev/reference/react/useContext)
T useContext<T>(Context<T> context) {
  final jsValue = _reactUseContext(context.jsContext);
  return switch (jsValue) {
    null => context.defaultValue,
    final v => switch (v.dartify()) {
      final T val => val,
      _ => context.defaultValue,
    },
  };
}
