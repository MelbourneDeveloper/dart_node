/// Tests for HTML elements functionality.
@TestOn('js')
library;

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('all common elements render correctly', () {
    final elements = registerFunctionComponent(
      (props) => div(
        children: [
          h1('Heading 1', props: {'data-testid': 'h1'}),
          h2('Heading 2', props: {'data-testid': 'h2'}),
          pEl('Paragraph', props: {'data-testid': 'p'}),
          span('Span text', props: {'data-testid': 'span'}),
          button(text: 'Button', props: {'data-testid': 'button'}),
          a(href: '#', text: 'Link', props: {'data-testid': 'a'}),
        ],
      ),
    );

    final result = render(fc(elements));

    expect(result.getByTestId('h1').textContent, equals('Heading 1'));
    expect(result.getByTestId('h2').textContent, equals('Heading 2'));
    expect(result.getByTestId('p').textContent, equals('Paragraph'));
    expect(result.getByTestId('span').textContent, equals('Span text'));
    expect(result.getByTestId('button').textContent, equals('Button'));
    expect(result.getByTestId('a').textContent, equals('Link'));

    result.unmount();
  });

  test('input types render correctly', () {
    final inputs = registerFunctionComponent(
      (props) => div(
        children: [
          input(type: 'text', props: {'data-testid': 'text'}),
          input(type: 'password', props: {'data-testid': 'password'}),
          input(type: 'checkbox', props: {'data-testid': 'checkbox'}),
          input(type: 'radio', props: {'data-testid': 'radio'}),
        ],
      ),
    );

    final result = render(fc(inputs));

    expect(result.getByTestId('text'), isNotNull);
    expect(result.getByTestId('password'), isNotNull);
    expect(result.getByTestId('checkbox'), isNotNull);
    expect(result.getByTestId('radio'), isNotNull);

    result.unmount();
  });

  test('list elements render correctly', () {
    final listEl = registerFunctionComponent(
      (props) => ul(
        props: {'data-testid': 'list'},
        children: [li('Item 1'), li('Item 2'), li('Item 3')],
      ),
    );

    final result = render(fc(listEl));

    expect(result.getByTestId('list').innerHTML, contains('Item 1'));
    expect(result.getByTestId('list').innerHTML, contains('Item 2'));
    expect(result.getByTestId('list').innerHTML, contains('Item 3'));

    result.unmount();
  });

  test('image element renders with attributes', () {
    final imageEl = registerFunctionComponent(
      (props) => img(
        src: 'test.png',
        alt: 'Test image',
        props: {'data-testid': 'img'},
      ),
    );

    final result = render(fc(imageEl));

    final imgEl = result.getByTestId('img');
    expect(imgEl.getAttribute('src'), equals('test.png'));
    expect(imgEl.getAttribute('alt'), equals('Test image'));

    result.unmount();
  });
}
