import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/src/react.dart';
import 'package:dart_node_react/src/synthetic_event.dart';

// =============================================================================
// Typed HTML Elements - Each element gets its own type for compile-time safety
// =============================================================================

/// Div element type
extension type DivElement._(JSObject _) implements ReactElement {
  /// Create from raw JSObject
  factory DivElement.fromJS(JSObject js) = DivElement._;
}

/// H1 heading element type
extension type H1Element._(JSObject _) implements ReactElement {
  /// Create from raw JSObject
  factory H1Element.fromJS(JSObject js) = H1Element._;
}

/// H2 heading element type
extension type H2Element._(JSObject _) implements ReactElement {
  /// Create from raw JSObject
  factory H2Element.fromJS(JSObject js) = H2Element._;
}

/// Paragraph element type
extension type PElement._(JSObject _) implements ReactElement {
  /// Create from raw JSObject
  factory PElement.fromJS(JSObject js) = PElement._;
}

/// Span element type
extension type SpanElement._(JSObject _) implements ReactElement {
  /// Create from raw JSObject
  factory SpanElement.fromJS(JSObject js) = SpanElement._;
}

/// Button element type
extension type ButtonElement._(JSObject _) implements ReactElement {
  /// Create from raw JSObject
  factory ButtonElement.fromJS(JSObject js) = ButtonElement._;
}

/// Input element type
extension type InputElement._(JSObject _) implements ReactElement {
  /// Create from raw JSObject
  factory InputElement.fromJS(JSObject js) = InputElement._;
}

/// Image element type
extension type ImgElement._(JSObject _) implements ReactElement {
  /// Create from raw JSObject
  factory ImgElement.fromJS(JSObject js) = ImgElement._;
}

/// Anchor element type
extension type AElement._(JSObject _) implements ReactElement {
  /// Create from raw JSObject
  factory AElement.fromJS(JSObject js) = AElement._;
}

/// Unordered list element type
extension type UlElement._(JSObject _) implements ReactElement {
  /// Create from raw JSObject
  factory UlElement.fromJS(JSObject js) = UlElement._;
}

/// List item element type
extension type LiElement._(JSObject _) implements ReactElement {
  /// Create from raw JSObject
  factory LiElement.fromJS(JSObject js) = LiElement._;
}

/// Header element type
extension type HeaderElement._(JSObject _) implements ReactElement {
  /// Create from raw JSObject
  factory HeaderElement.fromJS(JSObject js) = HeaderElement._;
}

/// Main element type
extension type MainElement._(JSObject _) implements ReactElement {
  /// Create from raw JSObject
  factory MainElement.fromJS(JSObject js) = MainElement._;
}

/// Footer element type
extension type FooterElement._(JSObject _) implements ReactElement {
  /// Create from raw JSObject
  factory FooterElement.fromJS(JSObject js) = FooterElement._;
}

// =============================================================================
// Helper functions
// =============================================================================

JSObject? _propsOrNull(Map<String, dynamic> p) =>
    p.isEmpty ? null : createProps(p);

/// Convert style map to JSObject for React inline styles
/// Numeric values get 'px' suffix for size-related properties
JSObject convertStyle(Map<String, dynamic> style) {
  final obj = JSObject();
  for (final entry in style.entries) {
    final value = entry.value;
    final jsValue = (value is num && _needsPxSuffix(entry.key))
        ? '${value}px'.toJS
        : (value is String)
        ? value.toJS
        : (value is num)
        ? value.toJS
        : (value as Object).jsify();
    obj.setProperty(entry.key.toJS, jsValue);
  }
  return obj;
}

bool _needsPxSuffix(String key) => !const {
  'flex',
  'fontWeight',
  'opacity',
  'zIndex',
  'lineHeight',
  'order',
}.contains(key);

Map<String, dynamic> _buildProps({
  Map<String, dynamic>? props,
  Map<String, dynamic>? style,
  String? className,
}) {
  final p = <String, dynamic>{};
  if (className != null) p['className'] = className;
  if (style != null) p['style'] = convertStyle(style);
  if (props != null) p.addAll(props);
  return p;
}

/// Create a div element
DivElement div({
  Map<String, dynamic>? props,
  Map<String, dynamic>? style,
  List<ReactElement>? children,
  String? className,
  ReactElement? child,
}) {
  final p = _buildProps(props: props, style: style, className: className);
  final jsObj = (children != null && children.isNotEmpty)
      ? createElementWithChildren('div'.toJS, _propsOrNull(p), children)
      : (child != null)
      ? createElement('div'.toJS, _propsOrNull(p), child)
      : createElement('div'.toJS, _propsOrNull(p));
  return DivElement.fromJS(jsObj);
}

/// Create an h1 element
H1Element h1(
  String text, {
  Map<String, dynamic>? props,
  Map<String, dynamic>? style,
  String? className,
}) {
  final p = _buildProps(props: props, style: style, className: className);
  return H1Element.fromJS(createElement('h1'.toJS, _propsOrNull(p), text.toJS));
}

/// Create an h2 element
H2Element h2(
  String text, {
  Map<String, dynamic>? props,
  Map<String, dynamic>? style,
  String? className,
}) {
  final p = _buildProps(props: props, style: style, className: className);
  return H2Element.fromJS(createElement('h2'.toJS, _propsOrNull(p), text.toJS));
}

/// Create a p element
PElement pEl(
  String text, {
  Map<String, dynamic>? props,
  Map<String, dynamic>? style,
  String? className,
}) {
  final p = _buildProps(props: props, style: style, className: className);
  return PElement.fromJS(createElement('p'.toJS, _propsOrNull(p), text.toJS));
}

