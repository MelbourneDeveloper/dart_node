import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_node_react/dart_node_react.dart' hide view;
import 'package:dart_node_react_native/dart_node_react_native.dart';
import 'package:nadz/nadz.dart';
import 'package:shared/http/http_client.dart';
import 'package:shared/theme/theme.dart';

import '../types.dart';
import '../websocket.dart';

/// Pomodoro timer screen component
ReactElement pomodoroScreen({
  required String token,
  required void Function() onBack,
  Fetch? fetchFn,
}) => functionalComponent('PomodoroScreen', (JSObject props) {
  final sessionState = useState<JSPomodoroSession?>(null);
  final timerState = useState<JSPomodoroEvent?>(null);
  final loadingState = useState(true);
  final errorState = useState<String?>(null);

  final session = sessionState.value;
  final timer = timerState.value;
  final loading = loadingState.value;
  final error = errorState.value;

  // Load active session
  useEffect(() {
    _loadActiveSession(token, sessionState, loadingState, errorState, fetchFn);
    return null;
  }, [token]);

  // WebSocket connection for real-time timer updates
  useEffect(() {
    final ws = connectWebSocket(
      token: token,
      onTaskEvent: (jsEvent) => _handlePomodoroEvent(jsEvent, timerState),
    );
    return () => ws?.close();
  }, [token]);

  void handleStart() {
    final currentSession = session;
    (currentSession == null)
        ? _createAndStartSession(token, sessionState, errorState, fetchFn)
        : _startSession(token, currentSession.id, errorState, fetchFn);
  }

  void handlePause() {
    final currentSession = session;
    (currentSession == null)
        ? null
        : _pauseSession(token, currentSession.id, errorState, fetchFn);
  }

  void handleResume() {
    final currentSession = session;
    (currentSession == null)
        ? null
        : _resumeSession(token, currentSession.id, errorState, fetchFn);
  }

  void handleStop() {
    final currentSession = session;
    (currentSession == null)
        ? null
        : _stopSession(
            token,
            currentSession.id,
            sessionState,
            timerState,
            errorState,
            fetchFn,
          );
  }

  return view(
    style: AppStyles.container,
    children: [
      _buildHeader(onBack),
      loading
          ? view(
              style: {'flex': 1, 'justifyContent': 'center'},
              child: activityIndicator(
                size: 'large',
                color: AppColors.accentPrimary,
              ),
            )
          : (error?.isNotEmpty ?? false)
          ? view(
              style: {...AppStyles.errorMsg, 'margin': AppSpacing.xl},
              child: text(error ?? '', style: AppStyles.errorText),
            )
          : _buildTimerContent(
              session: session,
              timer: timer,
              onStart: handleStart,
              onPause: handlePause,
              onResume: handleResume,
              onStop: handleStop,
            ),
    ].whereType<ReactElement>().toList(),
  );
});

RNViewElement _buildHeader(void Function() onBack) => view(
  style: AppStyles.header,
  children: [
    touchableOpacity(
      onPress: onBack,
      child: text('← Back', style: AppStyles.logoutText),
    ),
    text('Pomodoro Timer', style: AppStyles.headerTitle),
    view(style: {'width': 60}),
  ],
);

ReactElement _buildTimerContent({
  required JSPomodoroSession? session,
  required JSPomodoroEvent? timer,
  required void Function() onStart,
  required void Function() onPause,
  required void Function() onResume,
  required void Function() onStop,
}) {
  final state = timer?.state ?? 'idle';
  final defaultDuration = (session?.duration ?? 25) * 60;
  final remainingSeconds = timer?.remainingSeconds ?? defaultDuration;
  final sessionTitle = session?.title ?? 'Focus Session';

  return view(
    style: AppStyles.centeredContent,
    children: [
      view(
        style: AppStyles.pomodoroTimerContainer,
        children: [
          text(sessionTitle, style: _styles.sessionTitle),
          view(style: {'height': AppSpacing.lg}),
          text(stateDisplayText(state), style: _styles.stateText(state)),
          view(style: {'height': AppSpacing.xxl}),
          _buildTimerDisplay(remainingSeconds, state),
          view(style: {'height': AppSpacing.xxl}),
          _buildControls(
            state: state,
            onStart: onStart,
            onPause: onPause,
            onResume: onResume,
            onStop: onStop,
          ),
          view(style: {'height': AppSpacing.xl}),
          _buildSessionDots(completedSessions: 0, totalSessions: 4),
        ],
      ),
    ],
  );
}

