import 'dart:js_interop';

/// JS interop binding for marked.js parse function
@JS('marked.parse')
external JSString _markedParse(JSString markdown);

/// Convert markdown to HTML using marked.js
String markdownToHtml(String markdown) =>
    markdown.isEmpty ? '' : _markedParse(markdown.toJS).toDart;

/// Convert HTML from contenteditable back to markdown
/// Handles the subset of HTML that contenteditable produces
String htmlToMarkdown(String html) {
  if (html.isEmpty) return '';

  var result = html;

  // Process headings first (block level)
  result = _convertHeadings(result);

  // Process lists
  result = _convertLists(result);

  // Process inline elements
  result = _convertInlineElements(result);

  // Process block elements
  result = _convertBlockElements(result);

  // Final cleanup
  return _cleanupResult(result);
}

String _convertHeadings(String html) {
  var result = html;
  result = result.replaceAllMapped(
    RegExp('<h1[^>]*>(.*?)</h1>', caseSensitive: false, dotAll: true),
    (m) => '# ${_stripTags(m.group(1) ?? '')}\n\n',
  );
  result = result.replaceAllMapped(
    RegExp('<h2[^>]*>(.*?)</h2>', caseSensitive: false, dotAll: true),
    (m) => '## ${_stripTags(m.group(1) ?? '')}\n\n',
  );
  result = result.replaceAllMapped(
    RegExp('<h3[^>]*>(.*?)</h3>', caseSensitive: false, dotAll: true),
    (m) => '### ${_stripTags(m.group(1) ?? '')}\n\n',
  );
  return result;
}

String _convertLists(String html) {
  var result = html;

  // Convert unordered lists
  result = result.replaceAllMapped(
    RegExp('<ul[^>]*>(.*?)</ul>', caseSensitive: false, dotAll: true),
    (m) => _convertListItems(m.group(1) ?? '', ordered: false),
  );

  // Convert ordered lists
  result = result.replaceAllMapped(
    RegExp('<ol[^>]*>(.*?)</ol>', caseSensitive: false, dotAll: true),
    (m) => _convertListItems(m.group(1) ?? '', ordered: true),
  );

  return result;
}

String _convertListItems(String listContent, {required bool ordered}) {
  final items = RegExp(
    '<li[^>]*>(.*?)</li>',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(listContent);

  final buffer = StringBuffer();
  var index = 1;
  for (final item in items) {
    final content = _stripTags(item.group(1) ?? '').trim();
    final prefix = ordered ? '$index. ' : '- ';
    buffer.writeln('$prefix$content');
    index++;
  }
  buffer.writeln();
  return buffer.toString();
}

String _convertInlineElements(String html) {
  var result = html;

  // Bold: <strong> or <b>
  result = result.replaceAllMapped(
    RegExp(r'<(strong|b)[^>]*>(.*?)</\1>', caseSensitive: false, dotAll: true),
    (m) => '**${m.group(2)}**',
  );

  // Italic: <em> or <i>
  result = result.replaceAllMapped(
    RegExp(r'<(em|i)[^>]*>(.*?)</\1>', caseSensitive: false, dotAll: true),
    (m) => '*${m.group(2)}*',
  );

  // Underline: <u> (using __ convention)
  result = result.replaceAllMapped(
    RegExp('<u[^>]*>(.*?)</u>', caseSensitive: false, dotAll: true),
    (m) => '__${m.group(1)}__',
  );

  // Links: <a href="url">text</a>
  result = result.replaceAllMapped(
    RegExp(
      '<a[^>]*href="([^"]*)"[^>]*>(.*?)</a>',
      caseSensitive: false,
      dotAll: true,
    ),
    (m) => '[${m.group(2)}](${m.group(1)})',
  );

  // Inline code: <code>
  result = result.replaceAllMapped(
    RegExp('<code[^>]*>(.*?)</code>', caseSensitive: false, dotAll: true),
    (m) => '`${m.group(1)}`',
  );

  return result;
}

String _convertBlockElements(String html) {
  var result = html;

  // Paragraphs
  result = result.replaceAllMapped(
    RegExp('<p[^>]*>(.*?)</p>', caseSensitive: false, dotAll: true),
    (m) => '${m.group(1)}\n\n',
  );

  // Divs (contenteditable often uses these)
  result = result.replaceAllMapped(
    RegExp('<div[^>]*>(.*?)</div>', caseSensitive: false, dotAll: true),
    (m) => '${m.group(1)}\n',
  );

  // Line breaks
  result = result.replaceAll(RegExp(r'<br\s*/?>'), '\n');

  // Blockquotes
  result = result.replaceAllMapped(
    RegExp(
      '<blockquote[^>]*>(.*?)</blockquote>',
      caseSensitive: false,
      dotAll: true,
    ),
    (m) => '> ${_stripTags(m.group(1) ?? '').trim()}\n\n',
  );

  return result;
}

String _cleanupResult(String text) {
  var result = text;

  // Strip any remaining HTML tags
  result = _stripTags(result);

  // Decode common HTML entities
  result = _decodeHtmlEntities(result);

  // Normalize whitespace
  result = result.replaceAll(RegExp('\n{3,}'), '\n\n');
  result = result.replaceAll(RegExp('[ \t]+'), ' ');

  return result.trim();
}

String _stripTags(String html) => html.replaceAll(RegExp('<[^>]*>'), '');

String _decodeHtmlEntities(String text) {
  var result = text;
  result = result.replaceAll('&nbsp;', ' ');
  result = result.replaceAll('&amp;', '&');
  result = result.replaceAll('&lt;', '<');
  result = result.replaceAll('&gt;', '>');
  result = result.replaceAll('&quot;', '"');
  result = result.replaceAll('&#39;', "'");
  return result;
}
