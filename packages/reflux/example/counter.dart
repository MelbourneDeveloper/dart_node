/// Simple counter example demonstrating Reflux fundamentals.
///
/// Run with: dart run example/counter.dart
library;

import 'package:dart_logging/dart_logging.dart';
import 'package:reflux/reflux.dart';

// State is just a record
typedef CounterState = ({int count});

// Actions are sealed classes - pattern match on TYPE, not strings!
sealed class CounterAction extends Action {}

final class Increment extends CounterAction {}

final class Decrement extends CounterAction {}

final class Reset extends CounterAction {}

// Reducer uses exhaustive pattern matching
CounterState counterReducer(CounterState state, Action action) =>
    switch (action) {
      Increment() => (count: state.count + 1),
      Decrement() => (count: state.count - 1),
      Reset() => (count: 0),
      _ => state, // Handle system actions (InitAction, etc.)
    };

// Logging middleware using dart_logging
Middleware<CounterState> loggerMiddleware(Logger logger) =>
    (api) =>
        (next) => (action) {
          final before = api.getState().count;
          next(action);
          final after = api.getState().count;
          logger.debug(
            '${action.runtimeType}: $before -> $after',
            structuredData: {
              'action': action.runtimeType.toString(),
              'before': before,
              'after': after,
            },
          );
        };

void main() {
  final context = createLoggingContext(
    transports: [logTransport(logToConsole)],
    minimumLogLevel: LogLevel.debug,
  );
  final logger = createLoggerWithContext(context)
    ..info('=== Reflux Counter ===');

  final store = createStore<CounterState>(
    counterReducer,
    (count: 0),
    enhancer: applyMiddleware<CounterState>([loggerMiddleware(logger)]),
  );

  store
    ..subscribe(() => logger.info('State: ${store.getState().count}'))
    ..dispatch(Increment())
    ..dispatch(Increment())
    ..dispatch(Decrement())
    ..dispatch(Reset());

  logger.info('Final count: ${store.getState().count}');
}
