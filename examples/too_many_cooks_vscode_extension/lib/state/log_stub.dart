/// VM implementation of logging (for tests).
library;

/// Log a message to stdout (Dart VM).
void log(String message) {
  // Tests run in VM - print to stdout for debugging
  // ignore: avoid_print
  print(message);
}
