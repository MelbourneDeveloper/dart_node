/// JSX-like DSL for React element composition in Dart.
///
/// This module provides an operator-based syntax for creating React element
/// trees that closely resembles JSX structure while remaining pure Dart.
///
/// ## Basic Usage
///
/// ```dart
/// // Instead of:
/// div(children: [h1('Title'), p('Content')])
///
/// // Use:
/// $div() >> [$h1 >> 'Title', $p >> 'Content']
/// ```
///
/// ## The >> Operator
///
/// The `>>` operator adds children to an element:
/// - String → text child
/// - ReactElement → single child
/// - List<Object> → multiple children
///
/// ## Element Factories
///
/// All factories are prefixed with `$` to avoid conflicts:
/// - `$div`, `$span`, `$p`, `$h1`-`$h6`
/// - `$button`, `$input`, `$a`, `$img`
/// - `$ul`, `$ol`, `$li`
/// - `$header`, `$main`, `$footer`, `$nav`, `$section`, `$article`
/// - `$form`, `$label`, `$textarea`, `$select`, `$option`
/// - `$table`, `$tr`, `$td`, `$th`, `$thead`, `$tbody`
///
/// ## Examples
///
/// ### Simple Text
/// ```dart
/// $h1 >> 'Hello World'
/// ```
///
/// ### Nested Elements
/// ```dart
/// $div(className: 'card') >> [
///   $h2 >> 'Title',
///   $p >> 'Description',
/// ]
/// ```
///
/// ### With Events
/// ```dart
/// $button(onClick: handleClick) >> 'Submit'
/// ```
///
/// ### Conditional Rendering
/// ```dart
/// $div() >> [
///   $h1 >> 'Welcome',
///   if (showDetails) $p >> 'Details here',
/// ]
/// ```
library;

import 'dart:js_interop';

import 'package:dart_node_react/src/elements.dart';
import 'package:dart_node_react/src/react.dart';
import 'package:dart_node_react/src/synthetic_event.dart';

// =============================================================================
// Core JSX Extension Type
// =============================================================================

/// Wrapper class enabling operator-based element composition.
///
/// Wraps a ReactElement and provides the `>>` operator for adding children.
/// Uses a class instead of extension type to enable runtime type checking.
final class El<T extends ReactElement> {
  /// Wraps an existing element for operator composition.
  El(this._element)
      : _type = _element.type,
        _props = _element.props;

  /// The wrapped element.
  final T _element;

  /// The element's type for recreation.
  final JSAny _type;

  /// The element's props for recreation.
  final JSObject? _props;

  /// Access the underlying element.
  T get element => _element;

  /// Implicit conversion to ReactElement for use in element trees.
  ReactElement toElement() => _element;

  /// Adds children using the >> operator.
  ///
  /// Supports:
  /// - `String` → text child
  /// - `ReactElement` → single element child
  /// - `El<T>` → unwrapped element child
  /// - `List<Object>` → multiple children (can contain strings, elements)
  /// - `null` → ignored (supports conditional rendering)
  T operator >>(Object? child) {
    if (child == null) return _element;
    if (child is String) return _withTextChild(child);
    if (child is List<Object?>) return _withChildren(child);
    if (child is num) return _withTextChild(child.toString());
    if (child is El) return _withSingleChild(child._element);
    // Assume anything else is a ReactElement (JSObject)
    return _withJsChild(child as JSAny);
  }

  T _withTextChild(String text) {
    final jsObj = React.createElement(_type, _props, text.toJS);
    return ReactElement.fromJS(jsObj) as T;
  }

  T _withSingleChild(ReactElement child) {
    final jsObj = React.createElement(_type, _props, child);
    return ReactElement.fromJS(jsObj) as T;
  }

  T _withJsChild(JSAny child) {
    final jsObj = React.createElement(_type, _props, child);
    return ReactElement.fromJS(jsObj) as T;
  }

  T _withChildren(List<Object?> children) {
    final normalized = <JSAny>[];
    for (final child in children) {
      final jsChild = _normalizeChild(child);
      if (jsChild != null) normalized.add(jsChild);
    }
    return createElementWithChildren(_type, _props, normalized) as T;
  }

