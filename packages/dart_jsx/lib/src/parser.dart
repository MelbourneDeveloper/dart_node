/// JSX parser - converts JSX syntax to an AST.
library;

import 'package:nadz/nadz.dart';

/// Represents a JSX node in the AST.
sealed class JsxNode {}

/// A JSX element like `<div>...</div>`.
final class JsxElement extends JsxNode {
  JsxElement({
    required this.tagName,
    required this.attributes,
    required this.children,
    required this.isSelfClosing,
  });

  final String tagName;
  final List<JsxAttribute> attributes;
  final List<JsxNode> children;
  final bool isSelfClosing;

  @override
  String toString() =>
      'JsxElement($tagName, attrs: $attributes, children: $children)';
}

/// A JSX attribute like `className="app"` or `onClick={handler}`.
sealed class JsxAttribute {
  String get name;
}

/// String attribute: `className="app"`.
final class JsxStringAttribute extends JsxAttribute {
  JsxStringAttribute(this.name, this.value);

  @override
  final String name;
  final String value;

  @override
  String toString() => 'JsxStringAttribute($name="$value")';
}

/// Expression attribute: `onClick={handler}` or `disabled={true}`.
final class JsxExpressionAttribute extends JsxAttribute {
  JsxExpressionAttribute(this.name, this.expression);

  @override
  final String name;
  final String expression;

  @override
  String toString() => 'JsxExpressionAttribute($name={$expression})';
}

/// Boolean attribute: `disabled` (no value, implies true).
final class JsxBooleanAttribute extends JsxAttribute {
  JsxBooleanAttribute(this.name);

  @override
  final String name;

  @override
  String toString() => 'JsxBooleanAttribute($name)';
}

/// Spread attribute: `{...props}`.
final class JsxSpreadAttribute extends JsxAttribute {
  JsxSpreadAttribute(this.expression);

  final String expression;

  @override
  String get name => '...';

  @override
  String toString() => 'JsxSpreadAttribute({...$expression})';
}

/// Text content inside an element.
final class JsxText extends JsxNode {
  JsxText(this.text);

  final String text;

  @override
  String toString() => 'JsxText("$text")';
}

/// Expression inside an element: `{variable}` or `{condition ? a : b}`.
final class JsxExpression extends JsxNode {
  JsxExpression(this.expression);

  final String expression;

  @override
  String toString() => 'JsxExpression({$expression})';
}

/// A JSX fragment: `<>...</>` or `<Fragment>...</Fragment>`.
final class JsxFragment extends JsxNode {
  JsxFragment(this.children);

  final List<JsxNode> children;

  @override
  String toString() => 'JsxFragment($children)';
}

/// Parser for JSX syntax.
class JsxParser {
  JsxParser(this._source);

  final String _source;
  int _pos = 0;

  String get _remaining =>
      _pos >= _source.length ? '' : _source.substring(_pos);
  bool get _isEof => _pos >= _source.length;
  String get _currentChar => _isEof ? '' : _source[_pos];

  /// Parses JSX source and returns the root node.
  Result<JsxNode, String> parse() {
    _skipWhitespace();
    return _isEof ? Error('Empty JSX input') : _parseNode();
  }

  Result<JsxNode, String> _parseNode() {
    _skipWhitespace();
    return _currentChar == '<' ? _parseElement() : _parseTextOrExpression();
  }

  Result<JsxNode, String> _parseElement() {
    // Consume '<'
    _pos++;
    _skipWhitespace();

    // Check for fragment <>
    return _currentChar == '>' ? _parseFragment() : _parseNamedElement();
  }

  Result<JsxNode, String> _parseFragment() {
    // Consume '>'
    _pos++;

    final childrenResult = _parseChildren('</>');
    return childrenResult.match(
      onSuccess: (children) {
        // Consume '</>'
        _expect('</>');
        return Success(JsxFragment(children));
      },
      onError: Error.new,
    );
  }

  Result<JsxNode, String> _parseNamedElement() {
    // Parse tag name
    final tagName = _parseIdentifier();
    return tagName.isEmpty
        ? Error('Expected tag name at position $_pos')
        : _parseElementWithTag(tagName);
  }

  Result<JsxNode, String> _parseElementWithTag(String tagName) {
    _skipWhitespace();

    // Parse attributes
    final attrsResult = _parseAttributes();
    return attrsResult.match(
      onSuccess: (attrs) => _parseElementBody(tagName, attrs),
      onError: Error.new,
    );
  }

