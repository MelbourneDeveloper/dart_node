/// UI interaction tests for React Native components
/// Compiled to JS and run with Jest + React Native Testing Library
///
/// Build: dart compile js test/ui_test.dart -o test/dist/ui_test.js
/// Run: cd test && npm test
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react_native/dart_node_react_native.dart';

// =============================================================================
// Testing Library Bindings
// =============================================================================

@JS('rnTestingLibrary.render')
external JSObject _render(JSObject element);

@JS('rnTestingLibrary.screen')
external JSObject get _screen;

@JS('rnTestingLibrary.fireEvent')
external JSObject get _fireEvent;

@JS('rnTestingLibrary.waitFor')
external JSPromise<JSAny?> _waitFor(JSFunction callback);

// =============================================================================
// Test Utilities
// =============================================================================

/// Render a React Native element for testing
JSObject render(JSObject element) => _render(element);

/// Screen queries
JSObject get screen => _screen;

/// Fire events on elements
JSObject get fireEvent => _fireEvent;

/// Wait for async operations - takes a JSFunction callback
/// Returns a JSPromise that can be awaited in JS
JSPromise<JSAny?> waitFor(JSFunction callback) => _waitFor(callback);

/// Query by test ID
JSObject? queryByTestId(String testId) =>
    screen.callMethod('queryByTestId'.toJS, testId.toJS) as JSObject?;

/// Get by test ID (throws if not found)
JSObject getByTestId(String testId) =>
    switch (screen.callMethod('getByTestId'.toJS, testId.toJS)) {
      final JSObject obj => obj,
      _ => throw StateError('Element with testId "$testId" not found'),
    };

/// Query by text
JSObject? queryByText(String text) =>
    screen.callMethod('queryByText'.toJS, text.toJS) as JSObject?;

/// Get by text (throws if not found)
JSObject getByText(String text) =>
    switch (screen.callMethod('getByText'.toJS, text.toJS)) {
      final JSObject obj => obj,
      _ => throw StateError('Element with text "$text" not found'),
    };

/// Get all by text
JSArray getAllByText(String text) =>
    switch (screen.callMethod('getAllByText'.toJS, text.toJS)) {
      final JSArray arr => arr,
      _ => throw StateError('No elements found with text "$text"'),
    };

/// Query by placeholder
JSObject? queryByPlaceholder(String text) =>
    screen.callMethod('queryByPlaceholderText'.toJS, text.toJS) as JSObject?;

/// Get by placeholder (throws if not found)
JSObject getByPlaceholder(String text) =>
    switch (screen.callMethod('getByPlaceholderText'.toJS, text.toJS)) {
      final JSObject obj => obj,
      _ => throw StateError('Element with placeholder "$text" not found'),
    };

/// Press on a touchable element
void press(JSObject element) {
  fireEvent.callMethod('press'.toJS, element);
}

/// Change text in a TextInput
void changeText(JSObject element, String text) {
  fireEvent.callMethod('changeText'.toJS, element, text.toJS);
}

// =============================================================================
// Test Components
// =============================================================================

/// Simple counter component for testing state updates
JSObject counterComponent() => functionalComponent('Counter', (props) {
      final (countState, setCount) = useState(0.toJS);
      final count = (countState as JSNumber?)?.toDartInt ?? 0;

      return view(
        props: {'testID': 'counter-container'},
        children: [
          text('Count: $count', props: {'testID': 'count-display'}),
          touchableOpacity(
            onPress: () => setCount.callAsFunction(null, (count + 1).toJS),
            props: {'testID': 'increment-btn'},
            child: text('Increment'),
          ),
          touchableOpacity(
            onPress: () => setCount.callAsFunction(null, (count - 1).toJS),
            props: {'testID': 'decrement-btn'},
            child: text('Decrement'),
          ),
          touchableOpacity(
            onPress: () => setCount.callAsFunction(null, 0.toJS),
            props: {'testID': 'reset-btn'},
            child: text('Reset'),
          ),
        ],
      );
    });

/// Form component for testing input interactions
JSObject formComponent(
        {void Function(String email, String password)? onSubmit}) =>
    functionalComponent('Form', (props) {
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

      return view(
        props: {'testID': 'form-container'},
        children: [
          if (error != null)
            view(
              props: {'testID': 'error-message'},
              child: text(error),
            )
          else
            view(),
          if (submitted)
            view(
              props: {'testID': 'success-message'},
              child: text('Form submitted!'),
            )
          else
            view(),
          textInput(
            placeholder: 'Enter email',
            value: email,
            onChangeText: (val) => setEmail.callAsFunction(null, val.toJS),
            props: {'testID': 'email-input'},
          ),
          textInput(
            placeholder: 'Enter password',
            value: password,
            secureTextEntry: true,
            onChangeText: (val) => setPass.callAsFunction(null, val.toJS),
            props: {'testID': 'password-input'},
          ),
          touchableOpacity(
            onPress: handleSubmit,
            props: {'testID': 'submit-btn'},
            child: text('Submit'),
          ),
        ],
      );
    });

