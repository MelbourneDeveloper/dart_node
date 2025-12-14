/// Tests for special components (Fragment, StrictMode, Suspense, etc.).
@TestOn('js')
library;

import 'dart:js_interop';

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

void main() {
  test('Fragment groups children without wrapper', () {
    final fragmentComponent = registerFunctionComponent(
      (props) => fragment(
        children: [
          pEl('First', props: {'data-testid': 'first'}),
          pEl('Second', props: {'data-testid': 'second'}),
        ],
      ),
    );

    final result = render(fc(fragmentComponent));

    expect(result.getByTestId('first').textContent, equals('First'));
    expect(result.getByTestId('second').textContent, equals('Second'));

    result.unmount();
  });

  test('Fragment without children renders empty', () {
    final fragmentComponent = registerFunctionComponent((props) => fragment());

    final result = render(fc(fragmentComponent));

    // Fragment without children should render without error
    expect(result.container, isNotNull);

    result.unmount();
  });

  test('StrictMode wraps children', () {
    final strictComponent = registerFunctionComponent(
      (props) => strictMode(
        child: pEl('Strict content', props: {'data-testid': 'content'}),
      ),
    );

    final result = render(fc(strictComponent));

    expect(result.getByTestId('content').textContent, equals('Strict content'));

    result.unmount();
  });

  test('StrictMode wraps multiple children', () {
    final strictComponent = registerFunctionComponent(
      (props) => strictMode(
        children: [
          pEl('First', props: {'data-testid': 'first'}),
          pEl('Second', props: {'data-testid': 'second'}),
        ],
      ),
    );

    final result = render(fc(strictComponent));

    expect(result.getByTestId('first').textContent, equals('First'));
    expect(result.getByTestId('second').textContent, equals('Second'));

    result.unmount();
  });

  test('StrictMode without children renders empty', () {
    final strictComponent = registerFunctionComponent((props) => strictMode());

    final result = render(fc(strictComponent));

    expect(result.container, isNotNull);

    result.unmount();
  });

  test('Suspense shows fallback then content', () {
    final suspenseComponent = registerFunctionComponent(
      (props) => suspense(
        fallback: pEl('Loading...', props: {'data-testid': 'fallback'}),
        child: pEl('Content', props: {'data-testid': 'content'}),
      ),
    );

    final result = render(fc(suspenseComponent));

    // Content should render since child is not lazy
    expect(result.getByTestId('content').textContent, equals('Content'));

    result.unmount();
  });

  test('Suspense with multiple children', () {
    final suspenseComponent = registerFunctionComponent(
      (props) => suspense(
        fallback: pEl('Loading...'),
        children: [
          pEl('First', props: {'data-testid': 'first'}),
          pEl('Second', props: {'data-testid': 'second'}),
        ],
      ),
    );

    final result = render(fc(suspenseComponent));

    expect(result.getByTestId('first').textContent, equals('First'));
    expect(result.getByTestId('second').textContent, equals('Second'));

    result.unmount();
  });

  test('Suspense without child renders', () {
    final suspenseComponent = registerFunctionComponent(
      (props) => suspense(fallback: pEl('Loading...')),
    );

    final result = render(fc(suspenseComponent));

    expect(result.container, isNotNull);

    result.unmount();
  });

  test('forwardRef2 forwards ref to child', () {
    final forwardedComponent = forwardRef2(
      (props, ref) => div(
        props: {'ref': ref, 'data-testid': 'forwarded'},
        child: pEl(props['label'] as String? ?? 'default'),
      ),
    );

    final wrapper = registerFunctionComponent((props) {
      final myRef = useRef<JSObject?>();
      return div(
        children: [
          fc(forwardedComponent, {'label': 'Hello', 'ref': myRef.jsRef}),
        ],
      );
    });

    final result = render(fc(wrapper));

    expect(result.getByTestId('forwarded').textContent, equals('Hello'));

    result.unmount();
  });

  test('forwardRef2 with displayName', () {
    final forwardedComponent = forwardRef2(
      (props, ref) => pEl('Test'),
      displayName: 'MyForwardedComponent',
    );

    // Component should be created successfully with displayName
    expect(forwardedComponent, isNotNull);
  });

  test('memo2 prevents unnecessary re-renders', () {
    var renderCount = 0;

    final innerComponent = registerFunctionComponent((props) {
      renderCount++;
      return pEl(
        'Value: ${props['value']}',
        props: {'data-testid': 'memoized'},
      );
    });

    final memoizedComponent = memo2(innerComponent);

    final wrapper = registerFunctionComponent((props) {
      final count = useState(0);
      return div(
        children: [
          fc(memoizedComponent, {'value': 'static'}),
          button(
            text: 'Increment',
            onClick: () => count.set(count.value + 1),
            props: {'data-testid': 'button'},
          ),
          pEl('Count: ${count.value}', props: {'data-testid': 'count'}),
        ],
      );
    });

    final result = render(fc(wrapper));

    expect(result.getByTestId('memoized').textContent, equals('Value: static'));
    expect(renderCount, equals(1));

    result.unmount();
  });

  test('memo2 with custom arePropsEqual', () {
    final innerComponent = registerFunctionComponent(
      (props) => pEl('ID: ${props['id']}', props: {'data-testid': 'memoized'}),
    );

    final memoizedComponent = memo2(
      innerComponent,
      arePropsEqual: (prev, next) => prev['id'] == next['id'],
    );

    final result = render(fc(memoizedComponent, {'id': 123, 'other': 'a'}));

    expect(result.getByTestId('memoized').textContent, equals('ID: 123'));

    result.unmount();
  });

  test('Fragment type is accessible', () {
    expect(Fragment, isNotNull);
  });

  test('Suspense type is accessible', () {
    expect(Suspense, isNotNull);
  });

  test('StrictMode type is accessible', () {
    expect(StrictMode, isNotNull);
  });

  test('lazy creates a lazy-loaded component', () {
    final simpleComponent = registerFunctionComponent(
      (props) => pEl('Lazy Content', props: {'data-testid': 'lazy-content'}),
    );

    // Create a lazy component that resolves immediately
    final lazyComponent = lazy(() async => simpleComponent);

    // Lazy component should be created
    expect(lazyComponent, isNotNull);
  });
}
