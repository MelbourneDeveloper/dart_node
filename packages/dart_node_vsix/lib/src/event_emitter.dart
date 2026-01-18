import 'dart:js_interop';

import 'package:dart_node_vsix/src/disposable.dart';
import 'package:dart_node_vsix/src/vscode.dart';

/// An event emitter for VSCode events.
extension type EventEmitter<T extends JSAny?>._(JSObject _)
    implements JSObject {
  /// Creates a new EventEmitter.
  factory EventEmitter() {
    final ctor = _getEventEmitterConstructor(vscode);
    return EventEmitter._(_newInstance(ctor) as JSObject);
  }

  /// The event that listeners can subscribe to.
  external Event<T> get event;

  /// Fires the event with the given data.
  external void fire(T data);

  /// Disposes of this emitter.
  external void dispose();
}

@JS('Reflect.get')
external JSFunction _reflectGet(JSObject obj, JSString key);

@JS('Reflect.construct')
external JSAny _reflectConstruct(JSFunction ctor, JSArray args);

JSFunction _getEventEmitterConstructor(JSObject vscodeModule) =>
    _reflectGet(vscodeModule, 'EventEmitter'.toJS);

JSAny _newInstance(JSFunction ctor) => _reflectConstruct(ctor, <JSAny>[].toJS);

/// An event that can be subscribed to.
extension type Event<T extends JSAny?>._(JSFunction _) implements JSFunction {
  /// Subscribes to this event.
  Disposable call(void Function(T) listener) {
    final jsListener = ((T data) => listener(data)).toJS;
    return _eventSubscribe(_, jsListener);
  }
}

@JS('Reflect.apply')
external Disposable _eventSubscribeReflect(
  JSFunction event,
  JSAny? thisArg,
  JSArray<JSAny?> args,
);

/// Subscribe to a VSCode event.
Disposable _eventSubscribe(JSFunction event, JSFunction listener) =>
    _eventSubscribeReflect(event, null, [listener].toJS);