RNViewElement _buildTimerDisplay(int seconds, String state) {
  final timeText = formatTime(seconds);
  return view(
    style: _styles.timerCircle(state),
    child: text(timeText, style: _styles.timerText),
  );
}

RNViewElement _buildControls({
  required String state,
  required void Function() onStart,
  required void Function() onPause,
  required void Function() onResume,
  required void Function() onStop,
}) {
  final isIdle = state == 'idle';
  final isPaused = state == 'paused';
  final isActive = state == 'working' || state == 'onBreak';

  return view(
    style: _styles.controlsContainer,
    children: [
      isIdle
          ? touchableOpacity(
              onPress: onStart,
              style: _styles.primaryButton,
              child: text('Start', style: _styles.primaryButtonText),
            )
          : isActive
          ? touchableOpacity(
              onPress: onPause,
              style: _styles.secondaryButton,
              child: text('Pause', style: _styles.secondaryButtonText),
            )
          : touchableOpacity(
              onPress: onResume,
              style: _styles.primaryButton,
              child: text('Resume', style: _styles.primaryButtonText),
            ),
      view(style: {'width': AppSpacing.lg}),
      (isActive || isPaused)
          ? touchableOpacity(
              onPress: onStop,
              style: _styles.dangerButton,
              child: text('Stop', style: _styles.dangerButtonText),
            )
          : null,
    ].whereType<ReactElement>().toList(),
  );
}

/// Build session progress dots (pomodoros completed)
RNViewElement _buildSessionDots({
  required int completedSessions,
  required int totalSessions,
}) => view(
  style: AppStyles.pomodoroSessionCounter,
  children: [
    for (var i = 0; i < totalSessions; i++)
      view(
        style: i < completedSessions
            ? AppStyles.pomodoroSessionDotCompleted
            : AppStyles.pomodoroSessionDotPending,
      ),
  ],
);

void _loadActiveSession(
  String token,
  StateHook<JSPomodoroSession?> sessionState,
  StateHook<bool> loadingState,
  StateHook<String?> errorState,
  Fetch? fetchFn,
) {
  final doFetch = fetchFn ?? fetchJson;
  doFetch('$apiUrl/pomodoro/active', token: token)
      .then((result) {
        result.match(
          onSuccess: (response) {
            final data = response['data'];
            switch (data) {
              case final JSObject obj:
                sessionState.set(JSPomodoroSession.fromJS(obj));
              case _:
                sessionState.set(null);
            }
            errorState.set(null);
          },
          onError: (message) {
            sessionState.set(null);
            errorState.set(null);
          },
        );
      })
      .catchError((Object e) {
        errorState.set(e.toString());
      })
      .whenComplete(() {
        loadingState.set(false);
      });
}

void _createAndStartSession(
  String token,
  StateHook<JSPomodoroSession?> sessionState,
  StateHook<String?> errorState,
  Fetch? fetchFn,
) {
  final doFetch = fetchFn ?? fetchJson;
  doFetch(
        '$apiUrl/pomodoro/start',
        method: 'POST',
        token: token,
        body: {'title': 'Focus Session', 'duration': 25, 'breakDuration': 5},
      )
      .then((result) {
        result.match(
          onSuccess: (response) {
            final data = response['data'];
            switch (data) {
              case final JSObject obj:
                sessionState.set(JSPomodoroSession.fromJS(obj));
              case _:
                errorState.set('Failed to start session');
            }
          },
          onError: (message) => errorState.set(message),
        );
      })
      .catchError((Object e) {
        errorState.set(e.toString());
      });
}

void _startSession(
  String token,
  String sessionId,
  StateHook<String?> errorState,
  Fetch? fetchFn,
) {
  // Session already started via /pomodoro/start - this is a no-op
  // The API creates and starts in one call
  errorState.set(null);
}

