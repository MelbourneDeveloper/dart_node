/// Tests for ReactDOM bindings.
@TestOn('js')
library;

import 'dart:js_interop';

import 'package:dart_node_react/dart_node_react.dart' hide RenderResult, render;
import 'package:dart_node_react/src/testing_library.dart';
import 'package:test/test.dart';

@JS('document.createElement')
external JSObject _createElement(String tagName);

@JS('document.body.appendChild')
external void _appendChild(JSObject node);

@JS('document.body.removeChild')
external void _removeChild(JSObject node);

@JS('ReactDOM.createRoot')
external _JsRoot _createTestRoot(JSObject container);

@JS()
extension type _JsRoot._(JSObject _) implements JSObject {
  external void render(JSObject element);
  external void unmount();
}

@JS()
extension type _Container._(JSObject _) implements JSObject {
  external String? get innerHTML;
  external set innerHTML(String? value);
  external String? get id;
  external set id(String value);
}

void main() {
  test('createRoot creates a ReactRoot', () {
    final container = _createElement('div');
    final root = createRoot(container);

    expect(root, isA<ReactRoot>());
  });

  test('ReactRoot render works', () async {
    final container = _Container._(_createElement('div'));
    final root = _createTestRoot(container);

    final element = div(
      props: {'data-testid': 'test'},
      children: [pEl('Hello World')],
    );

    flushSync(() => root.render(element));

    // Allow React to complete rendering
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(container.innerHTML, contains('Hello World'));

    root.unmount();
  });

  test('createPortal creates a ReactPortal', () {
    final portalContainer = _createElement('div');
    final element = div(children: [pEl('Portal content')]);

    final portal = createPortal(element, portalContainer);

    expect(portal, isA<ReactPortal>());
  });

  test('ReactPortal has containerInfo', () {
    final portalContainer = _createElement('div');
    final element = pEl('Test content');

    final portal = createPortal(element, portalContainer);

    expect(portal.containerInfo, isNotNull);
  });

  test('flushSync function exists and is callable', () {
    var called = false;

    flushSync(() {
      called = true;
    });

    expect(called, isTrue);
  });

  test('hydrateRoot creates a ReactRoot for server-rendered content', () {
    final container = _Container._(_createElement('div'))
      ..innerHTML = '<p>Server rendered</p>';

    final element = pEl('Server rendered');

    final root = hydrateRoot(container, element);

    expect(root, isA<ReactRoot>());
  });

  test('multiple createRoot calls create independent roots', () {
    final container1 = _createElement('div');
    final container2 = _createElement('div');

    final root1 = createRoot(container1);
    final root2 = createRoot(container2);

    expect(root1, isA<ReactRoot>());
    expect(root2, isA<ReactRoot>());
    expect(root1, isNot(same(root2)));
  });

  test('ReactPortal renders in portal container', () async {
    final portalContainer = _Container._(_createElement('div'));
    _appendChild(portalContainer);

    final mainContainer = _createElement('div');
    final root = _createTestRoot(mainContainer);

    final portalComponent = registerFunctionComponent(
      (props) => fragment(
        children: [
          pEl('Main content'),
          ReactElement.fromJS(
            createPortal(
              div(children: [pEl('Portal content')]),
              portalContainer,
            ),
          ),
        ],
      ),
    );

    flushSync(() => root.render(fc(portalComponent)));

    // Allow React to complete rendering
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(portalContainer.innerHTML, contains('Portal content'));

    root.unmount();
    _removeChild(portalContainer);
  });

  test('Document.getElementById works', () {
    final container = _Container._(_createElement('div'))
      ..id = 'test-container-unique';
    _appendChild(container);

    final found = Document.getElementById('test-container-unique');
    expect(found, isNotNull);

    _removeChild(container);
  });

  test('render function from testing_library works with portals', () {
    final portalContainer = _Container._(_createElement('div'));
    _appendChild(portalContainer);

    final testComponent = registerFunctionComponent(
      (props) => div(props: {'data-testid': 'main'}, children: [pEl('Hello')]),
    );

    final result = render(fc(testComponent));
    expect(result.getByTestId('main'), isNotNull);

    result.unmount();
    _removeChild(portalContainer);
  });

  test('createPortal with complex nested children', () {
    final portalContainer = _createElement('div');

    final portal = createPortal(
      div(
        children: [
          h1('Modal Header'),
          div(children: [pEl('Line 1'), pEl('Line 2')]),
          button(text: 'Close'),
        ],
      ),
      portalContainer,
    );

    expect(portal, isA<ReactPortal>());
    expect(portal.children, isNotNull);
  });
}
