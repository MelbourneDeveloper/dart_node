import 'dart:js_interop';

import 'package:dart_node_react/dart_node_react.dart';
import 'package:dart_node_react_native/src/core.dart';

// =============================================================================
// Typed React Native Elements
// =============================================================================

/// View component type
extension type RNViewElement._(JSObject _) implements ReactElement {
  factory RNViewElement.fromJS(JSObject js) = RNViewElement._;
}

/// Text component type
extension type RNTextElement._(JSObject _) implements ReactElement {
  factory RNTextElement.fromJS(JSObject js) = RNTextElement._;
}

/// TextInput component type
extension type RNTextInputElement._(JSObject _) implements ReactElement {
  factory RNTextInputElement.fromJS(JSObject js) = RNTextInputElement._;
}

/// TouchableOpacity component type
extension type RNTouchableOpacityElement._(JSObject _) implements ReactElement {
  factory RNTouchableOpacityElement.fromJS(JSObject js) =
      RNTouchableOpacityElement._;
}

/// Button component type
extension type RNButtonElement._(JSObject _) implements ReactElement {
  factory RNButtonElement.fromJS(JSObject js) = RNButtonElement._;
}

/// ScrollView component type
extension type RNScrollViewElement._(JSObject _) implements ReactElement {
  factory RNScrollViewElement.fromJS(JSObject js) = RNScrollViewElement._;
}

/// SafeAreaView component type
extension type RNSafeAreaViewElement._(JSObject _) implements ReactElement {
  factory RNSafeAreaViewElement.fromJS(JSObject js) = RNSafeAreaViewElement._;
}

/// ActivityIndicator component type
extension type RNActivityIndicatorElement._(JSObject _)
    implements ReactElement {
  factory RNActivityIndicatorElement.fromJS(JSObject js) =
      RNActivityIndicatorElement._;
}

/// FlatList component type
extension type RNFlatListElement._(JSObject _) implements ReactElement {
  factory RNFlatListElement.fromJS(JSObject js) = RNFlatListElement._;
}

/// Image component type
extension type RNImageElement._(JSObject _) implements ReactElement {
  factory RNImageElement.fromJS(JSObject js) = RNImageElement._;
}

/// Switch component type
extension type RNSwitchElement._(JSObject _) implements ReactElement {
  factory RNSwitchElement.fromJS(JSObject js) = RNSwitchElement._;
}

// =============================================================================
// Component builders
// =============================================================================

/// View component - the fundamental building block
RNViewElement view({
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
  List<ReactElement>? children,
  JSAny? child,
  void Function()? onPress,
}) {
  final p = <String, dynamic>{};
  if (style != null) p['style'] = style;
  if (onPress != null) p['onPress'] = onPress;
  if (props != null) p.addAll(props);
  return RNViewElement.fromJS(
    rnElement('View', props: p, children: children, child: child),
  );
}

/// Text component
RNTextElement text(
  String content, {
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
  void Function()? onPress,
}) {
  final p = <String, dynamic>{};
  if (style != null) p['style'] = style;
  if (onPress != null) p['onPress'] = onPress;
  if (props != null) p.addAll(props);
  return RNTextElement.fromJS(rnElement('Text', props: p, child: content.toJS));
}

