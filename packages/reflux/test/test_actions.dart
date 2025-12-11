/// Common test actions for Reflux tests.
library;

import 'package:reflux/reflux.dart';

// Counter state
typedef CounterState = ({int count});

// Counter actions - sealed for exhaustive matching
sealed class CounterAction extends Action {
  const CounterAction();
}

final class Increment extends CounterAction {
  const Increment();
}

final class Decrement extends CounterAction {
  const Decrement();
}

final class Reset extends CounterAction {
  const Reset();
}

final class SetCount extends CounterAction {
  const SetCount(this.value);
  final int value;
}

// Counter reducer
CounterState counterReducer(CounterState state, Action action) =>
    switch (action) {
      Increment() => (count: state.count + 1),
      Decrement() => (count: state.count - 1),
      Reset() => (count: 0),
      SetCount(:final value) => (count: value),
      _ => state,
    };

// Todo actions
sealed class TodoAction extends Action {
  const TodoAction();
}

final class AddTodo extends TodoAction {
  const AddTodo(this.text);
  final String text;
}

final class RemoveTodo extends TodoAction {
  const RemoveTodo(this.index);
  final int index;
}

// Todo reducer
List<String> todosReducer(List<String> state, Action action) =>
    switch (action) {
      AddTodo(:final text) => [...state, text],
      RemoveTodo(:final index) => [
        ...state.sublist(0, index),
        ...state.sublist(index + 1),
      ],
      _ => state,
    };