  JSAny? _normalizeChild(Object? child) {
    if (child == null) return null;
    if (child is String) return child.toJS;
    if (child is num) return child.toString().toJS;
    if (child is bool) return child.toString().toJS;
    if (child is El) return child._element;
    if (child is List<Object?>) return _flattenChildren(child);
    // Assume JSAny/ReactElement
    return child as JSAny;
  }

  JSAny? _flattenChildren(List<Object?> children) {
    final normalized = <JSAny>[];
    for (final child in children) {
      final jsChild = _normalizeChild(child);
      if (jsChild != null) normalized.add(jsChild);
    }
    return normalized.isEmpty ? null : _createFragment(normalized);
  }

  JSAny _createFragment(List<JSAny> children) =>
      createElementWithChildren(_fragment, null, children);
}

@JS('React.Fragment')
external JSAny get _fragment;

// =============================================================================
// Helper Functions
// =============================================================================

Map<String, dynamic> _buildJsxProps({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
  void Function()? onClick,
  void Function(SyntheticEvent)? onChange,
  void Function(SyntheticEvent)? onInput,
  void Function(SyntheticFocusEvent)? onFocus,
  void Function(SyntheticFocusEvent)? onBlur,
  void Function(SyntheticEvent)? onSubmit,
  void Function(SyntheticKeyboardEvent)? onKeyDown,
  void Function(SyntheticKeyboardEvent)? onKeyUp,
  void Function(SyntheticMouseEvent)? onMouseEnter,
  void Function(SyntheticMouseEvent)? onMouseLeave,
}) {
  final p = <String, dynamic>{};
  if (className != null) p['className'] = className;
  if (id != null) p['id'] = id;
  if (style != null) p['style'] = convertStyle(style);
  if (props != null) p.addAll(props);
  if (onClick != null) p['onClick'] = onClick;
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
  if (onSubmit != null) {
    void handler(JSObject e) => onSubmit(SyntheticEvent.fromJs(e));
    p['onSubmit'] = handler;
  }
  if (onKeyDown != null) {
    void handler(JSObject e) => onKeyDown(SyntheticKeyboardEvent.fromJs(e));
    p['onKeyDown'] = handler;
  }
  if (onKeyUp != null) {
    void handler(JSObject e) => onKeyUp(SyntheticKeyboardEvent.fromJs(e));
    p['onKeyUp'] = handler;
  }
  if (onMouseEnter != null) {
    void handler(JSObject e) => onMouseEnter(SyntheticMouseEvent.fromJs(e));
    p['onMouseEnter'] = handler;
  }
  if (onMouseLeave != null) {
    void handler(JSObject e) => onMouseLeave(SyntheticMouseEvent.fromJs(e));
    p['onMouseLeave'] = handler;
  }
  return p;
}

JSObject? _jsxPropsOrNull(Map<String, dynamic> p) =>
  p.isEmpty ? null : createProps(p);

ReactElement _createJsxElement(String tag, Map<String, dynamic> props) =>
  createElement(tag.toJS, _jsxPropsOrNull(props));

// =============================================================================
// Container Elements
// =============================================================================

/// Creates a `<div>` element wrapper for JSX-style composition.
El<DivElement> $div({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
  void Function()? onClick,
  void Function(SyntheticMouseEvent)? onMouseEnter,
  void Function(SyntheticMouseEvent)? onMouseLeave,
}) => El(DivElement.fromJS(_createJsxElement('div', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
  onClick: onClick,
  onMouseEnter: onMouseEnter,
  onMouseLeave: onMouseLeave,
))));

/// Creates a `<span>` element wrapper for JSX-style composition.
El<SpanElement> $span({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
  void Function()? onClick,
}) => El(SpanElement.fromJS(_createJsxElement('span', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
  onClick: onClick,
))));

