/// JSX transpiler - processes Dart files containing JSX.
library;

import 'package:dart_jsx/src/parser.dart';
import 'package:dart_jsx/src/transformer.dart';
import 'package:nadz/nadz.dart';

/// Transpiles Dart source code containing JSX to pure Dart.
///
/// JSX can be embedded in Dart using the `<>` syntax directly.
/// The transpiler finds JSX blocks and converts them to dart_node_react calls.
///
/// Example input:
/// ```dart
/// final element = <div className="app">
///   <h1>Hello</h1>
/// </div>;
/// ```
///
/// Example output:
/// ```dart
/// final element = $div(className: 'app') >> [
///   $h1 >> 'Hello',
/// ];
/// ```
class JsxTranspiler {
  JsxTranspiler() : _transformer = JsxTransformer();

  final JsxTransformer _transformer;

  /// Transpiles a Dart source file containing JSX.
  Result<String, String> transpile(String source) {
    final buffer = StringBuffer();
    var pos = 0;

    while (pos < source.length) {
      final jsxStart = _findJsxStart(source, pos);

      // No more JSX found
      final noMoreJsx = jsxStart == -1;
      if (noMoreJsx) {
        buffer.write(source.substring(pos));
        break;
      }

      // Write content before JSX
      buffer.write(source.substring(pos, jsxStart));

      // Parse and transform JSX
      final jsxResult = _extractAndTransformJsx(source, jsxStart);
      final hasError = jsxResult.match(
        onSuccess: (result) {
          buffer.write(result.code);
          pos = result.endPos;
          return false;
        },
        onError: (e) => true,
      );

      if (hasError) {
        return jsxResult.match(
          onSuccess: (_) => Error('Unexpected success'),
          onError: Error.new,
        );
      }
    }

    return Success(buffer.toString());
  }

  /// Finds the start of a JSX block.
  /// Looks for `<` followed by a valid tag name or `>` (fragment).
  int _findJsxStart(String source, int startPos) {
    var pos = startPos;

    while (pos < source.length) {
      final ltPos = source.indexOf('<', pos);
      final notFound = ltPos == -1;
      if (notFound) return -1;

      // Skip if inside a string
      final inString = _isInsideString(source, ltPos);
      if (inString) {
        pos = ltPos + 1;
        continue;
      }

      // Skip if inside a comment
      final inComment = _isInsideComment(source, ltPos);
      if (inComment) {
        pos = ltPos + 1;
        continue;
      }

      // Check what follows '<'
      final afterLt = ltPos + 1 < source.length ? source[ltPos + 1] : '';

      // Fragment: <>
      final isFragment = afterLt == '>';
      if (isFragment) return ltPos;

      // HTML element: <div, <span, etc.
      final isHtmlElement = RegExp(r'[a-z]').hasMatch(afterLt);
      if (isHtmlElement) return ltPos;

      // Component: <MyComponent
      // But NOT generic types like <List<T>> or <Map<K,V>>
      final isComponent = RegExp(r'[A-Z]').hasMatch(afterLt);
      if (isComponent) {
        // Check if this is a Dart generic type, not JSX
        final isGeneric = _isGenericType(source, ltPos);
        if (!isGeneric) return ltPos;
      }

      // Not JSX (could be comparison operator or generic)
      pos = ltPos + 1;
    }

    return -1;
  }

  bool _isInsideString(String source, int pos) {
    var inSingleQuote = false;
    var inDoubleQuote = false;
    var inTripleSingle = false;
    var inTripleDouble = false;
    var i = 0;

    while (i < pos) {
      final c = source[i];
      final next2 = i + 2 < source.length ? source.substring(i, i + 3) : '';

      // Check for triple quotes first
      final isTripleSingleQuote = next2 == "'''";
      if (isTripleSingleQuote && !inDoubleQuote && !inTripleDouble) {
        inTripleSingle = !inTripleSingle;
        i += 3;
        continue;
      }

      final isTripleDoubleQuote = next2 == '"""';
      if (isTripleDoubleQuote && !inSingleQuote && !inTripleSingle) {
        inTripleDouble = !inTripleDouble;
        i += 3;
        continue;
      }

      // Skip if in triple quotes
      final inTriple = inTripleSingle || inTripleDouble;
      if (inTriple) {
        i++;
        continue;
      }

      // Handle escape sequences
      final isEscape = c == '\\';
      if (isEscape && (inSingleQuote || inDoubleQuote)) {
        i += 2;
        continue;
      }

      // Toggle string states
      final isSingleQuote = c == "'";
      if (isSingleQuote && !inDoubleQuote) {
        inSingleQuote = !inSingleQuote;
      }

      final isDoubleQuote = c == '"';
      if (isDoubleQuote && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
      }

      i++;
    }

    return inSingleQuote || inDoubleQuote || inTripleSingle || inTripleDouble;
  }

