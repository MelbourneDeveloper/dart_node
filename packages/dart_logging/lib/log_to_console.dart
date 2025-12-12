// This is a console logger
// ignore_for_file: avoid_print
// coverage:ignore-file

import 'dart:io';

import 'package:dart_logging/logging.dart';

const String _reset = '\x1B[0m';

final bool _useColors = !Platform.isIOS;

/// Formats a message with ANSI color codes based on severity level
String _formatMessage(String message, LogLevel severity) =>
    _useColors ? '${severity.ansiColor} $message$_reset' : message;

/// Logs a message to the console with formatting and structured data
void logToConsole(LogMessage message, LogLevel minimumLogLevel) {
  if (message.logLevel.index < minimumLogLevel.index) return;

  final timestamp = DateTime.now().toIso8601String().substring(11, 19);
  final levelIcon = switch (message.logLevel) {
    LogLevel.trace => '🔎',
    LogLevel.debug => '🔍',
    LogLevel.info => 'ℹ️ ',
    LogLevel.warn => '⚠️ ',
    LogLevel.error => '❌',
    LogLevel.fatal => '🚨',
  };

  final tagStr =
      (message.tags?.isNotEmpty ?? false)
          ? '[${message.tags!.join(',')}] '
          : '';

  print('$timestamp $levelIcon $tagStr${message.message}');

  if (message.structuredData?.isNotEmpty ?? false) {
    for (final entry in message.structuredData!.entries) {
      print('  └─ ${entry.key}: ${entry.value}');
    }
  }

  if (message.fault case final fault?) {
    print(_formatMessage('***** Fault *****\n$fault', message.logLevel));
  }

  if (message.stackTrace case final stackTrace?) {
    print(
      _formatMessage('***** Stack Trace *****\n$stackTrace', message.logLevel),
    );
  }
}
