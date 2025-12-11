import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:nadz/nadz.dart';

import 'async_handler.dart';
import 'request.dart';
import 'response.dart';

/// Validation result - sealed for exhaustive matching
sealed class ValidationResult<T> {
  const ValidationResult();
}

/// Validation succeeded with typed value
class Valid<T> extends ValidationResult<T> {
  final T value;
  const Valid(this.value);
}

/// Validation failed with field errors
class Invalid<T> extends ValidationResult<T> {
  final Map<String, List<String>> errors;
  const Invalid(this.errors);
}

/// Base validator interface
abstract class Validator<T> {
  ValidationResult<T> validate(dynamic value);

  /// Chain validators
  Validator<T> and(Validator<T> other) => _AndValidator(this, other);

  /// Transform the validated value
  Validator<R> map<R>(R Function(T) transform) =>
      _MapValidator(this, transform);
}

class _AndValidator<T> extends Validator<T> {
  final Validator<T> first;
  final Validator<T> second;

  _AndValidator(this.first, this.second);

  @override
  ValidationResult<T> validate(dynamic value) {
    final firstResult = first.validate(value);
    return switch (firstResult) {
      Invalid() => firstResult,
      Valid(:final value) => second.validate(value),
    };
  }
}

class _MapValidator<T, R> extends Validator<R> {
  final Validator<T> inner;
  final R Function(T) transform;

  _MapValidator(this.inner, this.transform);

  @override
  ValidationResult<R> validate(dynamic value) {
    final result = inner.validate(value);
    return switch (result) {
      Valid(:final value) => Valid(transform(value)),
      Invalid(:final errors) => Invalid(errors),
    };
  }
}

// ============================================================================
// String Validators
// ============================================================================

/// Create a string validator
StringValidator string() => StringValidator();

class StringValidator extends Validator<String> {
  final List<String Function(String)> _checks = [];
  final String _fieldName;

  StringValidator([this._fieldName = 'value']);

  @override
  ValidationResult<String> validate(dynamic value) {
    if (value == null) {
      return Invalid({
        _fieldName: ['is required'],
      });
    }
    if (value is! String) {
      return Invalid({
        _fieldName: ['must be a string'],
      });
    }

    final errors = <String>[];
    for (final check in _checks) {
      final error = check(value);
      if (error.isNotEmpty) errors.add(error);
    }

    if (errors.isNotEmpty) {
      return Invalid({_fieldName: errors});
    }
    return Valid(value);
  }

  StringValidator _addCheck(String Function(String) check) {
    _checks.add(check);
    return this;
  }

  /// Minimum length
  StringValidator minLength(int min) => _addCheck(
    (v) => v.length < min ? 'must be at least $min characters' : '',
  );

  /// Maximum length
  StringValidator maxLength(int max) =>
      _addCheck((v) => v.length > max ? 'must be at most $max characters' : '');

  /// Must not be empty
  StringValidator notEmpty() =>
      _addCheck((v) => v.isEmpty ? 'must not be empty' : '');

  /// Must match pattern
  StringValidator matches(RegExp pattern, [String? message]) => _addCheck(
    (v) => !pattern.hasMatch(v) ? (message ?? 'invalid format') : '',
  );

  /// Must be a valid email
  StringValidator email() =>
      matches(RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$'), 'must be a valid email');

  /// Must be alphanumeric
  StringValidator alphanumeric() =>
      matches(RegExp(r'^[a-zA-Z0-9]+$'), 'must be alphanumeric');
}

// ============================================================================
// Number Validators
// ============================================================================

/// Create an int validator
IntValidator int_() => IntValidator();

class IntValidator extends Validator<int> {
  final List<String Function(int)> _checks = [];
  final String _fieldName;

  IntValidator([this._fieldName = 'value']);

  @override
  ValidationResult<int> validate(dynamic value) {
    if (value == null) {
      return Invalid({
        _fieldName: ['is required'],
      });
    }

    int intValue;
    if (value is int) {
      intValue = value;
    } else if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed == null) {
        return Invalid({
          _fieldName: ['must be a number'],
        });
      }
      intValue = parsed;
    } else if (value is num) {
      intValue = value.toInt();
    } else {
      return Invalid({
        _fieldName: ['must be a number'],
      });
    }

    final errors = <String>[];
    for (final check in _checks) {
      final error = check(intValue);
      if (error.isNotEmpty) errors.add(error);
    }

