import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:nadz/nadz.dart';

typedef HttpMethod = String;

typedef Fetch =
    Future<Result<JSObject, String>> Function(
      String url, {
      HttpMethod method,
      String? token,
      Map<String, dynamic>? body,
    });

Future<Result<JSObject, String>> fetchJson(
  String url, {
  HttpMethod method = 'GET',
  String? token,
  Map<String, dynamic>? body,
}) async {
  final headers = _buildHeaders(token);
  final options = _createOptions(method, headers, body);
  final response = await _executeRequest(url, options);
  return response.bind(_guardSuccess);
}

Future<Result<JSArray, String>> fetchTasks({
  required String token,
  required String apiUrl,
}) async => (await fetchJson('$apiUrl/tasks', token: token)).map(_readTaskData);

List<String> getObjectKeys(JSObject obj) => _jsObjectKeys(
  obj,
).toDart.whereType<JSString>().map((key) => key.toDart).toList();

JSObject mapToJsObject(Map<String, dynamic> map) {
  final obj = JSObject();
  for (final entry in map.entries) {
    final value = entry.value;
    obj.setProperty(entry.key.toJS, switch (value) {
      final String s => s.toJS,
      final bool b => b.toJS,
      final num n => n.toJS,
      final JSAny jsValue => jsValue,
      _ => value.toString().toJS,
    });
  }
  return obj;
}

String extractErrorMessage(JSObject json) {
  final fieldErrors = switch (json['fields']) {
    final JSObject fields => _extractFieldErrors(fields),
    _ => null,
  };
  return switch (fieldErrors) {
    final String message => message,
    _ => _readError(json['error']),
  };
}

@JS('fetch')
external JSPromise _jsFetch(JSString url, JSObject? options);

@JS('JSON.stringify')
external JSString _jsonStringify(JSAny obj);

@JS('Object.keys')
external JSArray _jsObjectKeys(JSObject obj);

Map<String, String> _buildHeaders(String? token) => switch (token) {
  null => {'Content-Type': 'application/json'},
  final String t => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $t',
  },
};

JSObject _createOptions(
  HttpMethod method,
  Map<String, String> headers,
  Map<String, dynamic>? body,
) {
  final options = JSObject()
    ..setProperty('method'.toJS, method.toJS)
    ..setProperty('headers'.toJS, mapToJsObject(headers));
  switch (body) {
    case final Map<String, dynamic> payload:
      options.setProperty('body'.toJS, _jsonStringify(mapToJsObject(payload)));
  }
  return options;
}

Future<Result<JSObject, String>> _executeRequest(
  String url,
  JSObject options,
) async {
  final rawResponse = await _jsFetch(url.toJS, options).toDart;
  switch (rawResponse) {
    case JSObject obj:
      return _parseResponse(obj);
    default:
      return const Error('Response is not an object');
  }
}

Future<Result<JSObject, String>> _parseResponse(JSObject response) {
  final promise = response.callMethod('json'.toJS);
  switch (promise) {
    case JSPromise jsPromise:
      return _resolveJson(jsPromise);
    default:
      return Future.value(const Error('json() did not return a promise'));
  }
}

Future<Result<JSObject, String>> _resolveJson(JSPromise promise) async {
  final rawJson = await promise.toDart;
  return switch (rawJson) {
    final JSObject json => Success(json),
    _ => const Error('JSON response is not an object'),
  };
}

Result<JSObject, String> _guardSuccess(JSObject json) {
  final successFlag = switch (json['success']) {
    final JSBoolean flag => flag.toDart,
    _ => false,
  };
  return successFlag ? Success(json) : Error(extractErrorMessage(json));
}

JSArray _readTaskData(JSObject json) => switch (json['data']) {
  final JSArray tasks => tasks,
  _ => <JSAny>[].toJS,
};

String _readError(JSAny? error) => switch (error) {
  final JSString s => s.toDart,
  final JSObject obj =>
    (obj['message'] as JSString?)?.toDart ?? 'Request failed',
  _ => 'Request failed',
};

String? _extractFieldErrors(JSObject fields) {
  final keys = getObjectKeys(fields);
  final errors = <String>[];
  for (final key in keys) {
    final value = fields[key];
    final messages = switch (value) {
      final JSArray arr =>
        arr.toDart
            .map((entry) => (entry as JSString?)?.toDart ?? '')
            .where((message) => message.isNotEmpty)
            .toList(),
      _ => <String>[],
    };
    errors.addAll(messages.map((msg) => '$key: $msg'));
  }
  return errors.isEmpty ? null : errors.join(', ');
}
