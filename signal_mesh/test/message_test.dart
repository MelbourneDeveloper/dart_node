import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

import 'package:signal_mesh/signal_mesh.dart';

void main() {
  NodeId _randomId() => switch (nodeIdRandom()) {
    Success(:final value) => value,
    Error(:final error) => throw StateError(error),
  };

  test('createWireMessage creates message with unique ID', () {
    final sender = _randomId();
    final msg = createWireMessage(
      type: MessageType.chat,
      sender: sender,
      payload: {'text': 'hello'},
    );

    expect(msg.id, isNotEmpty);
    expect(msg.type, equals(MessageType.chat));
    expect(msg.payload['text'], equals('hello'));
    expect(msg.ttl, equals(7));
  });

  test('createWireMessage IDs are unique', () {
    final sender = _randomId();
    final msg1 = createWireMessage(
      type: MessageType.ping,
      sender: sender,
      payload: {},
    );
    final msg2 = createWireMessage(
      type: MessageType.ping,
      sender: sender,
      payload: {},
    );
    expect(msg1.id, isNot(equals(msg2.id)));
  });

  test('serializeWireMessage and deserializeWireMessage roundtrip', () {
    final sender = _randomId();
    final recipient = _randomId();
    final msg = createWireMessage(
      type: MessageType.chat,
      sender: sender,
      recipient: recipient,
      payload: {'text': 'hello mesh'},
      ttl: 5,
    );

    final bytes = serializeWireMessage(msg);
    final result = deserializeWireMessage(bytes);

    switch (result) {
      case Success(:final value):
        expect(value.type, equals(MessageType.chat));
        expect(value.payload['text'], equals('hello mesh'));
        expect(value.ttl, equals(5));
        expect(nodeIdToHex(value.sender), equals(nodeIdToHex(sender)));
        expect(
          nodeIdToHex(value.recipient ?? _randomId()),
          equals(nodeIdToHex(recipient)),
        );
      case Error(:final error):
        fail('Deserialize failed: $error');
    }
  });

  test('deserializeWireMessage handles missing recipient', () {
    final sender = _randomId();
    final msg = createWireMessage(
      type: MessageType.ping,
      sender: sender,
      payload: {},
    );

    final bytes = serializeWireMessage(msg);
    final result = deserializeWireMessage(bytes);

    switch (result) {
      case Success(:final value):
        expect(value.recipient, isNull);
      case Error(:final error):
        fail(error);
    }
  });

  test('all MessageType values can roundtrip', () {
    final sender = _randomId();
    for (final type in MessageType.values) {
      final msg = createWireMessage(
        type: type,
        sender: sender,
        payload: {'type_name': type.name},
      );
      final bytes = serializeWireMessage(msg);
      final result = deserializeWireMessage(bytes);
      switch (result) {
        case Success(:final value):
          expect(value.type, equals(type));
        case Error(:final error):
          fail('Failed for type ${type.name}: $error');
      }
    }
  });
}
