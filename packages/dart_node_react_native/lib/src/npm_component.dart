/// Generic npm React/React Native component wrapper.
///
/// Provides a flexible way to use ANY npm package's React components
/// without needing to write manual Dart wrappers for each one.
///
/// ## Basic Usage
///
/// ```dart
/// // Use any npm component by package name and component name
/// final button = npmComponent(
///   'react-native-paper',
///   'Button',
///   props: {'mode': 'contained', 'onPress': handlePress},
///   child: 'Click Me'.toJS,
/// );
/// ```
///
/// ## Nested Components
///
/// For components accessed via a namespace (like Stack.Navigator):
///
/// ```dart
/// final navigator = npmComponent(
///   '@react-navigation/stack',
///   'createStackNavigator',
/// );
/// ```
///
/// ## Default Exports
///
/// For packages that use default exports:
///
/// ```dart
/// final component = npmComponent(
///   'some-package',
///   'default',
/// );
/// ```
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_react/dart_node_react.dart';
import 'package:nadz/nadz.dart';

/// Extension type for npm component elements
extension type NpmComponentElement._(JSObject _) implements ReactElement {
  /// Create from a JSObject
  factory NpmComponentElement.fromJS(JSObject js) = NpmComponentElement._;
}

/// Cache for loaded npm modules to avoid repeated require() calls
final Map<String, JSObject> _moduleCache = {};

/// Load an npm module (with caching)
Result<JSObject, String> loadNpmModule(String packageName) {
  // Check cache first
  if (_moduleCache.containsKey(packageName)) {
    return Success(_moduleCache[packageName]!);
  }

  try {
    final module = requireModule(packageName);
    if (module case final JSObject obj) {
      _moduleCache[packageName] = obj;
      return Success(obj);
    }
    return Error('Module $packageName did not return an object');
  } on Object catch (e) {
    return Error('Failed to load module $packageName: $e');
  }
}

/// Get a component from a loaded module.
///
/// Handles:
/// - Named exports: `module.ComponentName`
/// - Default exports: `module.default` or `module.default.ComponentName`
/// - Nested paths: `module.Stack.Navigator` via dot notation
Result<JSAny, String> getComponentFromModule(
  JSObject module,
  String componentPath,
) {
  // Handle nested paths like "Stack.Navigator"
  final parts = componentPath.split('.');
  JSAny? current = module;

  for (final part in parts) {
    if (current == null) {
      return Error('Component path $componentPath not found (null at $part)');
    }

    final currentObj = current as JSObject;

    // Try direct access first
    final direct = currentObj[part];
    if (direct != null) {
      current = direct;
      continue;
    }

    // For the first part, try via default export
    if (part == parts.first) {
      final defaultExport = currentObj['default'];
      if (defaultExport != null) {
        final defaultObj = defaultExport as JSObject;
        final viaDefault = defaultObj[part];
        if (viaDefault != null) {
          current = viaDefault;
          continue;
        }
        // If asking for 'default' specifically, return the default export
        if (part == 'default') {
          current = defaultExport;
          continue;
        }
      }
    }

    return Error('Component $part not found in module (path: $componentPath)');
  }

  return switch (current) {
    null => Error('Component $componentPath resolved to null'),
    final JSAny c => Success(c),
  };
}

/// Create a React element from any npm package's component.
///
/// [packageName] - The npm package name (e.g., 'react-native-paper')
/// [componentPath] - The component name or path
///   (e.g., 'Button' or 'Stack.Navigator')
/// [props] - Optional props map
/// [children] - Optional list of child elements
/// [child] - Optional single child (text or element)
///
/// Returns [NpmComponentElement] on success, throws [StateError] on failure.
///
/// ## Examples
///
/// Basic usage:
/// ```dart
/// final button = npmComponent(
///   'react-native-paper',
///   'Button',
///   props: {'mode': 'contained'},
///   child: 'Click'.toJS,
/// );
/// ```
///
/// With children:
/// ```dart
/// final container = npmComponent(
///   '@react-navigation/native',
///   'NavigationContainer',
///   children: [navigator],
/// );
/// ```
NpmComponentElement npmComponent(
  String packageName,
  String componentPath, {
  Map<String, dynamic>? props,
  List<ReactElement>? children,
  JSAny? child,
}) {
  final moduleResult = loadNpmModule(packageName);
  final module = switch (moduleResult) {
    Success(:final value) => value,
    Error(:final error) => throw StateError(error),
  };

  final componentResult = getComponentFromModule(module, componentPath);
  final component = switch (componentResult) {
    Success(:final value) => value,
    Error(:final error) => throw StateError(error),
  };

  final jsProps = (props != null) ? createProps(props) : null;

  final element = (children != null && children.isNotEmpty)
      ? createElementWithChildren(component, jsProps, children)
      : (child != null)
      ? createElement(component, jsProps, child)
      : createElement(component, jsProps);

  return NpmComponentElement.fromJS(element);
}

