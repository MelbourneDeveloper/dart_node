import 'dart:typed_data';

import 'package:nadz/nadz.dart';
import 'package:test/test.dart';

import 'package:signal_mesh/signal_mesh.dart';

void main() {
  tearDown(clearInMemoryRegistry);

  test('createInMemoryTransport creates a transport', () {
    const addr = (host: '127.0.0.1', port: 8001);
    final transport = createInMemoryTransport(addr);
    expect(transport.connectedPeers(), isEmpty);
  });

  test('two transports can connect', () {
    const addr1 = (host: '127.0.0.1', port: 8001);
    const addr2 = (host: '127.0.0.1', port: 8002);
    final t1 = createInMemoryTransport(addr1);
    final t2 = createInMemoryTransport(addr2);

    final result = t1.connect(addr2);
    switch (result) {
      case Success():
        expect(t1.isConnected(addr2), isTrue);
        expect(t2.isConnected(addr1), isTrue);
      case Error(:final error):
        fail('Connect failed: $error');
    }
  });

  test('connect to nonexistent peer fails', () {
    const addr1 = (host: '127.0.0.1', port: 8001);
    const ghost = (host: '127.0.0.1', port: 9999);
    final t1 = createInMemoryTransport(addr1);

    final result = t1.connect(ghost);
    expect(result, isA<Error<void, String>>());
  });

  test('send delivers message to remote', () {
    const addr1 = (host: '127.0.0.1', port: 8001);
    const addr2 = (host: '127.0.0.1', port: 8002);
    final t1 = createInMemoryTransport(addr1);
    final t2 = createInMemoryTransport(addr2);

    TransportEventData? received;
    t2.onEvent((event) {
      if (event.event == TransportEvent.message) received = event;
    });

    t1.connect(addr2);
    final data = Uint8List.fromList([1, 2, 3]);
    t1.send(addr2, data);

    expect(received, isNotNull);
    expect(received?.data, equals([1, 2, 3]));
    expect(received?.peer, equals(addr1));
  });

  test('send to disconnected peer fails', () {
    const addr1 = (host: '127.0.0.1', port: 8001);
    const addr2 = (host: '127.0.0.1', port: 8002);
    final t1 = createInMemoryTransport(addr1);
    createInMemoryTransport(addr2);

    final result = t1.send(addr2, Uint8List(0));
    expect(result, isA<Error<void, String>>());
  });

  test('disconnect removes connection from both sides', () {
    const addr1 = (host: '127.0.0.1', port: 8001);
    const addr2 = (host: '127.0.0.1', port: 8002);
    final t1 = createInMemoryTransport(addr1);
    final t2 = createInMemoryTransport(addr2);

    t1.connect(addr2);
    expect(t1.isConnected(addr2), isTrue);

    t1.disconnect(addr2);
    expect(t1.isConnected(addr2), isFalse);
    expect(t2.isConnected(addr1), isFalse);
  });

  test('close disconnects all peers', () {
    const addr1 = (host: '127.0.0.1', port: 8001);
    const addr2 = (host: '127.0.0.1', port: 8002);
    const addr3 = (host: '127.0.0.1', port: 8003);
    final t1 = createInMemoryTransport(addr1);
    final t2 = createInMemoryTransport(addr2);
    final t3 = createInMemoryTransport(addr3);

    t1.connect(addr2);
    t1.connect(addr3);
    expect(t1.connectedPeers().length, equals(2));

    t1.close();
    expect(t2.isConnected(addr1), isFalse);
    expect(t3.isConnected(addr1), isFalse);
  });

  test('encodeMessage and decodeMessage roundtrip', () {
    final msg = {'type': 'hello', 'data': 42};
    final encoded = encodeMessage(msg);
    final decoded = decodeMessage(encoded);
    switch (decoded) {
      case Success(:final value):
        expect(value['type'], equals('hello'));
        expect(value['data'], equals(42));
      case Error(:final error):
        fail('Decode failed: $error');
    }
  });

  test('decodeMessage fails on invalid data', () {
    final result = decodeMessage(Uint8List.fromList([0xFF, 0xFE]));
    expect(result, isA<Error<Map<String, Object?>, String>>());
  });

  test('connection events are emitted', () {
    const addr1 = (host: '127.0.0.1', port: 8001);
    const addr2 = (host: '127.0.0.1', port: 8002);
    final t1 = createInMemoryTransport(addr1);
    createInMemoryTransport(addr2);

    final events = <TransportEvent>[];
    t1.onEvent((event) => events.add(event.event));

    t1.connect(addr2);
    t1.disconnect(addr2);

    expect(events, contains(TransportEvent.connected));
    expect(events, contains(TransportEvent.disconnected));
  });
}