/// Toggle component for testing boolean state
JSObject toggleComponent() => functionalComponent('Toggle', (props) {
      final (onState, setOn) = useState(false.toJS);
      final isOn = (onState as JSBoolean?)?.toDart ?? false;

      return view(
        props: {'testID': 'toggle-container'},
        children: [
          text(
            isOn ? 'ON' : 'OFF',
            props: {'testID': 'toggle-status'},
          ),
          touchableOpacity(
            onPress: () => setOn.callAsFunction(null, (!isOn).toJS),
            props: {'testID': 'toggle-btn'},
            child: text('Toggle'),
          ),
        ],
      );
    });

/// List component for testing dynamic rendering
JSObject listComponent() => functionalComponent('List', (props) {
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

      return view(
        props: {'testID': 'list-container'},
        children: [
          view(children: [
            textInput(
              placeholder: 'Add item',
              value: inputValue,
              onChangeText: (val) => setInput.callAsFunction(null, val.toJS),
              props: {'testID': 'add-item-input'},
            ),
            touchableOpacity(
              onPress: addItem,
              props: {'testID': 'add-item-btn'},
              child: text('Add'),
            ),
          ]),
          view(
            props: {'testID': 'items-list'},
            children: items.isEmpty
                ? [
                    text('No items', props: {'testID': 'empty-message'})
                  ]
                : items
                    .asMap()
                    .entries
                    .map(
                      (entry) => view(
                        props: {
                          'key': entry.key,
                          'testID': 'list-item-${entry.key}'
                        },
                        children: [
                          text(
                            switch (entry.value) {
                              final JSString s => s.toDart,
                              _ => '',
                            },
                          ),
                          touchableOpacity(
                            onPress: () => removeItem(entry.key),
                            props: {'testID': 'remove-btn-${entry.key}'},
                            child: text('Remove'),
                          ),
                        ],
                      ),
                    )
                    .toList(),
          ),
          text(
            'Total: ${items.length}',
            props: {'testID': 'items-count'},
          ),
        ],
      );
    });

/// Switch component for testing toggle with RN Switch
JSObject switchComponent() => functionalComponent('SwitchTest', (props) {
      final (onState, setOn) = useState(false.toJS);
      final isOn = (onState as JSBoolean?)?.toDart ?? false;

      return view(
        props: {'testID': 'switch-container'},
        children: [
          text(
            isOn ? 'Enabled' : 'Disabled',
            props: {'testID': 'switch-status'},
          ),
          rnSwitch(
            value: isOn,
            onValueChange: (val) => setOn.callAsFunction(null, val.toJS),
            props: {'testID': 'switch-control'},
          ),
        ],
      );
    });

/// Activity indicator component for testing loading states
JSObject loadingComponent() => functionalComponent('Loading', (props) {
      final (loadingState, setLoading) = useState(true.toJS);
      final isLoading = (loadingState as JSBoolean?)?.toDart ?? true;

      return view(
        props: {'testID': 'loading-container'},
        children: [
          if (isLoading)
            activityIndicator(
              size: 'large',
              color: '#6366f1',
              props: {'testID': 'loading-indicator'},
            )
          else
            text('Content loaded', props: {'testID': 'loaded-content'}),
          touchableOpacity(
            onPress: () => setLoading.callAsFunction(null, (!isLoading).toJS),
            props: {'testID': 'toggle-loading-btn'},
            child: text(isLoading ? 'Finish loading' : 'Start loading'),
          ),
        ],
      );
    });

// =============================================================================
// Export test components for Jest
// =============================================================================

@JS('dartReactNativeTests')
external set _dartReactNativeTests(JSObject value);

void main() {
  _dartReactNativeTests = JSObject()
    // Export components
    ..setProperty('counterComponent'.toJS, counterComponent.toJS)
    ..setProperty(
        'formComponent'.toJS,
        ((JSAny? onSubmit) => (onSubmit == null || onSubmit.isUndefinedOrNull)
            ? formComponent()
            : formComponent(
                onSubmit: (email, password) => (onSubmit as JSFunction)
                    .callAsFunction(null, email.toJS, password.toJS),
              )).toJS)
    ..setProperty('toggleComponent'.toJS, toggleComponent.toJS)
    ..setProperty('listComponent'.toJS, listComponent.toJS)
    ..setProperty('switchComponent'.toJS, switchComponent.toJS)
    ..setProperty('loadingComponent'.toJS, loadingComponent.toJS)
    // Export utilities
    ..setProperty('render'.toJS, render.toJS)
    ..setProperty('fireEvent'.toJS, fireEvent)
    ..setProperty('getByTestId'.toJS, getByTestId.toJS)
    ..setProperty('getByPlaceholder'.toJS, getByPlaceholder.toJS)
    ..setProperty('queryByText'.toJS, queryByText.toJS)
    ..setProperty('getByText'.toJS, getByText.toJS)
    ..setProperty('getAllByText'.toJS, getAllByText.toJS)
    ..setProperty('press'.toJS, press.toJS)
    ..setProperty('queryByPlaceholder'.toJS, queryByPlaceholder.toJS)
    ..setProperty('queryByTestId'.toJS, queryByTestId.toJS)
    ..setProperty('changeText'.toJS, changeText.toJS)
    ..setProperty('waitFor'.toJS, waitFor.toJS);
}
