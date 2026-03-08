/// Admin REST endpoints for the VSCode extension.
///
/// The VSIX talks to these endpoints — never touches the DB directly.
/// Streamable HTTP endpoint pushes all state changes in real-time.
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:dart_node_express/dart_node_express.dart';
import 'package:dart_node_mcp/dart_node_mcp.dart';
import 'package:nadz/nadz.dart';
import 'package:too_many_cooks_data/too_many_cooks_data.dart';

/// Admin event hub — manages Streamable HTTP transports
/// for pushing real-time events to the VSIX.
typedef AdminEventHub = ({
  Map<String, StreamableHttpTransport> transports,
  Map<String, McpServer> servers,
  void Function(String event, Map<String, Object?> payload)
      pushEvent,
});

/// Create an admin event hub for Streamable HTTP push.
AdminEventHub createAdminEventHub() {
  final transports =
      <String, StreamableHttpTransport>{};
  final servers = <String, McpServer>{};

  void pushEvent(
    String event,
    Map<String, Object?> payload,
  ) {
    consoleError(
      '[TMC] [PUSH] $event → '
      '${servers.length} server(s), '
      '${transports.length} transport(s)',
    );
    final data = <String, Object?>{
      'event': event,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'payload': payload,
    };

    for (final entry in [...servers.entries]) {
      consoleError(
        '[TMC] [PUSH] Sending to ${entry.key}',
      );
      unawaited(
        entry.value
            .sendLoggingMessage((
              level: 'info',
              logger: 'too-many-cooks-admin',
              data: data,
            ))
            .then((_) {
              consoleError(
                '[TMC] [PUSH] Sent OK to ${entry.key}',
              );
            }, onError: (Object e) {
              consoleError(
                '[TMC] [PUSH] FAILED ${entry.key}: $e',
              );
              // Transport closed — remove it
              servers.remove(entry.key);
              transports.remove(entry.key);
            }),
      );
    }
  }

  return (
    transports: transports,
    servers: servers,
    pushEvent: pushEvent,
  );
}

/// Register admin routes on an Express app.
void registerAdminRoutes(
  ExpressApp app,
  TooManyCooksDb db,
  AdminEventHub hub,
) {
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
          hub.pushEvent(
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
          hub.pushEvent(
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
          hub.pushEvent('message_sent', {
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
          hub.pushEvent('state_reset', <String, Object?>{});
          res.send('{"reset":true}');
        case Error(:final error):
          _sendError(res, 500, dbErrorToJson(error));
      }
    }));
}

/// Send an error response.
void _sendError(Response res, int code, String message) {
  res
    ..status(code)
    ..send(message);
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
