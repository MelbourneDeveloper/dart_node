import 'dart:js_interop';

import 'package:dart_node_vsix/src/disposable.dart';

/// An event emitter for VSCode events.
extension type EventEmitter<T extends JSAny?>._(JSObject _)
    implements JSObject {
  /// Creates a new EventEmitter.
  factory EventEmitter() => _eventEmitterConstructor();

  /// The event that listeners can subscribe to.
  external Event<T> get event;

  /// Fires the event with the given data.
  external void fire(T data);

  /// Disposes of this emitter.
  external void dispose();
}

@JS('vscode.EventEmitter')
external EventEmitter<T> _eventEmitterConstructor<T extends JSAny?>();

/// An event that can be subscribed to.
extension type Event<T extends JSAny?>._(JSFunction _) implements JSFunction {
  /// Subscribes to this event.
  Disposable call(void Function(T) listener) {
    final jsListener = ((T data) => listener(data)).toJS;
    return _eventSubscribe(_, jsListener);
  }
}

@JS()
external Disposable _eventSubscribe(JSFunction event, JSFunction listener);
