import 'package:reflux/src/types.dart';

/// Binds a single action creator to a dispatch function.
///
/// This turns an action creator into a function that directly dispatches
/// the action when called.
///
/// Example:
/// ```dart
/// Action increment() => Increment();
/// final boundIncrement = bindActionCreator(increment, store.dispatch);
/// boundIncrement(); // dispatches Increment action
/// ```
void Function() bindActionCreator<A extends Action>(
  A Function() actionCreator,
  void Function(Action) dispatch,
) =>
    () => dispatch(actionCreator());

/// Binds multiple action creators to a dispatch function.
///
/// This turns a map of action creators into a map with the same keys,
/// but with every action creator wrapped into a dispatch call.
///
/// Example:
/// ```dart
/// final actionCreators = {
///   'increment': () => Increment(),
///   'decrement': () => Decrement(),
/// };
///
/// final bound = bindActionCreators(actionCreators, store.dispatch);
/// bound['increment']!(); // dispatches Increment
/// ```
Map<String, void Function()> bindActionCreators(
  Map<String, Action Function()> actionCreators,
  void Function(Action) dispatch,
) => actionCreators.map(
  (key, creator) => MapEntry(key, () => dispatch(creator())),
);

/// Creates a dispatcher function for a specific action type.
///
/// This is a convenience for creating bound action creators inline.
///
/// Example:
/// ```dart
/// final dispatchIncrement = createDispatcher(
///   () => Increment(),
///   store.dispatch,
/// );
/// dispatchIncrement(); // automatically dispatches
/// ```
void Function() createDispatcher<A extends Action>(
  A Function() actionCreator,
  void Function(Action) dispatch,
) =>
    () => dispatch(actionCreator());

/// Creates a dispatcher function for an action with a parameter.
///
/// Example:
/// ```dart
/// final dispatchSetValue = createDispatcherWith(
///   (int v) => SetValue(v),
///   store.dispatch,
/// );
/// dispatchSetValue(42); // dispatches SetValue(42)
/// ```
void Function(P) createDispatcherWith<A extends Action, P>(
  A Function(P) actionCreator,
  void Function(Action) dispatch,
) =>
    (param) => dispatch(actionCreator(param));
