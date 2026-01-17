/// Tests for JSX DSL functionality.
@TestOn('js')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('creates element with text child using >> operator', () {
    final component = registerFunctionComponent((props) => $h1 >> 'Hello JSX');

    final result = render(fc(component));
    expect(result.container.textContent, equals('Hello JSX'));
    result.unmount();
  });

  test('creates nested elements with >> operator', () {
    final component = registerFunctionComponent(
      (props) =>
          $div(spread: {'data-testid': 'container'}) >>
          [$h1 >> 'Title', $p() >> 'Content'],
    );

    final result = render(fc(component));
    final container = result.getByTestId('container');
    expect(container.textContent, contains('Title'));
    expect(container.textContent, contains('Content'));
    result.unmount();
  });

  test(r'$div with className creates element', () {
    final component = registerFunctionComponent(
      (props) =>
          $div(className: 'my-class', spread: {'data-testid': 'styled'}) >>
          'Styled',
    );

    final result = render(fc(component));
    final el = result.getByTestId('styled');
    expect(el.className, equals('my-class'));
    result.unmount();
  });

  test(r'$button with onClick handler works', () {
    final component = registerFunctionComponent((props) {
      final count = useState(0);
      return $div() >>
          [
            $span(spread: {'data-testid': 'count'}) >> 'Count: ${count.value}',
            $button(
                  onClick: () => count.set(count.value + 1),
                  spread: {'data-testid': 'btn'},
                ) >>
                'Click',
          ];
    });

    final result = render(fc(component));
    expect(result.getByTestId('count').textContent, equals('Count: 0'));
    fireClick(result.getByTestId('btn'));
    expect(result.getByTestId('count').textContent, equals('Count: 1'));
    result.unmount();
  });

  test(r'$input with onChange handler works', () {
    final component = registerFunctionComponent((props) {
      final text = useState('');
      return $div() >>
          [
            $input(
              type: 'text',
              value: text.value,
              onChange: (e) {
                final target = e.target;
                if (target case final JSObject t) {
                  final value = t['value'];
                  if (value case final JSString s) text.set(s.toDart);
                }
              },
              spread: {'data-testid': 'input'},
            ),
            $span(spread: {'data-testid': 'output'}) >> 'Value: ${text.value}',
          ];
    });

    final result = render(fc(component));
    final inputEl = result.getByTestId('input');
    fireChange(inputEl, value: 'Hello');
    expect(result.getByTestId('output').textContent, equals('Value: Hello'));
    result.unmount();
  });

  test(r'$ul and $li create lists', () {
    final component = registerFunctionComponent(
      (props) =>
          $ul(spread: {'data-testid': 'list'}) >>
          [$li() >> 'Item 1', $li() >> 'Item 2', $li() >> 'Item 3'],
    );

    final result = render(fc(component));
    final list = result.getByTestId('list');
    expect(list.textContent, contains('Item 1'));
    expect(list.textContent, contains('Item 2'));
    expect(list.textContent, contains('Item 3'));
    result.unmount();
  });

  test(r'$fragment groups elements without wrapper', () {
    final component = registerFunctionComponent(
      (props) => $fragment >> [$h1 >> 'First', $h2 >> 'Second'],
    );

    final result = render(fc(component));
    expect(result.container.textContent, contains('First'));
    expect(result.container.textContent, contains('Second'));
    result.unmount();
  });

  test('conditional rendering with null children', () {
    final component = registerFunctionComponent((props) {
      final show = useState(false);
      return $div() >>
          [
            $button(
                  onClick: () => show.set(!show.value),
                  spread: {'data-testid': 'toggle'},
                ) >>
                'Toggle',
            if (show.value) $p(spread: {'data-testid': 'content'}) >> 'Visible',
          ];
    });

    final result = render(fc(component));
    expect(result.queryByTestId('content'), isNull);
    fireClick(result.getByTestId('toggle'));
    expect(result.getByTestId('content').textContent, equals('Visible'));
    result.unmount();
  });

  test('numeric children are converted to string', () {
    final component = registerFunctionComponent(
      (props) => $span(spread: {'data-testid': 'num'}) >> 42,
    );

    final result = render(fc(component));
    expect(result.getByTestId('num').textContent, equals('42'));
    result.unmount();
  });

  test('El elements can be used as children', () {
    final component = registerFunctionComponent((props) {
      final child = $span() >> 'Inner';
      return $div(spread: {'data-testid': 'outer'}) >> child;
    });

    final result = render(fc(component));
    expect(result.getByTestId('outer').textContent, equals('Inner'));
    result.unmount();
  });

  test(r'$a creates anchor with href', () {
    final component = registerFunctionComponent(
      (props) =>
          $a(href: 'https://example.com', spread: {'data-testid': 'link'}) >>
          'Click me',
    );

    final result = render(fc(component));
    final link = result.getByTestId('link');
    expect(link.textContent, equals('Click me'));
    expect(link.getAttribute('href'), isNotNull);
    result.unmount();
  });

  test('semantic elements work correctly', () {
    final component = registerFunctionComponent(
      (props) =>
          $main(spread: {'data-testid': 'main'}) >>
          [
            $header() >> [$h1 >> 'Header'],
            $section() >> [$p() >> 'Section content'],
            $footer() >> [$span() >> 'Footer'],
          ],
    );

    final result = render(fc(component));
    final mainEl = result.getByTestId('main');
    expect(mainEl.textContent, contains('Header'));
    expect(mainEl.textContent, contains('Section content'));
    expect(mainEl.textContent, contains('Footer'));
    result.unmount();
  });
}
