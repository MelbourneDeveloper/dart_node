/// Tests for useStateJSArray hook functionality.
@TestOn('js')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('initializes with empty array', () {
    final listComponent = registerFunctionComponent((props) {
      final items = useStateJSArray<JSObject>(<JSObject>[].toJS);
      return pEl(
        'Count: ${items.value.length}',
        props: {'data-testid': 'count'},
      );
    });

    final result = render(fc(listComponent));

    expect(result.getByTestId('count').textContent, equals('Count: 0'));
    result.unmount();
  });

  test('adds items with set', () {
    final listComponent = registerFunctionComponent((props) {
      final items = useStateJSArray<JSObject>(<JSObject>[].toJS);
      return div(
        children: [
          pEl('Count: ${items.value.length}', props: {'data-testid': 'count'}),
          button(
            text: 'Add',
            props: {'data-testid': 'add'},
            onClick: () {
              final newItem = {'name': 'Item ${items.value.length}'}.jsify()!;
              items.set([...items.value, newItem as JSObject]);
            },
          ),
        ],
      );
    });

    final result = render(fc(listComponent));

    expect(result.getByTestId('count').textContent, equals('Count: 0'));

    fireClick(result.getByTestId('add'));
    expect(result.getByTestId('count').textContent, equals('Count: 1'));

    fireClick(result.getByTestId('add'));
    expect(result.getByTestId('count').textContent, equals('Count: 2'));

    result.unmount();
  });

  test('updates items with setWithUpdater', () {
    final listComponent = registerFunctionComponent((props) {
      final items = useStateJSArray<JSObject>(<JSObject>[].toJS);
      return div(
        children: [
          pEl('Count: ${items.value.length}', props: {'data-testid': 'count'}),
          button(
            text: 'Add',
            props: {'data-testid': 'add'},
            onClick: () {
              items.setWithUpdater((prev) {
                final newItem = {'id': prev.length}.jsify()!;
                return [...prev, newItem as JSObject];
              });
            },
          ),
          button(
            text: 'Remove Last',
            props: {'data-testid': 'remove'},
            onClick: () {
              items.setWithUpdater(
                (prev) =>
                    prev.isEmpty ? prev : prev.sublist(0, prev.length - 1),
              );
            },
          ),
        ],
      );
    });

    final result = render(fc(listComponent));

    expect(result.getByTestId('count').textContent, equals('Count: 0'));

    fireClick(result.getByTestId('add'));
    fireClick(result.getByTestId('add'));
    fireClick(result.getByTestId('add'));
    expect(result.getByTestId('count').textContent, equals('Count: 3'));

    fireClick(result.getByTestId('remove'));
    expect(result.getByTestId('count').textContent, equals('Count: 2'));

    result.unmount();
  });

  test('renders list items from JSObject array', () {
    final listComponent = registerFunctionComponent((props) {
      final items = useStateJSArray<JSObject>(<JSObject>[].toJS);
      return div(
        children: [
          ul(
            props: {'data-testid': 'list'},
            children: items.value.map((item) {
              final name = (item['name'] as JSString?)?.toDart ?? '';
              return li(name);
            }).toList(),
          ),
          button(
            text: 'Add Apple',
            props: {'data-testid': 'add-apple'},
            onClick: () {
              items.setWithUpdater((prev) {
                final newItem = {'name': 'Apple'}.jsify()!;
                return [...prev, newItem as JSObject];
              });
            },
          ),
          button(
            text: 'Add Banana',
            props: {'data-testid': 'add-banana'},
            onClick: () {
              items.setWithUpdater((prev) {
                final newItem = {'name': 'Banana'}.jsify()!;
                return [...prev, newItem as JSObject];
              });
            },
          ),
        ],
      );
    });

    final result = render(fc(listComponent));

    expect(result.getByTestId('list').innerHTML, isEmpty);

    fireClick(result.getByTestId('add-apple'));
    expect(result.getByTestId('list').innerHTML, contains('Apple'));

    fireClick(result.getByTestId('add-banana'));
    expect(result.getByTestId('list').innerHTML, contains('Banana'));

    result.unmount();
  });

  test('filters items with setWithUpdater', () {
    final listComponent = registerFunctionComponent((props) {
      final items = useStateJSArray<JSObject>(<JSObject>[].toJS);
      return div(
        children: [
          pEl('Count: ${items.value.length}', props: {'data-testid': 'count'}),
          button(
            text: 'Add Done',
            props: {'data-testid': 'add-done'},
            onClick: () {
              items.setWithUpdater((prev) {
                final item = {'done': true}.jsify()!;
                return [...prev, item as JSObject];
              });
            },
          ),
          button(
            text: 'Add Not Done',
            props: {'data-testid': 'add-not-done'},
            onClick: () {
              items.setWithUpdater((prev) {
                final item = {'done': false}.jsify()!;
                return [...prev, item as JSObject];
              });
            },
          ),
          button(
            text: 'Remove Done',
            props: {'data-testid': 'remove-done'},
            onClick: () {
              items.setWithUpdater(
                (prev) => prev.where((item) {
                  final done = (item['done'] as JSBoolean?)?.toDart ?? false;
                  return !done;
                }).toList(),
              );
            },
          ),
        ],
      );
    });

    final result = render(fc(listComponent));

    fireClick(result.getByTestId('add-done'));
    fireClick(result.getByTestId('add-not-done'));
    fireClick(result.getByTestId('add-done'));
    expect(result.getByTestId('count').textContent, equals('Count: 3'));

    fireClick(result.getByTestId('remove-done'));
    expect(result.getByTestId('count').textContent, equals('Count: 1'));

    result.unmount();
  });

  test('maps items with setWithUpdater', () {
    final listComponent = registerFunctionComponent((props) {
      final items = useStateJSArray<JSObject>(<JSObject>[].toJS);

      int getTotal() => items.value.fold(0, (sum, item) {
        final val = (item['value'] as JSNumber?)?.toDartInt ?? 0;
        return sum + val;
      });

      return div(
        children: [
          pEl('Total: ${getTotal()}', props: {'data-testid': 'total'}),
          button(
            text: 'Add 10',
            props: {'data-testid': 'add'},
            onClick: () {
              items.setWithUpdater((prev) {
                final item = {'value': 10}.jsify()!;
                return [...prev, item as JSObject];
              });
            },
          ),
          button(
            text: 'Double All',
            props: {'data-testid': 'double'},
            onClick: () {
              items.setWithUpdater(
                (prev) => prev.map((item) {
                  final val = (item['value'] as JSNumber?)?.toDartInt ?? 0;
                  return {'value': val * 2}.jsify()! as JSObject;
                }).toList(),
              );
            },
          ),
        ],
      );
    });

    final result = render(fc(listComponent));

    fireClick(result.getByTestId('add'));
    fireClick(result.getByTestId('add'));
    expect(result.getByTestId('total').textContent, equals('Total: 20'));

    fireClick(result.getByTestId('double'));
    expect(result.getByTestId('total').textContent, equals('Total: 40'));

    result.unmount();
  });
}
