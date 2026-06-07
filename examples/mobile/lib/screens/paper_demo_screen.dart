/// Paper Demo Screen - shows BOTH approaches:
/// 1. DIRECT npmComponent() - loose, works immediately
/// 2. TYPED helpers - full autocomplete, type safety
///
/// Start with npmComponent() directly, add types WHERE YOU NEED THEM.
library;

import 'dart:js_interop';

import 'package:dart_node_react/dart_node_react.dart';
import 'package:dart_node_react_native/dart_node_react_native.dart';

/// Create Paper demo screen component
JSFunction createPaperDemoScreen() => createFunctionalComponent((JSObject props) {
  final countState = useState(0);
  final fabOpenState = useState(false);
  final count = countState.value;
  final fabOpen = fabOpenState.value;

  return npmComponent(
    'react-native',
    'ScrollView',
    props: {'style': {'flex': 1, 'padding': 16, 'backgroundColor': '#121212'}},
    children: [
      // Paper Button - DIRECT usage, no wrapper!
      npmComponent(
        'react-native-paper',
        'Button',
        props: {
          'mode': 'contained',
          'buttonColor': '#6200EE',
          'textColor': '#FFFFFF',
          'onPress': () => countState.set(count + 1),
        },
        child: 'Count: $count'.toJS,
      ),

      _spacer(),

      // Paper Button - outlined mode
      npmComponent(
        'react-native-paper',
        'Button',
        props: {
          'mode': 'outlined',
          'textColor': '#BB86FC',
          'onPress': () => countState.set(0),
        },
        child: 'Reset'.toJS,
      ),

      _spacer(),

      // Paper Card - DIRECT usage with nested components
      npmComponent(
        'react-native-paper',
        'Card',
        props: {'style': {'backgroundColor': '#1E1E1E'}},
        children: [
          npmComponent(
            'react-native-paper',
            'Card.Title',
            props: {
              'title': 'Direct npmComponent() Usage',
              'subtitle': 'No wrapper functions needed!',
              'titleStyle': {'color': '#FFFFFF'},
              'subtitleStyle': {'color': '#B0B0B0'},
            },
          ),
          npmComponent(
            'react-native-paper',
            'Card.Content',
            children: [
              npmComponent(
                'react-native-paper',
                'Text',
                props: {'style': {'color': '#E0E0E0'}},
                child: 'This card uses npmComponent() directly with react-native-paper. Props are just Map<String, dynamic> - no typed wrappers!'.toJS,
              ),
            ],
          ),
          npmComponent(
            'react-native-paper',
            'Card.Actions',
            children: [
              npmComponent(
                'react-native-paper',
                'Button',
                props: {'textColor': '#BB86FC'},
                child: 'Cancel'.toJS,
              ),
              npmComponent(
                'react-native-paper',
                'Button',
                props: {'mode': 'contained', 'buttonColor': '#6200EE'},
                child: 'OK'.toJS,
              ),
            ],
          ),
        ],
      ),

      _spacer(),

      // Paper TextInput - DIRECT usage
      npmComponent(
        'react-native-paper',
        'TextInput',
        props: {
          'label': 'Email',
          'mode': 'outlined',
          'placeholder': 'Enter your email',
          'activeOutlineColor': '#BB86FC',
          'textColor': '#FFFFFF',
          'style': {'backgroundColor': '#1E1E1E'},
        },
      ),

      _spacer(),

      // Paper FAB - DIRECT usage
      npmComponent(
        'react-native-paper',
        'FAB',
        props: {
          'icon': 'plus',
          'style': {'position': 'absolute', 'right': 16, 'bottom': 16},
          'color': '#FFFFFF',
          'customColor': '#6200EE',
          'onPress': () => fabOpenState.set(!fabOpen),
        },
      ),

      _spacer(),

      // =================================================================
      // TYPED HELPERS - Same components, but with full type safety!
      // =================================================================

      npmComponent(
        'react-native-paper',
        'Card',
        props: {'style': {'backgroundColor': '#2D2D2D'}},
        children: [
          npmComponent(
            'react-native-paper',
            'Card.Title',
            props: {
              'title': 'TYPED Wrappers (Optional)',
              'subtitle': 'Full autocomplete + type checking',
              'titleStyle': {'color': '#BB86FC'},
              'subtitleStyle': {'color': '#B0B0B0'},
            },
          ),
          npmComponent(
            'react-native-paper',
            'Card.Content',
            children: [
              npmComponent(
                'react-native-paper',
                'Text',
                props: {'style': {'color': '#E0E0E0', 'marginBottom': 12}},
                child: 'Same components, but typed! Props get autocomplete.'.toJS,
              ),

              // TYPED Button - using paperButton() helper
              paperButton(
                props: (
                  mode: 'contained',
                  disabled: false,
                  loading: null,
                  buttonColor: '#BB86FC',
                  textColor: '#000000',
                  style: null,
                  contentStyle: null,
                  labelStyle: null,
                ),
                onPress: () => countState.set(count + 10),
                label: 'Typed +10',
              ),

              _spacer(),

              // TYPED FAB - using paperFAB() helper
              paperFAB(
                props: (
                  icon: 'star',
                  label: null,
                  small: true,
                  visible: true,
                  loading: null,
                  disabled: null,
                  color: '#FFFFFF',
                  customColor: '#03DAC6',
                  style: {'marginTop': 8},
                ),
                onPress: () => fabOpenState.set(!fabOpen),
              ),

              _spacer(),

              // TYPED TextInput - using paperTextInput() helper
              paperTextInput(
                props: (
                  label: 'Typed Input',
                  placeholder: 'With full autocomplete',
                  mode: 'outlined',
                  disabled: null,
                  editable: null,
                  secureTextEntry: null,
                  value: null,
                  activeOutlineColor: '#03DAC6',
                  activeUnderlineColor: null,
                  textColor: '#FFFFFF',
                  style: {'backgroundColor': '#1E1E1E'},
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Simple spacer using View
ReactElement _spacer() => npmComponent(
  'react-native',
  'View',
  props: {'style': {'height': 16}},
);
