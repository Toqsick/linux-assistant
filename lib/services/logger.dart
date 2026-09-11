import 'package:flutter/foundation.dart';

/// Single funnel for the app's diagnostic output.
///
/// These lines are the only trace Linux Assistant leaves behind when something
/// goes wrong on a user's machine, so they are kept rather than deleted — but
/// they go through two functions instead of being scattered `print` calls, so
/// a level, a timestamp or a mute switch can be added in one place.
///
/// [debugPrint] rather than [print]: it is throttled, so a runaway loop cannot
/// flood the journal, and it is the channel Flutter's own diagnostics use.
void logInfo(String message) {
  debugPrint(message);
}

void logError(String message, [Object? error, StackTrace? stackTrace]) {
  debugPrint(error == null ? "Error: $message" : "Error: $message: $error");
  if (stackTrace != null) {
    debugPrint(stackTrace.toString());
  }
}
