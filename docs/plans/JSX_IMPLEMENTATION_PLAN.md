# JSX Implementation Plan for dart_node_react

## Overview

This document outlines the strategy for bringing JSX-like syntax to `dart_node_react`. Since Dart doesn't support JSX natively, we need creative approaches using Dart's language features.

## Goals

1. **Reduce Boilerplate** - Make component creation as concise as possible
2. **Maintain Type Safety** - Leverage Dart's type system
3. **Zero Runtime Overhead** - Use extension types and compile-time features
4. **Interop Seamlessly** - Work with existing element factories and React bindings
5. **Idiomatic Dart** - Feel natural to Dart developers

## Current State Analysis

### What We Have Now
```dart
// Current approach - verbose but functional
div(
  className: 'container',
  style: {'padding': 20},
  children: [
    h1('Title'),
    p('Some text'),
    button(text: 'Click', onClick: () => doSomething()),
  ],
)
```

### What We Want
```dart
// Ideal: Concise, readable, type-safe
$div(className: 'container', padding: 20) >> [
  $h1 >> 'Title',
  $p >> 'Some text',
  $button(onClick: doSomething) >> 'Click',
]

// OR using call syntax
div.c['container'](
  h1('Title'),
  p('Some text'),
  button('Click', onClick: doSomething),
)

// OR using extension types with builder pattern
Div()
  .className('container')
  .padding(20)
  .children([
    H1().text('Title'),
    P().text('Some text'),
    Button().text('Click').onClick(doSomething),
  ])
  .build()
```

## Implementation Approaches

### Approach 1: Operator Overloading (Recommended First Step)

Use `>>` operator to chain elements and children:

```dart
// jsx.dart
extension type El<T extends ReactElement>._(T element) implements ReactElement {
  El(T element) : this._(element);

  // Child operator - single child
  T operator >>(Object child) => _withChild(child);

  // Children operator
  T operator >>>(List<Object> children) => _withChildren(children);
}

// Element factories return El<T> instead of T
El<DivElement> $div({String? className, ...}) => El(div(className: className));
```

**Usage:**
```dart
$div(className: 'app') >> [
  $h1 >> 'Welcome',
  $div(className: 'content') >> [
    $p >> 'Hello world',
    $button(onClick: handleClick) >> 'Submit',
  ],
]
```

**Pros:**
- Concise syntax
- Easy to implement
- Works today without macros

**Cons:**
- Non-standard Dart idiom
- Learning curve

### Approach 2: Extension Types with Fluent API

Create fluent builders for each element:

```dart
// jsx_builders.dart
extension type DivBuilder._(Map<String, Object?> _props) {
  factory DivBuilder() => DivBuilder._({});

  DivBuilder className(String value) => _set('className', value);
  DivBuilder id(String value) => _set('id', value);
  DivBuilder style(Map<String, Object?> value) => _set('style', value);

  // Direct style props
  DivBuilder padding(Object value) => _setStyle('padding', value);
  DivBuilder margin(Object value) => _setStyle('margin', value);
  DivBuilder display(String value) => _setStyle('display', value);

  // Event handlers
  DivBuilder onClick(void Function() handler) => _set('onClick', handler);

  // Terminal: builds the element
  DivElement child(ReactElement element) => div(props: _props, child: element);
  DivElement children(List<ReactElement> elements) => div(props: _props, children: elements);
  DivElement text(String content) => div(props: _props, child: span(content));
  DivElement get empty => div(props: _props);
}

// Shorthand factories
DivBuilder get Div => DivBuilder();
H1Builder get H1 => H1Builder();
```

**Usage:**
```dart
Div.className('app').padding(20).children([
  H1.text('Welcome'),
  Div.className('content').children([
    P.text('Hello world'),
    Button.onClick(handleClick).text('Submit'),
  ]),
])
```

**Pros:**
- Type-safe props
- IDE autocomplete for all style/event props
- No operator magic

**Cons:**
- More verbose than JSX
- Lots of boilerplate in implementation

### Approach 3: Tagged Element Constructors

Use Dart's record syntax for a DSL:

```dart
// jsx_records.dart
typedef Props = Map<String, Object?>;

ReactElement jsx(String tag, Props props, [List<Object>? children]) {
  return domElement(tag, props, _normalizeChildren(children));
}

// Shorthand with records
(String, Props?, List<Object>?) $div = ('div', null, null);

extension JsxTuple on (String, Props?, List<Object>?) {
  ReactElement call([List<Object>? children]) =>
    jsx($1, $2 ?? {}, children ?? $3);
}
```

### Approach 4: Code Generation (Future - Requires Build Runner)

Generate typed element builders from React type definitions:

```dart
// In build.yaml, use source_gen to create:
// - Typed props classes
// - Builder methods
// - Factory functions

@GenerateJsxBuilder()
abstract class DivProps {
  String? className;
  String? id;
  void Function()? onClick;
  // ... all valid div props
}

// Generates:
class DivBuilder extends ElementBuilder<DivElement> {
  // ... all typed methods
}
```

### Approach 5: Dart Macros (Future - Dart 3.5+)

When Dart macros stabilize:

