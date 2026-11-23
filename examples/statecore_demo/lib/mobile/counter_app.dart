/// React Native (Mobile) UI for the counter demo.
///
/// This UI uses the SAME shared state from counter_state.dart as web!
library;

import 'package:dart_node_react/dart_node_react.dart' hide view;
import 'package:dart_node_react_native/dart_node_react_native.dart';
import 'package:dart_node_statecore/dart_node_statecore.dart';
import 'package:statecore_demo/state/counter_state.dart';

// Styles
const _containerStyle = <String, dynamic>{
  'flex': 1,
  'backgroundColor': '#f5f5f5',
  'padding': 20,
};

const _headerStyle = <String, dynamic>{
  'fontSize': 28,
  'fontWeight': 'bold',
  'textAlign': 'center',
  'marginBottom': 20,
  'color': '#333',
};

const _countStyle = <String, dynamic>{
  'fontSize': 72,
  'fontWeight': 'bold',
  'textAlign': 'center',
  'color': '#2196F3',
  'marginVertical': 30,
};

const _buttonRowStyle = <String, dynamic>{
  'flexDirection': 'row',
  'justifyContent': 'center',
  'gap': 20,
  'marginVertical': 10,
};

const _buttonStyle = <String, dynamic>{
  'backgroundColor': '#2196F3',
  'paddingHorizontal': 30,
  'paddingVertical': 15,
  'borderRadius': 8,
};

const _dangerButtonStyle = <String, dynamic>{
  'backgroundColor': '#f44336',
  'paddingHorizontal': 30,
  'paddingVertical': 15,
  'borderRadius': 8,
};

const _disabledButtonStyle = <String, dynamic>{
  'backgroundColor': '#ccc',
  'paddingHorizontal': 30,
  'paddingVertical': 15,
  'borderRadius': 8,
};

const _buttonTextStyle = <String, dynamic>{
  'color': '#fff',
  'fontSize': 18,
  'fontWeight': 'bold',
};

const _statsStyle = <String, dynamic>{
  'marginTop': 30,
  'padding': 15,
  'backgroundColor': '#fff',
  'borderRadius': 8,
};

const _statTextStyle = <String, dynamic>{
  'fontSize': 14,
  'color': '#666',
  'textAlign': 'center',
};

Map<String, dynamic> _inactiveButtonStyle() => {
      ..._buttonStyle,
      'backgroundColor': '#888',
    };

/// The main counter app component for mobile (React Native).
ReactElement mobileCounterApp({Store<CounterState>? store}) =>
    functionalComponent('MobileCounterApp', (props) {
      // Create store on first render, or use provided one
      final storeRef = useRef<Store<CounterState>?>();
      if (storeRef.current == null) {
        storeRef.current = store ?? createCounterStore();
      }
      final s = storeRef.current!;

      // Force re-render on state change
      final forceUpdate = _useForceUpdate();
      useEffect(() {
        final unsubscribe = s.subscribe(forceUpdate);
        return unsubscribe;
      }, []);

      final state = s.getState();
      final canUndo = selectCanUndo(state);
      final stats = selectHistoryStats(state);

      return safeAreaView(
        style: _containerStyle,
        children: [
          text('Statecore Counter', style: _headerStyle),
          text('${state.count}', style: _countStyle),
          // Increment/Decrement buttons
          view(
            style: _buttonRowStyle,
            children: [
              touchableOpacity(
                style: _buttonStyle,
                onPress: () => s.dispatch(const Decrement()),
                child: text('-${state.step}', style: _buttonTextStyle),
              ),
              touchableOpacity(
                style: _buttonStyle,
                onPress: () => s.dispatch(const Increment()),
                child: text('+${state.step}', style: _buttonTextStyle),
              ),
            ],
          ),
          // Step selector
          view(
            style: _buttonRowStyle,
            children: [
              for (final step in [1, 5, 10])
                touchableOpacity(
                  style: state.step == step
                      ? _buttonStyle
                      : _inactiveButtonStyle(),
                  onPress: () => s.dispatch(SetStep(step)),
                  child: text('Step $step', style: _buttonTextStyle),
                ),
            ],
          ),
          // Undo/Reset buttons
          view(
            style: _buttonRowStyle,
            children: [
              touchableOpacity(
                style: canUndo ? _buttonStyle : _disabledButtonStyle,
                onPress: canUndo ? () => s.dispatch(const Undo()) : null,
                child: text('Undo', style: _buttonTextStyle),
              ),
              touchableOpacity(
                style: _dangerButtonStyle,
                onPress: () => s.dispatch(const Reset()),
                child: text('Reset', style: _buttonTextStyle),
              ),
            ],
          ),
          // Stats
          view(
            style: _statsStyle,
            children: [
              text(
                'History: ${state.history.length} entries',
                style: _statTextStyle,
              ),
              text(
                'Min: ${stats.min} | Max: ${stats.max}',
                style: _statTextStyle,
              ),
              text(
                'Avg: ${stats.avg.toStringAsFixed(1)}',
                style: _statTextStyle,
              ),
            ],
          ),
        ],
      );
    });

/// Hook to force re-render
void Function() _useForceUpdate() {
  final state = useState(0);
  return () => state.set(state.value + 1);
}