/// TextInput component
RNTextInputElement textInput({
  String? value,
  String? placeholder,
  bool? secureTextEntry,
  void Function(String)? onChangeText,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) {
  final p = <String, dynamic>{};
  if (value != null) p['value'] = value;
  if (placeholder != null) p['placeholder'] = placeholder;
  if (secureTextEntry != null) p['secureTextEntry'] = secureTextEntry;
  if (onChangeText != null) {
    p['onChangeText'] = ((JSString t) => onChangeText(t.toDart)).toJS;
  }
  if (style != null) p['style'] = style;
  if (props != null) p.addAll(props);
  return RNTextInputElement.fromJS(rnElement('TextInput', props: p));
}

/// TouchableOpacity component
RNTouchableOpacityElement touchableOpacity({
  void Function()? onPress,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
  List<ReactElement>? children,
  JSAny? child,
}) {
  final p = <String, dynamic>{};
  if (onPress != null) p['onPress'] = onPress;
  if (style != null) p['style'] = style;
  if (props != null) p.addAll(props);
  return RNTouchableOpacityElement.fromJS(
    rnElement('TouchableOpacity', props: p, children: children, child: child),
  );
}

/// Button component
RNButtonElement rnButton({
  required String title,
  void Function()? onPress,
  String? color,
  bool? disabled,
  Map<String, dynamic>? props,
}) {
  final p = <String, dynamic>{'title': title};
  if (onPress != null) p['onPress'] = onPress;
  if (color != null) p['color'] = color;
  if (disabled != null) p['disabled'] = disabled;
  if (props != null) p.addAll(props);
  return RNButtonElement.fromJS(rnElement('Button', props: p));
}

/// ScrollView component
RNScrollViewElement scrollView({
  Map<String, dynamic>? style,
  Map<String, dynamic>? contentContainerStyle,
  Map<String, dynamic>? props,
  List<ReactElement>? children,
  JSAny? child,
}) {
  final p = <String, dynamic>{};
  if (style != null) p['style'] = style;
  if (contentContainerStyle != null) {
    p['contentContainerStyle'] = contentContainerStyle;
  }
  if (props != null) p.addAll(props);
  return RNScrollViewElement.fromJS(
    rnElement('ScrollView', props: p, children: children, child: child),
  );
}

/// SafeAreaView component
RNSafeAreaViewElement safeAreaView({
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
  List<ReactElement>? children,
  JSAny? child,
}) {
  final p = <String, dynamic>{};
  if (style != null) p['style'] = style;
  if (props != null) p.addAll(props);
  return RNSafeAreaViewElement.fromJS(
    rnElement('SafeAreaView', props: p, children: children, child: child),
  );
}

/// ActivityIndicator component
RNActivityIndicatorElement activityIndicator({
  bool? animating,
  String? color,
  String? size,
  Map<String, dynamic>? props,
}) {
  final p = <String, dynamic>{};
  if (animating != null) p['animating'] = animating;
  if (color != null) p['color'] = color;
  if (size != null) p['size'] = size;
  if (props != null) p.addAll(props);
  return RNActivityIndicatorElement.fromJS(
    rnElement('ActivityIndicator', props: p),
  );
}

/// FlatList component
RNFlatListElement flatList({
  required JSArray data,
  required JSFunction renderItem,
  JSFunction? keyExtractor,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) {
  final p = <String, dynamic>{
    'data': data,
    'renderItem': renderItem,
  };
  if (keyExtractor != null) p['keyExtractor'] = keyExtractor;
  if (style != null) p['style'] = style;
  if (props != null) p.addAll(props);
  return RNFlatListElement.fromJS(rnElement('FlatList', props: p));
}

/// Image component
RNImageElement rnImage({
  required Map<String, dynamic> source,
  Map<String, dynamic>? style,
  String? resizeMode,
  Map<String, dynamic>? props,
}) {
  final p = <String, dynamic>{'source': source};
  if (style != null) p['style'] = style;
  if (resizeMode != null) p['resizeMode'] = resizeMode;
  if (props != null) p.addAll(props);
  return RNImageElement.fromJS(rnElement('Image', props: p));
}

/// Switch component
RNSwitchElement rnSwitch({
  bool? value,
  void Function(bool)? onValueChange,
  String? trackColor,
  String? thumbColor,
  Map<String, dynamic>? props,
}) {
  final p = <String, dynamic>{};
  if (value != null) p['value'] = value;
  if (onValueChange != null) {
    p['onValueChange'] = ((JSBoolean v) => onValueChange(v.toDart)).toJS;
  }
  if (trackColor != null) p['trackColor'] = trackColor;
  if (thumbColor != null) p['thumbColor'] = thumbColor;
  if (props != null) p.addAll(props);
  return RNSwitchElement.fromJS(rnElement('Switch', props: p));
}
