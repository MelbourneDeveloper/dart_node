import 'package:dart_node_statecore/dart_node_statecore.dart';
import 'package:test/test.dart';

typedef AppState = ({int counter, List<String> todos});

// Counter actions
sealed class CounterAction extends Action {
  const CounterAction();
}

final class Increment extends CounterAction {
  const Increment();
}

// Todo actions
sealed class TodoAction extends Action {
  const TodoAction();
}

final class AddTodo extends TodoAction {
  const AddTodo(this.text);
  final String text;
}

// Unknown action for testing no-op scenarios
final class Unknown extends Action {
  const Unknown();
}

// Reducers
int counterReducer(int state, Action action) => switch (action) {
      Increment() => state + 1,
      _ => state,
    };

List<String> todosReducer(List<String> state, Action action) =>
    switch (action) {
      AddTodo(:final text) => [...state, text],
      _ => state,
    };

SliceDefinition<AppState, dynamic> counterSlice() => (
      selector: (AppState s) => s.counter,
      updater: (AppState s, v) => (counter: v as int, todos: s.todos),
      reducer: (state, Action action) => counterReducer(state as int, action),
      initialState: 0,
    );

SliceDefinition<AppState, dynamic> todosSlice() => (
      selector: (AppState s) => s.todos,
      updater: (AppState s, v) =>
          (counter: s.counter, todos: v as List<String>),
      reducer: (state, Action action) =>
          todosReducer(state as List<String>, action),
      initialState: <String>[],
    );

void main() {
  group('combineReducers', () {
    test('combines multiple slice reducers', () {
      final reducer = combineReducers<AppState>(
        initialState: (counter: 0, todos: []),
        slices: [counterSlice(), todosSlice()],
      );

      final store = createStore(reducer, (counter: 0, todos: <String>[]))
        ..dispatch(const Increment());
      expect(store.getState().counter, equals(1));
      expect(store.getState().todos, isEmpty);

      store.dispatch(const AddTodo('Learn Dart'));
      expect(store.getState().counter, equals(1));
      expect(store.getState().todos, equals(['Learn Dart']));
    });

    test('returns same state reference if nothing changed', () {
      final reducer = combineReducers<AppState>(
        initialState: (counter: 0, todos: []),
        slices: [counterSlice()],
      );

      final initialState = (counter: 5, todos: <String>['test']);
      final nextState = reducer(initialState, const Unknown());
      expect(identical(initialState, nextState), isTrue);
    });

    test('handles empty slices list', () {
      final reducer = combineReducers<AppState>(
        initialState: (counter: 0, todos: []),
        slices: [],
      );

      final state = (counter: 5, todos: <String>[]);
      final nextState = reducer(state, const Increment());
      expect(identical(state, nextState), isTrue);
    });
  });

  group('combineReducersMap', () {
    test('combines reducers with string keys', () {
      final reducer = combineReducersMap({
        'counter': (state, action) {
          final current = (state ?? 0) as int;
          return switch (action) {
            Increment() => current + 1,
            _ => current,
          };
        },
        'todos': (state, action) {
          final current = (state ?? <String>[]) as List;
          return switch (action) {
            AddTodo(:final text) => [...current, text],
            _ => current,
          };
        },
      });

      final store = createStore(
        reducer,
        <String, Object?>{'counter': 0, 'todos': <String>[]},
      )..dispatch(const Increment());
      expect(store.getState()['counter'], equals(1));

      store.dispatch(const AddTodo('Test'));
      expect(store.getState()['todos'], equals(['Test']));
    });

    test('returns same state reference if nothing changed', () {
      final reducer = combineReducersMap({
        'value': (state, action) => state ?? 0,
      });

      final state = <String, Object?>{'value': 5};
      final nextState = reducer(state, const Unknown());
      expect(identical(state, nextState), isTrue);
    });
  });
}