    if (errors.isNotEmpty) {
      return Invalid({_fieldName: errors});
    }
    return Valid(intValue);
  }

  IntValidator _addCheck(String Function(int) check) {
    _checks.add(check);
    return this;
  }

  /// Minimum value
  IntValidator min(int min) =>
      _addCheck((v) => v < min ? 'must be at least $min' : '');

  /// Maximum value
  IntValidator max(int max) =>
      _addCheck((v) => v > max ? 'must be at most $max' : '');

  /// Must be in range
  IntValidator range(int min, int max) => this.min(min).max(max);

  /// Must be positive
  IntValidator positive() => _addCheck((v) => v <= 0 ? 'must be positive' : '');
}

// ============================================================================
// Bool Validator
// ============================================================================

/// Create a bool validator
BoolValidator bool_() => BoolValidator();

class BoolValidator extends Validator<bool> {
  final String _fieldName;

  BoolValidator([this._fieldName = 'value']);

  @override
  ValidationResult<bool> validate(dynamic value) {
    if (value == null) {
      return Invalid({
        _fieldName: ['is required'],
      });
    }
    if (value is bool) {
      return Valid(value);
    }
    if (value is String) {
      if (value.toLowerCase() == 'true') return Valid(true);
      if (value.toLowerCase() == 'false') return Valid(false);
    }
    return Invalid({
      _fieldName: ['must be a boolean'],
    });
  }
}

// ============================================================================
// Optional Validator
// ============================================================================

/// Make a validator optional (null is valid)
OptionalValidator<T> optional<T>(Validator<T> inner) =>
    OptionalValidator(inner);

class OptionalValidator<T> extends Validator<T?> {
  final Validator<T> inner;

  OptionalValidator(this.inner);

  @override
  ValidationResult<T?> validate(dynamic value) {
    if (value == null) return const Valid(null);
    final result = inner.validate(value);
    return switch (result) {
      Valid(:final value) => Valid(value),
      Invalid(:final errors) => Invalid(errors),
    };
  }
}

// ============================================================================
// Schema Validator (for objects)
// ============================================================================

/// Create a schema for validating objects
Schema<T> schema<T>(
  Map<String, Validator> fields,
  T Function(Map<String, dynamic>) constructor,
) => Schema(fields, constructor);

class Schema<T> extends Validator<T> {
  final Map<String, Validator> fields;
  final T Function(Map<String, dynamic>) constructor;

  Schema(this.fields, this.constructor);

  @override
  ValidationResult<T> validate(dynamic value) {
    if (value == null) {
      return const Invalid({
        'body': ['is required'],
      });
    }

    final map = switch (value) {
      final Map<String, dynamic> m => m,
      final JSObject jsObj => switch (jsObj.dartify()) {
        final Map m => m.cast<String, dynamic>(),
        _ => null,
      },
      _ => null,
    };
    if (map == null) {
      return const Invalid({
        'body': ['must be an object'],
      });
    }

    final errors = <String, List<String>>{};
    final validated = <String, dynamic>{};

    for (final entry in fields.entries) {
      final fieldName = entry.key;
      final validator = entry.value;
      final fieldValue = map[fieldName];

      final result = validator.validate(fieldValue);
      switch (result) {
        case Valid(:final value):
          validated[fieldName] = value;
        case final Invalid invalid:
          // Prefix errors with field name
          for (final e in invalid.errors.entries) {
            final key = e.key == 'value' ? fieldName : '$fieldName.${e.key}';
            errors[key] = e.value;
          }
      }
    }

    if (errors.isNotEmpty) {
      return Invalid(errors);
    }

    return Valid(constructor(validated));
  }
}

// ============================================================================
// Validation Middleware
// ============================================================================

/// Key for storing validated body in request context
const _validatedBodyKey = '__validated_body__';

/// Create middleware that validates request body
JSFunction validateBody<T extends Object>(Schema<T> schema) {
  return ((Request req, Response res, JSNextFunction next) {
    final result = schema.validate(req.body);

    switch (result) {
      case Valid(:final value):
        // Store validated data in request context
        req[_validatedBodyKey] = value.jsify();
        next();
      case Invalid(:final errors):
        res.status(400);
        res.jsonMap({'error': 'Validation failed', 'fields': errors});
    }
  }).toJS;
}

/// Get validated body from request (use after validateBody middleware)
Result<T, String> getValidatedBody<T>(Request req) {
  final value = req[_validatedBodyKey]?.dartify();
  return switch (value) {
    final T v => Success(v),
    _ => const Error('No validated body found. Did you use validateBody middleware?'),
  };
}