/// Create a span element
SpanElement span(
  String text, {
  Map<String, dynamic>? props,
  Map<String, dynamic>? style,
  String? className,
}) {
  final p = _buildProps(props: props, style: style, className: className);
  return SpanElement.fromJS(
    createElement('span'.toJS, _propsOrNull(p), text.toJS),
  );
}

/// Create a button element
ButtonElement button({
  required String text,
  void Function()? onClick,
  Map<String, dynamic>? props,
  Map<String, dynamic>? style,
  String? className,
}) {
  final p = _buildProps(props: props, style: style, className: className);
  if (onClick != null) p['onClick'] = onClick;
  return ButtonElement.fromJS(
    createElement('button'.toJS, createProps(p), text.toJS),
  );
}

/// Create an input element
InputElement input({
  String? type,
  String? value,
  String? placeholder,
  void Function(SyntheticEvent)? onChange,
  void Function(SyntheticEvent)? onInput,
  void Function(SyntheticFocusEvent)? onFocus,
  void Function(SyntheticFocusEvent)? onBlur,
  Map<String, dynamic>? props,
  Map<String, dynamic>? style,
  String? className,
}) {
  final p = _buildProps(props: props, style: style, className: className);
  if (type != null) p['type'] = type;
  if (value != null) p['value'] = value;
  if (placeholder != null) p['placeholder'] = placeholder;
  if (onChange != null) {
    void handler(JSObject e) => onChange(SyntheticEvent.fromJs(e));
    p['onChange'] = handler;
  }
  if (onInput != null) {
    void handler(JSObject e) => onInput(SyntheticEvent.fromJs(e));
    p['onInput'] = handler;
  }
  if (onFocus != null) {
    void handler(JSObject e) => onFocus(SyntheticFocusEvent.fromJs(e));
    p['onFocus'] = handler;
  }
  if (onBlur != null) {
    void handler(JSObject e) => onBlur(SyntheticFocusEvent.fromJs(e));
    p['onBlur'] = handler;
  }
  return InputElement.fromJS(createElement('input'.toJS, createProps(p)));
}

/// Create an img element
ImgElement img({
  required String src,
  String? alt,
  Map<String, dynamic>? props,
  Map<String, dynamic>? style,
  String? className,
}) {
  final p = _buildProps(props: props, style: style, className: className);
  p['src'] = src;
  if (alt != null) p['alt'] = alt;
  return ImgElement.fromJS(createElement('img'.toJS, createProps(p)));
}

/// Create an a (anchor) element
AElement a({
  required String href,
  required String text,
  Map<String, dynamic>? props,
  Map<String, dynamic>? style,
  String? className,
}) {
  final p = _buildProps(props: props, style: style, className: className);
  p['href'] = href;
  return AElement.fromJS(createElement('a'.toJS, createProps(p), text.toJS));
}

/// Create a ul element
UlElement ul({
  List<LiElement>? children,
  Map<String, dynamic>? props,
  Map<String, dynamic>? style,
  String? className,
}) {
  final p = _buildProps(props: props, style: style, className: className);
  final jsObj = (children != null && children.isNotEmpty)
      ? createElementWithChildren('ul'.toJS, _propsOrNull(p), children)
      : createElement('ul'.toJS, _propsOrNull(p));
  return UlElement.fromJS(jsObj);
}

/// Create a li element
LiElement li(
  String text, {
  Map<String, dynamic>? props,
  Map<String, dynamic>? style,
  String? className,
}) {
  final p = _buildProps(props: props, style: style, className: className);
  return LiElement.fromJS(createElement('li'.toJS, _propsOrNull(p), text.toJS));
}

/// Create a header element
HeaderElement header({
  List<ReactElement>? children,
  ReactElement? child,
  Map<String, dynamic>? props,
  Map<String, dynamic>? style,
  String? className,
}) {
  final p = _buildProps(props: props, style: style, className: className);
  final jsObj = (children != null && children.isNotEmpty)
      ? createElementWithChildren('header'.toJS, _propsOrNull(p), children)
      : (child != null)
      ? createElement('header'.toJS, _propsOrNull(p), child)
      : createElement('header'.toJS, _propsOrNull(p));
  return HeaderElement.fromJS(jsObj);
}

/// Create a main element
MainElement mainEl({
  List<ReactElement>? children,
  ReactElement? child,
  Map<String, dynamic>? props,
  Map<String, dynamic>? style,
  String? className,
}) {
  final p = _buildProps(props: props, style: style, className: className);
  final jsObj = (children != null && children.isNotEmpty)
      ? createElementWithChildren('main'.toJS, _propsOrNull(p), children)
      : (child != null)
      ? createElement('main'.toJS, _propsOrNull(p), child)
      : createElement('main'.toJS, _propsOrNull(p));
  return MainElement.fromJS(jsObj);
}

/// Create a footer element
FooterElement footer({
  List<ReactElement>? children,
  ReactElement? child,
  Map<String, dynamic>? props,
  Map<String, dynamic>? style,
  String? className,
}) {
  final p = _buildProps(props: props, style: style, className: className);
  final jsObj = (children != null && children.isNotEmpty)
      ? createElementWithChildren('footer'.toJS, _propsOrNull(p), children)
      : (child != null)
      ? createElement('footer'.toJS, _propsOrNull(p), child)
      : createElement('footer'.toJS, _propsOrNull(p));
  return FooterElement.fromJS(jsObj);
}