/// Safe version of [npmComponent] that returns a Result instead of throwing.
Result<NpmComponentElement, String> npmComponentSafe(
  String packageName,
  String componentPath, {
  Map<String, dynamic>? props,
  List<ReactElement>? children,
  JSAny? child,
}) {
  final moduleResult = loadNpmModule(packageName);
  if (moduleResult case Error(:final error)) {
    return Error(error);
  }
  final module = (moduleResult as Success<JSObject, String>).value;

  final componentResult = getComponentFromModule(module, componentPath);
  if (componentResult case Error(:final error)) {
    return Error(error);
  }
  final component = (componentResult as Success<JSAny, String>).value;

  try {
    final jsProps = (props != null) ? createProps(props) : null;

    final element = (children != null && children.isNotEmpty)
        ? createElementWithChildren(component, jsProps, children)
        : (child != null)
        ? createElement(component, jsProps, child)
        : createElement(component, jsProps);

    return Success(NpmComponentElement.fromJS(element));
  } on Object catch (e) {
    return Error('Failed to create element: $e');
  }
}

/// Call a factory function from an npm module.
///
/// Useful for packages that export factory functions rather than components,
/// like `createStackNavigator` from @react-navigation/stack.
///
/// ```dart
/// final stackNav = npmFactory<JSFunction>(
///   '@react-navigation/stack',
///   'createStackNavigator',
/// );
/// final Stack = stackNav.call();
/// ```
Result<T, String> npmFactory<T extends JSAny>(
  String packageName,
  String functionPath,
) {
  final moduleResult = loadNpmModule(packageName);
  if (moduleResult case Error(:final error)) {
    return Error(error);
  }
  final module = (moduleResult as Success<JSObject, String>).value;

  final componentResult = getComponentFromModule(module, functionPath);
  return switch (componentResult) {
    Success(:final value) => Success(value as T),
    Error(:final error) => Error(error),
  };
}

/// Clear the module cache.
///
/// Useful for testing or when you need to force reload modules.
void clearNpmModuleCache() {
  _moduleCache.clear();
}

/// Check if a module is cached.
bool isModuleCached(String packageName) =>
    _moduleCache.containsKey(packageName);

// =============================================================================
// TYPED EXTENSION TYPES
// =============================================================================
// Zero-cost wrappers over NpmComponentElement for type safety.
// Use these when you want IDE autocomplete and type checking.
// Start loose with npmComponent(), add types WHERE YOU NEED THEM.

/// Typed element for Paper Button - zero-cost wrapper
extension type PaperButton._(NpmComponentElement _) implements ReactElement {
  /// Create from NpmComponentElement
  factory PaperButton._create(NpmComponentElement e) = PaperButton._;
}

/// Typed element for Paper FAB - zero-cost wrapper
extension type PaperFAB._(NpmComponentElement _) implements ReactElement {
  /// Create from NpmComponentElement
  factory PaperFAB._create(NpmComponentElement e) = PaperFAB._;
}

/// Typed element for Paper Card - zero-cost wrapper
extension type PaperCard._(NpmComponentElement _) implements ReactElement {
  /// Create from NpmComponentElement
  factory PaperCard._create(NpmComponentElement e) = PaperCard._;
}

/// Typed element for Paper TextInput - zero-cost wrapper
extension type PaperTextInput._(NpmComponentElement _) implements ReactElement {
  /// Create from NpmComponentElement
  factory PaperTextInput._create(NpmComponentElement e) = PaperTextInput._;
}

// =============================================================================
// TYPED PROPS (typedef records)
// =============================================================================
// Named fields give full IDE autocomplete. Add only the props you use.

/// Props for Paper Button
typedef PaperButtonProps = ({
  String? mode, // 'text' | 'outlined' | 'contained' | 'elevated'
  bool? disabled,
  bool? loading,
  String? buttonColor,
  String? textColor,
  Map<String, dynamic>? style,
  Map<String, dynamic>? contentStyle,
  Map<String, dynamic>? labelStyle,
});

/// Props for Paper FAB (Floating Action Button)
typedef PaperFABProps = ({
  String? icon,
  String? label,
  bool? small,
  bool? visible,
  bool? loading,
  bool? disabled,
  String? color,
  String? customColor,
  Map<String, dynamic>? style,
});

/// Props for Paper Card
typedef PaperCardProps = ({
  String? mode, // 'elevated' | 'outlined' | 'contained'
  Map<String, dynamic>? style,
  Map<String, dynamic>? contentStyle,
});

/// Props for Paper TextInput
typedef PaperTextInputProps = ({
  String? label,
  String? placeholder,
  String? mode, // 'flat' | 'outlined'
  bool? disabled,
  bool? editable,
  bool? secureTextEntry,
  String? value,
  String? activeOutlineColor,
  String? activeUnderlineColor,
  String? textColor,
  Map<String, dynamic>? style,
});

// =============================================================================
// TYPED FACTORY FUNCTIONS
// =============================================================================
// Build props Map and call npmComponent(). Type-safe with autocomplete!

