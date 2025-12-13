/// UI interaction tests for the Counter component.
///
/// Tests verify actual user interactions using the Counter component.
/// Run with: dart test -p chrome
@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:jsx_demo/counter.g.dart';
import 'package:test/test.dart';

void main() {
  late JSAny counterComponent;

  setUp(() {
    counterComponent = registerFunctionComponent((props) => Counter());
  });

  test('counter initializes at 0', () {
    final result = render(fc(counterComponent));

    expect(result.container.textContent, contains('Dart + JSX'));
    expect(result.container.querySelector('.value')!.textContent, '0');

    result.unmount();
  });

  test('increment button increases count', () {
    final result = render(fc(counterComponent));

    expect(result.container.querySelector('.value')!.textContent, '0');

    final incrementBtn = result.container.querySelector('.btn-inc')!;
    fireClick(incrementBtn);
    expect(result.container.querySelector('.value')!.textContent, '1');

    fireClick(incrementBtn);
    expect(result.container.querySelector('.value')!.textContent, '2');

    result.unmount();
  });

  test('decrement button decreases count', () {
    final result = render(fc(counterComponent));

    expect(result.container.querySelector('.value')!.textContent, '0');

    final decrementBtn = result.container.querySelector('.btn-dec')!;
    fireClick(decrementBtn);
    expect(result.container.querySelector('.value')!.textContent, '-1');

    fireClick(decrementBtn);
    expect(result.container.querySelector('.value')!.textContent, '-2');

    result.unmount();
  });

  test('reset button sets count back to 0', () {
    final result = render(fc(counterComponent));

    final incrementBtn = result.container.querySelector('.btn-inc')!;
    final resetBtn = result.container.querySelector('.btn-reset')!;

    fireClick(incrementBtn);
    fireClick(incrementBtn);
    fireClick(incrementBtn);
    expect(result.container.querySelector('.value')!.textContent, '3');

    fireClick(resetBtn);
    expect(result.container.querySelector('.value')!.textContent, '0');

    result.unmount();
  });

  test('increment and decrement work together', () {
    final result = render(fc(counterComponent));

    final incrementBtn = result.container.querySelector('.btn-inc')!;
    final decrementBtn = result.container.querySelector('.btn-dec')!;

    fireClick(incrementBtn);
    fireClick(incrementBtn);
    fireClick(incrementBtn);
    expect(result.container.querySelector('.value')!.textContent, '3');

    fireClick(decrementBtn);
    expect(result.container.querySelector('.value')!.textContent, '2');

    fireClick(decrementBtn);
    expect(result.container.querySelector('.value')!.textContent, '1');

    fireClick(decrementBtn);
    expect(result.container.querySelector('.value')!.textContent, '0');

    fireClick(decrementBtn);
    expect(result.container.querySelector('.value')!.textContent, '-1');

    result.unmount();
  });

  test('rapid clicks all register', () {
    final result = render(fc(counterComponent));

    final incrementBtn = result.container.querySelector('.btn-inc')!;

    for (var i = 1; i <= 10; i++) {
      fireClick(incrementBtn);
      expect(result.container.querySelector('.value')!.textContent, '$i');
    }

    result.unmount();
  });

  test('all buttons are rendered with correct classes', () {
    final result = render(fc(counterComponent));

    expect(result.container.querySelector('.btn-inc'), isNotNull);
    expect(result.container.querySelector('.btn-dec'), isNotNull);
    expect(result.container.querySelector('.btn-reset'), isNotNull);
    expect(result.container.querySelector('.value'), isNotNull);
    expect(result.container.querySelector('.counter'), isNotNull);
    expect(result.container.querySelector('.buttons'), isNotNull);

    result.unmount();
  });
}
