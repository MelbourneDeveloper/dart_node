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
final class El {
  /// Wraps an existing element for operator composition.
  El(this._element) : _type = _element.type, _props = _element.props;

  /// The wrapped element.
  final ReactElement _element;

  /// The element's type for recreation.
  final JSAny _type;

  /// The element's props for recreation.
  final JSObject? _props;

  /// Access the underlying element.
  ReactElement get element => _element;

  /// Implicit conversion to ReactElement for use in element trees.
  ReactElement toElement() => _element;

  /// Adds children using the >> operator.
  ///
  /// Supports:
  /// - `String` → text child
  /// - `ReactElement` → single element child
  /// - `El` → unwrapped element child
  /// - `List<Object>` → multiple children (can contain strings, elements)
  /// - `null` → ignored (supports conditional rendering)
  ReactElement operator >>(Object? child) => switch (child) {
    null => _element,
    final String s => _withTextChild(s),
    final List<Object?> list => _withChildren(list),
    final num n => _withTextChild(n.toString()),
    final El el => _withSingleChild(el._element),
    final ReactElement re => _withSingleChild(re),
    _ => _element,
  };

  ReactElement _withTextChild(String text) =>
      ReactElement.fromJS(React.createElement(_type, _props, text.toJS));

  ReactElement _withSingleChild(ReactElement child) =>
      ReactElement.fromJS(React.createElement(_type, _props, child));

  ReactElement _withChildren(List<Object?> children) {
    final normalized = <JSAny>[];
    for (final child in children) {
      final jsChild = _normalizeChild(child);
      if (jsChild != null) normalized.add(jsChild);
    }
    return createElementWithChildren(_type, _props, normalized);
  }

