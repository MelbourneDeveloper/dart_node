/// UI interaction tests for React components
/// Compiled to JS and run with Jest + React Testing Library
///
/// Build: dart compile js test/ui_test.dart -o test/dist/ui_test.js
/// Run: cd test && npm test
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart';

// =============================================================================
// Testing Library Bindings
// =============================================================================

@JS('testingLibrary.render')
external JSObject _render(JSObject element);

@JS('testingLibrary.screen')
external JSObject get _screen;

@JS('testingLibrary.fireEvent')
external JSObject get _fireEvent;

@JS('userEvent.setup')
external JSObject _userEventSetup();

// =============================================================================
// Test Utilities - Exported for shared use
// =============================================================================

/// Render a React element for testing
JSObject render(JSObject element) => _render(element);

/// Screen queries
JSObject get screen => _screen;

/// Fire events on elements
JSObject get fireEvent => _fireEvent;

/// User event instance for realistic interactions
JSObject userEvent() => _userEventSetup();

/// Query by text
JSObject? queryByText(String text) =>
    screen.callMethod('queryByText'.toJS, text.toJS) as JSObject?;

/// Get by text (throws if not found)
JSObject getByText(String text) =>
    screen.callMethod('getByText'.toJS, text.toJS)! as JSObject;

/// Query by placeholder
JSObject? queryByPlaceholder(String text) =>
    screen.callMethod('queryByPlaceholderText'.toJS, text.toJS) as JSObject?;

/// Get by placeholder (throws if not found)
JSObject getByPlaceholder(String text) =>
    screen.callMethod('getByPlaceholderText'.toJS, text.toJS)! as JSObject;

/// Query by role
JSObject? queryByRole(String role, [JSObject? options]) => (options != null)
    ? screen.callMethod('queryByRole'.toJS, role.toJS, options) as JSObject?
    : screen.callMethod('queryByRole'.toJS, role.toJS) as JSObject?;

/// Get by role (throws if not found)
JSObject getByRole(String role, [JSObject? options]) => (options != null)
    ? screen.callMethod('getByRole'.toJS, role.toJS, options)! as JSObject
    : screen.callMethod('getByRole'.toJS, role.toJS)! as JSObject;

/// Query by test ID
JSObject? queryByTestId(String testId) =>
    screen.callMethod('queryByTestId'.toJS, testId.toJS) as JSObject?;

/// Get by test ID (throws if not found)
JSObject getByTestId(String testId) =>
    switch (screen.callMethod('getByTestId'.toJS, testId.toJS)) {
      final JSObject obj => obj,
      _ => throw StateError('Element with testId "$testId" not found'),
    };

/// Click an element
void click(JSObject element) {
  fireEvent.callMethod('click'.toJS, element);
}

/// Change input value (sync)
void changeValue(JSObject element, String value) {
  final eventInit = JSObject()
    ..setProperty(
      'target'.toJS,
      JSObject()..setProperty('value'.toJS, value.toJS),
    );
  fireEvent.callMethod('change'.toJS, element, eventInit);
}

// =============================================================================
// Test Components
// =============================================================================

/// Simple counter component for testing state updates
JSObject counterComponent() => createElement(
  ((JSAny props) {
    final (countState, setCount) = useState(0.toJS);
    final count = (countState as JSNumber?)?.toDartInt ?? 0;

    return div(
      children: [
        span('Count: $count', props: {'data-testid': 'count-display'}),
        button(
          text: 'Increment',
          onClick: () => setCount.callAsFunction(null, (count + 1).toJS),
          props: {'data-testid': 'increment-btn'},
        ),
        button(
          text: 'Decrement',
          onClick: () => setCount.callAsFunction(null, (count - 1).toJS),
          props: {'data-testid': 'decrement-btn'},
        ),
        button(
          text: 'Reset',
          onClick: () => setCount.callAsFunction(null, 0.toJS),
          props: {'data-testid': 'reset-btn'},
        ),
      ],
    );
  }).toJS,
);

/// Form component for testing input interactions
JSObject formComponent({
  void Function(String email, String password)? onSubmit,
}) => createElement(
  ((JSAny props) {
    final (emailState, setEmail) = useState(''.toJS);
    final (passState, setPass) = useState(''.toJS);
    final (errorState, setError) = useState(null);
    final (submittedState, setSubmitted) = useState(false.toJS);

    final email = (emailState as JSString?)?.toDart ?? '';
    final password = (passState as JSString?)?.toDart ?? '';
    final error = (errorState as JSString?)?.toDart;
    final submitted = (submittedState as JSBoolean?)?.toDart ?? false;

    void handleSubmit() {
      (email.isEmpty || password.isEmpty)
          ? setError.callAsFunction(null, 'All fields required'.toJS)
          : () {
              setError.callAsFunction();
              setSubmitted.callAsFunction(null, true.toJS);
              onSubmit?.call(email, password);
            }();
    }

    return div(
      props: {'data-testid': 'form-container'},
      children: [
        if (error != null)
          div(props: {'data-testid': 'error-message'}, child: span(error))
        else
          span(''),
        if (submitted)
          div(
            props: {'data-testid': 'success-message'},
            child: span('Form submitted!'),
          )
        else
          span(''),
        div(
          children: [
            input(
              type: 'email',
              placeholder: 'Enter email',
              value: email,
              onChange: (e) =>
                  setEmail.callAsFunction(null, _extractInputValue(e)),
              props: {'data-testid': 'email-input'},
            ),
          ],
        ),
        div(
          children: [
            input(
              type: 'password',
              placeholder: 'Enter password',
              value: password,
              onChange: (e) =>
                  setPass.callAsFunction(null, _extractInputValue(e)),
              props: {'data-testid': 'password-input'},
            ),
          ],
        ),
        button(
          text: 'Submit',
          onClick: handleSubmit,
          props: {'data-testid': 'submit-btn'},
        ),
      ],
    );
  }).toJS,
);