  Result<JsxNode, String> _parseElementBody(
    String tagName,
    List<JsxAttribute> attrs,
  ) {
    _skipWhitespace();

    // Self-closing tag?
    return _remaining.startsWith('/>')
        ? _parseSelfClosingEnd(tagName, attrs)
        : _parseElementWithChildren(tagName, attrs);
  }

  Result<JsxNode, String> _parseSelfClosingEnd(
    String tagName,
    List<JsxAttribute> attrs,
  ) {
    _pos += 2; // consume '/>'
    return Success(
      JsxElement(
        tagName: tagName,
        attributes: attrs,
        children: [],
        isSelfClosing: true,
      ),
    );
  }

  Result<JsxNode, String> _parseElementWithChildren(
    String tagName,
    List<JsxAttribute> attrs,
  ) {
    // Consume '>'
    return _currentChar != '>'
        ? Error('Expected ">" at position $_pos')
        : _parseChildrenAndClose(tagName, attrs);
  }

  Result<JsxNode, String> _parseChildrenAndClose(
    String tagName,
    List<JsxAttribute> attrs,
  ) {
    _pos++; // consume '>'

    final closingTag = '</$tagName>';
    final childrenResult = _parseChildren(closingTag);
    return childrenResult.match(
      onSuccess: (children) =>
          _finishElement(tagName, attrs, children, closingTag),
      onError: Error.new,
    );
  }

  Result<JsxNode, String> _finishElement(
    String tagName,
    List<JsxAttribute> attrs,
    List<JsxNode> children,
    String closingTag,
  ) {
    // Consume closing tag
    if (!_remaining.startsWith(closingTag)) {
      return Error('Expected closing tag $closingTag at position $_pos');
    }
    _pos += closingTag.length;
    return Success(
      JsxElement(
        tagName: tagName,
        attributes: attrs,
        children: children,
        isSelfClosing: false,
      ),
    );
  }

  Result<List<JsxAttribute>, String> _parseAttributes() {
    final attrs = <JsxAttribute>[];
    while (!_isEof && _currentChar != '>' && !_remaining.startsWith('/>')) {
      _skipWhitespace();
      if (!_shouldParseAttribute()) break;

      final posBefore = _pos;
      final result = _parseAttribute();

      final shouldContinue = result.match(
        onSuccess: (attr) {
          if (attr != null) attrs.add(attr);
          return true;
        },
        onError: (_) => false,
      );
      if (!shouldContinue) {
        return result.match(
          onSuccess: (_) => Success(attrs),
          onError: Error.new,
        );
      }

      // Detect infinite loop - invalid char that can't be parsed
      if (_pos == posBefore) {
        return Error('Unexpected character "$_currentChar" at position $_pos');
      }
    }
    return Success(attrs);
  }

  bool _shouldParseAttribute() =>
      !_isEof && _currentChar != '>' && !_remaining.startsWith('/>');

  Result<JsxAttribute?, String> _parseAttribute() {
    _skipWhitespace();

    // Spread attribute?
    return _remaining.startsWith('{...')
        ? _parseSpreadAttribute()
        : _parseNamedAttribute();
  }

  Result<JsxAttribute, String> _parseSpreadAttribute() {
    _pos += 4; // consume '{...'
    final expr = _parseBalancedExpression('}');
    if (_isEof || _currentChar != '}') {
      return Error('Unclosed spread attribute at position $_pos');
    }
    _pos++; // consume '}'
    return Success(JsxSpreadAttribute(expr));
  }

  Result<JsxAttribute?, String> _parseNamedAttribute() {
    final name = _parseIdentifier();
    return name.isEmpty ? Success(null) : _parseAttributeValue(name);
  }

  Result<JsxAttribute, String> _parseAttributeValue(String name) {
    _skipWhitespace();

    // Boolean attribute (no value)?
    return _currentChar != '='
        ? Success(JsxBooleanAttribute(name))
        : _parseAttributeWithValue(name);
  }

  Result<JsxAttribute, String> _parseAttributeWithValue(String name) {
    _pos++; // consume '='
    _skipWhitespace();

    return _currentChar == '"' || _currentChar == "'"
        ? _parseStringAttribute(name)
        : _currentChar == '{'
        ? _parseExpressionAttribute(name)
        : Error('Expected string or expression for attribute $name');
  }

