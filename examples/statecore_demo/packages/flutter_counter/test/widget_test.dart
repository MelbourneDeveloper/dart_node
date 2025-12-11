import 'package:flutter/material.dart';
import 'package:flutter_counter/main.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _incrementBtn() => find.widgetWithText(ElevatedButton, '+1');
Finder _decrementBtn() => find.widgetWithText(ElevatedButton, '-1');
Finder _incrementBtn5() => find.widgetWithText(ElevatedButton, '+5');
Finder _decrementBtn5() => find.widgetWithText(ElevatedButton, '-5');
Finder _incrementBtn10() => find.widgetWithText(ElevatedButton, '+10');
Finder _decrementBtn10() => find.widgetWithText(ElevatedButton, '-10');
Finder _undoBtn() => find.widgetWithText(ElevatedButton, 'Undo');
Finder _resetBtn() => find.widgetWithText(ElevatedButton, 'Reset');

/// Finds text with large font (the count display).
Finder _countText(String text) => find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data == text &&
          widget.style?.fontSize == 72,
    );

void main() {
  testWidgets('initial state shows count 0 and correct UI elements',
      (tester) async {
    await tester.pumpWidget(const CounterApp());

    expect(find.text('Statecore Counter'), findsOneWidget);
    expect(_countText('0'), findsOneWidget);
    expect(_incrementBtn(), findsOneWidget);
    expect(_decrementBtn(), findsOneWidget);
    expect(_undoBtn(), findsOneWidget);
    expect(_resetBtn(), findsOneWidget);
    expect(find.text('Step: '), findsOneWidget);
    expect(find.text('History: 1 entries'), findsOneWidget);
    expect(find.text('Min: 0 | Max: 0'), findsOneWidget);
    expect(find.text('Avg: 0.0'), findsOneWidget);

    await expectLater(
      find.byType(CounterApp),
      matchesGoldenFile('goldens/initial_state.png'),
    );
  });

  testWidgets('increment button increases count by step', (tester) async {
    await tester.pumpWidget(const CounterApp());

    await tester.tap(_incrementBtn());
    await tester.pump();

    expect(_countText('1'), findsOneWidget);
    expect(find.text('History: 2 entries'), findsOneWidget);
    expect(find.text('Min: 0 | Max: 1'), findsOneWidget);
    expect(find.text('Avg: 0.5'), findsOneWidget);

    await tester.tap(_incrementBtn());
    await tester.pump();

    expect(_countText('2'), findsOneWidget);
    expect(find.text('History: 3 entries'), findsOneWidget);
    expect(find.text('Min: 0 | Max: 2'), findsOneWidget);
    expect(find.text('Avg: 1.0'), findsOneWidget);

    await tester.tap(_incrementBtn());
    await tester.pump();

    expect(_countText('3'), findsOneWidget);
    expect(find.text('History: 4 entries'), findsOneWidget);

    await expectLater(
      find.byType(CounterApp),
      matchesGoldenFile('goldens/after_increments.png'),
    );
  });

  testWidgets('decrement button decreases count', (tester) async {
    await tester.pumpWidget(const CounterApp());

    await tester.tap(_decrementBtn());
    await tester.pump();

    expect(find.text('History: 2 entries'), findsOneWidget);
    expect(find.text('Min: -1 | Max: 0'), findsOneWidget);
    expect(find.text('Avg: -0.5'), findsOneWidget);

    await tester.tap(_decrementBtn());
    await tester.pump();

    expect(find.text('History: 3 entries'), findsOneWidget);
    expect(find.text('Min: -2 | Max: 0'), findsOneWidget);

    await expectLater(
      find.byType(CounterApp),
      matchesGoldenFile('goldens/negative_count.png'),
    );
  });

  testWidgets('undo button is disabled when no history', (tester) async {
    await tester.pumpWidget(const CounterApp());

    final button = tester.widget<ElevatedButton>(_undoBtn());
    expect(button.onPressed, isNull);
  });

  testWidgets('undo button reverts last action', (tester) async {
    await tester.pumpWidget(const CounterApp());

    await tester.tap(_incrementBtn());
    await tester.pump();
    expect(_countText('1'), findsOneWidget);

    await tester.tap(_incrementBtn());
    await tester.pump();
    expect(_countText('2'), findsOneWidget);

    var button = tester.widget<ElevatedButton>(_undoBtn());
    expect(button.onPressed, isNotNull);

    await tester.tap(_undoBtn());
    await tester.pump();

    expect(_countText('1'), findsOneWidget);
    expect(find.text('History: 2 entries'), findsOneWidget);

    await tester.tap(_undoBtn());
    await tester.pump();

    expect(_countText('0'), findsOneWidget);
    expect(find.text('History: 1 entries'), findsOneWidget);

    button = tester.widget<ElevatedButton>(_undoBtn());
    expect(button.onPressed, isNull);
  });

  testWidgets('reset button clears count and history', (tester) async {
    await tester.pumpWidget(const CounterApp());

    await tester.tap(_incrementBtn());
    await tester.pump();
    await tester.tap(_incrementBtn());
    await tester.pump();
    await tester.tap(_incrementBtn());
    await tester.pump();

    expect(_countText('3'), findsOneWidget);
    expect(find.text('History: 4 entries'), findsOneWidget);

    await tester.tap(_resetBtn());
    await tester.pump();

    expect(_countText('0'), findsOneWidget);
    expect(find.text('History: 1 entries'), findsOneWidget);
    expect(find.text('Min: 0 | Max: 0'), findsOneWidget);
    expect(find.text('Avg: 0.0'), findsOneWidget);
  });

  testWidgets('step selector changes step size', (tester) async {
    await tester.pumpWidget(const CounterApp());

    expect(_incrementBtn(), findsOneWidget);
    expect(_decrementBtn(), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('5').last);
    await tester.pumpAndSettle();

    expect(_incrementBtn5(), findsOneWidget);
    expect(_decrementBtn5(), findsOneWidget);

    await tester.tap(_incrementBtn5());
    await tester.pump();

    expect(find.text('History: 2 entries'), findsOneWidget);

    await expectLater(
      find.byType(CounterApp),
      matchesGoldenFile('goldens/step_5.png'),
    );
  });

  testWidgets('step 10 works correctly', (tester) async {
    await tester.pumpWidget(const CounterApp());

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('10').last);
    await tester.pumpAndSettle();

    expect(_incrementBtn10(), findsOneWidget);
    expect(_decrementBtn10(), findsOneWidget);

    await tester.tap(_incrementBtn10());
    await tester.pump();

    await tester.tap(_incrementBtn10());
    await tester.pump();

    expect(_countText('20'), findsOneWidget);

    await tester.tap(_decrementBtn10());
    await tester.pump();

    await expectLater(
      find.byType(CounterApp),
      matchesGoldenFile('goldens/step_10.png'),
    );
  });

  testWidgets('mixed operations work correctly', (tester) async {
    await tester.pumpWidget(const CounterApp());

    await tester.tap(_incrementBtn());
    await tester.pump();
    await tester.tap(_incrementBtn());
    await tester.pump();
    await tester.tap(_incrementBtn());
    await tester.pump();

    expect(_countText('3'), findsOneWidget);

    await tester.tap(_decrementBtn());
    await tester.pump();

    expect(_countText('2'), findsOneWidget);
    expect(find.text('History: 5 entries'), findsOneWidget);

    await tester.tap(_undoBtn());
    await tester.pump();

    expect(_countText('3'), findsOneWidget);
    expect(find.text('History: 4 entries'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5').last);
    await tester.pumpAndSettle();

    await tester.tap(_incrementBtn5());
    await tester.pump();

    expect(_countText('8'), findsOneWidget);

    await expectLater(
      find.byType(CounterApp),
      matchesGoldenFile('goldens/mixed_operations.png'),
    );
  });

  testWidgets('reset preserves step size', (tester) async {
    await tester.pumpWidget(const CounterApp());

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10').last);
    await tester.pumpAndSettle();

    await tester.tap(_incrementBtn10());
    await tester.pump();
    await tester.tap(_incrementBtn10());
    await tester.pump();

    expect(_countText('20'), findsOneWidget);
    expect(_incrementBtn10(), findsOneWidget);

    await tester.tap(_resetBtn());
    await tester.pump();

    expect(_countText('0'), findsOneWidget);
    expect(_incrementBtn10(), findsOneWidget);
    expect(_decrementBtn10(), findsOneWidget);
  });

  testWidgets('stats update correctly through operations', (tester) async {
    await tester.pumpWidget(const CounterApp());

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5').last);
    await tester.pumpAndSettle();

    await tester.tap(_incrementBtn5());
    await tester.pump();
    expect(find.text('Min: 0 | Max: 5'), findsOneWidget);

    await tester.tap(_incrementBtn5());
    await tester.pump();
    expect(find.text('Min: 0 | Max: 10'), findsOneWidget);

    await tester.tap(_decrementBtn5());
    await tester.pump();

    expect(find.text('Min: 0 | Max: 10'), findsOneWidget);
    expect(find.text('History: 4 entries'), findsOneWidget);
    expect(find.text('Avg: 5.0'), findsOneWidget);

    await expectLater(
      find.byType(CounterApp),
      matchesGoldenFile('goldens/stats_display.png'),
    );
  });

  testWidgets('rapid clicks all register', (tester) async {
    await tester.pumpWidget(const CounterApp());

    for (var i = 0; i < 10; i++) {
      await tester.tap(_incrementBtn());
      await tester.pump();
    }

    expect(find.text('History: 11 entries'), findsOneWidget);
    expect(find.text('Min: 0 | Max: 10'), findsOneWidget);
    expect(find.text('Avg: 5.0'), findsOneWidget);

    await expectLater(
      find.byType(CounterApp),
      matchesGoldenFile('goldens/rapid_clicks.png'),
    );
  });

  testWidgets('undo all the way back works', (tester) async {
    await tester.pumpWidget(const CounterApp());

    for (var i = 0; i < 5; i++) {
      await tester.tap(_incrementBtn());
      await tester.pump();
    }

    for (var i = 0; i < 5; i++) {
      await tester.tap(_undoBtn());
      await tester.pump();
    }

    expect(_countText('0'), findsOneWidget);
    expect(find.text('History: 1 entries'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(_undoBtn());
    expect(button.onPressed, isNull);
  });

  testWidgets('negative count displays correctly', (tester) async {
    await tester.pumpWidget(const CounterApp());

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10').last);
    await tester.pumpAndSettle();

    await tester.tap(_decrementBtn10());
    await tester.pump();

    expect(find.text('Min: -10 | Max: 0'), findsOneWidget);

    await tester.tap(_decrementBtn10());
    await tester.pump();

    expect(_countText('-20'), findsOneWidget);
    expect(find.text('Min: -20 | Max: 0'), findsOneWidget);

    await expectLater(
      find.byType(CounterApp),
      matchesGoldenFile('goldens/large_negative.png'),
    );
  });
}