/// Create a Paper Button with full type safety.
///
/// ```dart
/// final btn = paperButton(
///   props: (mode: 'contained', disabled: false, loading: null,
///           buttonColor: '#6200EE', textColor: null, style: null,
///           contentStyle: null, labelStyle: null),
///   onPress: () => print('pressed'),
///   label: 'Click Me',
/// );
/// ```
PaperButton paperButton({
  PaperButtonProps? props,
  void Function()? onPress,
  String? label,
}) {
  final p = <String, dynamic>{};
  if (props != null) {
    if (props.mode != null) p['mode'] = props.mode;
    if (props.disabled != null) p['disabled'] = props.disabled;
    if (props.loading != null) p['loading'] = props.loading;
    if (props.buttonColor != null) p['buttonColor'] = props.buttonColor;
    if (props.textColor != null) p['textColor'] = props.textColor;
    if (props.style != null) p['style'] = props.style;
    if (props.contentStyle != null) p['contentStyle'] = props.contentStyle;
    if (props.labelStyle != null) p['labelStyle'] = props.labelStyle;
  }
  if (onPress != null) p['onPress'] = onPress;

  return PaperButton._create(
    npmComponent(
      'react-native-paper',
      'Button',
      props: p.isEmpty ? null : p,
      child: label?.toJS,
    ),
  );
}

/// Create a Paper FAB with full type safety.
///
/// ```dart
/// final fab = paperFAB(
///   props: (icon: 'plus', label: null, small: false, visible: true,
///           loading: null, disabled: null, color: null,
///           customColor: '#6200EE', style: null),
///   onPress: handleAdd,
/// );
/// ```
PaperFAB paperFAB({PaperFABProps? props, void Function()? onPress}) {
  final p = <String, dynamic>{};
  if (props != null) {
    if (props.icon != null) p['icon'] = props.icon;
    if (props.label != null) p['label'] = props.label;
    if (props.small != null) p['small'] = props.small;
    if (props.visible != null) p['visible'] = props.visible;
    if (props.loading != null) p['loading'] = props.loading;
    if (props.disabled != null) p['disabled'] = props.disabled;
    if (props.color != null) p['color'] = props.color;
    if (props.customColor != null) p['customColor'] = props.customColor;
    if (props.style != null) p['style'] = props.style;
  }
  if (onPress != null) p['onPress'] = onPress;

  return PaperFAB._create(
    npmComponent('react-native-paper', 'FAB', props: p.isEmpty ? null : p),
  );
}

/// Create a Paper Card with full type safety.
///
/// ```dart
/// final card = paperCard(
///   props: (mode: 'elevated', style: null, contentStyle: null),
///   children: [cardTitle, cardContent, cardActions],
/// );
/// ```
PaperCard paperCard({
  PaperCardProps? props,
  void Function()? onPress,
  List<ReactElement>? children,
}) {
  final p = <String, dynamic>{};
  if (props != null) {
    if (props.mode != null) p['mode'] = props.mode;
    if (props.style != null) p['style'] = props.style;
    if (props.contentStyle != null) p['contentStyle'] = props.contentStyle;
  }
  if (onPress != null) p['onPress'] = onPress;

  return PaperCard._create(
    npmComponent(
      'react-native-paper',
      'Card',
      props: p.isEmpty ? null : p,
      children: children,
    ),
  );
}

/// Create a Paper TextInput with full type safety.
///
/// ```dart
/// final input = paperTextInput(
///   props: (label: 'Email', placeholder: 'Enter email',
///           mode: 'outlined', disabled: null, editable: null,
///           secureTextEntry: null, value: null,
///           activeOutlineColor: '#6200EE',
///           activeUnderlineColor: null, textColor: null, style: null),
///   onChangeText: (text) => setState(text),
/// );
/// ```
PaperTextInput paperTextInput({
  PaperTextInputProps? props,
  void Function(String)? onChangeText,
  String? value,
}) {
  final p = <String, dynamic>{};
  if (props != null) {
    if (props.label != null) p['label'] = props.label;
    if (props.placeholder != null) p['placeholder'] = props.placeholder;
    if (props.mode != null) p['mode'] = props.mode;
    if (props.disabled != null) p['disabled'] = props.disabled;
    if (props.editable != null) p['editable'] = props.editable;
    if (props.secureTextEntry != null) {
      p['secureTextEntry'] = props.secureTextEntry;
    }
    if (props.value != null) p['value'] = props.value;
    if (props.activeOutlineColor != null) {
      p['activeOutlineColor'] = props.activeOutlineColor;
    }
    if (props.activeUnderlineColor != null) {
      p['activeUnderlineColor'] = props.activeUnderlineColor;
    }
    if (props.textColor != null) p['textColor'] = props.textColor;
    if (props.style != null) p['style'] = props.style;
  }
  if (onChangeText != null) p['onChangeText'] = onChangeText;
  if (value != null) p['value'] = value;

  return PaperTextInput._create(
    npmComponent(
      'react-native-paper',
      'TextInput',
      props: p.isEmpty ? null : p,
    ),
  );
}