```dart
@jsx
class MyComponent {
  ReactElement build() {
    return jsx'''
      <div className="app">
        <h1>Welcome</h1>
        <p>Hello {name}</p>
      </div>
    ''';
  }
}
```

## Recommended Implementation Order

### Phase 1: Operator-Based DSL (Immediate)

Create `jsx.dart` with:
1. `El<T>` extension type for operator overloading
2. `$div`, `$h1`, `$p`, etc. factory functions
3. Support for text children via `>>` operator
4. Support for list children via `>>` with lists

**File:** `packages/dart_node_react/lib/src/jsx.dart`

### Phase 2: Fluent Builders (Short-term)

Create `jsx_builders.dart` with:
1. Builder extension types for all elements
2. Type-safe style props (padding, margin, display, etc.)
3. Type-safe event handlers
4. Terminal methods (`.child()`, `.children()`, `.text()`)

**File:** `packages/dart_node_react/lib/src/jsx_builders.dart`

### Phase 3: Convenience Extensions (Medium-term)

Add quality-of-life improvements:
1. String extension for text nodes: `'Hello'.el`
2. Int extension for spacers: `20.px`
3. Conditional rendering helpers
4. List flattening for fragments

**File:** `packages/dart_node_react/lib/src/jsx_extensions.dart`

### Phase 4: Code Generation (Long-term)

If adoption warrants it:
1. Create `jsx_generator` package
2. Generate builders from React type defs
3. Auto-generate prop types

### Phase 5: Macros (When Available)

When Dart macros are stable:
1. True JSX-like string interpolation
2. Compile-time transformation

## Implementation Details

### Phase 1: `jsx.dart`

```dart
// packages/dart_node_react/lib/src/jsx.dart

import 'dart:js_interop';
import 'elements.dart';
import 'html_elements.dart';
import 'react.dart';

/// Extension type that adds operator overloading for element composition
extension type El<T extends ReactElement>._(T _element) implements ReactElement {
  /// Creates an El wrapper around a ReactElement
  El(T element) : this._(element);

  /// Adds a single child or list of children using >> operator
  ///
  /// Usage:
  /// ```dart
  /// $div >> 'text'
  /// $div >> [$h1 >> 'Title', $p >> 'Content']
  /// ```
  T operator >>(Object child) => switch (child) {
    String text => _withTextChild(text),
    List<Object> children => _withChildren(children),
    ReactElement element => _withSingleChild(element),
    El<ReactElement> el => _withSingleChild(el._element),
    _ => throw ArgumentError('Invalid child type: ${child.runtimeType}'),
  };

  T _withTextChild(String text) {
    // Get the element type and recreate with text child
    final props = _element.props;
    final type = _element.type;
    return createElement(
      type,
      props,
      text.toJS,
    ) as T;
  }

  T _withSingleChild(ReactElement child) {
    final props = _element.props;
    final type = _element.type;
    return createElement(type, props, child) as T;
  }

  T _withChildren(List<Object> children) {
    final normalizedChildren = children.map(_normalizeChild).toList();
    final props = _element.props;
    final type = _element.type;
    return createElementWithChildren(
      type,
      props,
      normalizedChildren.cast<JSAny>(),
    ) as T;
  }

  JSAny _normalizeChild(Object child) => switch (child) {
    String text => text.toJS,
    ReactElement element => element,
    El<ReactElement> el => el._element,
    int n => n.toString().toJS,
    double n => n.toString().toJS,
    _ => throw ArgumentError('Invalid child: ${child.runtimeType}'),
  };
}

// Element factory functions that return El<T>
El<DivElement> $div({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
  void Function()? onClick,
}) => El(div(
  className: className,
  style: style,
  props: _mergeProps(props, id: id, onClick: onClick),
));