  JSAny? _normalizeChild(Object? child) => switch (child) {
    null => null,
    final String s => s.toJS,
    final num n => n.toString().toJS,
    final bool b => b.toString().toJS,
    final El el => el._element,
    final ReactElement re => re,
    final List<Object?> list => _flattenChildren(list),
    _ => null,
  };

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
  String? key,
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? spread,
  Map<String, dynamic>? props,
  void Function()? onClick,
  void Function(SyntheticMouseEvent)? onClickEvent,
  void Function()? onDoubleClick,
  void Function(SyntheticEvent)? onChange,
  void Function(SyntheticEvent)? onInput,
  void Function(SyntheticFocusEvent)? onFocus,
  void Function(SyntheticFocusEvent)? onBlur,
  void Function(SyntheticEvent)? onSubmit,
  void Function(SyntheticKeyboardEvent)? onKeyDown,
  void Function(SyntheticKeyboardEvent)? onKeyUp,
  void Function(SyntheticKeyboardEvent)? onKeyPress,
  void Function(SyntheticMouseEvent)? onMouseDown,
  void Function(SyntheticMouseEvent)? onMouseUp,
  void Function(SyntheticMouseEvent)? onMouseEnter,
  void Function(SyntheticMouseEvent)? onMouseLeave,
  void Function(SyntheticMouseEvent)? onMouseOver,
  void Function(SyntheticMouseEvent)? onMouseOut,
  void Function(SyntheticMouseEvent)? onMouseMove,
  void Function(SyntheticEvent)? onScroll,
  void Function(SyntheticWheelEvent)? onWheel,
  void Function(SyntheticDragEvent)? onDrag,
  void Function(SyntheticDragEvent)? onDragStart,
  void Function(SyntheticDragEvent)? onDragEnd,
  void Function(SyntheticDragEvent)? onDragEnter,
  void Function(SyntheticDragEvent)? onDragLeave,
  void Function(SyntheticDragEvent)? onDragOver,
  void Function(SyntheticDragEvent)? onDrop,
  void Function(SyntheticTouchEvent)? onTouchStart,
  void Function(SyntheticTouchEvent)? onTouchMove,
  void Function(SyntheticTouchEvent)? onTouchEnd,
  void Function(SyntheticClipboardEvent)? onCopy,
  void Function(SyntheticClipboardEvent)? onCut,
  void Function(SyntheticClipboardEvent)? onPaste,
}) {
  final p = <String, dynamic>{};
  // Spread props first so explicit props override them
  if (spread != null) p.addAll(spread);
  if (props != null) p.addAll(props);
  if (key != null) p['key'] = key;
  if (className != null) p['className'] = className;
  if (id != null) p['id'] = id;
  if (style != null) p['style'] = convertStyle(style);
  // Mouse events
  if (onClick != null) p['onClick'] = onClick;
  if (onClickEvent != null) {
    void handler(JSObject e) => onClickEvent(SyntheticMouseEvent.fromJs(e));
    p['onClick'] = handler;
  }
  if (onDoubleClick != null) p['onDoubleClick'] = onDoubleClick;
  if (onMouseDown != null) {
    void handler(JSObject e) => onMouseDown(SyntheticMouseEvent.fromJs(e));
    p['onMouseDown'] = handler;
  }
  if (onMouseUp != null) {
    void handler(JSObject e) => onMouseUp(SyntheticMouseEvent.fromJs(e));
    p['onMouseUp'] = handler;
  }
  if (onMouseEnter != null) {
    void handler(JSObject e) => onMouseEnter(SyntheticMouseEvent.fromJs(e));
    p['onMouseEnter'] = handler;
  }
  if (onMouseLeave != null) {
    void handler(JSObject e) => onMouseLeave(SyntheticMouseEvent.fromJs(e));
    p['onMouseLeave'] = handler;
  }
  if (onMouseOver != null) {
    void handler(JSObject e) => onMouseOver(SyntheticMouseEvent.fromJs(e));
    p['onMouseOver'] = handler;
  }
  if (onMouseOut != null) {
    void handler(JSObject e) => onMouseOut(SyntheticMouseEvent.fromJs(e));
    p['onMouseOut'] = handler;
  }
  if (onMouseMove != null) {
    void handler(JSObject e) => onMouseMove(SyntheticMouseEvent.fromJs(e));
    p['onMouseMove'] = handler;
  }
  // Keyboard events
  if (onKeyDown != null) {
    void handler(JSObject e) => onKeyDown(SyntheticKeyboardEvent.fromJs(e));
    p['onKeyDown'] = handler;
  }
  if (onKeyUp != null) {
    void handler(JSObject e) => onKeyUp(SyntheticKeyboardEvent.fromJs(e));
    p['onKeyUp'] = handler;
  }
  if (onKeyPress != null) {
    void handler(JSObject e) => onKeyPress(SyntheticKeyboardEvent.fromJs(e));
    p['onKeyPress'] = handler;
  }
  // Form events
  if (onChange != null) {
    void handler(JSObject e) => onChange(SyntheticEvent.fromJs(e));
    p['onChange'] = handler;
  }
  if (onInput != null) {
    void handler(JSObject e) => onInput(SyntheticEvent.fromJs(e));
    p['onInput'] = handler;
  }
  if (onSubmit != null) {
    void handler(JSObject e) => onSubmit(SyntheticEvent.fromJs(e));
    p['onSubmit'] = handler;
  }
  // Focus events
  if (onFocus != null) {
    void handler(JSObject e) => onFocus(SyntheticFocusEvent.fromJs(e));
    p['onFocus'] = handler;
  }
  if (onBlur != null) {
    void handler(JSObject e) => onBlur(SyntheticFocusEvent.fromJs(e));
    p['onBlur'] = handler;
  }
  // Scroll/wheel events
  if (onScroll != null) {
    void handler(JSObject e) => onScroll(SyntheticEvent.fromJs(e));
    p['onScroll'] = handler;
  }
  if (onWheel != null) {
    void handler(JSObject e) => onWheel(SyntheticWheelEvent.fromJs(e));
    p['onWheel'] = handler;
  }
  // Drag events
  if (onDrag != null) {
    void handler(JSObject e) => onDrag(SyntheticDragEvent.fromJs(e));
    p['onDrag'] = handler;
  }
  if (onDragStart != null) {
    void handler(JSObject e) => onDragStart(SyntheticDragEvent.fromJs(e));
    p['onDragStart'] = handler;
  }
  if (onDragEnd != null) {
    void handler(JSObject e) => onDragEnd(SyntheticDragEvent.fromJs(e));
    p['onDragEnd'] = handler;
  }
  if (onDragEnter != null) {
    void handler(JSObject e) => onDragEnter(SyntheticDragEvent.fromJs(e));
    p['onDragEnter'] = handler;
  }
  if (onDragLeave != null) {
    void handler(JSObject e) => onDragLeave(SyntheticDragEvent.fromJs(e));
    p['onDragLeave'] = handler;
  }
  if (onDragOver != null) {
    void handler(JSObject e) => onDragOver(SyntheticDragEvent.fromJs(e));
    p['onDragOver'] = handler;
  }
  if (onDrop != null) {
    void handler(JSObject e) => onDrop(SyntheticDragEvent.fromJs(e));
    p['onDrop'] = handler;
  }
  // Touch events
  if (onTouchStart != null) {
    void handler(JSObject e) => onTouchStart(SyntheticTouchEvent.fromJs(e));
    p['onTouchStart'] = handler;
  }
  if (onTouchMove != null) {
    void handler(JSObject e) => onTouchMove(SyntheticTouchEvent.fromJs(e));
    p['onTouchMove'] = handler;
  }
  if (onTouchEnd != null) {
    void handler(JSObject e) => onTouchEnd(SyntheticTouchEvent.fromJs(e));
    p['onTouchEnd'] = handler;
  }
  // Clipboard events
  if (onCopy != null) {
    void handler(JSObject e) => onCopy(SyntheticClipboardEvent.fromJs(e));
    p['onCopy'] = handler;
  }
  if (onCut != null) {
    void handler(JSObject e) => onCut(SyntheticClipboardEvent.fromJs(e));
    p['onCut'] = handler;
  }
  if (onPaste != null) {
    void handler(JSObject e) => onPaste(SyntheticClipboardEvent.fromJs(e));
    p['onPaste'] = handler;
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
El $div({
  String? key,
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? spread,
  void Function()? onClick,
  void Function(SyntheticMouseEvent)? onMouseEnter,
  void Function(SyntheticMouseEvent)? onMouseLeave,
}) => El(
  DivElement.fromJS(
    _createJsxElement(
      'div',
      _buildJsxProps(
        key: key,
        className: className,
        id: id,
        style: style,
        spread: spread,
        onClick: onClick,
        onMouseEnter: onMouseEnter,
        onMouseLeave: onMouseLeave,
      ),
    ),
  ),
);

/// Creates a `<span>` element wrapper for JSX-style composition.
El $span({
  String? key,
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? spread,
  void Function()? onClick,
}) => El(
  SpanElement.fromJS(
    _createJsxElement(
      'span',
      _buildJsxProps(
        key: key,
        className: className,
        id: id,
        style: style,
        spread: spread,
        onClick: onClick,
      ),
    ),
  ),
);

/// Creates a `<p>` element wrapper for JSX-style composition.
El $p({
  String? key,
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? spread,
}) => El(
  PElement.fromJS(
    _createJsxElement(
      'p',
      _buildJsxProps(
        key: key,
        className: className,
        id: id,
        style: style,
        spread: spread,
      ),
    ),
  ),
);

/// Creates a `<section>` element wrapper for JSX-style composition.
El $section({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(
  _createJsxElement(
    'section',
    _buildJsxProps(className: className, id: id, style: style, props: props),
  ),
);

/// Creates an `<article>` element wrapper for JSX-style composition.
El $article({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(
  _createJsxElement(
    'article',
    _buildJsxProps(className: className, id: id, style: style, props: props),
  ),
);

/// Creates a `<nav>` element wrapper for JSX-style composition.
El $nav({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(
  _createJsxElement(
    'nav',
    _buildJsxProps(className: className, id: id, style: style, props: props),
  ),
);

/// Creates an `<aside>` element wrapper for JSX-style composition.
El $aside({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(
  _createJsxElement(
    'aside',
    _buildJsxProps(className: className, id: id, style: style, props: props),
  ),
);

// =============================================================================
// Heading Elements
// =============================================================================

/// Creates an `<h1>` element wrapper for JSX-style composition.
El get $h1 => El(H1Element.fromJS(_createJsxElement('h1', {})));

/// Creates an `<h1>` element with props.
El $h1Props({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(
  H1Element.fromJS(
    _createJsxElement(
      'h1',
      _buildJsxProps(className: className, id: id, style: style, props: props),
    ),
  ),
);

/// Creates an `<h2>` element wrapper for JSX-style composition.
El get $h2 => El(H2Element.fromJS(_createJsxElement('h2', {})));

/// Creates an `<h2>` element with props.
El $h2Props({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(
  H2Element.fromJS(
    _createJsxElement(
      'h2',
      _buildJsxProps(className: className, id: id, style: style, props: props),
    ),
  ),
);

/// Creates an `<h3>` element wrapper for JSX-style composition.
El get $h3 => El(_createJsxElement('h3', {}));

/// Creates an `<h3>` element with props.
El $h3Props({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(
  _createJsxElement(
    'h3',
    _buildJsxProps(className: className, id: id, style: style, props: props),
  ),
);

/// Creates an `<h4>` element wrapper for JSX-style composition.
El get $h4 => El(_createJsxElement('h4', {}));

/// Creates an `<h5>` element wrapper for JSX-style composition.
El get $h5 => El(_createJsxElement('h5', {}));

/// Creates an `<h6>` element wrapper for JSX-style composition.
El get $h6 => El(_createJsxElement('h6', {}));

// =============================================================================
// Semantic Structure
// =============================================================================

/// Creates a `<header>` element wrapper for JSX-style composition.
El $header({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(
  HeaderElement.fromJS(
    _createJsxElement(
      'header',
      _buildJsxProps(className: className, id: id, style: style, props: props),
    ),
  ),
);

/// Creates a `<main>` element wrapper for JSX-style composition.
El $main({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? spread,
}) => El(
  MainElement.fromJS(
    _createJsxElement(
      'main',
      _buildJsxProps(
        className: className,
        id: id,
        style: style,
        spread: spread,
      ),
    ),
  ),
);

/// Creates a `<footer>` element wrapper for JSX-style composition.
El $footer({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(
  FooterElement.fromJS(
    _createJsxElement(
      'footer',
      _buildJsxProps(className: className, id: id, style: style, props: props),
    ),
  ),
);

// =============================================================================
// Interactive Elements
// =============================================================================

/// Creates a `<button>` element wrapper for JSX-style composition.
El $button({
  String? key,
  String? className,
  String? id,
  String? type,
  bool? disabled,
  Map<String, dynamic>? style,
  Map<String, dynamic>? spread,
  void Function()? onClick,
}) {
  final p = _buildJsxProps(
    key: key,
    className: className,
    id: id,
    style: style,
    spread: spread,
    onClick: onClick,
  );
  if (type != null) p['type'] = type;
  if (disabled != null) p['disabled'] = disabled;
  return El(ButtonElement.fromJS(_createJsxElement('button', p)));
}

/// Creates an `<a>` element wrapper for JSX-style composition.
El $a({
  required String href,
  String? key,
  String? className,
  String? id,
  String? target,
  String? rel,
  Map<String, dynamic>? style,
  Map<String, dynamic>? spread,
  void Function()? onClick,
}) {
  final p = _buildJsxProps(
    key: key,
    className: className,
    id: id,
    style: style,
    spread: spread,
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
El $form({
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
El $input({
  String? key,
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
  Map<String, dynamic>? spread,
  void Function(SyntheticEvent)? onChange,
  void Function(SyntheticEvent)? onInput,
  void Function(SyntheticFocusEvent)? onFocus,
  void Function(SyntheticFocusEvent)? onBlur,
  void Function(SyntheticKeyboardEvent)? onKeyDown,
  void Function(SyntheticKeyboardEvent)? onKeyUp,
}) {
  final p = _buildJsxProps(
    key: key,
    className: className,
    id: id,
    style: style,
    spread: spread,
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
El $textarea({
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
El $select({
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
El $option({
  required String value,
  String? key,
  bool? disabled,
  bool? selected,
  Map<String, dynamic>? spread,
}) {
  final p = <String, dynamic>{'value': value};
  if (key != null) p['key'] = key;
  if (disabled != null) p['disabled'] = disabled;
  if (selected != null) p['selected'] = selected;
  if (spread != null) p.addAll(spread);
  return El(_createJsxElement('option', p));
}

/// Creates a `<label>` element wrapper for JSX-style composition.
El $label({
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
El $ul({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? spread,
}) => El(
  UlElement.fromJS(
    _createJsxElement(
      'ul',
      _buildJsxProps(
        className: className,
        id: id,
        style: style,
        spread: spread,
      ),
    ),
  ),
);

/// Creates an `<ol>` element wrapper for JSX-style composition.
El $ol({
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
El $li({
  String? key,
  String? className,
  String? id,
  int? value,
  Map<String, dynamic>? style,
  Map<String, dynamic>? spread,
}) {
  final p = _buildJsxProps(
    key: key,
    className: className,
    id: id,
    style: style,
    spread: spread,
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
El $video({
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
El $audio({
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
El $table({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(
  _createJsxElement(
    'table',
    _buildJsxProps(className: className, id: id, style: style, props: props),
  ),
);

/// Creates a `<thead>` element wrapper for JSX-style composition.
El $thead({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(
  _createJsxElement(
    'thead',
    _buildJsxProps(className: className, id: id, style: style, props: props),
  ),
);

/// Creates a `<tbody>` element wrapper for JSX-style composition.
El $tbody({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(
  _createJsxElement(
    'tbody',
    _buildJsxProps(className: className, id: id, style: style, props: props),
  ),
);

/// Creates a `<tfoot>` element wrapper for JSX-style composition.
El $tfoot({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(
  _createJsxElement(
    'tfoot',
    _buildJsxProps(className: className, id: id, style: style, props: props),
  ),
);

/// Creates a `<tr>` element wrapper for JSX-style composition.
El $tr({
  String? key,
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? spread,
}) => El(
  _createJsxElement(
    'tr',
    _buildJsxProps(
      key: key,
      className: className,
      id: id,
      style: style,
      spread: spread,
    ),
  ),
);

/// Creates a `<th>` element wrapper for JSX-style composition.
El $th({
  String? key,
  String? className,
  String? id,
  int? colSpan,
  int? rowSpan,
  String? scope,
  Map<String, dynamic>? style,
  Map<String, dynamic>? spread,
}) {
  final p = _buildJsxProps(
    key: key,
    className: className,
    id: id,
    style: style,
    spread: spread,
  );
  if (colSpan != null) p['colSpan'] = colSpan;
  if (rowSpan != null) p['rowSpan'] = rowSpan;
  if (scope != null) p['scope'] = scope;
  return El(_createJsxElement('th', p));
}

/// Creates a `<td>` element wrapper for JSX-style composition.
El $td({
  String? key,
  String? className,
  String? id,
  int? colSpan,
  int? rowSpan,
  Map<String, dynamic>? style,
  Map<String, dynamic>? spread,
}) {
  final p = _buildJsxProps(
    key: key,
    className: className,
    id: id,
    style: style,
    spread: spread,
  );
  if (colSpan != null) p['colSpan'] = colSpan;
  if (rowSpan != null) p['rowSpan'] = rowSpan;
  return El(_createJsxElement('td', p));
}

// =============================================================================
// Text Formatting
// =============================================================================

/// Creates a `<strong>` element wrapper for JSX-style composition.
El get $strong => El(_createJsxElement('strong', {}));

/// Creates an `<em>` element wrapper for JSX-style composition.
El get $em => El(_createJsxElement('em', {}));

/// Creates a `<code>` element wrapper for JSX-style composition.
El get $code => El(_createJsxElement('code', {}));

/// Creates a `<pre>` element wrapper for JSX-style composition.
El $pre({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(
  _createJsxElement(
    'pre',
    _buildJsxProps(className: className, id: id, style: style, props: props),
  ),
);

/// Creates a `<blockquote>` element wrapper for JSX-style composition.
El $blockquote({
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
}) => _createJsxElement(
  'hr',
  _buildJsxProps(className: className, id: id, style: style, props: props),
);

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
El get $fragment => El(createElement(_fragment));

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
El $el(
  String tagName, {
  String? key,
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? spread,
}) => El(
  _createJsxElement(
    tagName,
    _buildJsxProps(
      key: key,
      className: className,
      id: id,
      style: style,
      spread: spread,
    ),
  ),
);
