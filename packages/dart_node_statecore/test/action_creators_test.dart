import 'package:dart_node_statecore/dart_node_statecore.dart';
import 'package:test/test.dart';

// Actions for testing
sealed class TestAction extends Action {
  const TestAction();
}

final class Increment extends TestAction {
  const Increment();
}

final class Decrement extends TestAction {
  const Decrement();
}

final class SetValue extends TestAction {
  const SetValue(this.value);
  final int value;
}

void main() {
  group('bindActionCreator', () {
    test('binds single action creator to dispatch', () {
      final dispatched = <Action>[];
      void dispatch(Action action) => dispatched.add(action);

      Increment increment() => const Increment();
      final boundIncrement = bindActionCreator(increment, dispatch);

      boundIncrement();
      expect(dispatched.length, equals(1));
      expect(dispatched.first, isA<Increment>());
    });

    test('works with different action types', () {
      final dispatched = <Action>[];
      void dispatch(Action action) => dispatched.add(action);

      Decrement decrement() => const Decrement();
      final boundDecrement = bindActionCreator(decrement, dispatch);

      boundDecrement();
      expect(dispatched.first, isA<Decrement>());
    });
  });

  group('bindActionCreators', () {
    test('binds multiple action creators', () {
      final dispatched = <Action>[];
      void dispatch(Action action) => dispatched.add(action);

      final creators = <String, Action Function()>{
        'increment': () => const Increment(),
        'decrement': () => const Decrement(),
      };

      final bound = bindActionCreators(creators, dispatch);

      bound['increment']!();
      bound['decrement']!();

      expect(dispatched.length, equals(2));
      expect(dispatched[0], isA<Increment>());
      expect(dispatched[1], isA<Decrement>());
    });

    test('returns map with same keys', () {
      final dispatched = <Action>[];
      void dispatch(Action action) => dispatched.add(action);

      final creators = <String, Action Function()>{
        'a': () => const Increment(),
        'b': () => const Decrement(),
      };

      final bound = bindActionCreators(creators, dispatch);

      expect(bound.keys, containsAll(['a', 'b']));
    });
  });

  group('createDispatcher', () {
    test('creates and dispatches in one call', () {
      final dispatched = <Action>[];
      void dispatch(Action action) => dispatched.add(action);

      final dispatchIncrement = createDispatcher(
        () => const Increment(),
        dispatch,
      );
      dispatchIncrement();

      expect(dispatched.length, equals(1));
      expect(dispatched.first, isA<Increment>());
    });
  });

  group('createDispatcherWith', () {
    test('creates dispatcher with parameter', () {
      final dispatched = <Action>[];
      void dispatch(Action action) => dispatched.add(action);

      final dispatchSetValue = createDispatcherWith(
        SetValue.new,
        dispatch,
      );
      dispatchSetValue(42);

      expect(dispatched.length, equals(1));
      expect(dispatched.first, isA<SetValue>());
      expect((dispatched.first as SetValue).value, equals(42));
    });

    test('works with transform', () {
      final dispatched = <Action>[];
      void dispatch(Action action) => dispatched.add(action);

      final dispatchSetValue = createDispatcherWith<SetValue, int>(
        (v) => SetValue(v * 2),
        dispatch,
      );
      dispatchSetValue(21);

      expect((dispatched.first as SetValue).value, equals(42));
    });
  });
}