JSString _extractInputValue(JSAny event) {
  final obj = event as JSObject;
  final target = obj['target'] as JSObject?;
  return (target?['value'] as JSString?) ?? ''.toJS;
}

/// Toggle component for testing boolean state
JSObject toggleComponent() => createElement(
  ((JSAny props) {
    final (onState, setOn) = useState(false.toJS);
    final isOn = (onState as JSBoolean?)?.toDart ?? false;

    return div(
      children: [
        span(isOn ? 'ON' : 'OFF', props: {'data-testid': 'toggle-status'}),
        button(
          text: 'Toggle',
          onClick: () => setOn.callAsFunction(null, (!isOn).toJS),
          props: {'data-testid': 'toggle-btn'},
        ),
      ],
    );
  }).toJS,
);

/// List component for testing dynamic rendering
JSObject listComponent() => createElement(
  ((JSAny props) {
    final (itemsState, setItems) = useState(<JSAny>[].toJS);
    final (inputState, setInput) = useState(''.toJS);

    final items = (itemsState as JSArray?)?.toDart ?? [];
    final inputValue = (inputState as JSString?)?.toDart ?? '';

    void addItem() => switch (inputValue.trim().isNotEmpty) {
      true => () {
        final newItems = [...items, inputValue.toJS];
        setItems.callAsFunction(null, newItems.toJS);
        setInput.callAsFunction(null, ''.toJS);
      }(),
      false => null,
    };

    void removeItem(int index) {
      final newItems = [...items]..removeAt(index);
      setItems.callAsFunction(null, newItems.toJS);
    }

    return div(
      props: {'data-testid': 'list-container'},
      children: [
        div(
          children: [
            input(
              type: 'text',
              placeholder: 'Add item',
              value: inputValue,
              onChange: (e) =>
                  setInput.callAsFunction(null, _extractInputValue(e)),
              props: {'data-testid': 'add-item-input'},
            ),
            button(
              text: 'Add',
              onClick: addItem,
              props: {'data-testid': 'add-item-btn'},
            ),
          ],
        ),
        div(
          props: {'data-testid': 'items-list'},
          children: items.isEmpty
              ? [
                  span('No items', props: {'data-testid': 'empty-message'}),
                ]
              : items
                    .asMap()
                    .entries
                    .map(
                      (entry) => div(
                        props: {
                          'key': entry.key,
                          'data-testid': 'list-item-${entry.key}',
                        },
                        children: [
                          span(switch (entry.value) {
                            final JSString s => s.toDart,
                            _ => '',
                          }),
                          button(
                            text: 'Remove',
                            onClick: () => removeItem(entry.key),
                            props: {'data-testid': 'remove-btn-${entry.key}'},
                          ),
                        ],
                      ),
                    )
                    .toList(),
        ),
        span('Total: ${items.length}', props: {'data-testid': 'items-count'}),
      ],
    );
  }).toJS,
);

// =============================================================================
// Export test components for Jest
// =============================================================================

@JS('dartReactTests')
external set _dartReactTests(JSObject value);

/// Wrapper to handle JS undefined vs null for formComponent
JSObject _wrapFormComponent(JSAny? onSubmit) => switch (onSubmit) {
      null => formComponent(),
      final cb when cb.isUndefinedOrNull => formComponent(),
      final JSFunction cb => formComponent(
          onSubmit: (email, password) =>
              cb.callAsFunction(null, email.toJS, password.toJS),
        ),
      _ => formComponent(),
    };

void main() {
  // Create formComponent wrapper that handles both 0 and 1 args
  final formComponentWrapper = ((JSAny? arg) =>
      (arg == null || arg.isUndefinedOrNull)
          ? formComponent()
          : _wrapFormComponent(arg)).toJS;

  _dartReactTests = JSObject()
    // Export components
    ..setProperty('counterComponent'.toJS, counterComponent.toJS)
    ..setProperty('formComponent'.toJS, formComponentWrapper)
    ..setProperty('toggleComponent'.toJS, toggleComponent.toJS)
    ..setProperty('listComponent'.toJS, listComponent.toJS)
    // Export utilities
    ..setProperty('render'.toJS, render.toJS)
    ..setProperty('getByText'.toJS, getByText.toJS)
    ..setProperty('getByTestId'.toJS, getByTestId.toJS)
    ..setProperty('getByPlaceholder'.toJS, getByPlaceholder.toJS)
    ..setProperty('queryByPlaceholder'.toJS, queryByPlaceholder.toJS)
    ..setProperty('queryByTestId'.toJS, queryByTestId.toJS)
    ..setProperty('queryByRole'.toJS, queryByRole.toJS)
    ..setProperty('getByRole'.toJS, getByRole.toJS)
    ..setProperty('click'.toJS, click.toJS)
    ..setProperty('changeValue'.toJS, changeValue.toJS)
    ..setProperty('queryByText'.toJS, queryByText.toJS)
    ..setProperty('userEvent'.toJS, userEvent.toJS);
}