/// Creates a `<p>` element wrapper for JSX-style composition.
El<PElement> $p({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(PElement.fromJS(_createJsxElement('p', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
))));

/// Creates a `<section>` element wrapper for JSX-style composition.
El<ReactElement> $section({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(_createJsxElement('section', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
)));

/// Creates an `<article>` element wrapper for JSX-style composition.
El<ReactElement> $article({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(_createJsxElement('article', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
)));

/// Creates a `<nav>` element wrapper for JSX-style composition.
El<ReactElement> $nav({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(_createJsxElement('nav', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
)));

/// Creates an `<aside>` element wrapper for JSX-style composition.
El<ReactElement> $aside({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(_createJsxElement('aside', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
)));

// =============================================================================
// Heading Elements
// =============================================================================

/// Creates an `<h1>` element wrapper for JSX-style composition.
El<H1Element> get $h1 => El(H1Element.fromJS(_createJsxElement('h1', {})));

/// Creates an `<h1>` element with props.
El<H1Element> $h1Props({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(H1Element.fromJS(_createJsxElement('h1', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
))));

/// Creates an `<h2>` element wrapper for JSX-style composition.
El<H2Element> get $h2 => El(H2Element.fromJS(_createJsxElement('h2', {})));

/// Creates an `<h2>` element with props.
El<H2Element> $h2Props({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(H2Element.fromJS(_createJsxElement('h2', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
))));

/// Creates an `<h3>` element wrapper for JSX-style composition.
El<ReactElement> get $h3 => El(_createJsxElement('h3', {}));

/// Creates an `<h3>` element with props.
El<ReactElement> $h3Props({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(_createJsxElement('h3', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
)));

/// Creates an `<h4>` element wrapper for JSX-style composition.
El<ReactElement> get $h4 => El(_createJsxElement('h4', {}));

/// Creates an `<h5>` element wrapper for JSX-style composition.
El<ReactElement> get $h5 => El(_createJsxElement('h5', {}));

/// Creates an `<h6>` element wrapper for JSX-style composition.
El<ReactElement> get $h6 => El(_createJsxElement('h6', {}));

// =============================================================================
// Semantic Structure
// =============================================================================

/// Creates a `<header>` element wrapper for JSX-style composition.
El<HeaderElement> $header({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(HeaderElement.fromJS(_createJsxElement('header', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
))));

/// Creates a `<main>` element wrapper for JSX-style composition.
El<MainElement> $main({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(MainElement.fromJS(_createJsxElement('main', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
))));

/// Creates a `<footer>` element wrapper for JSX-style composition.
El<FooterElement> $footer({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(FooterElement.fromJS(_createJsxElement('footer', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
))));

// =============================================================================
// Interactive Elements
// =============================================================================

/// Creates a `<button>` element wrapper for JSX-style composition.
El<ButtonElement> $button({
  String? className,
  String? id,
  String? type,
  bool? disabled,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
  void Function()? onClick,
}) {
  final p = _buildJsxProps(
    className: className,
    id: id,
    style: style,
    props: props,
    onClick: onClick,
  );
  if (type != null) p['type'] = type;
  if (disabled != null) p['disabled'] = disabled;
  return El(ButtonElement.fromJS(_createJsxElement('button', p)));
}

/// Creates an `<a>` element wrapper for JSX-style composition.
El<AElement> $a({
  required String href,
  String? className,
  String? id,
  String? target,
  String? rel,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
  void Function()? onClick,
}) {
  final p = _buildJsxProps(
    className: className,
    id: id,
    style: style,
    props: props,
    onClick: onClick,
  );
  p['href'] = href;
  if (target != null) p['target'] = target;
  if (rel != null) p['rel'] = rel;
  return El(AElement.fromJS(_createJsxElement('a', p)));
}

// =============================================================================
// Form Elements
// =============================================================================

/// Creates a `<form>` element wrapper for JSX-style composition.
El<ReactElement> $form({
  String? className,
  String? id,
  String? action,
  String? method,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
  void Function(SyntheticEvent)? onSubmit,
}) {
  final p = _buildJsxProps(
    className: className,
    id: id,
    style: style,
    props: props,
    onSubmit: onSubmit,
  );
  if (action != null) p['action'] = action;
  if (method != null) p['method'] = method;
  return El(_createJsxElement('form', p));
}

/// Creates an `<input>` element wrapper for JSX-style composition.
El<InputElement> $input({
  String? className,
  String? id,
  String? type,
  String? name,
  String? value,
  String? placeholder,
  bool? disabled,
  bool? readOnly,
  bool? required,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
  void Function(SyntheticEvent)? onChange,
  void Function(SyntheticEvent)? onInput,
  void Function(SyntheticFocusEvent)? onFocus,
  void Function(SyntheticFocusEvent)? onBlur,
  void Function(SyntheticKeyboardEvent)? onKeyDown,
  void Function(SyntheticKeyboardEvent)? onKeyUp,
}) {
  final p = _buildJsxProps(
    className: className,
    id: id,
    style: style,
    props: props,
    onChange: onChange,
    onInput: onInput,
    onFocus: onFocus,
    onBlur: onBlur,
    onKeyDown: onKeyDown,
    onKeyUp: onKeyUp,
  );
  if (type != null) p['type'] = type;
  if (name != null) p['name'] = name;
  if (value != null) p['value'] = value;
  if (placeholder != null) p['placeholder'] = placeholder;
  if (disabled != null) p['disabled'] = disabled;
  if (readOnly != null) p['readOnly'] = readOnly;
  if (required != null) p['required'] = required;
  return El(InputElement.fromJS(_createJsxElement('input', p)));
}

/// Creates a `<textarea>` element wrapper for JSX-style composition.
El<ReactElement> $textarea({
  String? className,
  String? id,
  String? name,
  String? value,
  String? placeholder,
  int? rows,
  int? cols,
  bool? disabled,
  bool? readOnly,
  bool? required,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
  void Function(SyntheticEvent)? onChange,
  void Function(SyntheticEvent)? onInput,
  void Function(SyntheticFocusEvent)? onFocus,
  void Function(SyntheticFocusEvent)? onBlur,
}) {
  final p = _buildJsxProps(
    className: className,
    id: id,
    style: style,
    props: props,
    onChange: onChange,
    onInput: onInput,
    onFocus: onFocus,
    onBlur: onBlur,
  );
  if (name != null) p['name'] = name;
  if (value != null) p['value'] = value;
  if (placeholder != null) p['placeholder'] = placeholder;
  if (rows != null) p['rows'] = rows;
  if (cols != null) p['cols'] = cols;
  if (disabled != null) p['disabled'] = disabled;
  if (readOnly != null) p['readOnly'] = readOnly;
  if (required != null) p['required'] = required;
  return El(_createJsxElement('textarea', p));
}

/// Creates a `<select>` element wrapper for JSX-style composition.
El<ReactElement> $select({
  String? className,
  String? id,
  String? name,
  String? value,
  bool? disabled,
  bool? multiple,
  bool? required,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
  void Function(SyntheticEvent)? onChange,
  void Function(SyntheticFocusEvent)? onFocus,
  void Function(SyntheticFocusEvent)? onBlur,
}) {
  final p = _buildJsxProps(
    className: className,
    id: id,
    style: style,
    props: props,
    onChange: onChange,
    onFocus: onFocus,
    onBlur: onBlur,
  );
  if (name != null) p['name'] = name;
  if (value != null) p['value'] = value;
  if (disabled != null) p['disabled'] = disabled;
  if (multiple != null) p['multiple'] = multiple;
  if (required != null) p['required'] = required;
  return El(_createJsxElement('select', p));
}

/// Creates an `<option>` element wrapper for JSX-style composition.
El<ReactElement> $option({
  required String value,
  bool? disabled,
  bool? selected,
  Map<String, dynamic>? props,
}) {
  final p = <String, dynamic>{'value': value};
  if (disabled != null) p['disabled'] = disabled;
  if (selected != null) p['selected'] = selected;
  if (props != null) p.addAll(props);
  return El(_createJsxElement('option', p));
}

/// Creates a `<label>` element wrapper for JSX-style composition.
El<ReactElement> $label({
  String? className,
  String? id,
  String? htmlFor,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) {
  final p = _buildJsxProps(
    className: className,
    id: id,
    style: style,
    props: props,
  );
  if (htmlFor != null) p['htmlFor'] = htmlFor;
  return El(_createJsxElement('label', p));
}

// =============================================================================
// List Elements
// =============================================================================

/// Creates a `<ul>` element wrapper for JSX-style composition.
El<UlElement> $ul({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(UlElement.fromJS(_createJsxElement('ul', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
))));

/// Creates an `<ol>` element wrapper for JSX-style composition.
El<ReactElement> $ol({
  String? className,
  String? id,
  int? start,
  String? type,
  bool? reversed,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) {
  final p = _buildJsxProps(
    className: className,
    id: id,
    style: style,
    props: props,
  );
  if (start != null) p['start'] = start;
  if (type != null) p['type'] = type;
  if (reversed != null) p['reversed'] = reversed;
  return El(_createJsxElement('ol', p));
}

/// Creates a `<li>` element wrapper for JSX-style composition.
El<LiElement> $li({
  String? className,
  String? id,
  int? value,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) {
  final p = _buildJsxProps(
    className: className,
    id: id,
    style: style,
    props: props,
  );
  if (value != null) p['value'] = value;
  return El(LiElement.fromJS(_createJsxElement('li', p)));
}

// =============================================================================
// Media Elements
// =============================================================================

/// Creates an `<img>` element (self-closing, no children).
ImgElement $img({
  required String src,
  String? alt,
  String? className,
  String? id,
  int? width,
  int? height,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
  void Function()? onClick,
}) {
  final p = _buildJsxProps(
    className: className,
    id: id,
    style: style,
    props: props,
    onClick: onClick,
  );
  p['src'] = src;
  if (alt != null) p['alt'] = alt;
  if (width != null) p['width'] = width;
  if (height != null) p['height'] = height;
  return ImgElement.fromJS(_createJsxElement('img', p));
}

/// Creates a `<video>` element wrapper for JSX-style composition.
El<ReactElement> $video({
  String? src,
  String? className,
  String? id,
  int? width,
  int? height,
  bool? controls,
  bool? autoplay,
  bool? loop,
  bool? muted,
  String? poster,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) {
  final p = _buildJsxProps(
    className: className,
    id: id,
    style: style,
    props: props,
  );
  if (src != null) p['src'] = src;
  if (width != null) p['width'] = width;
  if (height != null) p['height'] = height;
  if (controls != null) p['controls'] = controls;
  if (autoplay != null) p['autoplay'] = autoplay;
  if (loop != null) p['loop'] = loop;
  if (muted != null) p['muted'] = muted;
  if (poster != null) p['poster'] = poster;
  return El(_createJsxElement('video', p));
}

/// Creates an `<audio>` element wrapper for JSX-style composition.
El<ReactElement> $audio({
  String? src,
  String? className,
  String? id,
  bool? controls,
  bool? autoplay,
  bool? loop,
  bool? muted,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) {
  final p = _buildJsxProps(
    className: className,
    id: id,
    style: style,
    props: props,
  );
  if (src != null) p['src'] = src;
  if (controls != null) p['controls'] = controls;
  if (autoplay != null) p['autoplay'] = autoplay;
  if (loop != null) p['loop'] = loop;
  if (muted != null) p['muted'] = muted;
  return El(_createJsxElement('audio', p));
}

// =============================================================================
// Table Elements
// =============================================================================

/// Creates a `<table>` element wrapper for JSX-style composition.
El<ReactElement> $table({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(_createJsxElement('table', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
)));

/// Creates a `<thead>` element wrapper for JSX-style composition.
El<ReactElement> $thead({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(_createJsxElement('thead', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
)));

/// Creates a `<tbody>` element wrapper for JSX-style composition.
El<ReactElement> $tbody({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(_createJsxElement('tbody', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
)));

/// Creates a `<tfoot>` element wrapper for JSX-style composition.
El<ReactElement> $tfoot({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(_createJsxElement('tfoot', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
)));

/// Creates a `<tr>` element wrapper for JSX-style composition.
El<ReactElement> $tr({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(_createJsxElement('tr', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
)));

/// Creates a `<th>` element wrapper for JSX-style composition.
El<ReactElement> $th({
  String? className,
  String? id,
  int? colSpan,
  int? rowSpan,
  String? scope,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) {
  final p = _buildJsxProps(
    className: className,
    id: id,
    style: style,
    props: props,
  );
  if (colSpan != null) p['colSpan'] = colSpan;
  if (rowSpan != null) p['rowSpan'] = rowSpan;
  if (scope != null) p['scope'] = scope;
  return El(_createJsxElement('th', p));
}

/// Creates a `<td>` element wrapper for JSX-style composition.
El<ReactElement> $td({
  String? className,
  String? id,
  int? colSpan,
  int? rowSpan,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) {
  final p = _buildJsxProps(
    className: className,
    id: id,
    style: style,
    props: props,
  );
  if (colSpan != null) p['colSpan'] = colSpan;
  if (rowSpan != null) p['rowSpan'] = rowSpan;
  return El(_createJsxElement('td', p));
}

// =============================================================================
// Text Formatting
// =============================================================================

/// Creates a `<strong>` element wrapper for JSX-style composition.
El<ReactElement> get $strong => El(_createJsxElement('strong', {}));

/// Creates an `<em>` element wrapper for JSX-style composition.
El<ReactElement> get $em => El(_createJsxElement('em', {}));

/// Creates a `<code>` element wrapper for JSX-style composition.
El<ReactElement> get $code => El(_createJsxElement('code', {}));

/// Creates a `<pre>` element wrapper for JSX-style composition.
El<ReactElement> $pre({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(_createJsxElement('pre', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
)));

/// Creates a `<blockquote>` element wrapper for JSX-style composition.
El<ReactElement> $blockquote({
  String? className,
  String? id,
  String? cite,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) {
  final p = _buildJsxProps(
    className: className,
    id: id,
    style: style,
    props: props,
  );
  if (cite != null) p['cite'] = cite;
  return El(_createJsxElement('blockquote', p));
}

// =============================================================================
// Misc Elements
// =============================================================================

/// Creates a `<br>` element (self-closing, no children).
ReactElement get $br => _createJsxElement('br', {});

/// Creates an `<hr>` element (self-closing, no children).
ReactElement $hr({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => _createJsxElement('hr', _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
));

/// Creates an `<iframe>` element (self-closing unless children needed).
ReactElement $iframe({
  required String src,
  String? className,
  String? id,
  int? width,
  int? height,
  String? title,
  String? sandbox,
  String? allow,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) {
  final p = _buildJsxProps(
    className: className,
    id: id,
    style: style,
    props: props,
  );
  p['src'] = src;
  if (width != null) p['width'] = width;
  if (height != null) p['height'] = height;
  if (title != null) p['title'] = title;
  if (sandbox != null) p['sandbox'] = sandbox;
  if (allow != null) p['allow'] = allow;
  return _createJsxElement('iframe', p);
}

// =============================================================================
// Fragment Helper
// =============================================================================

/// Creates a Fragment wrapper for JSX-style composition.
///
/// Usage:
/// ```dart
/// $fragment >> [
///   $h1 >> 'Title',
///   $p >> 'Content',
/// ]
/// ```
El<ReactElement> get $fragment => El(createElement(_fragment));

// =============================================================================
// Generic Element Factory
// =============================================================================

/// Creates any HTML element by tag name for JSX-style composition.
///
/// Use this for elements not covered by specific factories.
///
/// Usage:
/// ```dart
/// $el('custom-element', className: 'my-class') >> 'Content'
/// ```
El<ReactElement> $el(
  String tagName, {
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(_createJsxElement(tagName, _buildJsxProps(
  className: className,
  id: id,
  style: style,
  props: props,
)));
