import 'package:flutter/foundation.dart';

/// Logs [message] only in debug builds. Avoids unbounded `print` output in
/// release, where these run every second from the timer/foreground service.
void logDebug(Object? message) {
  if (kDebugMode) {
    print(message);
  }
}
