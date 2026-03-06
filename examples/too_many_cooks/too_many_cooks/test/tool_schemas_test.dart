/// Tests for tool input schema definitions.
/// Ensures maxLength and other constraints are present
/// so agents respect limits.
library;

import 'package:test/test.dart';
import 'package:too_many_cooks/src/tools/message_tool.dart';
import 'package:too_many_cooks/src/tools/plan_tool.dart';
import 'package:too_many_cooks/src/tools/register_tool.dart';

Map<String, Object?> _props(Map<String, Object?> schema) {
  if (schema['properties'] case final Map<String, Object?> p) return p;
  throw StateError('No properties in schema');
}

Map<String, Object?> _field(
  Map<String, Object?> schema,
  String name,
) {
  if (_props(schema)[name] case final Map<String, Object?> f) return f;
  throw StateError('No field $name in schema');
}

String _desc(Map<String, Object?> schema, String name) {
  if (_field(schema, name)['description'] case final String d) return d;
  throw StateError('No description for $name');
}

void main() {
  group('message tool schema', () {
    test('content has maxLength 200', () {
      expect(_field(messageInputSchema, 'content')['maxLength'], 200);
    });

    test('content description mentions 200 char limit', () {
      expect(_desc(messageInputSchema, 'content'), contains('200'));
    });
  });

  group('plan tool schema', () {
    test('goal has maxLength 100', () {
      expect(_field(planInputSchema, 'goal')['maxLength'], 100);
    });

    test('goal description mentions 100 char limit', () {
      expect(_desc(planInputSchema, 'goal'), contains('100'));
    });

    test('current_task has maxLength 100', () {
      expect(
        _field(planInputSchema, 'current_task')['maxLength'],
        100,
      );
    });

    test('current_task description mentions char limit', () {
      expect(
        _desc(planInputSchema, 'current_task'),
        contains('100'),
      );
    });
  });

  group('register tool schema', () {
    test('has name field for first registration', () {
      expect(_props(registerInputSchema), contains('name'));
    });

    test('has key field for reconnect', () {
      expect(_props(registerInputSchema), contains('key'));
    });

    test('name description says first registration only', () {
      expect(
        _desc(registerInputSchema, 'name'),
        contains('FIRST'),
      );
    });

    test('key description says reconnect only', () {
      expect(
        _desc(registerInputSchema, 'key'),
        contains('RECONNECT'),
      );
    });

    test('does not require both name and key', () {
      // Schema should NOT have required: ['name', 'key']
      // Either name or key, not both — validated in handler
      expect(registerInputSchema['required'], isNull);
    });

    test('description explains both modes', () {
      expect(
        registerToolConfig.description,
        allOf(
          contains('name'),
          contains('key'),
          contains('RECONNECT'),
        ),
      );
    });
  });
}
