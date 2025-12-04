/// Unit tests for mobile app types.
@TestOn('js')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:mobile/types.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(setupMocks);

  group('JSTask', () {
    test('parses id from JSObject', () {
      final task = createMockTask(id: 'task-123', title: 'Test');
      expect(task.id, equals('task-123'));
    });

    test('parses title from JSObject', () {
      final task = createMockTask(id: '1', title: 'Buy groceries');
      expect(task.title, equals('Buy groceries'));
    });

    test('parses completed false by default', () {
      final task = createMockTask(id: '1', title: 'Test');
      expect(task.completed, isFalse);
    });

    test('parses completed true', () {
      final task = createMockTask(id: '1', title: 'Test', completed: true);
      expect(task.completed, isTrue);
    });

    test('withCompleted creates new task with updated status', () {
      final task = createMockTask(id: '1', title: 'Test', completed: false);
      final updated = task.withCompleted(true);

      expect(updated.id, equals('1'));
      expect(updated.title, equals('Test'));
      expect(updated.completed, isTrue);
      // Original unchanged
      expect(task.completed, isFalse);
    });

    test('handles missing id gracefully', () {
      final jsObj = JSObject();
      jsObj['title'] = 'No ID'.toJS;
      final task = JSTask.fromJS(jsObj);
      expect(task.id, equals(''));
    });

    test('handles missing title gracefully', () {
      final jsObj = JSObject();
      jsObj['id'] = '1'.toJS;
      final task = JSTask.fromJS(jsObj);
      expect(task.title, equals(''));
    });

    test('handles missing completed gracefully', () {
      final jsObj = JSObject();
      jsObj['id'] = '1'.toJS;
      jsObj['title'] = 'Test'.toJS;
      final task = JSTask.fromJS(jsObj);
      expect(task.completed, isFalse);
    });
  });

  group('JSUser', () {
    test('parses name from JSObject', () {
      final user = createMockUser(name: 'John Doe');
      expect(user.name, equals('John Doe'));
    });

    test('parses email from JSObject', () {
      final user = createMockUser(name: 'John', email: 'john@example.com');
      expect(user.email, equals('john@example.com'));
    });

    test('handles missing name gracefully', () {
      final jsObj = JSObject();
      jsObj['email'] = 'test@test.com'.toJS;
      final user = JSUser.fromJS(jsObj);
      expect(user.name, equals(''));
    });

    test('handles missing email gracefully', () {
      final jsObj = JSObject();
      jsObj['name'] = 'Test'.toJS;
      final user = JSUser.fromJS(jsObj);
      expect(user.email, equals(''));
    });
  });

  group('AuthEffects', () {
    test('setToken is callable', () {
      var called = false;
      JSAny? capturedToken;

      final effects = createMockAuth(
        onSetToken: (t) {
          called = true;
          capturedToken = t;
        },
      );

      effects.setToken('test-token'.toJS);

      expect(called, isTrue);
      expect((capturedToken as JSString?)?.toDart, equals('test-token'));
    });

    test('setUser is callable', () {
      var called = false;
      final effects = createMockAuth(onSetUser: (_) => called = true);

      effects.setUser(createJSObject({'name': 'Test'}));

      expect(called, isTrue);
    });

    test('setView is callable', () {
      var capturedView = '';
      final effects = createMockAuth(onSetView: (v) => capturedView = v);

      effects.setView('tasks');

      expect(capturedView, equals('tasks'));
    });
  });

  group('TaskEffects', () {
    test('onToggle receives id and completed status', () {
      String? capturedId;
      bool? capturedCompleted;

      final effects = (
        onToggle: (String id, bool completed) {
          capturedId = id;
          capturedCompleted = completed;
        },
        onDelete: (String _) {},
      );

      effects.onToggle('task-1', true);

      expect(capturedId, equals('task-1'));
      expect(capturedCompleted, isTrue);
    });

    test('onDelete receives id', () {
      String? capturedId;

      final effects = (
        onToggle: (String _, bool __) {},
        onDelete: (String id) => capturedId = id,
      );

      effects.onDelete('task-to-delete');

      expect(capturedId, equals('task-to-delete'));
    });
  });
}
