/// React (Web) UI for the counter demo.
///
/// This UI uses the shared state from counter_state.dart.
/// Run with: dart test -p chrome
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart';
import 'package:dart_node_statecore/dart_node_statecore.dart';
import 'package:statecore_demo/state/counter_state.dart';

String _getSelectValue(SyntheticEvent e) {
  final target = (e as JSObject)['target'];
  if (target case final JSObject t) {
    if (t['value'] case final JSString v) {
      return v.toDart;
    }
  }
  return '';
}

/// The main counter app component for web.
/// Uses createElement directly for proper React event handling.
ReactElement counterApp({Store<CounterState>? store}) => createElement(
      ((JSAny props) {
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

        return $div(className: 'counter-app') >> [
          $h1 >> 'Statecore Counter',
          $div(className: 'counter-display') >> [
            $span(className: 'count') >> '${state.count}',
          ],
          $div(className: 'controls') >> [
            $button(
              className: 'btn',
              onClick: () => s.dispatch(const Decrement()),
            ) >> '-${state.step}',
            $button(
              className: 'btn primary',
              onClick: () => s.dispatch(const Increment()),
            ) >> '+${state.step}',
          ],
          $div(className: 'step-control') >> [
            $label() >> 'Step: ',
            $select(
              value: '${state.step}',
              onChange: (e) {
                final val = int.tryParse(_getSelectValue(e)) ?? 1;
                s.dispatch(SetStep(val));
              },
            ) >> [
              $option(key: '1', value: '1') >> '1',
              $option(key: '5', value: '5') >> '5',
              $option(key: '10', value: '10') >> '10',
            ],
          ],
          $div(className: 'actions') >> [
            $button(
              className: 'btn',
              disabled: !canUndo,
              onClick: () => s.dispatch(const Undo()),
            ) >> 'Undo',
            $button(
              className: 'btn danger',
              onClick: () => s.dispatch(const Reset()),
            ) >> 'Reset',
          ],
          $div(className: 'stats') >> [
            $p() >> 'History: ${state.history.length} entries',
            $p() >> 'Min: ${stats.min} | Max: ${stats.max}',
            $p() >> 'Avg: ${stats.avg.toStringAsFixed(1)}',
          ],
        ];
      }).toJS,
    );

/// Hook to force re-render
void Function() _useForceUpdate() {
  final state = useState(0);
  return () => state.set(state.value + 1);
}
