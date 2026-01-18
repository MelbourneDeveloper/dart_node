/// JS implementation of logging (for production).
library;

import 'dart:js_interop';

@JS('console.log')
external void _consoleLog(JSAny? message);

/// Log a message to the browser console (JS).
void log(String message) => _consoleLog(message.toJS);
