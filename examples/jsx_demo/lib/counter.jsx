/// Counter component using JSX syntax.
///
/// This demonstrates how to write React components in Dart using JSX.
/// The .jsx.dart file gets transpiled to pure Dart before compilation.
library;

import 'package:dart_node_react/dart_node_react.dart';

/// A counter component with increment, decrement, and reset.
ReactElement Counter() {
  final count = useState(0);

  return <div className="counter">
    <h1>Dart + JSX</h1>
    <div className="value">{count.value}</div>
    <div className="buttons">
      <button className="btn-dec" onClick={() => count.set(count.value - 1)}>
        -
      </button>
      <button className="btn-inc" onClick={() => count.set(count.value + 1)}>
        + 
      </button>
    </div>
    <div className="buttons">
      <button className="btn-reset" onClick={() => count.set(0)}>
        Reset
      </button>
    </div>
  </div>;
}
