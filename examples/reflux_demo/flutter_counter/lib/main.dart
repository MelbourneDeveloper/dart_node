import 'package:counter_state/counter_state.dart';
import 'package:flutter/material.dart';

void main() => runApp(const CounterApp());

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Reflux Counter',
        theme: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: Colors.indigo.shade400,
            secondary: Colors.purple.shade400,
          ),
          scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        ),
        home: const CounterScreen(),
      );
}

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  late final Store<CounterState> _store;
  late final void Function() _unsubscribe;

  @override
  void initState() {
    super.initState();
    _store = createCounterStore();
    _unsubscribe = _store.subscribe(() => setState(() {}));
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _store.getState();
    final canUndo = selectCanUndo(state);
    final stats = selectHistoryStats(state);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'Reflux Counter',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              _CountDisplay(count: state.count),
              const SizedBox(height: 24),
              _ControlButtons(
                step: state.step,
                onIncrement: () => _store.dispatch(const Increment()),
                onDecrement: () => _store.dispatch(const Decrement()),
              ),
              const SizedBox(height: 16),
              _StepSelector(
                step: state.step,
                onStepChanged: (step) => _store.dispatch(SetStep(step)),
              ),
              const SizedBox(height: 16),
              _ActionButtons(
                canUndo: canUndo,
                onUndo: () => _store.dispatch(const Undo()),
                onReset: () => _store.dispatch(const Reset()),
              ),
              const SizedBox(height: 24),
              _StatsDisplay(
                historyLength: state.history.length,
                min: stats.min,
                max: stats.max,
                avg: stats.avg,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountDisplay extends StatelessWidget {
  const _CountDisplay({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(
          '$count',
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
              ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
          ),
        ),
      );
}

class _ControlButtons extends StatelessWidget {
  const _ControlButtons({
    required this.step,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int step;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Button(label: '-$step', onPressed: onDecrement),
          const SizedBox(width: 16),
          _Button(label: '+$step', onPressed: onIncrement, primary: true),
        ],
      );
}

class _StepSelector extends StatelessWidget {
  const _StepSelector({required this.step, required this.onStepChanged});

  final int step;
  final ValueChanged<int> onStepChanged;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Step: ',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A24),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: DropdownButton<int>(
              value: step,
              dropdownColor: const Color(0xFF1A1A24),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1')),
                DropdownMenuItem(value: 5, child: Text('5')),
                DropdownMenuItem(value: 10, child: Text('10')),
              ],
              onChanged: (value) {
                if (value != null) onStepChanged(value);
              },
            ),
          ),
        ],
      );
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.canUndo,
    required this.onUndo,
    required this.onReset,
  });

  final bool canUndo;
  final VoidCallback onUndo;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Button(label: 'Undo', onPressed: canUndo ? onUndo : null),
          const SizedBox(width: 16),
          _Button(label: 'Reset', onPressed: onReset, danger: true),
        ],
      );
}

class _StatsDisplay extends StatelessWidget {
  const _StatsDisplay({
    required this.historyLength,
    required this.min,
    required this.max,
    required this.avg,
  });

  final int historyLength;
  final int min;
  final int max;
  final double avg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A24),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            _StatLine('History: $historyLength entries'),
            _StatLine('Min: $min | Max: $max'),
            _StatLine('Avg: ${avg.toStringAsFixed(1)}'),
          ],
        ),
      );
}

class _StatLine extends StatelessWidget {
  const _StatLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          text,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
      );
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        backgroundColor: primary
            ? const Color(0xFF6366F1)
            : danger
                ? const Color(0xFFEF4444)
                : const Color(0xFF1A1A24),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF1A1A24).withValues(alpha: 0.5),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: (!primary && !danger && enabled)
              ? BorderSide(color: Colors.white.withValues(alpha: 0.08))
              : BorderSide.none,
        ),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
