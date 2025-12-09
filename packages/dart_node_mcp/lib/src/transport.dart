/// Transport interface for MCP communication.
library;

import 'dart:js_interop';

/// Transport interface (matches TypeScript Transport type).
///
/// Transports handle the communication between client and server.
extension type Transport._(JSObject _) implements JSObject {
  /// Start the transport and begin listening for messages.
  external JSPromise<JSAny?> start();

  /// Send a JSON-RPC message through the transport.
  external JSPromise<JSAny?> send(JSObject message);

  /// Close the transport and release resources.
  external JSPromise<JSAny?> close();
}

/// Event callback type for transport messages.
typedef TransportMessageCallback = void Function(JSObject message);

/// Event callback type for transport errors.
typedef TransportErrorCallback = void Function(JSAny error);

/// Event callback type for transport close.
typedef TransportCloseCallback = void Function();
