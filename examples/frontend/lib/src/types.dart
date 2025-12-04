import 'dart:js_interop';

import 'package:shared/http/http_client.dart';

// Re-export shared JS types
export 'package:shared/js_types/js_types.dart';

/// API configuration
const apiUrl = 'http://localhost:3000';

/// Replaceable fetch - swap this for testing
Fetch fetch = fetchJson;

/// WebSocket URL
const wsUrl = 'ws://localhost:3001';

/// Auth actions - typed setters for authentication state
typedef SetToken = void Function(JSString?);
typedef SetUser = void Function(JSObject?);
typedef SetView = void Function(String);

/// Auth effects bundle - passed to form components
typedef AuthEffects = ({SetToken setToken, SetUser setUser, SetView setView});

/// Task operations
typedef OnToggleTask = void Function(String id, bool completed);
typedef OnDeleteTask = void Function(String id);

/// Task effects bundle
typedef TaskEffects = ({OnToggleTask onToggle, OnDeleteTask onDelete});

/// Event handler effect
typedef OnClick = void Function();
