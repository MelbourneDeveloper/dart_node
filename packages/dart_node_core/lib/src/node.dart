import 'dart:js_interop';
import 'package:dart_node_core/src/interop.dart';

/// Require a Node module
JSAny requireModule(String module) =>
    require.callAsFunction(null, module.toJS)!;
