import 'package:dart_jsx/dart_jsx.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

void main() {
  test('parses simple element with text', () {
    final parser = JsxParser('<div>Hello</div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final node = (result as Success<JsxNode, String>).value;
    expect(node, isA<JsxElement>());

    final element = node as JsxElement;
    expect(element.tagName, equals('div'));
    expect(element.children.length, equals(1));
    expect((element.children.first as JsxText).text, equals('Hello'));
  });

  test('parses self-closing element', () {
    final parser = JsxParser('<input />');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.tagName, equals('input'));
    expect(element.isSelfClosing, isTrue);
    expect(element.children, isEmpty);
  });

  test('parses element with string attribute', () {
    final parser = JsxParser('<div className="container">Content</div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.attributes.length, equals(1));

    final attr = element.attributes.first as JsxStringAttribute;
    expect(attr.name, equals('className'));
    expect(attr.value, equals('container'));
  });

  test('parses element with expression attribute', () {
    final parser = JsxParser('<button onClick={handleClick}>Click</button>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;

    final attr = element.attributes.first as JsxExpressionAttribute;
    expect(attr.name, equals('onClick'));
    expect(attr.expression, equals('handleClick'));
  });

  test('parses element with boolean attribute', () {
    final parser = JsxParser('<input disabled />');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;

    final attr = element.attributes.first as JsxBooleanAttribute;
    expect(attr.name, equals('disabled'));
  });

  test('parses nested elements', () {
    final parser = JsxParser('<div><h1>Title</h1><p>Content</p></div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.children.length, equals(2));

    final h1 = element.children[0] as JsxElement;
    expect(h1.tagName, equals('h1'));

    final p = element.children[1] as JsxElement;
    expect(p.tagName, equals('p'));
  });

  test('parses fragment', () {
    final parser = JsxParser('<><h1>First</h1><p>Second</p></>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final fragment = (result as Success<JsxNode, String>).value as JsxFragment;
    expect(fragment.children.length, equals(2));
  });

  test('parses expression children', () {
    final parser = JsxParser('<div>{count}</div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;

    final expr = element.children.first as JsxExpression;
    expect(expr.expression, equals('count'));
  });

  test('transforms simple element to Dart', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'div',
      attributes: [],
      children: [JsxText('Hello')],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, equals("\$div() >> 'Hello'"));
  });

  test('transforms element with className', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'div',
      attributes: [JsxStringAttribute('className', 'container')],
      children: [JsxText('Content')],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, equals("\$div(className: 'container') >> 'Content'"));
  });

  test('transforms element with onClick', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'button',
      attributes: [JsxExpressionAttribute('onClick', 'handleClick')],
      children: [JsxText('Click me')],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, equals("\$button(onClick: handleClick) >> 'Click me'"));
  });

  test('transforms nested elements', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'div',
      attributes: [],
      children: [
        JsxElement(
          tagName: 'h1',
          attributes: [],
          children: [JsxText('Title')],
          isSelfClosing: false,
        ),
        JsxElement(
          tagName: 'p',
          attributes: [],
          children: [JsxText('Content')],
          isSelfClosing: false,
        ),
      ],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, equals("\$div() >> [\$h1 >> 'Title', \$p() >> 'Content']"));
  });

  test('transforms fragment', () {
    final transformer = JsxTransformer();
    final fragment = JsxFragment([
      JsxElement(
        tagName: 'h1',
        attributes: [],
        children: [JsxText('First')],
        isSelfClosing: false,
      ),
      JsxElement(
        tagName: 'p',
        attributes: [],
        children: [JsxText('Second')],
        isSelfClosing: false,
      ),
    ]);

    final result = transformer.transform(fragment);
    expect(
      result,
      equals("\$fragment >> [\$h1 >> 'First', \$p() >> 'Second']"),
    );
  });

  test('transpiles JSX in Dart source', () {
    const source = '''
final element = <div className="app">
  <h1>Hello</h1>
</div>;
''';

    final result = transpileJsx(source);
    expect(result.isSuccess, isTrue);

    final output = (result as Success<String, String>).value;
    expect(output, contains("\$div(className: 'app')"));
    expect(output, contains("\$h1 >> 'Hello'"));
  });

  test('preserves non-JSX Dart code', () {
    const source = '''
import 'package:dart_node_react/dart_node_react.dart';

void main() {
  final count = 0;
  final element = <div>{count}</div>;
  print(element);
}
''';

    final result = transpileJsx(source);
    expect(result.isSuccess, isTrue);

    final output = (result as Success<String, String>).value;
    expect(
      output,
      contains("import 'package:dart_node_react/dart_node_react.dart';"),
    );
    expect(output, contains('void main()'));
    expect(output, contains('final count = 0;'));
    expect(output, contains('\$div() >> count'));
  });

  test('ignores JSX-like syntax in strings', () {
    const source = '''
final html = '<div>Not JSX</div>';
final element = <div>Real JSX</div>;
''';

    final result = transpileJsx(source);
    expect(result.isSuccess, isTrue);

    final output = (result as Success<String, String>).value;
    expect(output, contains("'<div>Not JSX</div>'"));
    expect(output, contains("\$div() >> 'Real JSX'"));
  });

  test('ignores comparison operators', () {
    const source = '''
final isSmaller = a < b;
final element = <div>JSX</div>;
''';

    final result = transpileJsx(source);
    expect(result.isSuccess, isTrue);

    final output = (result as Success<String, String>).value;
    expect(output, contains('a < b'));
    expect(output, contains("\$div() >> 'JSX'"));
  });

  test('handles complex expressions in attributes', () {
    final parser = JsxParser(
      '<button onClick={() => setState(prev => prev + 1)}>+</button>',
    );
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;

    final attr = element.attributes.first as JsxExpressionAttribute;
    expect(attr.expression, equals('() => setState(prev => prev + 1)'));
  });

  test('handles ternary in children', () {
    final parser = JsxParser('<div>{isLoading ? "Loading..." : content}</div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;

    final expr = element.children.first as JsxExpression;
    expect(expr.expression, equals('isLoading ? "Loading..." : content'));
  });

  test('parses spread attributes', () {
    final parser = JsxParser('<div {...props}>Content</div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.attributes.length, equals(1));

    final attr = element.attributes.first as JsxSpreadAttribute;
    expect(attr.expression, equals('props'));
  });

  test('parses multiple attributes on same element', () {
    final parser = JsxParser(
      '<button className="btn" disabled onClick={handler}>Click</button>',
    );
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.attributes.length, equals(3));

    final classNameAttr = element.attributes[0] as JsxStringAttribute;
    expect(classNameAttr.name, equals('className'));
    expect(classNameAttr.value, equals('btn'));

    final disabledAttr = element.attributes[1] as JsxBooleanAttribute;
    expect(disabledAttr.name, equals('disabled'));

    final onClickAttr = element.attributes[2] as JsxExpressionAttribute;
    expect(onClickAttr.name, equals('onClick'));
    expect(onClickAttr.expression, equals('handler'));
  });

  test('parses components with children', () {
    final parser = JsxParser('<MyComponent><Child /></MyComponent>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.tagName, equals('MyComponent'));
    expect(element.children.length, equals(1));

    final child = element.children.first as JsxElement;
    expect(child.tagName, equals('Child'));
    expect(child.isSelfClosing, isTrue);
  });

  test('parses empty self-closing components', () {
    final parser = JsxParser('<EmptyComponent />');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.tagName, equals('EmptyComponent'));
    expect(element.isSelfClosing, isTrue);
    expect(element.children, isEmpty);
    expect(element.attributes, isEmpty);
  });

  test('transforms spread attributes in HTML elements', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'div',
      attributes: [JsxSpreadAttribute('props')],
      children: [JsxText('Content')],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, equals("\$div(...props) >> 'Content'"));
  });

  test('transforms multiple attributes on same element', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'button',
      attributes: [
        JsxStringAttribute('className', 'btn'),
        JsxBooleanAttribute('disabled'),
        JsxExpressionAttribute('onClick', 'handler'),
      ],
      children: [JsxText('Click')],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(
      result,
      equals(
        "\$button(className: 'btn', disabled: true, onClick: handler) >> 'Click'",
      ),
    );
  });

  test('transforms components with children', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'MyComponent',
      attributes: [],
      children: [
        JsxElement(
          tagName: 'Child',
          attributes: [],
          children: [],
          isSelfClosing: true,
        ),
      ],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, equals('MyComponent(, children: Child())'));
  });

  test('transforms empty self-closing components', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'EmptyComponent',
      attributes: [],
      children: [],
      isSelfClosing: true,
    );

    final result = transformer.transform(element);
    expect(result, equals('EmptyComponent()'));
  });

  test('parses deeply nested elements (3+ levels)', () {
    final parser = JsxParser(
      '<div><section><article><header><h1>Deep</h1></header></article></section></div>',
    );
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final div = (result as Success<JsxNode, String>).value as JsxElement;
    expect(div.tagName, equals('div'));
    expect(div.children.length, equals(1));

    final section = div.children[0] as JsxElement;
    expect(section.tagName, equals('section'));
    expect(section.children.length, equals(1));

    final article = section.children[0] as JsxElement;
    expect(article.tagName, equals('article'));
    expect(article.children.length, equals(1));

    final header = article.children[0] as JsxElement;
    expect(header.tagName, equals('header'));
    expect(header.children.length, equals(1));

    final h1 = header.children[0] as JsxElement;
    expect(h1.tagName, equals('h1'));
    expect(h1.children.length, equals(1));
    expect((h1.children[0] as JsxText).text, equals('Deep'));
  });

  test('transforms deeply nested elements (3+ levels)', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'div',
      attributes: [],
      children: [
        JsxElement(
          tagName: 'section',
          attributes: [],
          children: [
            JsxElement(
              tagName: 'article',
              attributes: [],
              children: [
                JsxElement(
                  tagName: 'header',
                  attributes: [],
                  children: [
                    JsxElement(
                      tagName: 'h1',
                      attributes: [],
                      children: [JsxText('Deep')],
                      isSelfClosing: false,
                    ),
                  ],
                  isSelfClosing: false,
                ),
              ],
              isSelfClosing: false,
            ),
          ],
          isSelfClosing: false,
        ),
      ],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, contains('\$div'));
    expect(result, contains('\$section'));
    expect(result, contains('\$article'));
    expect(result, contains('\$header'));
    expect(result, contains('\$h1'));
    expect(result, contains('\'Deep\''));
  });

  test('parses mixed children (text + elements + expressions)', () {
    final parser = JsxParser(
      '<div>Hello <strong>world</strong> {count} items</div>',
    );
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.tagName, equals('div'));
    expect(element.children.length, equals(4));

    expect((element.children[0] as JsxText).text, equals('Hello'));
    expect((element.children[1] as JsxElement).tagName, equals('strong'));
    expect((element.children[2] as JsxExpression).expression, equals('count'));
    expect((element.children[3] as JsxText).text, equals('items'));
  });

  test('transforms mixed children (text + elements + expressions)', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'div',
      attributes: [],
      children: [
        JsxText('Hello '),
        JsxElement(
          tagName: 'strong',
          attributes: [],
          children: [JsxText('world')],
          isSelfClosing: false,
        ),
        JsxExpression('count'),
        JsxText(' items'),
      ],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, contains('\$div() >> ['));
    expect(result, contains('\'Hello \''));
    expect(result, contains('\$strong >> \'world\''));
    expect(result, contains('count'));
    expect(result, contains('\' items\''));
  });

  test('parses single quotes in double-quoted attributes', () {
    final parser = JsxParser('<div title="It\'s working">Text</div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.attributes.length, equals(1));

    final attr = element.attributes[0] as JsxStringAttribute;
    expect(attr.name, equals('title'));
    expect(attr.value, equals('It\'s working'));
  });

  test('parses double quotes in single-quoted attributes', () {
    final parser = JsxParser("<div title='Say \"hi\"'>Text</div>");
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.attributes.length, equals(1));

    final attr = element.attributes[0] as JsxStringAttribute;
    expect(attr.name, equals('title'));
    expect(attr.value, equals('Say "hi"'));
  });

  test('parses attributes with special characters', () {
    final parser = JsxParser('<div data-test="value-with-dashes">Text</div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.attributes.length, equals(1));

    final attr = element.attributes[0] as JsxStringAttribute;
    expect(attr.name, equals('data-test'));
    expect(attr.value, equals('value-with-dashes'));
  });

  test('parses deeply nested mixed content', () {
    final parser = JsxParser(
      '<div><p>Text {expr1} more</p><span>{expr2}</span></div>',
    );
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final div = (result as Success<JsxNode, String>).value as JsxElement;
    expect(div.tagName, equals('div'));
    expect(div.children.length, equals(2));

    final p = div.children[0] as JsxElement;
    expect(p.tagName, equals('p'));
    expect(p.children.length, equals(3));
    expect((p.children[0] as JsxText).text, equals('Text'));
    expect((p.children[1] as JsxExpression).expression, equals('expr1'));
    expect((p.children[2] as JsxText).text, equals('more'));

    final span = div.children[1] as JsxElement;
    expect(span.tagName, equals('span'));
    expect(span.children.length, equals(1));
    expect((span.children[0] as JsxExpression).expression, equals('expr2'));
  });

  test('parses complex nested structure with multiple levels', () {
    final parser = JsxParser(
      '<ul><li><a href="#">Link 1</a></li><li><a href="#">Link 2</a></li></ul>',
    );
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final ul = (result as Success<JsxNode, String>).value as JsxElement;
    expect(ul.tagName, equals('ul'));
    expect(ul.children.length, equals(2));

    final li1 = ul.children[0] as JsxElement;
    expect(li1.tagName, equals('li'));
    expect(li1.children.length, equals(1));

    final a1 = li1.children[0] as JsxElement;
    expect(a1.tagName, equals('a'));
    expect(a1.attributes.length, equals(1));
    expect((a1.attributes[0] as JsxStringAttribute).value, equals('#'));
    expect((a1.children[0] as JsxText).text, equals('Link 1'));
  });

  test('transpiles complex nested structure', () {
    const source = '''
final nav = <nav className="menu">
  <ul>
    <li><a href="/home">Home</a></li>
    <li><a href="/about">About</a></li>
  </ul>
</nav>;
''';

    final result = transpileJsx(source);
    expect(result.isSuccess, isTrue);

    final output = (result as Success<String, String>).value;
    expect(output, contains('\$nav(className: \'menu\')'));
    expect(output, contains('\$ul'));
    expect(output, contains('\$li'));
    expect(output, contains('\$a(href: \'/home\')'));
    expect(output, contains('\'Home\''));
    expect(output, contains('\$a(href: \'/about\')'));
    expect(output, contains('\'About\''));
  });

  test('parses elements with multiple expressions and text', () {
    final parser = JsxParser(
      '<div>Count: {count}, Total: {total}, Status: {status}</div>',
    );
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.children.length, equals(6));
    expect((element.children[0] as JsxText).text, equals('Count:'));
    expect((element.children[1] as JsxExpression).expression, equals('count'));
    expect((element.children[2] as JsxText).text, equals(', Total:'));
    expect((element.children[3] as JsxExpression).expression, equals('total'));
    expect((element.children[4] as JsxText).text, equals(', Status:'));
    expect((element.children[5] as JsxExpression).expression, equals('status'));
  });

  test('transforms complex mixed children correctly', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'p',
      attributes: [],
      children: [
        JsxText('Value:'),
        JsxExpression('x'),
        JsxText('+'),
        JsxExpression('y'),
        JsxText('='),
        JsxExpression('x + y'),
      ],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, contains('\$p() >> ['));
    expect(result, contains('\'Value:\''));
    expect(result, contains('x'));
    expect(result, contains('\'+\''));
    expect(result, contains('y'));
    expect(result, contains('\'=\''));
    expect(result, contains('x + y'));
  });

  // ============================================================================
  // GETTER ELEMENT TESTS - h1-h6, strong, em, code are getters in dart_node_react
  // They should NOT have () appended when used without props
  // ============================================================================

  test('h1 without props uses getter syntax (no parentheses)', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'h1',
      attributes: [],
      children: [JsxText('Title')],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    // $h1 is a getter in dart_node_react, NOT a function
    // So it should be: $h1 >> 'Title'  NOT  $h1() >> 'Title'
    expect(result, equals("\$h1 >> 'Title'"));
  });

  test('h2 without props uses getter syntax (no parentheses)', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'h2',
      attributes: [],
      children: [JsxText('Subtitle')],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, equals("\$h2 >> 'Subtitle'"));
  });

  test('h3 without props uses getter syntax (no parentheses)', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'h3',
      attributes: [],
      children: [JsxText('Section')],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, equals("\$h3 >> 'Section'"));
  });

  test('strong without props uses getter syntax (no parentheses)', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'strong',
      attributes: [],
      children: [JsxText('Bold')],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, equals("\$strong >> 'Bold'"));
  });

  test('em without props uses getter syntax (no parentheses)', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'em',
      attributes: [],
      children: [JsxText('Italic')],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, equals("\$em >> 'Italic'"));
  });

  test('code without props uses getter syntax (no parentheses)', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'code',
      attributes: [],
      children: [JsxText('snippet')],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, equals("\$code >> 'snippet'"));
  });

  test('h1 with props uses h1Props function', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'h1',
      attributes: [JsxStringAttribute('className', 'title')],
      children: [JsxText('Title')],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, equals("\$h1Props(className: 'title') >> 'Title'"));
  });

  test('h2 with props uses h2Props function', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'h2',
      attributes: [JsxStringAttribute('id', 'subtitle')],
      children: [JsxText('Subtitle')],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, equals("\$h2Props(id: 'subtitle') >> 'Subtitle'"));
  });

  test('empty h1 (no children, no props) uses getter syntax', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'h1',
      attributes: [],
      children: [],
      isSelfClosing: true,
    );

    final result = transformer.transform(element);
    expect(result, equals('\$h1'));
  });

  test('nested getter elements use correct syntax', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'div',
      attributes: [],
      children: [
        JsxElement(
          tagName: 'h1',
          attributes: [],
          children: [JsxText('Header')],
          isSelfClosing: false,
        ),
        JsxElement(
          tagName: 'h2',
          attributes: [],
          children: [JsxText('Subheader')],
          isSelfClosing: false,
        ),
      ],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, contains("\$h1 >> 'Header'"));
    expect(result, contains("\$h2 >> 'Subheader'"));
    // Should NOT contain $h1() or $h2()
    expect(result.contains('\$h1()'), isFalse);
    expect(result.contains('\$h2()'), isFalse);
  });

  test('parses empty element with opening and closing tags', () {
    final parser = JsxParser('<div></div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.tagName, equals('div'));
    expect(element.children, isEmpty);
    expect(element.isSelfClosing, isFalse);
  });

  test('parses self-closing br tag', () {
    final parser = JsxParser('<br />');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.tagName, equals('br'));
    expect(element.isSelfClosing, isTrue);
    expect(element.children, isEmpty);
  });

  test('parses deeply nested elements (6 levels)', () {
    final parser = JsxParser(
      '<div><nav><ul><li><a><span>Deep</span></a></li></ul></nav></div>',
    );
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    var current = (result as Success<JsxNode, String>).value as JsxElement;
    expect(current.tagName, equals('div'));
    expect(current.children.length, equals(1));

    current = current.children[0] as JsxElement;
    expect(current.tagName, equals('nav'));

    current = current.children[0] as JsxElement;
    expect(current.tagName, equals('ul'));

    current = current.children[0] as JsxElement;
    expect(current.tagName, equals('li'));

    current = current.children[0] as JsxElement;
    expect(current.tagName, equals('a'));

    current = current.children[0] as JsxElement;
    expect(current.tagName, equals('span'));
    expect((current.children[0] as JsxText).text, equals('Deep'));
  });

  test('parses numeric attribute with expression', () {
    final parser = JsxParser('<input tabIndex={0} />');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    final attr = element.attributes.first as JsxExpressionAttribute;
    expect(attr.name, equals('tabIndex'));
    expect(attr.expression, equals('0'));
  });

  test('parses template literal in expression', () {
    final parser = JsxParser('<div className={`test-\${id}`}>Text</div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    final attr = element.attributes.first as JsxExpressionAttribute;
    expect(attr.name, equals('className'));
    expect(attr.expression, contains('`test-\${id}`'));
  });

  test('parses special characters in text content', () {
    final parser = JsxParser('<div>&copy; 2024 &amp; &lt;Company&gt;</div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.children.length, equals(1));
    final text = element.children[0] as JsxText;
    expect(text.text, contains('&copy;'));
    expect(text.text, contains('&amp;'));
  });

  test('parses escaped backslash in string attribute', () {
    final parser = JsxParser(r'<div title="path\\to\\file">Text</div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    final attr = element.attributes.first as JsxStringAttribute;
    expect(attr.value, equals(r'path\\to\\file'));
  });

  test('returns error for unclosed tag', () {
    final parser = JsxParser('<div>Content');
    final result = parser.parse();

    expect(result.isError, isTrue);
    final error = (result as Error<JsxNode, String>).error;
    expect(error, contains('Expected closing tag'));
  });

  test('returns error for mismatched tags', () {
    final parser = JsxParser('<div>Content</span>');
    final result = parser.parse();

    expect(result.isError, isTrue);
    final error = (result as Error<JsxNode, String>).error;
    expect(error, contains('position'));
  });

  test('parses unclosed fragment as error', () {
    final parser = JsxParser('<>Content');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final fragment = (result as Success<JsxNode, String>).value as JsxFragment;
    expect(fragment.children.length, equals(1));
  });

  test('returns error for empty JSX input', () {
    final parser = JsxParser('');
    final result = parser.parse();

    expect(result.isError, isTrue);
    final error = (result as Error<JsxNode, String>).error;
    expect(error, equals('Empty JSX input'));
  });

  test('returns error for whitespace-only input', () {
    final parser = JsxParser('   \n\t  ');
    final result = parser.parse();

    expect(result.isError, isTrue);
    final error = (result as Error<JsxNode, String>).error;
    expect(error, equals('Empty JSX input'));
  });

  test('returns error for missing tag name', () {
    final parser = JsxParser('<>Content</>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final fragment = (result as Success<JsxNode, String>).value as JsxFragment;
    expect(fragment.children.length, equals(1));
  });

  test('parses fragment with empty content', () {
    final parser = JsxParser('<></>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final fragment = (result as Success<JsxNode, String>).value as JsxFragment;
    expect(fragment.children, isEmpty);
  });

  test('parses nested fragments', () {
    final parser = JsxParser('<><><div>Inner</div></></>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final outerFragment =
        (result as Success<JsxNode, String>).value as JsxFragment;
    expect(outerFragment.children.length, equals(1));

    final innerFragment = outerFragment.children[0] as JsxFragment;
    expect(innerFragment.children.length, equals(1));

    final div = innerFragment.children[0] as JsxElement;
    expect(div.tagName, equals('div'));
  });

  test('parses complex nested expressions', () {
    final parser = JsxParser(
      '<div>{items.map((item) => <span key={item.id}>{item.name}</span>)}</div>',
    );
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    final expr = element.children.first as JsxExpression;
    expect(expr.expression, contains('items.map'));
    expect(expr.expression, contains('<span key={item.id}>{item.name}</span>'));
  });

  test('parses attribute with nested braces', () {
    final parser = JsxParser(
      '<div style={{color: "red", fontSize: 14}}>Text</div>',
    );
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    final attr = element.attributes.first as JsxExpressionAttribute;
    expect(attr.name, equals('style'));
    expect(attr.expression, contains('{color: "red", fontSize: 14}'));
  });

  test('parses multiple boolean attributes', () {
    final parser = JsxParser('<input disabled readOnly required />');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.attributes.length, equals(3));

    expect(
      (element.attributes[0] as JsxBooleanAttribute).name,
      equals('disabled'),
    );
    expect(
      (element.attributes[1] as JsxBooleanAttribute).name,
      equals('readOnly'),
    );
    expect(
      (element.attributes[2] as JsxBooleanAttribute).name,
      equals('required'),
    );
  });

  test('parses mix of attribute types', () {
    final parser = JsxParser(
      '<button type="submit" disabled onClick={handler} {...props}>Submit</button>',
    );
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.attributes.length, equals(4));

    expect(element.attributes[0], isA<JsxStringAttribute>());
    expect(element.attributes[1], isA<JsxBooleanAttribute>());
    expect(element.attributes[2], isA<JsxExpressionAttribute>());
    expect(element.attributes[3], isA<JsxSpreadAttribute>());
  });

  test('returns error for invalid attribute syntax', () {
    final parser = JsxParser('<div className=>Text</div>');
    final result = parser.parse();

    expect(result.isError, isTrue);
    final error = (result as Error<JsxNode, String>).error;
    expect(error, contains('Expected'));
  });

  test('parses whitespace-heavy JSX', () {
    final parser = JsxParser('''
      <div
        className  =  "test"
        id  =  "main"
      >
        Text content
      </div>
    ''');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.tagName, equals('div'));
    expect(element.attributes.length, equals(2));
    expect(element.children.length, equals(1));
  });

  test('parses JSX with newlines in text', () {
    final parser = JsxParser('<div>Line 1\nLine 2\nLine 3</div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    final text = element.children.first as JsxText;
    expect(text.text, contains('Line 1'));
    expect(text.text, contains('Line 2'));
    expect(text.text, contains('Line 3'));
  });

  test('transforms special characters in text', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'div',
      attributes: [],
      children: [JsxText("Text with 'quotes' and \"double quotes\"")],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, contains("\\'"));
  });

  test('transforms newlines in text content', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'div',
      attributes: [],
      children: [JsxText('Line 1\nLine 2')],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, contains('\\n'));
  });

  test('parses very deeply nested elements (10 levels)', () {
    final parser = JsxParser(
      '<a><b><c><d><e><f><g><h><i><j>Deep</j></i></h></g></f></e></d></c></b></a>',
    );
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    var depth = 0;
    var current = (result as Success<JsxNode, String>).value as JsxElement;

    while (current.children.isNotEmpty &&
        current.children.first is JsxElement) {
      depth++;
      current = current.children.first as JsxElement;
    }

    expect(depth, equals(9));
    expect(current.tagName, equals('j'));
    expect((current.children.first as JsxText).text, equals('Deep'));
  });

  test('parses fragment with mixed content types', () {
    final parser = JsxParser('<>Text {expr} <div>Element</div> more text</>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final fragment = (result as Success<JsxNode, String>).value as JsxFragment;
    expect(fragment.children.length, equals(4));

    expect(fragment.children[0], isA<JsxText>());
    expect(fragment.children[1], isA<JsxExpression>());
    expect(fragment.children[2], isA<JsxElement>());
    expect(fragment.children[3], isA<JsxText>());
  });

  test('transforms empty element correctly', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'div',
      attributes: [],
      children: [],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, equals('\$div()'));
  });

  test('transforms self-closing element with attributes', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'input',
      attributes: [
        JsxStringAttribute('type', 'text'),
        JsxBooleanAttribute('disabled'),
      ],
      children: [],
      isSelfClosing: true,
    );

    final result = transformer.transform(element);
    expect(result, equals("\$input(type: 'text', disabled: true)"));
  });

  test('error message includes position for mismatched closing tag', () {
    final parser = JsxParser('<div><span>Content</div>');
    final result = parser.parse();

    expect(result.isError, isTrue);
    final error = (result as Error<JsxNode, String>).error;
    expect(error, contains('position'));
  });

  test('parses expression with arrow functions and JSX', () {
    final parser = JsxParser('<div>{() => <span>Content</span>}</div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    final expr = element.children.first as JsxExpression;
    expect(expr.expression, contains('() => <span>Content</span>'));
  });

  test('parses expression with ternary containing JSX', () {
    final parser = JsxParser(
      '<div>{condition ? <span>Yes</span> : <span>No</span>}</div>',
    );
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    final expr = element.children.first as JsxExpression;
    expect(
      expr.expression,
      contains('condition ? <span>Yes</span> : <span>No</span>'),
    );
  });

  test('parses self-closing tag without space before slash', () {
    final parser = JsxParser('<input/>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.tagName, equals('input'));
    expect(element.isSelfClosing, isTrue);
    expect(element.children, isEmpty);
  });

  test('parses multiple consecutive expressions', () {
    final parser = JsxParser('<div>{a}{b}{c}</div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.children.length, equals(3));
    expect((element.children[0] as JsxExpression).expression, equals('a'));
    expect((element.children[1] as JsxExpression).expression, equals('b'));
    expect((element.children[2] as JsxExpression).expression, equals('c'));
  });

  test('parses empty string attribute', () {
    final parser = JsxParser('<div className="">Text</div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.attributes.length, equals(1));
    final attr = element.attributes.first as JsxStringAttribute;
    expect(attr.name, equals('className'));
    expect(attr.value, equals(''));
  });

  test('returns error for unclosed expression brace', () {
    final parser = JsxParser('<div>{expr</div>');
    final result = parser.parse();

    expect(result.isSuccess, isFalse);
  });

  test('parses unicode characters in text content', () {
    final parser = JsxParser('<div>Hello 世界 🌍</div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    final text = element.children.first as JsxText;
    expect(text.text, equals('Hello 世界 🌍'));
  });

  test('parses unicode characters in attribute values', () {
    final parser = JsxParser('<div title="Hello 世界">Text</div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    final attr = element.attributes.first as JsxStringAttribute;
    expect(attr.value, equals('Hello 世界'));
  });

  test('parses self-closing tag with attributes', () {
    final parser = JsxParser('<img src="image.png" alt="Description" />');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.tagName, equals('img'));
    expect(element.isSelfClosing, isTrue);
    expect(element.attributes.length, equals(2));
    expect((element.attributes[0] as JsxStringAttribute).name, equals('src'));
    expect((element.attributes[1] as JsxStringAttribute).name, equals('alt'));
  });

  test('parses very long attribute value', () {
    final longValue = 'a' * 1000;
    final parser = JsxParser('<div data-long="$longValue">Text</div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    final attr = element.attributes.first as JsxStringAttribute;
    expect(attr.value, equals(longValue));
  });

  test('parses element with only whitespace between tags', () {
    final parser = JsxParser('<div>   \n\t   </div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.children, isEmpty);
  });

  test('parses deeply nested expressions with multiple brace levels', () {
    final parser = JsxParser(
      '<div>{obj.prop[func({nested: {deep: true}})]}</div>',
    );
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    final expr = element.children.first as JsxExpression;
    expect(expr.expression, contains('obj.prop[func({nested: {deep: true}})]'));
  });

  test('parses multiple spread attributes', () {
    final parser = JsxParser(
      '<div {...props1} {...props2} className="test">Text</div>',
    );
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.attributes.length, equals(3));
    expect(element.attributes[0], isA<JsxSpreadAttribute>());
    expect(element.attributes[1], isA<JsxSpreadAttribute>());
    expect(element.attributes[2], isA<JsxStringAttribute>());
  });

  test('parses element with many children (stress test)', () {
    final children = List.generate(100, (i) => '<span>Item $i</span>').join();
    final parser = JsxParser('<div>$children</div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.children.length, equals(100));
  });

  test('returns error for tag with invalid character in name', () {
    final parser = JsxParser('<div@invalid>Content</div@invalid>');
    final result = parser.parse();

    expect(result.isSuccess, isFalse);
  });

  test('parses nested fragments correctly', () {
    final parser = JsxParser(
      '<div><><span>A</span></><><span>B</span></></div>',
    );
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final div = (result as Success<JsxNode, String>).value as JsxElement;
    expect(div.children.length, equals(2));
    expect(div.children[0], isA<JsxFragment>());
    expect(div.children[1], isA<JsxFragment>());
  });

  test('parses attribute with array expression', () {
    final parser = JsxParser('<div data-items={[1, 2, 3]}>Text</div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    final attr = element.attributes.first as JsxExpressionAttribute;
    expect(attr.expression, equals('[1, 2, 3]'));
  });

  test('parses attribute with object expression', () {
    final parser = JsxParser(
      '<div style={{margin: 10, padding: 20}}>Text</div>',
    );
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    final attr = element.attributes.first as JsxExpressionAttribute;
    expect(attr.expression, contains('{margin: 10, padding: 20}'));
  });

  test('parses mixed whitespace in attributes', () {
    final parser = JsxParser(
      '<div\n  className="test"\n  id="main"\n>Text</div>',
    );
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    expect(element.attributes.length, equals(2));
  });

  test('parses expression with string containing JSX-like syntax', () {
    final parser = JsxParser('<div>{"<not>JSX</not>"}</div>');
    final result = parser.parse();

    expect(result.isSuccess, isTrue);
    final element = (result as Success<JsxNode, String>).value as JsxElement;
    final expr = element.children.first as JsxExpression;
    expect(expr.expression, equals('"<not>JSX</not>"'));
  });

  test('transforms multiple consecutive expressions correctly', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'div',
      attributes: [],
      children: [JsxExpression('a'), JsxExpression('b'), JsxExpression('c')],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, equals('\$div() >> [a, b, c]'));
  });

  test('transforms empty string attribute correctly', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'div',
      attributes: [JsxStringAttribute('className', '')],
      children: [JsxText('Text')],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, equals("\$div(className: '') >> 'Text'"));
  });

  test('transforms unicode text correctly', () {
    final transformer = JsxTransformer();
    final element = JsxElement(
      tagName: 'div',
      attributes: [],
      children: [JsxText('Hello 世界 🌍')],
      isSelfClosing: false,
    );

    final result = transformer.transform(element);
    expect(result, equals("\$div() >> 'Hello 世界 🌍'"));
  });

  test('parses closing tag with whitespace', () {
    final parser = JsxParser('<div>Content< / div>');
    final result = parser.parse();

    expect(result.isError, isTrue);
  });

  test('returns error for missing closing bracket on self-closing tag', () {
    final parser = JsxParser('<br /');
    final result = parser.parse();

    expect(result.isSuccess, isFalse);
  });
}