  Result<JsxAttribute, String> _parseStringAttribute(String name) {
    final quote = _currentChar;
    _pos++; // consume opening quote

    final start = _pos;
    while (!_isEof && _currentChar != quote) {
      _pos++;
    }
    final value = _source.substring(start, _pos);
    _pos++; // consume closing quote

    return Success(JsxStringAttribute(name, value));
  }

  Result<JsxAttribute, String> _parseExpressionAttribute(String name) {
    _pos++; // consume '{'
    final expr = _parseBalancedExpression('}');
    if (_isEof || _currentChar != '}') {
      return Error('Unclosed expression in attribute $name at position $_pos');
    }
    _pos++; // consume '}'
    return Success(JsxExpressionAttribute(name, expr));
  }

  Result<List<JsxNode>, String> _parseChildren(String closingTag) {
    final children = <JsxNode>[];

    while (!_isEof && !_remaining.startsWith(closingTag)) {
      final result = _parseChild();
      final shouldContinue = result.match(
        onSuccess: (child) {
          if (child != null) children.add(child);
          return true;
        },
        onError: (_) => false,
      );
      if (!shouldContinue) {
        return result.match(
          onSuccess: (_) => Success(children),
          onError: Error.new,
        );
      }
    }
    return Success(children);
  }

  Result<JsxNode?, String> _parseChild() {
    return _currentChar == '<'
        ? _parseElement().map((e) => e)
        : _currentChar == '{'
        ? _parseExpressionNode()
        : _parseTextNode();
  }

  Result<JsxNode, String> _parseExpressionNode() {
    _pos++; // consume '{'
    final expr = _parseBalancedExpression('}');
    if (_isEof || _currentChar != '}') {
      return Error('Unclosed expression at position $_pos');
    }
    _pos++; // consume '}'
    return Success(JsxExpression(expr.trim()));
  }

  Result<JsxNode?, String> _parseTextNode() {
    final start = _pos;
    while (!_isEof && _currentChar != '<' && _currentChar != '{') {
      _pos++;
    }
    final text = _source.substring(start, _pos).trim();
    return Success(text.isEmpty ? null : JsxText(text));
  }

  Result<JsxNode, String> _parseTextOrExpression() {
    return _currentChar == '{' ? _parseExpressionNode() : _parseTextContent();
  }

  Result<JsxNode, String> _parseTextContent() {
    final start = _pos;
    while (!_isEof && _currentChar != '<' && _currentChar != '{') {
      _pos++;
    }
    final text = _source.substring(start, _pos).trim();
    return text.isEmpty ? Error('Empty text content') : Success(JsxText(text));
  }

  String _parseIdentifier() {
    final start = _pos;
    while (!_isEof && _isIdentifierChar(_currentChar)) {
      _pos++;
    }
    return _source.substring(start, _pos);
  }

  bool _isIdentifierChar(String c) => RegExp(r'[a-zA-Z0-9_\-]').hasMatch(c);

  String _parseBalancedExpression(String terminator) {
    final buffer = StringBuffer();
    var depth = 0;

    while (!_isEof) {
      final c = _currentChar;

      // Handle string literals
      final isStringStart = c == '"' || c == "'" || c == '`';
      if (isStringStart) {
        buffer.write(_parseString(c));
        continue;
      }

      // Track nested braces/parens/brackets
      final isOpener = c == '{' || c == '(' || c == '[';
      final isCloser = c == '}' || c == ')' || c == ']';

      if (isOpener) depth++;
      if (isCloser) {
        final atTerminator = depth == 0 && c == terminator;
        if (atTerminator) break;
        depth--;
      }

      buffer.write(c);
      _pos++;
    }

    return buffer.toString();
  }

  String _parseString(String quote) {
    final buffer = StringBuffer(quote);
    _pos++; // consume opening quote

    while (!_isEof) {
      final c = _currentChar;
      buffer.write(c);
      _pos++;

      final isEscape = c == '\\' && !_isEof;
      if (isEscape) {
        buffer.write(_currentChar);
        _pos++;
        continue;
      }

      final isClosingQuote = c == quote;
      if (isClosingQuote) break;
    }

    return buffer.toString();
  }

  void _skipWhitespace() {
    while (!_isEof && _currentChar.trim().isEmpty) {
      _pos++;
    }
  }

  void _expect(String expected) {
    final matches = _remaining.startsWith(expected);
    if (matches) _pos += expected.length;
  }
}