  bool _isInsideComment(String source, int pos) {
    var inLineComment = false;
    var inBlockComment = false;
    var i = 0;

    while (i < pos) {
      final c = source[i];
      final next = i + 1 < source.length ? source[i + 1] : '';

      // Check for comment start
      final isLineCommentStart = c == '/' && next == '/' && !inBlockComment;
      if (isLineCommentStart) {
        inLineComment = true;
        i += 2;
        continue;
      }

      final isBlockCommentStart = c == '/' && next == '*' && !inLineComment;
      if (isBlockCommentStart) {
        inBlockComment = true;
        i += 2;
        continue;
      }

      // Check for comment end
      final isLineEnd = c == '\n' && inLineComment;
      if (isLineEnd) {
        inLineComment = false;
      }

      final isBlockCommentEnd = c == '*' && next == '/' && inBlockComment;
      if (isBlockCommentEnd) {
        inBlockComment = false;
        i += 2;
        continue;
      }

      i++;
    }

    return inLineComment || inBlockComment;
  }

  /// Checks if `<` at pos is part of a Dart generic type, not JSX.
  bool _isGenericType(String source, int ltPos) {
    var end = ltPos + 1;
    while (end < source.length &&
        RegExp(r'[a-zA-Z0-9_]').hasMatch(source[end])) {
      end++;
    }
    final identifier = source.substring(ltPos + 1, end);

    const genericTypes = {
      'List',
      'Map',
      'Set',
      'Future',
      'Stream',
      'Iterable',
      'Iterator',
      'Function',
      'Record',
      'Type',
      'Symbol',
    };

    if (genericTypes.contains(identifier)) return true;

    // If preceded by alphanumeric (like `useState<`), it's a generic param
    final prevChar = ltPos > 0 ? source[ltPos - 1] : '';
    if (RegExp(r'[a-zA-Z0-9_]').hasMatch(prevChar)) return true;

    // If next char is `<` (nested generic), it's generic
    final nextChar = end < source.length ? source[end] : '';
    if (nextChar == '<') return true;

    return false;
  }

  Result<({String code, int endPos}), String> _extractAndTransformJsx(
    String source,
    int startPos,
  ) {
    // Find the end of the JSX expression
    final endResult = _findJsxEnd(source, startPos);

    return endResult.match(
      onSuccess: (endPos) {
        final jsxSource = source.substring(startPos, endPos);
        final parser = JsxParser(jsxSource);

        return parser.parse().match(
          onSuccess: (node) {
            final code = _transformer.transform(node);
            return Success((code: code, endPos: endPos));
          },
          onError: Error.new,
        );
      },
      onError: Error.new,
    );
  }

  Result<int, String> _findJsxEnd(String source, int startPos) {
    var pos = startPos + 1; // skip initial '<'
    var depth = 1;

    while (pos < source.length && depth > 0) {
      final c = source[pos];

      // Handle strings in expressions
      final isStringStart = c == '"' || c == "'" || c == '`';
      if (isStringStart) {
        pos = _skipString(source, pos);
        continue;
      }

      // Handle opening tag
      final isOpenTag = c == '<' && !_isClosingTag(source, pos);
      if (isOpenTag) {
        depth++;
        pos++;
        continue;
      }

      // Handle closing tag
      final isCloseTagStart = c == '<' && _isClosingTag(source, pos);
      if (isCloseTagStart) {
        depth--;
        pos = _skipToTagEnd(source, pos);
        continue;
      }

      // Handle self-closing
      final next = pos + 1 < source.length ? source[pos + 1] : '';
      final isSelfClose = c == '/' && next == '>';
      if (isSelfClose) {
        depth--;
        pos += 2;
        continue;
      }

      // Handle fragment close
      final next2 = pos + 2 < source.length
          ? source.substring(pos, pos + 3)
          : '';
      final isFragmentClose = next2 == '</>';
      if (isFragmentClose) {
        depth--;
        pos += 3;
        continue;
      }

      pos++;
    }

    return depth == 0
        ? Success(pos)
        : Error('Unclosed JSX element starting at position $startPos');
  }

  bool _isClosingTag(String source, int pos) =>
      pos + 1 < source.length && source[pos + 1] == '/';

  int _skipToTagEnd(String source, int pos) {
    while (pos < source.length && source[pos] != '>') {
      pos++;
    }
    return pos + 1;
  }

  int _skipString(String source, int pos) {
    final quote = source[pos];
    pos++;

    while (pos < source.length) {
      final c = source[pos];

      final isEscape = c == '\\';
      if (isEscape) {
        pos += 2;
        continue;
      }

      final isEndQuote = c == quote;
      if (isEndQuote) {
        return pos + 1;
      }

      pos++;
    }

    return pos;
  }
}

/// Convenience function to transpile JSX in a Dart source file.
Result<String, String> transpileJsx(String source) =>
    JsxTranspiler().transpile(source);
