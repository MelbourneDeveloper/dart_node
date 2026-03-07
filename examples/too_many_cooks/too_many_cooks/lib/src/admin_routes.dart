/// Admin REST endpoints for the VSCode extension.
///
/// The VSIX talks to these endpoints — never touches the DB directly.
/// SSE endpoint pushes all state changes in real-time.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_express/dart_node_express.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks_data/too_many_cooks_data.dart';

/// Active SSE connections for push events.
final _sseClients = <Response>[];

/// Register admin routes on an Express app.
void registerAdminRoutes(ExpressApp app, TooManyCooksDb db) {
  // JSON body parser
  final expressModule = requireModule('express') as JSObject;
  final jsonMiddleware =
      (expressModule['json'] as JSFunction?)
          ?.callAsFunction(expressModule);
  app
    ..use(jsonMiddleware)

    // GET /admin/status — full status snapshot
    ..get('/admin/status', handler((req, res) {
      final agents = switch (db.listAgents()) {
        Success(:final value) =>
          value.map(agentIdentityToJson).join(','),
        Error() => '',
      };
      final locks = switch (db.listLocks()) {
        Success(:final value) =>
          value.map(fileLockToJson).join(','),
        Error() => '',
      };
      final plans = switch (db.listPlans()) {
        Success(:final value) =>
          value.map(agentPlanToJson).join(','),
        Error() => '',
      };
      final messages = switch (db.listAllMessages()) {
        Success(:final value) =>
          value.map(messageToJson).join(','),
        Error() => '',
      };

      res
        ..set('Content-Type', 'application/json')
        ..send(
          '{"agents":[$agents],"locks":[$locks],'
          '"plans":[$plans],"messages":[$messages]}',
        );
    }))

    // POST /admin/delete-lock — force-delete a lock
    ..post('/admin/delete-lock', handler((req, res) {
      final body = _parseBody(req);
      final filePath = body['filePath'] as String?;
      if (filePath == null) {
        _sendError(res, 400, 'filePath required');
        return;
      }
      switch (db.adminDeleteLock(filePath)) {
        case Success():
          _pushEvent(
            'lock_released',
            {'file_path': filePath},
          );
          res.send('{"deleted":true}');
        case Error(:final error):
          _sendError(res, 400, dbErrorToJson(error));
      }
    }))

    // POST /admin/delete-agent — delete agent + data
    ..post('/admin/delete-agent', handler((req, res) {
      final body = _parseBody(req);
      final agentName = body['agentName'] as String?;
      if (agentName == null) {
        _sendError(res, 400, 'agentName required');
        return;
      }
      switch (db.adminDeleteAgent(agentName)) {
        case Success():
          _pushEvent(
            'agent_deleted',
            {'agent_name': agentName},
          );
          res.send('{"deleted":true}');
        case Error(:final error):
          _sendError(res, 400, dbErrorToJson(error));
      }
    }))

    // POST /admin/reset-key — generate new key for agent
    ..post('/admin/reset-key', handler((req, res) {
      final body = _parseBody(req);
      final agentName = body['agentName'] as String?;
      if (agentName == null) {
        _sendError(res, 400, 'agentName required');
        return;
      }
      switch (db.adminResetKey(agentName)) {
        case Success(:final value):
          res.send(agentRegistrationToJson(value));
        case Error(:final error):
          _sendError(res, 400, dbErrorToJson(error));
      }
    }))

    // POST /admin/send-message — send message (no auth)
    ..post('/admin/send-message', handler((req, res) {
      final body = _parseBody(req);
      final fromAgent = body['fromAgent'] as String?;
      final toAgent = body['toAgent'] as String?;
      final content = body['content'] as String?;
      if (fromAgent == null ||
          toAgent == null ||
          content == null) {
        _sendError(
          res,
          400,
          'fromAgent, toAgent, content required',
        );
        return;
      }
      switch (db.adminSendMessage(
        fromAgent,
        toAgent,
        content,
      )) {
        case Success(:final value):
          _pushEvent('message_sent', {
            'from_agent': fromAgent,
            'to_agent': toAgent,
            'message_id': value,
          });
          res.send(
            '{"sent":true,"message_id":"$value"}',
          );
        case Error(:final error):
          _sendError(res, 400, dbErrorToJson(error));
      }
    }))

    // POST /admin/reset — clear all data (testing)
    ..post('/admin/reset', handler((req, res) {
      switch (db.adminReset()) {
        case Success():
          res.send('{"reset":true}');
        case Error(:final error):
          _sendError(res, 500, dbErrorToJson(error));
      }
    }))

    // GET /admin/events — SSE stream
    ..get('/admin/events', handler((req, res) {
      res
        ..set('Content-Type', 'text/event-stream')
        ..set('Cache-Control', 'no-cache')
        ..set('Connection', 'keep-alive')
        ..set('Access-Control-Allow-Origin', '*');

      _writeSSE(
        res,
        'connected',
        '{"status":"connected"}',
      );

      _sseClients.add(res);

      // Remove on disconnect via req.socket close event
      final socket =
          (req as JSObject)['socket'] as JSObject?;
      if (socket != null) {
        (socket['on'] as JSFunction?)?.callAsFunction(
          socket,
          'close'.toJS,
          (() {
            _sseClients.remove(res);
          }).toJS,
        );
      }
    }));
}

/// Push an event to all SSE clients.
void _pushEvent(
  String event,
  Map<String, Object?> payload,
) {
  final data =
      '{"event":"$event",'
      '"payload":${_simpleJsonEncode(payload)}}';
  for (final client in [..._sseClients]) {
    try {
      _writeSSE(client, event, data);
    } on Object {
      _sseClients.remove(client);
    }
  }
}

/// Write an SSE event to a response.
void _writeSSE(Response res, String event, String data) {
  final writeFn =
      (res as JSObject)['write'] as JSFunction?;
  writeFn?.callAsFunction(
    res,
    'event: $event\ndata: $data\n\n'.toJS,
  );
}

/// Send an error response.
void _sendError(Response res, int code, String message) {
  res
    ..status(code)
    ..send(message);
}

/// Simple JSON encoder for maps.
String _simpleJsonEncode(Map<String, Object?> map) {
  final entries = map.entries.map((e) => switch (e.value) {
    final String s => '"${e.key}":"$s"',
    final int n => '"${e.key}":$n',
    final bool b => '"${e.key}":$b',
    null => '"${e.key}":null',
    _ => '"${e.key}":"${e.value}"',
  });
  return '{${entries.join(',')}}';
}

/// Parse request body as Map.
Map<String, Object?> _parseBody(Request req) {
  final body = req.body;
  if (body == null) return {};
  final dartified = body.dartify();
  if (dartified is Map) {
    return Map<String, Object?>.fromEntries(
      dartified.entries.map(
        (e) => MapEntry(e.key.toString(), e.value),
      ),
    );
  }
  return {};
}