El<H1Element> $h1({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(h1('', className: className, style: style, props: _mergeProps(props, id: id)));

El<H2Element> $h2({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(h2('', className: className, style: style, props: _mergeProps(props, id: id)));

El<PElement> $p({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(pEl('', className: className, style: style, props: _mergeProps(props, id: id)));

El<SpanElement> $span({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
}) => El(span('', className: className, style: style, props: _mergeProps(props, id: id)));

El<ButtonElement> $button({
  String? className,
  String? id,
  Map<String, dynamic>? style,
  Map<String, dynamic>? props,
  void Function()? onClick,
}) => El(button(text: '', className: className, style: style, props: props, onClick: onClick));

// ... more element factories

Map<String, dynamic>? _mergeProps(
  Map<String, dynamic>? props, {
  String? id,
  void Function()? onClick,
}) {
  final hasExtra = id != null || onClick != null;
  if (props == null && !hasExtra) return null;
  return {
    ...?props,
    if (id != null) 'id': id,
    if (onClick != null) 'onClick': onClick,
  };
}
```

### Children Normalization

Handle various child types:

```dart
// Text: 'Hello' → JSString
// Element: div(...) → as-is
// Number: 42 → '42'.toJS
// List: [...] → flattened JSArray
// Null: null → filtered out
// Conditional: condition ? element : null → filtered out
```

### Style Shorthand Props

For the fluent builders (Phase 2):

```dart
extension type DivBuilder._(Map<String, Object?> _props) {
  // Layout
  DivBuilder display(String v) => _style('display', v);
  DivBuilder flex(int v) => _style('flex', v);
  DivBuilder flexDirection(String v) => _style('flexDirection', v);
  DivBuilder alignItems(String v) => _style('alignItems', v);
  DivBuilder justifyContent(String v) => _style('justifyContent', v);

  // Spacing
  DivBuilder padding(Object v) => _style('padding', v);
  DivBuilder paddingX(Object v) => this.paddingLeft(v).paddingRight(v);
  DivBuilder paddingY(Object v) => this.paddingTop(v).paddingBottom(v);
  DivBuilder margin(Object v) => _style('margin', v);

  // Size
  DivBuilder width(Object v) => _style('width', v);
  DivBuilder height(Object v) => _style('height', v);
  DivBuilder minWidth(Object v) => _style('minWidth', v);
  DivBuilder maxWidth(Object v) => _style('maxWidth', v);

  // Colors
  DivBuilder backgroundColor(String v) => _style('backgroundColor', v);
  DivBuilder color(String v) => _style('color', v);

  // Border
  DivBuilder border(String v) => _style('border', v);
  DivBuilder borderRadius(Object v) => _style('borderRadius', v);

  // ... etc
}
```

## File Structure

```
packages/dart_node_react/lib/src/
├── jsx.dart              # Phase 1: Operator-based DSL
├── jsx_builders.dart     # Phase 2: Fluent builders
├── jsx_extensions.dart   # Phase 3: Convenience extensions
└── (existing files)      # Untouched existing implementation
```

## Export Strategy

Add to `dart_node_react.dart`:

```dart
// Core API (existing)
export 'src/react.dart';
export 'src/elements.dart';
// ... other existing exports

// JSX-like API (new)
export 'src/jsx.dart';
export 'src/jsx_builders.dart';  // Phase 2
export 'src/jsx_extensions.dart'; // Phase 3
```

## Example: Counter Component

### Current API
```dart
ReactElement Counter() {
  final count = useState(0);

  return div(
    className: 'counter',
    style: {'padding': 20, 'textAlign': 'center'},
    children: [
      h1('Counter: ${count.value}'),
      div(
        style: {'display': 'flex', 'gap': 10, 'justifyContent': 'center'},
        children: [
          button(text: '-', onClick: () => count.set(count.value - 1)),
          button(text: '+', onClick: () => count.set(count.value + 1)),
        ],
      ),
    ],
  );
}
```

### Phase 1: Operator DSL
```dart
ReactElement Counter() {
  final count = useState(0);

  return $div(className: 'counter', style: {'padding': 20, 'textAlign': 'center'}) >> [
    $h1() >> 'Counter: ${count.value}',
    $div(style: {'display': 'flex', 'gap': 10, 'justifyContent': 'center'}) >> [
      $button(onClick: () => count.set(count.value - 1)) >> '-',
      $button(onClick: () => count.set(count.value + 1)) >> '+',
    ],
  ];
}
```

### Phase 2: Fluent Builders
```dart
ReactElement Counter() {
  final count = useState(0);

  return Div
    .className('counter')
    .padding(20)
    .textAlign('center')
    .children([
      H1.text('Counter: ${count.value}'),
      Div.display('flex').gap(10).justifyContent('center').children([
        Button.onClick(() => count.set(count.value - 1)).text('-'),
        Button.onClick(() => count.set(count.value + 1)).text('+'),
      ]),
    ]);
}
```

## Testing Strategy

Create `test/jsx_test.dart`:

```dart
void main() {
  group('JSX Operator DSL', () {
    test('creates element with text child', () {
      final el = $h1() >> 'Hello';
      expect(el, isA<H1Element>());
    });

    test('creates element with element child', () {
      final el = $div() >> ($span() >> 'text');
      expect(el, isA<DivElement>());
    });

    test('creates element with multiple children', () {
      final el = $div() >> [
        $h1() >> 'Title',
        $p() >> 'Content',
      ];
      expect(el, isA<DivElement>());
    });

    test('preserves props', () {
      final el = $div(className: 'test', id: 'my-id') >> 'content';
      // verify props are set correctly
    });
  });
}
```

## Compatibility Notes

1. **Existing API Unchanged** - All current `div()`, `h1()`, etc. functions remain
2. **Opt-in** - Import `jsx.dart` to use new syntax
3. **Interoperable** - Can mix old and new syntax freely
4. **No Breaking Changes** - Pure additive feature

## Open Questions

1. **Operator Choice** - Is `>>` the best operator? Alternatives: `|`, `%`, `&`
2. **Naming** - `$div` vs `Div` vs `div_` for factories
3. **Null Children** - How to handle conditional `null` children in lists?
4. **Keys** - How to specify React keys in the new syntax?
5. **Ref Forwarding** - How to attach refs cleanly?

## Next Steps

1. Create `jsx.dart` with Phase 1 implementation
2. Add tests for operator behavior
3. Document usage patterns
4. Gather feedback on syntax preferences
5. Iterate on API design