void _pauseSession(
  String token,
  String sessionId,
  StateHook<String?> errorState,
  Fetch? fetchFn,
) {
  final doFetch = fetchFn ?? fetchJson;
  doFetch('$apiUrl/pomodoro/$sessionId/pause', method: 'POST', token: token)
      .then((result) {
        result.match(
          onSuccess: (_) => errorState.set(null),
          onError: (message) => errorState.set(message),
        );
      })
      .catchError((Object e) {
        errorState.set(e.toString());
      });
}

void _resumeSession(
  String token,
  String sessionId,
  StateHook<String?> errorState,
  Fetch? fetchFn,
) {
  final doFetch = fetchFn ?? fetchJson;
  doFetch('$apiUrl/pomodoro/$sessionId/resume', method: 'POST', token: token)
      .then((result) {
        result.match(
          onSuccess: (_) => errorState.set(null),
          onError: (message) => errorState.set(message),
        );
      })
      .catchError((Object e) {
        errorState.set(e.toString());
      });
}

void _stopSession(
  String token,
  String sessionId,
  StateHook<JSPomodoroSession?> sessionState,
  StateHook<JSPomodoroEvent?> timerState,
  StateHook<String?> errorState,
  Fetch? fetchFn,
) {
  final doFetch = fetchFn ?? fetchJson;
  doFetch('$apiUrl/pomodoro/$sessionId/complete', method: 'POST', token: token)
      .then((result) {
        result.match(
          onSuccess: (_) {
            sessionState.set(null);
            timerState.set(null);
            errorState.set(null);
          },
          onError: (message) => errorState.set(message),
        );
      })
      .catchError((Object e) {
        errorState.set(e.toString());
      });
}

void _handlePomodoroEvent(JSObject jsEvent, StateHook<JSPomodoroEvent?> timerState) {
  final eventType = jsEvent['type'];
  switch (eventType) {
    case final JSString t when t.toDart == 'pomodoro_tick' || t.toDart == 'pomodoro_update':
      final data = jsEvent['data'];
      switch (data) {
        case final JSObject obj:
          timerState.set(JSPomodoroEvent.fromJS(obj));
        case _:
          break;
      }
    case _:
      break;
  }
}

final _styles = _PomodoroStyles();

class _PomodoroStyles {
  Map<String, Object?> get sessionTitle => {
    'fontSize': 24,
    'fontWeight': '600',
    'color': AppColors.textPrimary,
    'textAlign': 'center',
  };

  Map<String, Object?> stateText(String state) => {
    'fontSize': 18,
    'fontWeight': '500',
    'color': stateColor(state),
    'textAlign': 'center',
    'textTransform': 'uppercase',
    'letterSpacing': 2,
  };

  /// Use the shared pomodoro circle styles based on state
  Map<String, Object?> timerCircle(String state) => switch (state) {
    'working' => AppStyles.pomodoroCircleWork,
    'onBreak' => AppStyles.pomodoroCircleShortBreak,
    'paused' => AppStyles.pomodoroCirclePaused,
    _ => AppStyles.pomodoroCircle,
  };

  Map<String, Object?> get timerText => AppStyles.pomodoroTimeText;

  Map<String, Object?> get controlsContainer => AppStyles.pomodoroControls;

  Map<String, Object?> get primaryButton => AppStyles.pomodoroControlBtnPrimary;

  Map<String, Object?> get primaryButtonText => AppStyles.pomodoroControlIcon;

  Map<String, Object?> get secondaryButton => AppStyles.pomodoroControlBtnSecondary;

  Map<String, Object?> get secondaryButtonText => AppStyles.pomodoroControlIconSecondary;

  Map<String, Object?> get dangerButton => {
    ...AppStyles.pomodoroControlBtnSecondary,
    'backgroundColor': AppColors.danger,
    'borderColor': AppColors.danger,
  };

  Map<String, Object?> get dangerButtonText => {
    'color': AppColors.textPrimary,
    'fontSize': 16,
    'fontWeight': '600',
  };
}
