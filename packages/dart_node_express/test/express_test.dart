/// Tests for dart_node_express library types and APIs.
///
/// These tests run in Node.js environment to get coverage for the library.
@TestOn('node')
library;

import 'dart:js_interop';

import 'package:dart_node_coverage/dart_node_coverage.dart';
import 'package:dart_node_express/dart_node_express.dart';
import 'package:test/test.dart';

void main() {
  setUp(initCoverage);
  tearDownAll(() => writeCoverageFile('coverage/coverage.json'));

  group('express()', () {
    test('creates an Express application', () {
      final app = express();
      expect(app, isNotNull);
    });

    test('app has get method', () {
      final app = express();
      // Should not throw
      app.get('/test', handler((req, res) {}));
    });

    test('app has post method', () {
      final app = express();
      // Should not throw
      app.post('/test', handler((req, res) {}));
    });

    test('app has put method', () {
      final app = express();
      // Should not throw
      app.put('/test', handler((req, res) {}));
    });

    test('app has delete method', () {
      final app = express();
      // Should not throw
      app.delete('/test', handler((req, res) {}));
    });

    test('app has use method for middleware', () {
      final app = express();
      // Should not throw
      app.use(handler((req, res) {}));
    });
  });

  group('handler()', () {
    test('converts Dart function to JS function', () {
      final jsHandler = handler((req, res) {});
      expect(jsHandler, isA<JSFunction>());
    });
  });

  group('ExpressAppMultiHandler', () {
    test('getWithMiddleware registers route with middleware', () {
      final app = express();
      final middlewareCalled = <String>[];

      app.getWithMiddleware('/test', [
        middleware((req, res, next) {
          middlewareCalled.add('middleware1');
          next();
        }),
        handler((req, res) {
          middlewareCalled.add('handler');
        }),
      ]);
      // Route registered without throwing
      expect(true, isTrue);
    });

    test('postWithMiddleware registers route with middleware', () {
      final app = express();
      app.postWithMiddleware('/test', [handler((req, res) {})]);
      expect(true, isTrue);
    });

    test('putWithMiddleware registers route with middleware', () {
      final app = express();
      app.putWithMiddleware('/test', [handler((req, res) {})]);
      expect(true, isTrue);
    });

    test('deleteWithMiddleware registers route with middleware', () {
      final app = express();
      app.deleteWithMiddleware('/test', [handler((req, res) {})]);
      expect(true, isTrue);
    });
  });

  group('Router', () {
    test('creates a new router', () {
      final router = Router();
      expect(router, isNotNull);
    });

    test('router has get method', () {
      final router = Router();
      router.get('/test', handler((req, res) {}));
    });

    test('router has post method', () {
      final router = Router();
      router.post('/test', handler((req, res) {}));
    });

    test('router has put method', () {
      final router = Router();
      router.put('/test', handler((req, res) {}));
    });

    test('router has delete method', () {
      final router = Router();
      router.delete('/test', handler((req, res) {}));
    });

    test('router has patch method', () {
      final router = Router();
      router.patch('/test', handler((req, res) {}));
    });

    test('router use adds middleware', () {
      final router = Router();
      router.use(handler((req, res) {}));
    });

    test('router useAt adds middleware at path', () {
      final router = Router();
      router.useAt('/api', handler((req, res) {}));
    });
  });

  group('middleware()', () {
    test('converts Dart middleware to JS function', () {
      final jsMiddleware = middleware((req, res, next) {
        next();
      });
      expect(jsMiddleware, isA<JSFunction>());
    });
  });

  group('chain()', () {
    test('chains multiple middleware', () {
      final chained = chain([
        middleware((req, res, next) => next()),
        middleware((req, res, next) => next()),
        handler((req, res) {}),
      ]);
      expect(chained, isA<JSFunction>());
    });

    test('empty chain creates valid function', () {
      final chained = chain([]);
      expect(chained, isA<JSFunction>());
    });
  });

  group('asyncHandler()', () {
    test('wraps async function', () {
      final jsHandler = asyncHandler((req, res) async {
        await Future<void>.value();
      });
      expect(jsHandler, isA<JSFunction>());
    });
  });

  group('AppError types', () {
    test('ValidationError has status 400', () {
      const error = ValidationError('invalid');
      expect(error.statusCode, equals(400));
      expect(error.message, equals('invalid'));
    });

    test('ValidationError toJson returns proper structure', () {
      const error = ValidationError('invalid');
      final json = error.toJson();
      expect(json['success'], isFalse);
      expect(json['error'], isA<Map>());
      expect((json['error'] as Map)['statusCode'], equals(400));
    });

    test('UnauthorizedError has status 401', () {
      const error = UnauthorizedError();
      expect(error.statusCode, equals(401));
      expect(error.message, equals('Unauthorized'));
    });

    test('UnauthorizedError with custom message', () {
      const error = UnauthorizedError('Token expired');
      expect(error.message, equals('Token expired'));
    });

    test('ForbiddenError has status 403', () {
      const error = ForbiddenError();
      expect(error.statusCode, equals(403));
      expect(error.message, equals('Forbidden'));
    });

    test('ForbiddenError with custom message', () {
      const error = ForbiddenError('Admin only');
      expect(error.message, equals('Admin only'));
    });

    test('NotFoundError has status 404', () {
      const error = NotFoundError();
      expect(error.statusCode, equals(404));
      expect(error.message, equals('Resource not found'));
    });

    test('NotFoundError with custom resource', () {
      const error = NotFoundError('User');
      expect(error.message, equals('User not found'));
    });

    test('ConflictError has status 409', () {
      const error = ConflictError();
      expect(error.statusCode, equals(409));
      expect(error.message, equals('Resource conflict'));
    });

    test('ConflictError with custom message', () {
      const error = ConflictError('Email already exists');
      expect(error.message, equals('Email already exists'));
    });

    test('InternalError has status 500', () {
      const error = InternalError();
      expect(error.statusCode, equals(500));
      expect(error.message, equals('Internal server error'));
    });

    test('InternalError with custom message', () {
      const error = InternalError('Database connection failed');
      expect(error.message, equals('Database connection failed'));
    });
  });

  group('errorHandler()', () {
    test('creates JS function', () {
      final jsHandler = errorHandler();
      expect(jsHandler, isA<JSFunction>());
    });
  });

  group('Validation - StringValidator', () {
    test('string() creates validator', () {
      final validator = string();
      expect(validator, isA<StringValidator>());
    });

    test('validates string value', () {
      final result = string().validate('hello');
      expect(result, isA<Valid<String>>());
      expect((result as Valid<String>).value, equals('hello'));
    });

    test('rejects null value', () {
      final result = string().validate(null);
      expect(result, isA<Invalid<String>>());
    });

    test('rejects non-string value', () {
      final result = string().validate(123);
      expect(result, isA<Invalid<String>>());
    });

    test('minLength rejects short strings', () {
      final result = string().minLength(5).validate('hi');
      expect(result, isA<Invalid<String>>());
    });

    test('minLength accepts valid strings', () {
      final result = string().minLength(2).validate('hello');
      expect(result, isA<Valid<String>>());
    });

    test('maxLength rejects long strings', () {
      final result = string().maxLength(3).validate('hello');
      expect(result, isA<Invalid<String>>());
    });

    test('maxLength accepts valid strings', () {
      final result = string().maxLength(10).validate('hello');
      expect(result, isA<Valid<String>>());
    });

    test('notEmpty rejects empty string', () {
      final result = string().notEmpty().validate('');
      expect(result, isA<Invalid<String>>());
    });

    test('notEmpty accepts non-empty string', () {
      final result = string().notEmpty().validate('x');
      expect(result, isA<Valid<String>>());
    });

    test('matches validates pattern', () {
      final result = string().matches(RegExp(r'^\d+$')).validate('123');
      expect(result, isA<Valid<String>>());
    });

    test('matches rejects invalid pattern', () {
      final result = string().matches(RegExp(r'^\d+$')).validate('abc');
      expect(result, isA<Invalid<String>>());
    });

    test('email validates email format', () {
      final result = string().email().validate('test@example.com');
      expect(result, isA<Valid<String>>());
    });

    test('email rejects invalid format', () {
      final result = string().email().validate('not-an-email');
      expect(result, isA<Invalid<String>>());
    });

    test('alphanumeric validates alphanumeric', () {
      final result = string().alphanumeric().validate('abc123');
      expect(result, isA<Valid<String>>());
    });

    test('alphanumeric rejects special chars', () {
      final result = string().alphanumeric().validate('abc-123');
      expect(result, isA<Invalid<String>>());
    });

    test('chained validators work', () {
      final result = string().minLength(3).maxLength(10).validate('hello');
      expect(result, isA<Valid<String>>());
    });
  });

  group('Validation - IntValidator', () {
    test('int_() creates validator', () {
      final validator = int_();
      expect(validator, isA<IntValidator>());
    });

    test('validates int value', () {
      final result = int_().validate(42);
      expect(result, isA<Valid<int>>());
      expect((result as Valid<int>).value, equals(42));
    });

    test('validates string number', () {
      final result = int_().validate('42');
      expect(result, isA<Valid<int>>());
      expect((result as Valid<int>).value, equals(42));
    });

    test('validates num value', () {
      final result = int_().validate(42.0);
      expect(result, isA<Valid<int>>());
    });

    test('rejects null value', () {
      final result = int_().validate(null);
      expect(result, isA<Invalid<int>>());
    });

    test('rejects non-numeric string', () {
      final result = int_().validate('abc');
      expect(result, isA<Invalid<int>>());
    });

    test('rejects invalid type', () {
      final result = int_().validate([]);
      expect(result, isA<Invalid<int>>());
    });

    test('min rejects small values', () {
      final result = int_().min(10).validate(5);
      expect(result, isA<Invalid<int>>());
    });

    test('min accepts valid values', () {
      final result = int_().min(5).validate(10);
      expect(result, isA<Valid<int>>());
    });

    test('max rejects large values', () {
      final result = int_().max(10).validate(15);
      expect(result, isA<Invalid<int>>());
    });

    test('max accepts valid values', () {
      final result = int_().max(20).validate(10);
      expect(result, isA<Valid<int>>());
    });

    test('range validates within range', () {
      final result = int_().range(5, 15).validate(10);
      expect(result, isA<Valid<int>>());
    });

    test('range rejects outside range', () {
      final result = int_().range(5, 15).validate(20);
      expect(result, isA<Invalid<int>>());
    });

    test('positive rejects zero', () {
      final result = int_().positive().validate(0);
      expect(result, isA<Invalid<int>>());
    });

    test('positive rejects negative', () {
      final result = int_().positive().validate(-1);
      expect(result, isA<Invalid<int>>());
    });

    test('positive accepts positive', () {
      final result = int_().positive().validate(1);
      expect(result, isA<Valid<int>>());
    });
  });

  group('Validation - BoolValidator', () {
    test('bool_() creates validator', () {
      final validator = bool_();
      expect(validator, isA<BoolValidator>());
    });

    test('validates bool true', () {
      final result = bool_().validate(true);
      expect(result, isA<Valid<bool>>());
      expect((result as Valid<bool>).value, isTrue);
    });

    test('validates bool false', () {
      final result = bool_().validate(false);
      expect(result, isA<Valid<bool>>());
      expect((result as Valid<bool>).value, isFalse);
    });

    test('validates string true', () {
      final result = bool_().validate('true');
      expect(result, isA<Valid<bool>>());
      expect((result as Valid<bool>).value, isTrue);
    });

    test('validates string false', () {
      final result = bool_().validate('false');
      expect(result, isA<Valid<bool>>());
      expect((result as Valid<bool>).value, isFalse);
    });

    test('validates string TRUE (case insensitive)', () {
      final result = bool_().validate('TRUE');
      expect(result, isA<Valid<bool>>());
    });

    test('rejects null', () {
      final result = bool_().validate(null);
      expect(result, isA<Invalid<bool>>());
    });

    test('rejects invalid string', () {
      final result = bool_().validate('yes');
      expect(result, isA<Invalid<bool>>());
    });
  });

  group('Validation - OptionalValidator', () {
    test('optional allows null', () {
      final result = optional(string()).validate(null);
      expect(result, isA<Valid<String?>>());
      expect((result as Valid<String?>).value, isNull);
    });

    test('optional validates non-null values', () {
      final result = optional(string()).validate('hello');
      expect(result, isA<Valid<String?>>());
      expect((result as Valid<String?>).value, equals('hello'));
    });

    test('optional propagates inner validation errors', () {
      final result = optional(string().minLength(10)).validate('hi');
      expect(result, isA<Invalid<String?>>());
    });
  });

  group('Validation - Schema', () {
    test('schema validates object', () {
      final testSchema = schema<({String name, int age})>({
        'name': string(),
        'age': int_(),
      }, (m) => (name: m['name'] as String, age: m['age'] as int));

      final result = testSchema.validate({'name': 'John', 'age': 30});
      expect(result, isA<Valid<({String name, int age})>>());
      final value = (result as Valid).value as ({String name, int age});
      expect(value.name, equals('John'));
      expect(value.age, equals(30));
    });

    test('schema rejects null', () {
      final testSchema = schema<({String name})>({
        'name': string(),
      }, (m) => (name: m['name'] as String));

      final result = testSchema.validate(null);
      expect(result, isA<Invalid>());
    });

    test('schema collects field errors', () {
      final testSchema = schema<({String name, int age})>({
        'name': string().minLength(3),
        'age': int_().min(18),
      }, (m) => (name: m['name'] as String, age: m['age'] as int));

      final result = testSchema.validate({'name': 'Jo', 'age': 10});
      expect(result, isA<Invalid>());
      final errors = (result as Invalid).errors;
      expect(errors.containsKey('name'), isTrue);
      expect(errors.containsKey('age'), isTrue);
    });
  });

  group('Validator combinators', () {
    test('and chains validators', () {
      final validator = string().and(string().minLength(3));
      final result = validator.validate('hello');
      expect(result, isA<Valid<String>>());
    });

    test('and short-circuits on first failure', () {
      final validator = string().and(string().minLength(10));
      final result = validator.validate('hi');
      expect(result, isA<Invalid<String>>());
    });

    test('map transforms valid value', () {
      final validator = string().map((s) => s.length);
      final result = validator.validate('hello');
      expect(result, isA<Valid<int>>());
      expect((result as Valid<int>).value, equals(5));
    });

    test('map propagates invalid', () {
      final validator = string().map((s) => s.length);
      final result = validator.validate(123);
      expect(result, isA<Invalid<int>>());
    });
  });

  group('validateBody middleware', () {
    test('creates JS function', () {
      final testSchema = schema<({String name})>({
        'name': string(),
      }, (m) => (name: m['name'] as String));
      final middleware = validateBody(testSchema);
      expect(middleware, isA<JSFunction>());
    });
  });
}
