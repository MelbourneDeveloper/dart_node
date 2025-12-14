/// JSX transformer - converts JSX AST to Dart code.
library;

import 'package:dart_jsx/src/parser.dart';

/// Transforms JSX AST nodes to Dart code using dart_node_react's JSX DSL.
class JsxTransformer {
  /// HTML elements that are getters (not functions) in jsx.dart.
  /// These elements cannot be called with () when they have no props.
  static const _getterElements = {
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'strong',
    'em',
    'code',
  };

  /// Transforms a JSX node to Dart code.
  String transform(JsxNode node) => switch (node) {
    JsxElement e => _transformElement(e),
    JsxFragment f => _transformFragment(f),
    JsxText t => _transformText(t),
    JsxExpression e => e.expression,
  };

  String _transformElement(JsxElement element) {
    final tag = element.tagName;
    final isComponent = _isComponentTag(tag);

    return isComponent
        ? _transformComponent(element)
        : _transformHtmlElement(element);
  }

  bool _isComponentTag(String tag) =>
      tag.isNotEmpty && tag[0] == tag[0].toUpperCase();

  String _transformComponent(JsxElement element) {
    final props = _transformPropsAsMap(element.attributes);
    final children = element.children;

    final hasChildren = children.isNotEmpty;
    final propsArg = props.isEmpty ? '' : props;

    return hasChildren
        ? '${element.tagName}($propsArg, children: ${_transformChildren(children)})'
        : '${element.tagName}($propsArg)';
  }

  String _transformHtmlElement(JsxElement element) {
    final factoryName = '\$${element.tagName}';
    final props = _transformProps(element.attributes);
    final children = element.children;

    final hasProps = props.isNotEmpty;
    final hasChildren = children.isNotEmpty;
    final isGetter = _getterElements.contains(element.tagName);

    // No props, no children
    // For getters (h1, h2, etc.): just use $h1
    // For functions (div, span, etc.): use $div()
    final noPropsNoChildren = !hasProps && !hasChildren;
    if (noPropsNoChildren) return isGetter ? factoryName : '$factoryName()';

    // Props but no children
    // For getters with props, use $h1Props(...) variant
    // For functions, use $div(...)
    final propsNoChildren = hasProps && !hasChildren;
    if (propsNoChildren) {
      return isGetter
          ? '\$${element.tagName}Props($props)'
          : '$factoryName($props)';
    }

    // Children (with or without props)
    // For getters without props: $h1 >> [...]
    // For getters with props: $h1Props(...) >> [...]
    // For functions without props: $div() >> [...]
    // For functions with props: $div(...) >> [...]
    final factory = hasProps
        ? (isGetter
              ? '\$${element.tagName}Props($props)'
              : '$factoryName($props)')
        : (isGetter ? factoryName : '$factoryName()');
    final childrenCode = _transformChildrenForOperator(children);
    return '$factory >> $childrenCode';
  }

  String _transformProps(List<JsxAttribute> attrs) {
    final parts = <String>[];

    for (final attr in attrs) {
      final part = switch (attr) {
        JsxStringAttribute a =>
          '${_dartPropName(a.name)}: \'${_escapeString(a.value)}\'',
        JsxExpressionAttribute a => '${_dartPropName(a.name)}: ${a.expression}',
        JsxBooleanAttribute a => '${_dartPropName(a.name)}: true',
        JsxSpreadAttribute a => '...${a.expression}',
      };
      parts.add(part);
    }

    return parts.join(', ');
  }

  String _transformPropsAsMap(List<JsxAttribute> attrs) {
    final parts = <String>[];

    for (final attr in attrs) {
      final part = switch (attr) {
        JsxStringAttribute a => "'${a.name}': '${_escapeString(a.value)}'",
        JsxExpressionAttribute a => "'${a.name}': ${a.expression}",
        JsxBooleanAttribute a => "'${a.name}': true",
        JsxSpreadAttribute a => '...${a.expression}',
      };
      parts.add(part);
    }

    return parts.isEmpty ? '' : '{${parts.join(', ')}}';
  }

  String _transformChildren(List<JsxNode> children) {
    final transformed = children
        .map(transform)
        .where((s) => s.isNotEmpty)
        .toList();

    return _formatArray(transformed);
  }

  String _formatArray(List<String> items) => switch (items.length) {
    0 => '[]',
    1 => items.first,
    _ => '[${items.join(', ')}]',
  };

  String _transformChildrenForOperator(List<JsxNode> children) {
    final meaningful = children.where(_isMeaningfulNode).toList();

    if (meaningful.isEmpty) return "''";
    if (meaningful.length == 1) return _transformSingleChild(meaningful.first);

    final transformed = meaningful.map(_transformChildForList).toList();
    return _formatChildrenArray(transformed);
  }

  String _formatChildrenArray(List<String> items) {
    final joined = items.join(', ');
    final isTooLong = joined.length > 80;
    if (!isTooLong) return '[${joined}]';

    final formattedItems = items
        .map((item) {
          final hasNewlines = item.contains('\n');
          return hasNewlines ? item.replaceAll('\n', '\n  ') : item;
        })
        .join(',\n  ');

    return '[\n  $formattedItems,\n]';
  }

  bool _isMeaningfulNode(JsxNode node) => switch (node) {
    JsxText t => t.text.trim().isNotEmpty,
    _ => true,
  };

  String _transformSingleChild(JsxNode node) => switch (node) {
    JsxText t => "'${_escapeString(t.text)}'",
    JsxExpression e => e.expression,
    JsxElement e => _wrapIfNeeded(transform(e)),
    JsxFragment f => _wrapIfNeeded(transform(f)),
  };

  /// Wraps code in parentheses if it contains >> to prevent chaining issues.
  String _wrapIfNeeded(String code) => code.contains(' >> ') ? '($code)' : code;

  String _transformChildForList(JsxNode node) => switch (node) {
    JsxText t => "'${_escapeString(t.text)}'",
    JsxExpression e => e.expression,
    _ => transform(node),
  };

  String _transformFragment(JsxFragment fragment) {
    final children = _transformChildrenForOperator(fragment.children);
    return '\$fragment >> $children';
  }

  String _transformText(JsxText text) => "'${_escapeString(text.text)}'";

  String _dartPropName(String jsxName) => switch (jsxName) {
    'class' => 'className',
    'for' => 'htmlFor',
    'readonly' => 'readOnly',
    'tabindex' => 'tabIndex',
    'colspan' => 'colSpan',
    'rowspan' => 'rowSpan',
    'maxlength' => 'maxLength',
    'minlength' => 'minLength',
    'autocomplete' => 'autoComplete',
    'autofocus' => 'autoFocus',
    'autoplay' => 'autoPlay',
    _ => jsxName,
  };

  String _escapeString(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll("'", "\\'")
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');
}
