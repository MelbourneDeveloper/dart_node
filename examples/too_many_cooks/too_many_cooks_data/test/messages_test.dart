/// Tests for inter-agent messaging.
library;

import 'dart:js_interop';

import 'package:dart_node_core/dart_node_core.dart';
import 'package:nadz/nadz.dart';
import 'package:test/test.dart';
import 'package:too_many_cooks_data/too_many_cooks_data.dart';

extension type _Fs(JSObject _) implements JSObject {
  external void unlinkSync(String path);
  external bool existsSync(String path);
}

final _Fs _fs = _Fs(requireModule('fs') as JSObject);

void _deleteIfExists(String path) {
  try {
    if (_fs.existsSync(path)) {
      _fs.unlinkSync(path);
    }
  } on Object catch (_) {}
}

void main() {
  const testDbPath = '.test_messages.db';
  TooManyCooksDb? db;
  var senderName = '';
  var senderKey = '';
  var receiverName = '';
  var receiverKey = '';

  setUp(() {
    _deleteIfExists(testDbPath);
    final config = createDataConfig(dbPath: testDbPath);
    final result = createDb(config);
    expect(result, isA<Success<TooManyCooksDb, String>>());
    db = (result as Success<TooManyCooksDb, String>).value;

    // Register sender
    final senderReg = db!.register('sender-agent');
    final sender = (senderReg as Success<AgentRegistration, DbError>).value;
    senderName = sender.agentName;
    senderKey = sender.agentKey;

    // Register receiver
    final receiverReg = db!.register('receiver-agent');
    final receiver = (receiverReg as Success<AgentRegistration, DbError>).value;
    receiverName = receiver.agentName;
    receiverKey = receiver.agentKey;
  });

  tearDown(() {
    db?.close();
    _deleteIfExists(testDbPath);
  });

  test('sendMessage creates message with ID', () {
    final result = db!.sendMessage(
      senderName,
      senderKey,
      receiverName,
      'Hello!',
    );
    expect(result, isA<Success<String, DbError>>());
    final messageId = (result as Success<String, DbError>).value;
    expect(messageId.length, 16);
  });

  test('sendMessage fails with invalid credentials', () {
    final result = db!.sendMessage(
      senderName,
      'wrong-key',
      receiverName,
      'Hello!',
    );
    expect(result, isA<Error<String, DbError>>());
    final error = (result as Error<String, DbError>).error;
    expect(error.code, errUnauthorized);
  });

  test('sendMessage fails for content exceeding max length', () {
    final longContent = 'x' * 201; // Default max is 200
    final result = db!.sendMessage(
      senderName,
      senderKey,
      receiverName,
      longContent,
    );
    expect(result, isA<Error<String, DbError>>());
    final error = (result as Error<String, DbError>).error;
    expect(error.code, errValidation);
    expect(error.message, contains('200'));
  });

  test('getMessages returns messages for agent', () {
    db!.sendMessage(senderName, senderKey, receiverName, 'Message 1');
    db!.sendMessage(senderName, senderKey, receiverName, 'Message 2');

    final result = db!.getMessages(receiverName, receiverKey);
    expect(result, isA<Success<List<Message>, DbError>>());
    final messages = (result as Success<List<Message>, DbError>).value;
    expect(messages.length, 2);
    expect(messages.map((m) => m.content).toSet(), {'Message 1', 'Message 2'});
  });

  test('getMessages auto-marks messages as read', () {
    db!.sendMessage(senderName, senderKey, receiverName, 'Test message');

    // First fetch marks as read
    db!.getMessages(receiverName, receiverKey);

    // Second fetch with unreadOnly=true should return empty
    final result = db!.getMessages(receiverName, receiverKey, unreadOnly: true);
    final messages = (result as Success<List<Message>, DbError>).value;
    expect(messages, isEmpty);
  });

  test('getMessages with unreadOnly=false returns all messages', () {
    db!.sendMessage(senderName, senderKey, receiverName, 'Test message');

    // First fetch marks as read
    db!.getMessages(receiverName, receiverKey);

    // Second fetch with unreadOnly=false should still return message
    final result = db!.getMessages(
      receiverName,
      receiverKey,
      unreadOnly: false,
    );
    final messages = (result as Success<List<Message>, DbError>).value;
    expect(messages.length, 1);
  });

  test('getMessages fails with invalid credentials', () {
    final result = db!.getMessages(receiverName, 'wrong-key');
    expect(result, isA<Error<List<Message>, DbError>>());
    final error = (result as Error<List<Message>, DbError>).error;
    expect(error.code, errUnauthorized);
  });

  test('markRead marks specific message', () {
    final sendResult = db!.sendMessage(
      senderName,
      senderKey,
      receiverName,
      'To be read',
    );
    final messageId = (sendResult as Success<String, DbError>).value;

    final result = db!.markRead(messageId, receiverName, receiverKey);
    expect(result, isA<Success<void, DbError>>());
  });

  test('markRead fails for nonexistent message', () {
    final result = db!.markRead('nonexistent-id', receiverName, receiverKey);
    expect(result, isA<Error<void, DbError>>());
    final error = (result as Error<void, DbError>).error;
    expect(error.code, errNotFound);
  });

  test('broadcast message reaches all agents', () {
    // Send broadcast (to_agent = '*' is broadcast)
    db!.sendMessage(senderName, senderKey, '*', 'Announcement!');

    // Receiver should get broadcast messages
    final result = db!.getMessages(receiverName, receiverKey);
    final messages = (result as Success<List<Message>, DbError>).value;
    expect(messages.any((m) => m.content == 'Announcement!'), true);
  });

  test('listAllMessages returns all messages', () {
    db!.sendMessage(senderName, senderKey, receiverName, 'Direct message');
    db!.sendMessage(senderName, senderKey, '*', 'Broadcast');

    final result = db!.listAllMessages();
    expect(result, isA<Success<List<Message>, DbError>>());
    final messages = (result as Success<List<Message>, DbError>).value;
    expect(messages.length, 2);
  });

  test('message contains correct metadata', () {
    db!.sendMessage(senderName, senderKey, receiverName, 'Test');

    final result = db!.getMessages(receiverName, receiverKey);
    final messages = (result as Success<List<Message>, DbError>).value;
    final msg = messages.first;

    expect(msg.fromAgent, senderName);
    expect(msg.toAgent, receiverName);
    expect(msg.content, 'Test');
    expect(msg.createdAt, greaterThan(0));
    expect(msg.id.length, 16);
  });
}
