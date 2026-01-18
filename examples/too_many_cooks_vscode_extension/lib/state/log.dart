/// Cross-platform logging.
///
/// Uses conditional imports to work in both VM (for testing)
/// and JS (for production).
library;

import 'package:too_many_cooks_vscode_extension/state/log_stub.dart'
    if (dart.library.js_interop)
        'package:too_many_cooks_vscode_extension/state/log_js.dart'
    as impl;

/// Log a message. In JS, logs to console. In VM, prints to stdout.
void log(String message) => impl.log(message);
